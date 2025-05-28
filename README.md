# Description
Ready to flash home assistant supervised img file for dq08

# Build

```
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
- release everything and wait for the green cell (2 minutes)
- unplug everything, connect ethernet + DC and wait approx 12 minutes: system will install requirements (3min) then reboot and install HA (5 min) and setup HA (5 min)
- scan your network with [this](https://www.nirsoft.net/utils/wireless_network_watcher.html)
- connect to `http://<ip>:8123`

# Flash with a microsd

- unzip `dq08_recovery_<version>.zip` recovery image and flash with [this](https://hddguru.com/software/HDD-Raw-Copy-Tool/)
- copy zipped sd image to the `500mb fat32` partition on the microsd card
- put in `dq08`, power on and wait for `finished` message on the display