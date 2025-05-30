VERSION := 3.0.0_r2
RECOVERY_VERSION := 1.0.1

clean:
	rm -f *.img *.zip

img: rk3528-tvbox/dq08.img

rk3528-tvbox/dq08.img:
	./build.sh

sd: dq08_ha_supervised_$(VERSION).sd.img

dq08_ha_supervised_$(VERSION).sd.img: rk3528-tvbox/dq08.img
	./make-sd-img.sh $(VERSION)

rk: dq08_ha_supervised_$(VERSION).img

dq08_ha_supervised_$(VERSION).img: dq08_ha_supervised_$(VERSION).sd.img
	./make-rk-img.sh $(VERSION)

recovery: rk3528-tvbox/dq08.img
	./make-recovery-img.sh $(RECOVERY_VERSION)

zip: rk sd recovery
	rm -f dq08_ha_supervised_$(VERSION).sd.img.zip dq08_ha_supervised_$(VERSION).img.zip
	zip dq08_ha_supervised_$(VERSION).sd.zip dq08_ha_supervised_$(VERSION).sd.img
	zip dq08_ha_supervised_$(VERSION).zip dq08_ha_supervised_$(VERSION).img
	zip dq08_recovery_$(RECOVERY_VERSION).zip dq08_recovery_$(RECOVERY_VERSION).img

