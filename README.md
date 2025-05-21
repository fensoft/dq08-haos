# Description
Ready to flash home assistant supervised img file for dq08 (install to emmc)

# Build

```
# ./build.sh
# ./make-rk-img.sh
```

# Flash

On windows 64 bit:
- unzip `tools/FactoryTool.zip` on the root of your disk (example: `c:\`)
- unzip the release in the same directory
- run `FactoryTool`
- clic on `Firmware` and select the `.img` file
- clic on `Restore`
- clic on `Run`
- do not plug the power on the box
- keep pushed the reset button in the AV connector
- plug a male-male usb cable to the black port (not the blue one)
- wait 2 seconds (windows usb sound)
- release everything and wait for the green cell (~ 2 minutes)
- unplug everything, connect ethernet + DC and wait ~12 minutes: system will install requirements (~ 3min) then reboot and install HA (~5 min) and setup HA (~5 min)
- scan your network with [this](https://www.nirsoft.net/utils/wireless_network_watcher.html)
- connect to `http://<ip>:8123`