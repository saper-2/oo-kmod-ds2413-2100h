# Using module

I have based on article from Onion for set up 1-Wire, but before loading module that handle 1-wire bus, you have to **first** load this module to register chip ID handler.
Article: https://onion.io/2bt-reading-temperature-from-a-1-wire-sensor/

## 1. Load 2100H module
First insert this module ```w1_ds2413_2100h.ko``` to kernel (from root home directory):
```
root@Omega-0AAA:~# insmod w1_ds2413_2100h.ko
```
You can check if it's loaded:
```
root@Omega-0AAA:~# lsmod |grep w1
w1_ds2413_2100h         1136  0
w1_gpio                 2320  0
w1_therm                4496  0
wire                   17811  3 w1_ds2413_2100h,w1_therm,w1_gpio
```

## 2. Load Custom GPIO-based 1-Wire driver

1-Wire bus with pull-up resistor (4,7kOhm to 3,3V) I have connected to GPIO 3 :
```
insmod w1-gpio-custom bus0=0,3,0
```

Now if you have any 1-Wire chip hooked to 1-Wire bus in console should pop up few lines with information what chip was found (I have 4: 3xDS18B20 and 1x2100H):
```
root@Omega-0AAA:~# insmod w1-gpio-custom bus0=0,3,0
[26167.327082] Custom GPIO-based W1 driver version 0.1.1
[26167.377119] w1_master_driver w1_bus_master1: Attaching one wire slave 28.02161f7444ee crc 9b
[26167.487333] w1_master_driver w1_bus_master1: Attaching one wire slave 28.02161f7a89ee crc 40
[26167.597365] w1_master_driver w1_bus_master1: Attaching one wire slave 28.02161f8d67ee crc cf
[26167.707187] w1_master_driver w1_bus_master1: Attaching one wire slave 85.1003c073b2be crc 3d
```

Let's check module usage:
```
root@Omega-0AAA:~# lsmod |grep w1
w1_ds2413_2100h         1136  0
w1_gpio                 2320  0
w1_gpio_custom           912  0
w1_therm                4496  0
wire                   17811  3 w1_ds2413_2100h,w1_therm,w1_gpio
```

And devices in sys/bus:
```
root@Omega-0AAA:~# ls /sys/bus/w1/devices/
28-02161f7444ee  28-02161f8d67ee  w1_bus_master1
28-02161f7a89ee  85-1003c073b2be
```
As you see my 2100H have ID ```85-1003c073b2be```

## 3. Verify if driver is used for 2100H
Verify if driver is really loaded for 2100H device:
```
root@Omega-0C65:~# ls /sys/bus/w1/devices/85-1003c073b2be/
driver     id         name       output     state      subsystem  uevent
```
You should see in directory with 2100H, two files:
* output
* state

Those two prove that w1_ds2413_2100h kernel module driver is loaded successfully.

## 4. Using 2100H from bash/shell

### 4.1. Read 2100H PIOs
To read 2100H PIO state you just read the "state" file, it'll return a byte with PIO status, see DS2413 for the byte format.

E.g.: I have shorten PIOB to GND:
```
 dd bs=1 count=1 if=/sys/bus/w1/devices/85-1003c073b2be/state 2>/dev/null | hexdump -e '"%02x\n"'
 ```
 Result is ```0x4b``` which is ```0100 1011``` - this translate to - bits [3:0]:
 * PIOB output latch state = ```1```
 * PIOB pin state = ```0```
 * PIOA output latch state = ```1```
 * PIOB pin state = ```1```
 
 *High nibble [7:4] is inversion of low nibble [3:0]*

 Result is ```0x1e``` which is ```0001 1110```

 ### 4.2. Set 2100H PIOs
 To set 2100H PIOs just write a byte to ```output``` where bit 0 is PIOA state, and bit 1 is PIOB state.

 E.g.: Set PIOA to 0 - the byte will be 0x02 (```0b00000010```):
 ```
echo -e "\x02"|dd of=/sys/bus/w1/devices/85-1003c073b2be/output bs=1 count=1
```

And read:
```
root@Omega-0C65:~# dd bs=1 count=1 if=/sys/bus/w1/devices/85-1003c073b2be/state
2>/dev/null | hexdump -e '"%02x\n"'
3c
```
Result ```0x3c``` -> ```0b0011 1100```: Latch A=```0```, Pin A=```0``` , Latch B=```1``` , Pin B=```1```

## 5. EOF