# Description
Ready to flash home assistant supervised img file for dq08

# Build

```
# apt install build-essential bison flex swig python3-dev gnutls-dev python3-pyelftools
# make zip
```

You'll have 
- `dq08_ha_supervised_<version>.sd.zip` : sd image
- `dq08_ha_supervised_<version>.zip` : rk image
- `dq08_recovery_<version>.zip` : recovery image to autoflash emmc using an sdcard

# Flash with a cable

On windows 64 bit
- unzip `tools/FactoryTool.zip` on the root of your disk (example: `c:\`)
- unzip the release in the same directory
- run `FactoryTool`
- clic on `Firmware` and select the `dq08_ha_supervised_<version>.img` rk file
- clic on `Restore`
- clic on `Run`
- do not plug the power on the box
- keep pushed the reset button in the AV connector
- plug a male-male usb cable to the black port (not the blue one)
- wait 2 seconds (windows usb sound)
- if needed, try again with an sdcard flashed with [Raspberry Pi Imager](https://www.raspberrypi.com/software/) (in OS choose the previous unzipped as "custom image") using [bootloader.img](https://github.com/fensoft/dq08-haos/raw/refs/heads/master/bootloader.img)
- release everything and wait for the green cell (2 minutes)
- unplug everything, connect ethernet + DC and wait approx 12 minutes: system will install requirements (3min) then reboot and install HA (5 min) and setup HA (5 min)
- scan your network with [this](https://www.nirsoft.net/utils/wireless_network_watcher.html)
- connect to `http://<ip>:8123`

# Flash with a microsd

- download and unzip [recovery](https://github.com/fensoft/dq08-haos/releases/download/3.0.0_r2/dq08_recovery_1.0.1.zip)
- flash it with [Raspberry Pi Imager](https://www.raspberrypi.com/software/) (in OS choose the previous unzipped as "custom image")
- unplug/replug sd card and put zipped [sd image](https://github.com/fensoft/dq08-haos/releases/download/3.0.0_r2/dq08_ha_supervised_3.0.0_r2.sd.zip) in the 500mb disk
- put sd in DQ08 and plug power. screen will display several steps. wait for "finished"
- unplug sd card, connect ethernet + DC and wait approx 12 minutes: system will install requirements (3min) then reboot and install HA (5 min) and setup HA (5 min)
- ip address will be shown on the display, connect to http://ip-address:8123 and setup HA

# Use microsd slot for HA backups
- connect in ssh to the box (user=root, pass=1234)
- `curl https://raw.githubusercontent.com/fensoft/dq08-haos/refs/heads/master/create_sdcard_hassio_backups.sh | bash -`
- plug sd card
