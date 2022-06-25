# buildroot_perdita

## Initial steps with snander_electricboogaloo

FILE=perdita-gcis.bin; cd /tmp && tftp -g -r $FILE 192.168.3.197
FILE=perdita-ipl; cd /tmp && tftp -g -r $FILE 192.168.3.197

```
snandr_electricboogaloo -p mstarddc -c /dev/i2c-0:49 -e
snandr_electricboogaloo -p mstarddc -c /dev/i2c-0:49 -a 0x0 -v -w perdita-gcis.bin -l2048
snandr_electricboogaloo -p mstarddc -c /dev/i2c-0:49 -a 0x20000 -v -w perdita-ipl
snandr_electricboogaloo -p mstarddc -c /dev/i2c-0:49 -a 0x40000 -v -w perdita-ipl
```

## PicoW

FILE=perdita-gcis.bin; cd /tmp && tftp -g -r $FILE 192.168.3.197
FILE=dongshanpipicow-ipl; cd /tmp && tftp -g -r $FILE 192.168.3.197
FILE=dongshanpipicow-u-boot.ubi; cd /tmp && tftp -g -r $FILE 192.168.3.197

```
snandr_electricboogaloo -p mstarddc -c /dev/i2c-0:49 -e
snandr_electricboogaloo -p mstarddc -c /dev/i2c-0:49 -a 0x0 -v -w perdita-gcis.bin -l2048
snandr_electricboogaloo -p mstarddc -c /dev/i2c-0:49 -a 0x20000 -v -w dongshanpipicow-ipl
snandr_electricboogaloo -p mstarddc -c /dev/i2c-0:49 -a 0x40000 -v -w dongshanpipicow-ipl
snandr_electricboogaloo -p mstarddc -c /dev/i2c-0:49 -a 0x60000 -v -w dongshanpipicow-u-boot.ubi
```

### Manually creating the partitions in u-boot

```
ubi createvol uboot 0x100000 static
ubi createvol env 0x20000 static
ubi createvol kernel 0x1000000 static
ubi createvol root 0x1000000 static
ubi createvol rescue 0x1000000 static
ubi createvol data
```

### Manually booting

```
mw.w 0x1f207980 0x200; setenv bootargs clk_ignore_unused usbcore.autosuspend=-1 console=ttyS0,115200 ubi.fm_autoconvert=1 ubi.mtd=1 ubi.block=0,root root=/dev/ubiblock0_3 quiet; ubi read 0x21000000 kernel; bootm 0x21000000
```

### Manually updating the rescue image

```
UBIFILE=perdita-kernel-rescue.fit; cd /tmp && tftp -g -r $UBIFILE 192.168.3.197 && ubiupdatevol /dev/ubi0_4 $UBIFILE
```

### Manually booting the rescue image

In u-boot:

```
setenv bootargs clk_ignore_unused console=ttyS0,115200 ubi.mtd=1 quiet; ubi read 0x21000000 rescue; bootm 0x21000000#ssd210-picow
```

To flash another board using a picow:

```
setenv bootargs clk_ignore_unused console=ttyS0,115200 ubi.mtd=1 quiet; ubi read 0x21000000 rescue; bootm 0x21000000#ssd210-picow#ssd210-picow-snander
```
