#!/bin/bash

readonly PROJECT_PATH=$(dirname $(dirname "$(readlink -f "$0")"))

. "$PROJECT_PATH/scripts/helper_functions.sh"
. "$PROJECT_PATH/scripts/reTerminal2_functions.sh"

################################################################################
# Parse options

EXIT_AFTER_PRINT_ENVIRONMENT=n
UNINSTALL_MODULES_ONLY=n
while [ $# -gt 0 ]
do
  case $1 in
    --print-environment)
      EXIT_AFTER_PRINT_ENVIRONMENT=Y
      shift
      ;;
    --uninstall-modules)
      UNINSTALL_MODULES_ONLY=Y
      shift
      ;;
    --)
      set --
      ;;
    *) 
      echo 'ERROR: Unknown option. '"$1"
      exit 1
      ;;
  esac
done
readonly EXIT_AFTER_PRINT_ENVIRONMENT
readonly UNINSTALL_MODULES_ONLY

################################################################################
# Set constant (1st phase)

readonly DTOVERLAY_PATH=overlays/rpi  # Makefile does not support full path. :(

readonly MODEL=reTerminal
readonly REQUIRED_PACKAGES='dkms'
readonly REQUIRED_MODULES='mipi_dsi ltr30x lis3lv02d bq24179_charger'
readonly REQUIRED_DTOVERLAYS='reTerminal'

readonly DISTRO_ID=$(lsb_release -is)
readonly DISTRO_CODE=$(lsb_release -cs)
readonly KERNEL_RELEASE=$(uname -r)
readonly MACHINE=$(uname -m)
readonly PKGMGR_ARCH=$(dpkg --print-architecture)

if [ -e /boot/firmware/config.txt ]
then
  BOOTFS_PATH=/boot/firmware
elif [ -e /boot/config.txt ]
then
  BOOTFS_PATH=/boot
else
  exit 1
fi
readonly BOOTFS_PATH

readonly MODULE_DEST_PATH=/usr/src
readonly MODULE_PATH=$(dirname "$(dirname "$(readlink -f "$0")")")/modules
readonly RESOURCE_PATH=$(dirname "$(dirname "$(readlink -f "$0")")")/extras/reTerminal/resources

readonly DISPLAY_MANAGER=$(basename "$(cat /etc/X11/default-display-manager)")
case $DISPLAY_MANAGER in
  lightdm)
    GREETER_SESSION=$(grep ^greeter-session= /etc/lightdm/lightdm.conf)
    GREETER_SESSION=${GREETER_SESSION#*=}
    USER_SESSION=$(grep ^user-session= /etc/lightdm/lightdm.conf)
    USER_SESSION=${USER_SESSION#*=}
    ;;
  gdm3)
    ;;
  *)
    echo 'ERROR: Unsupported display manager. '"$DISPLAY_MANAGER"
    exit 1
    ;;
esac
readonly GREETER_SESSION
readonly USER_SESSION

################################################################################
# Set constant (2nd phase)

readonly CONFIG_TXT="$BOOTFS_PATH/config.txt"
readonly CMDLINE_TXT="$BOOTFS_PATH/cmdline.txt"
readonly DTOVERLAY_DEST_PATH="$BOOTFS_PATH/overlays"

case $DISTRO_ID in
  Raspbian|Debian)
    case $DISTRO_CODE in
      buster|bullseye)
        KERNEL_PACKAGE_NAME=raspberrypi-kernel
        KERNEL_HEADERS_PACKAGE_NAME=raspberrypi-kernel-headers
        ;;
      bookworm)
        KERNEL_PACKAGE_NAME=linux-image-rpi-${KERNEL_RELEASE##*-}
        KERNEL_HEADERS_PACKAGE_NAME=linux-headers-rpi-${KERNEL_RELEASE##*-}
        ;;
    esac
    ;;
  Ubuntu)
    KERNEL_PACKAGE_NAME=linux-image-raspi
    KERNEL_HEADERS_PACKAGE_NAME=linux-headers-raspi
    ;;
esac
readonly KERNEL_PACKAGE_NAME
readonly KERNEL_HEADERS_PACKAGE_NAME

################################################################################
# Print environment

echo
echo '### Environment'
echo '# script commit:                '"$(git describe --always --tags)"
echo '# model:                        '"$MODEL"
echo -n '# generator comment:            '
if [ -e "$BOOTFS_PATH/issue.txt" ]
then
  echo "$(sed -n '1p' "$BOOTFS_PATH/issue.txt")"
else
  echo '(unknown)'
fi
echo '# distributor ID:               '"$DISTRO_ID"
echo '# distributor code:             '"$DISTRO_CODE"
echo '# kernel release:               '"$KERNEL_RELEASE"
echo '# machine:                      '"$MACHINE"
echo '# package manager architecture: '"$PKGMGR_ARCH"
echo '# bootfs:                       '"$BOOTFS_PATH"
echo '# kernel package name:          '"$KERNEL_PACKAGE_NAME"
echo '# kernel headers package name:  '"$KERNEL_HEADERS_PACKAGE_NAME"
echo '# display manager:              '"$DISPLAY_MANAGER"
[ "$DISPLAY_MANAGER" = 'lightdm' ] &&
{
  echo '# greeter session:              '"$GREETER_SESSION"
  echo '# user session:                 '"$USER_SESSION"
}

echo
echo '### Options'
echo '# exit after print environment: '"$EXIT_AFTER_PRINT_ENVIRONMENT"
echo '# uninstall modules only:       '"$UNINSTALL_MODULES_ONLY"

[ "$EXIT_AFTER_PRINT_ENVIRONMENT" = 'Y' ] && exit 0

################################################################################
# Execute tasks

POST_COMMANDS=

echo
echo '### Check prerequisites'
ui_update_package_list
ui_check_prerequisites

echo
echo '### Packages required'
ui_install_packages

[ "$UNINSTALL_MODULES_ONLY" = 'Y' ] &&
{
  echo
  echo '### Uninstall device tree overlays'
  ui_uninstall_dtoverlays

  echo
  echo '### Uninstall modules'
  ui_uninstall_modules

  echo
  echo '------------------------------------------------------'
  echo 'Please reboot your device to apply all settings'
  echo 'Enjoy!'
  echo '------------------------------------------------------'
  exit 0
}

echo
echo '### Kernel header package required'
ui_install_kernel_headers_package

echo
echo '### Install modules'
ui_uninstall_modules
ui_install_modules

echo
echo '### Install device tree overlays'
ui_uninstall_dtoverlays
ui_install_dtoverlays

echo
echo '### Set model-specific settings'
case $DISTRO_ID in
  Raspbian|Debian)
    case $DISTRO_CODE in
      buster|bookworm)
        set_config_value "$CONFIG_TXT" 'dtoverlay' 'reTerminal,tp_rotate=0'
        ;;
      bullseye)
        set_config_value "$CONFIG_TXT" 'dtoverlay' 'reTerminal,tp_rotate=1'
        ;;
    esac
    ;;
  Ubuntu)
    case $DISTRO_CODE in
      jammy)
        set_config_value "$CONFIG_TXT" 'dtoverlay' 'reTerminal,tp_rotate=1'
        ;;
    esac
    ;;
esac
set_config_value "$CONFIG_TXT" 'dtparam' 'ant2'
set_config_value "$CONFIG_TXT" 'gpio' '13=pu'
set_config_value "$CONFIG_TXT" 'dtoverlay' 'i2c1,pins_2_3'
set_config_value "$CONFIG_TXT" 'dtoverlay' 'i2c3,pins_4_5'

echo
echo '### Set monitor settings'
case $DISTRO_ID in
  Raspbian|Debian)
    case $DISTRO_CODE in
      buster)
        echo "# cp $RESOURCE_PATH/dispsetup.sh /usr/share/dispsetup.sh"
        cp "$RESOURCE_PATH/dispsetup.sh" /usr/share/dispsetup.sh
        ;;
      bullseye)
        # Disable automatic rotation
        POST_COMMANDS="$POST_COMMANDS"$'\n$ gsettings set org.gnome.settings-daemon.peripherals.touchscreen orientation-lock true'

        for file in /home/*
        do
          [ -e "$file/.config/monitors.xml" ] ||
          {
            echo "# cp $RESOURCE_PATH/monitors.xml $file/.config/monitors.xml"
            cp "$RESOURCE_PATH/monitors.xml" "$file/.config/monitors.xml"
          }
        done
        ;;
      bookworm)
        for file in /home/*
        do
          [ -e "$file/.config/wayfire.ini" ] &&
          {
            grep -q '^\[output\:DSI-1\]$' "$file/.config/wayfire.ini" ||
            {
              echo "# cat $RESOURCE_PATH/wayfire.ini.diff >> $file/.config/wayfire.ini"
              cat "$RESOURCE_PATH/wayfire.ini.diff" >> "$file/.config/wayfire.ini"
            }
          }
        done
        ;;
    esac
    ;;
  Ubuntu)
    case $DISTRO_CODE in
      jammy)
        echo "# cp $RESOURCE_PATH/monitors.xml /var/lib/gdm3/.config/monitors.xml"
        cp "$RESOURCE_PATH/monitors.xml" /var/lib/gdm3/.config/monitors.xml

        for file in /home/*
        do
          [ -e "$file/.config/monitors.xml" ] ||
          {
            echo "# cp $RESOURCE_PATH/monitors.xml $file/.config/monitors.xml"
            cp "$RESOURCE_PATH/monitors.xml" "$file/.config/monitors.xml"
          }
        done
        ;;
    esac
    ;;
esac

echo
echo '### Set additional settings'
remove_config_value "$CONFIG_TXT" 'dtoverlay' 'vc4-fkms-v3d'
set_config_value "$CONFIG_TXT" 'dtoverlay' 'vc4-kms-v3d'
set_config_value "$CONFIG_TXT" 'dtoverlay' 'dwc2,dr_mode=host'
set_config_value "$CONFIG_TXT" 'disable_splash' '1'
set_config_value "$CONFIG_TXT" 'ignore_lcd' '1'

grep -Eq '(^|\s+)console=tty\S+($|\s+)' "$CMDLINE_TXT" &&
{
  echo "# sed -ri 's/(^|\s+)console=tty\S+($|\s+)/ /g' $CMDLINE_TXT"
  sed -ri 's/(^|\s+)console=tty\S+($|\s+)/ /g' "$CMDLINE_TXT"
}
echo "# sed -i 's/$/ console=tty3/' $CMDLINE_TXT"
sed -i 's/$/ console=tty3/' "$CMDLINE_TXT"

set_cmdline_value "$CMDLINE_TXT" 'logo.nologo'
set_cmdline_value "$CMDLINE_TXT" 'quiet'
set_cmdline_value "$CMDLINE_TXT" 'loglevel=0'
set_cmdline_value "$CMDLINE_TXT" 'vt.global_cursor_default=0'
set_cmdline_value "$CMDLINE_TXT" 'plymouth.enable=0'

[ -n "$POST_COMMANDS" ] &&
{
  echo
  echo '------------------------------------------------------'
  echo 'Execute command(s) below:'
  echo "$POST_COMMANDS"
  echo '------------------------------------------------------'
}

echo
echo '------------------------------------------------------'
echo 'Please reboot your device to apply all settings'
echo 'Enjoy!'
echo '------------------------------------------------------'
exit 0
