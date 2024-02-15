# Renewed reTerminal driver for Raspberry Pi OS

**This is currently an experimental script.**

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
   sudo poweroff
   ```

2. When buster, upgrade the kernel.

   ```
   sudo apt --only-upgrade install raspberrypi-kernel
   sudo poweroff
   ```

3. Download the driver.

   ```
   git clone --depth 1 https://github.com/matsujirushi/seeed-linux-dtoverlays
   cd seeed-linux-dtoverlays
   ```

4. Install the driver.

   ```
   sudo ./scripts/reTerminal2.sh
   ```

5. When the message "Execute command(s) below:" is displayed, execute the specified command.

6. Reboot.

   ```
   sudo reboot
   ```

## Known Issues

