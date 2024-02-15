################################################################################
# Interactive functions

ui_check_prerequisites()
{
  echo '## Check distributor'
  case $DISTRO_ID in
    Raspbian|Debian)
      case $DISTRO_CODE in
        buster|bullseye|bookworm)
          ;;
        *)
          echo 'ERROR: Unsupported distributor. '"$DISTRO_ID $DISTRO_CODE"
          exit 1
          ;;
      esac
      ;;
    Ubuntu)
      ;;
    *)
      echo 'ERROR: Unsupported distributor. '"$DISTRO_ID"
      exit 1
      ;;
  esac
  if [ "$PKGMGR_ARCH" = 'armhf' -a "$MACHINE" != 'armv7l' ] || [ "$PKGMGR_ARCH" = 'arm64' -a "$MACHINE" != 'aarch64' ]
  then
    echo 'ERROR: Combination of unsupported machine and package manager architecture. '"$MACHINE $PKGMGR_ARCH"
    exit 1
  fi
  
  echo '## Check user'
  [ "$EUID" -ne 0 ] &&
  {
    echo 'ERROR: Not root user. This script must be run as root user (using sudo).'
    exit 1
  }

  echo '## Check bootfs free space'
  local free_space_size=$(get_free_space_size "$BOOTFS_PATH")
  [ "$?" -ne 0 ] &&
  {
    echo 'ERROR: Unable to obtain bootfs free space. '"$BOOTFS_PATH"
    exit 1
  }
  [ "$free_space_size" -lt 26214400 ] && # < 25MiB
  {
    echo 'ERROR: There is not enough free space in bootfs. '"$BOOTFS_PATH"
    exit 1
  }

  echo '## Check kernel version'
  case $DISTRO_ID in
    Raspbian|Debian)
      case $DISTRO_CODE in
        buster)
          local installed_version=$(get_installed_package_version "$KERNEL_PACKAGE_NAME")
          local new_version=$(get_new_package_version "$KERNEL_PACKAGE_NAME")
          [ "$installed_version" != "$new_version" ] &&
          {
            echo 'ERROR: The kernel version is out of date. It must be brought up to date when using buster. '"$installed_version $new_version"
            echo
            echo '------------------------------------------------------'
            echo 'Execute command(s) below:'
            echo
            echo '$ sudo apt --only-upgrade install raspberrypi-kernel'
            echo '$ sudo poweroff'
            echo '------------------------------------------------------'
            exit 1
          }
          ;;
      esac
      ;;
  esac
}

ui_update_package_list()
{
  echo '## Update package list'
  echo '# apt-get update'
  apt-get update &> /dev/null
  [ "$?" -ne 0 ] &&
  {
    echo 'ERROR: Unable to update package list.'
    exit 1
  }
}

ui_install_packages()
{
  [ -n "$REQUIRED_PACKAGES" ] &&
  {
    echo '## Install/upgrade packages'
    echo "# apt-get -y --no-install-recommends install $REQUIRED_PACKAGES"
    apt-get -y --no-install-recommends install $REQUIRED_PACKAGES &> /dev/null
    [ "$?" -ne 0 ] &&
    {
      echo 'ERROR: Could not install/upgrade packages.'
      exit 1
    }
  }
}

ui_install_kernel_headers_package()
{
  echo '## Get the version of the kernel package'
  local kernel_package_version=$(get_installed_package_version "$KERNEL_PACKAGE_NAME")
  [ "$?" -ne 0 ] &&
  {
    unset kernel_package_version
  }
  echo "# $kernel_package_version"

  echo '## Get the version of the kernel headers package'
  local kernel_headers_package_version=$(get_installed_package_version "$KERNEL_HEADERS_PACKAGE_NAME")
  [ "$?" -ne 0 ] &&
  {
    unset kernel_headers_package_version
  }
  echo "# $kernel_headers_package_version"

  [ -n "$kernel_package_version" -a "$kernel_package_version" != "$kernel_headers_package_version" ] &&
  {
    if [ "$KERNEL_PACKAGE_NAME" = 'raspberrypi-kernel' ]
    then
      echo '## Install specific kernel headers package'
      local uri=$(get_download_uri_raspbian "$KERNEL_HEADERS_PACKAGE_NAME" "$kernel_package_version" "$PKGMGR_ARCH")
      [ "$?" -ne 0 ] &&
      {
        echo 'ERROR: Could not get download uri. '"$KERNEL_HEADERS_PACKAGE_NAME $kernel_package_version $PKGMGR_ARCH"
        exit 1
      }
    
      local file=/tmp/${uri##*/}
    
      echo "# wget $uri -O $file"
      wget "$uri" -O "$file" &> /dev/null
      [ "$?" -ne 0 ] &&
      {
        echo 'ERROR: Unable to download. '"$uri"
        exit 1
      }

      echo "# dpkg -i $file"
      dpkg -i "$file" &> /dev/null
      [ "$?" -ne 0 ] &&
      {
        rm "$file"
        echo 'ERROR: Unable to install. '"$file"
        exit 1
      }

      rm "$file"
    else
      local packages=$KERNEL_HEADERS_PACKAGE_NAME=$kernel_package_version
      echo "# apt-get -y --no-install-recommends install $packages"
      apt-get -y --no-install-recommends install $packages &> /dev/null
      [ "$?" -ne 0 ] &&
      {
        echo 'ERROR: Could not install/upgrade packages.'
        exit 1
      }
    fi
  }
}

ui_install_modules()
{
  echo '## Copy all module source'
  local name
  for name in $REQUIRED_MODULES
  do
    local version=$(get_module_version_from_file "$MODULE_PATH/$name")
    [ "$?" -ne 0 ] &&
    {
      echo 'ERROR: Unable to get module version. '"$name"
      exit 1
    }

    echo "# rm -rf $MODULE_DEST_PATH/$name-$version"
    rm -rf "$MODULE_DEST_PATH/$name-$version"
    echo "# cp -r $MODULE_PATH/$name $MODULE_DEST_PATH/$name-$version"
    cp -r "$MODULE_PATH/$name" "$MODULE_DEST_PATH/$name-$version"
  done

  echo '## Build modules'
  local name
  for name in $REQUIRED_MODULES
  do
    local version=$(get_module_version_from_file "$MODULE_PATH/$name")
    [ "$?" -ne 0 ] &&
    {
      echo 'ERROR: Unable to get module version. '"$name"
      exit 1
    }

    echo "# dkms build $name/$version"
    dkms build "$name/$version" &> /dev/null
    [ "$?" -ne 0 ] &&
    {
      echo 'ERROR: An error occurred in the module build. Check the log file. '"/var/lib/dkms/$name/$version/$KERNEL_RELEASE/$MACHINE/log/make.log"
      exit 1
    }
  done

  echo '## Install modules'
  local name
  for name in $REQUIRED_MODULES
  do
    local version=$(get_module_version_from_file "$MODULE_PATH/$name")
    [ "$?" -ne 0 ] &&
    {
      echo 'ERROR: Unable to get module version. '"$name"
      exit 1
    }

    echo "# dkms install $name/$version"
    dkms install "$name/$version"
    [ "$?" -ne 0 ] &&
    {
      echo 'ERROR: An error occurred in the module install. '"$name/$version"
      exit 1
    }
  done
}

ui_uninstall_modules()
{
  echo '## Remove modules'
  local name
  for name in $REQUIRED_MODULES
  do
    local version=$(get_module_version_from_file "$MODULE_PATH/$name")
    [ "$?" -ne 0 ] &&
    {
      echo 'ERROR: Unable to get module version. '"$name"
      exit 1
    }

    echo "# dkms remove $name/$version --all"
    dkms remove "$name/$version" --all &> /dev/null
  done

  echo '## Remove all module source'
  local name
  for name in $REQUIRED_MODULES
  do
    local version=$(get_module_version_from_file "$MODULE_PATH/$name")
    [ "$?" -ne 0 ] &&
    {
      echo 'ERROR: Unable to get module version. '"$name"
      exit 1
    }

    echo "# rm -rf $MODULE_DEST_PATH/$name-$version"
    rm -rf "$MODULE_DEST_PATH/$name-$version" &> /dev/null
  done
}

ui_install_dtoverlays()
{
  echo '## Build device tree overlays'
  local name
  for name in $REQUIRED_DTOVERLAYS
  do
    echo "# make $DTOVERLAY_PATH/$name-overlay.dtbo"
    make "$DTOVERLAY_PATH/$name-overlay.dtbo"
    [ "$?" -ne 0 ] &&
    {
      echo 'ERROR: An error occurred in the device tree overlay build. '"$DTOVERLAY_PATH/$name-overlay.dts"
      exit 1
    }
    echo "# rm $DTOVERLAY_PATH/.$name-overlay.dtbo.*"
    rm $DTOVERLAY_PATH/.$name-overlay.dtbo.*
  done

  echo '## Copy device tree overlays'
  local name
  for name in $REQUIRED_DTOVERLAYS
  do
    echo "# rm $DTOVERLAY_DEST_PATH/$name.dtbo"
    rm "$DTOVERLAY_DEST_PATH/$name.dtbo" &> /dev/null
    echo "# mv $DTOVERLAY_PATH/$name-overlay.dtbo $DTOVERLAY_DEST_PATH/$name.dtbo"
    mv "$DTOVERLAY_PATH/$name-overlay.dtbo" "$DTOVERLAY_DEST_PATH/$name.dtbo"
  done
}

ui_uninstall_dtoverlays()
{
  echo '## Remove device tree overlays'
  local name
  for name in $REQUIRED_DTOVERLAYS
  do
    echo "# rm $DTOVERLAY_DEST_PATH/$name.dtbo"
    rm "$DTOVERLAY_DEST_PATH/$name.dtbo" &> /dev/null
  done
}
