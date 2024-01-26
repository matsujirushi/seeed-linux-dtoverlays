# The reTerminal driver for Ubuntu OS

## Support Platforms
* ~~ubuntu-20.04.4-preinstalled-server-arm64+raspi.img.xz~~ (*2)
* ubuntu-22.04.3-preinstalled-server-arm64+raspi.img.xz

*2) Not supported before Kernel 5.10. (See [here](https://github.com/raspberrypi/linux/issues/2521#issuecomment-741738760).)

## Install script

1. Install the latest Kernel and header and reboot.

   ```
   sudo apt install linux-raspi
   sudo reboot
   ```

2. Download the driver.

   ```
   git clone --depth 1 https://github.com/matsujirushi/seeed-linux-dtoverlays
   cd seeed-linux-dtoverlays
   ```

3. Install the driver.

   ```
   sudo ./scripts/reTerminal.sh
   ```

4. Create `~/.config/monitors.xml`.

   ```
   <monitors version="2">
     <configuration>
       <logicalmonitor>
         <x>0</x>
         <y>0</y>
         <primary>yes</primary>
         <monitor>
           <monitorspec>
             <connector>DSI-1</connector>
             <vendor>unknown</vendor>
             <product>unknown</product>
             <serial>unknown</serial>
           </monitorspec>
           <mode>
             <width>720</width>
             <height>1280</height>
             <rate>60.000</rate>
           </mode>
         </monitor>
         <transform>
           <rotation>right</rotation>
         </transform>
       </logicalmonitor>
     </configuration>
   </monitors>
   ```

5. Reboot.

   ```
   sudo reboot
   ```

## Known Issues

* The `--keep-kernel` option is not supported.
* When connecting an HDMI monitor, the LCD resolution decreases.
* The touch panel does not return from the LCD turning off.
