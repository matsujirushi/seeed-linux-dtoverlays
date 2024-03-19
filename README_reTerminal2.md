# The reTerminal driver

This repository is a device driver for reTerminal.

Except for the following Support Hardwares and Support Platforms, I do not support any other platforms.
The drivers for other devices are included because they are cloned and modified from [the Seeed Studio repository](https://github.com/Seeed-Studio/seeed-linux-dtoverlays), but they are not maintained.

## Support Hardwares

* [reTerminal CM4104032](https://www.seeedstudio.com/ReTerminal-with-CM4-p-4904.html)
* [reTerminal CM4108032](https://www.seeedstudio.com/reTerminal-CM4108032-p-5712.html)

## Support Platforms

* Raspberry Pi OS 32-bit
  * 2021-05-07-raspios-buster-armhf.zip
  * 2023-02-21-raspios-bullseye-armhf.img.xz
  * ~~2023-05-03-raspios-bullseye-armhf.img.xz (arm_64bit=1)~~ (*1)
  * 2023-05-03-raspios-bullseye-armhf.img.xz arm_64bit=0
  * ~~2023-10-10-raspios-bookworm-armhf.img.xz (arm_64bit=1)~~ (*1)
  * 2023-10-10-raspios-bookworm-armhf.img.xz arm_64bit=0
  * ~~2023-12-05-raspios-bookworm-armhf.img.xz (arm_64bit=1)~~ (*1)
  * 2023-12-05-raspios-bookworm-armhf.img.xz arm_64bit=0
  * ~~2024-03-12-raspios-bookworm-armhf.img.xz (arm_64bit=1)~~ (*1)
  * 2024-03-12-raspios-bookworm-armhf.img.xz arm_64bit=0 (*3)
* Raspberry Pi OS 64-bit
  * 2021-05-07-raspios-buster-arm64.zip
  * 2023-05-03-raspios-bullseye-arm64.img.xz
  * 2023-10-10-raspios-bookworm-arm64.img.xz
  * 2023-12-05-raspios-bookworm-arm64.img.xz
  * 2024-03-12-raspios-bookworm-arm64.img.xz (*3)
* Ubuntu OS 64-bit
  * ~~ubuntu-20.04.4-preinstalled-server-arm64+raspi.img.xz~~ (*2)
  * ubuntu-22.04.3-preinstalled-server-arm64+raspi.img.xz

*1) The bit numbers of user-space and Kernel are different. Requires cross-compilation.  
*2) Not supported before Kernel 5.10. (See [here](https://github.com/raspberrypi/linux/issues/2521#issuecomment-741738760).)  
*3) Currently in the vnext branch.

## Install script

1. When using a 32-bit OS, add arm_64bit=0 to /boot/firmware/config.txt (or /boot/config.txt) and reboot.

   ```
   sudo sed -i '$aarm_64bit=0' /boot/firmware/config.txt
   sudo reboot
   ```

2. Download the driver.

   ```
   git clone --depth 1 https://github.com/matsujirushi/seeed-linux-dtoverlays
   cd seeed-linux-dtoverlays
   ```

   > The latest bookworm support is currently in the vnext branch.
   > 
   > * 2024-03-12-raspios-bookworm-arm64.img.xz
   > * 2024-03-12-raspios-bookworm-armhf.img.xz arm_64bit=0
   > 
   > ```
   > git clone -b vnext --depth 1 https://github.com/matsujirushi/seeed-linux-dtoverlays
   > ```


3. Install the driver.

   ```
   sudo ./scripts/reTerminal2.sh
   ```

4. When the message "Execute command(s) below:" is displayed, execute the specified command.

5. Reboot.

   ```
   sudo reboot
   ```
