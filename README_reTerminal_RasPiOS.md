# The reTerminal driver for Raspberry Pi OS

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
* Raspberry Pi OS 64-bit
  * 2021-05-07-raspios-buster-arm64.zip
  * 2023-05-03-raspios-bullseye-arm64.img.xz
  * 2023-10-10-raspios-bookworm-arm64.img.xz
  * 2023-12-05-raspios-bookworm-arm64.img.xz

*1) The bit numbers of userland and Kernel land are different. Requires cross-compilation.

## Install script

1. When using a 32-bit OS, add arm_64bit=0 to /boot/config.txt (or /boot/firmware/config.txt) and reboot.

   ```
   echo arm_64bit=0 | sudo tee -a /boot/config.txt
   sudo reboot
   ```

2. Download the driver.

   ```
   git clone --depth 1 https://github.com/matsujirushi/seeed-linux-dtoverlays
   cd seeed-linux-dtoverlays
   ```

3. Install the driver.

   ```
   sudo ./scripts/reTerminal.sh --keep-kernel
   ```

4. Reboot.

   ```
   sudo reboot
   ```

## Known Issues
