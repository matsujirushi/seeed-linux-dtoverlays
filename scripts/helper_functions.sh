## Obtains free disk space for the specified file/directory.
##
## Returns free disk space to stdout. Unit is bytes.
## @param $1 File(s) and/or directory(s)
## @retval 0 Success.
## @retval 1 Incorrect number of arguments.
## @retval 2 Failed to obtain free disk space.
get_free_space_size()
{
  [ "$#" -lt 1 ] && return 1

  local file
  for file
  do
    local free_space_size=$(df -k --output=avail "$file" 2> /dev/null | tail -n 1)
    [ -z "$free_space_size" ] && return 2
    echo "$(expr "$free_space_size" '*' 1024)"
  done

  return 0
}

## Get the version of the installed package.
##
## Returns the version of the installed package to stdout.
## @param $@ Package name(s)
## @retval 0 Success.
## @retval 1 Incorrect number of arguments.
## @retval 2 Unable to get version of the package.
get_installed_package_version()
{
  [ "$#" -lt 1 ] && return 1

  local name
  for name
  do
    local version=$(dpkg-query -W -f='${Version}' "$name" 2> /dev/null)
    [ "$?" -ne 0 ] && return 2
    echo "$version"
  done

  return 0
}

## Get the latest version of the package.
##
## Returns the latest version of the package to stdout.
## @param $@ Package name(s)
## @retval 0 Success.
## @retval 1 Incorrect number of arguments.
## @retval 2 Unable to get version of the package.
get_new_package_version()
{
  [ "$#" -lt 1 ] && return 1

  local name
  for name
  do
    local version=$(apt-cache policy "$name" | grep 'Candidate:' | awk '{print $2}')
    [ -z "$version" ] && return 2
    echo "$version"
  done

  return 0
}

## Get the URI of the package.
## This function can only be used on Raspbian.
##
## Returns the URI of the package to stdout.
## @param $1 Package name
## @param $2 Package version
## @param $3 Package architecture
## @retval 0 Success.
## @retval 1 Incorrect number of arguments.
## @retval 2 Can't find the package.
get_download_uri_raspbian()
{
  [ "$#" -ne 3 ] && return 1

  local name="$1"
  local version="$2"
  local arch="$3"

  local uri=$(apt-get --print-uris download "$name" 2> /dev/null)
  [ "$?" -ne 0 ] && return 2

  uri="${uri#*\'}"
  uri="${uri%%\'*}"
  echo "${uri%/*}/${name}_${version#*:}_${arch}.deb" # Remove epoch

  return 0
}

## Get the version from the module's dkms.conf file.
##
## Returns the version to stdout.
## @param $@ Directory(s) containing the dkms.conf file
## @retval 0 Success.
## @retval 1 Incorrect number of arguments.
## @retval 2 Version cannot be obtained.
get_module_version_from_file()
{
  [ "$#" -lt 1 ] && return 1

  local path
  for path
  do
    unset version
    local version
    [ -f "$path/dkms.conf" ] &&
    {
      version=$(grep 'PACKAGE_VERSION=' "$path/dkms.conf")
      version=${version#*=}
      version=${version#\"}
      version=${version%\"}
    }
    [ -z "$version" ] && return 2
    echo "$version"
  done

  return 0
}

## Add settings to config.txt file.
##
## @param $1 File (config.txt)
## @param $2 Key name
## @param $3 Value
## @retval 0 Success.
## @retval 1 Incorrect number of arguments.
set_config_value()
{
  [ "$#" -ne 3 ] && return 1

  local file="$1"
  local key="$2"
  local value="$3"

  # Already set.
  grep -q "^$key=$value$" "$file" && return 0

  echo "# echo $key=$value >> $file"
  echo "$key=$value" >> "$file"

  return 0
}

## Remove settings from config.txt file.
##
## @param $1 File (config.txt)
## @param $2 Key name
## @param $3 Value
## @retval 0 Success.
## @retval 1 Incorrect number of arguments.
remove_config_value()
{
  [ "$#" -ne 3 ] && return 1

  local file="$1"
  local key="$2"
  local value="$3"

  echo "# sed -i /^$key=$value$/d $file"
  sed -i "/^$key=$value$/d" "$file"

  return 0
}

## Add settings to cmdline.txt file.
##
## @param $1 File (cmdline.txt)
## @param $2 Value
## @retval 0 Success.
## @retval 1 Incorrect number of arguments.
set_cmdline_value()
{
  [ "$#" -ne 2 ] && return 1

  local file="$1"
  local value="$2"

  # Already set.
  grep -Eq "(^|\s+)$value($|\s+)" "$file" && return 0

  echo "# sed -i \"s/$/ $value/\" $file"
  sed -i "s/$/ $value/" "$file"

  return 0
}

## Remove settings from cmdline.txt file.
##
## @param $1 File (cmdline.txt)
## @param $2 Value
## @retval 0 Success.
## @retval 1 Incorrect number of arguments.
remove_cmdline_value()
{
  [ "$#" -ne 2 ] && return 1

  local file="$1"
  local value="$2"

  echo "# sed -ri \"s/(^|\s+)$value($|\s+)/ /g\" $file"
  sed -ri "s/(^|\s+)$value($|\s+)/ /g" "$file"
}
