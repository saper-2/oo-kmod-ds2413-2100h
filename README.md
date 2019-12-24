# Onion Omega 2 kernel driver for 2100h
## 0. Intro
This is a driver for **2100H** chips that are Chinese clones of Dallas/Maxim DS2413 dual-IO 1-wire expanders.

Basically this is a copy-paste of DS2413 code with adjustments for 2100H.

## 1. Build
For building this module you need first to prepare environement, description of doing this is based on this project: http://community.onion.io/topic/2830/building-kernel-modules-for-the-omega2 and the Docs Cross-Compiling setup: https://docs.onion.io/omega2-docs/cross-compiling.html .
I'll just add my 2 cents to those descriptions :wink:.

### 1.0. Intro
This description was tested on firmware ```v0.3.2-b233``` and on Omega 2+ module. 
The build system source I used from git is from commit: https://github.com/OnionIoT/source/commit/52a1594fbbabbfeeaad12496eabcaee1a794fbd6 (2019-12-06 17:26).
I use Debian 10 (Buster).

### 1.1. Prereqisites
Update system:
```
sudo apt update
sudo apt upgrade
```

Now install packages required to build LEDE for Omega2:
```
sudo apt install -y git wget subversion build-essential libncurses5-dev zlib1g-dev gawk flex quilt git-core unzip libssl-dev python-dev python-pip libxml-parser-perl

sudo apt install -y libpam0g-dev libgnutls28-dev liblmdb-dev libldap2-dev libidn2-dev libssh2-1-dev liblzma-dev libsnmp-dev
```

Download LEDE Build System - create for it directory e.g. ```/home/me/onion``` and in that run this:
```
git clone https://github.com/OnionIoT/source.git
```

### 1.2. Setup Build System
Go to ```source``` directory and start menuconfig.
```
cd source
make menuconfig
```

In window ```OpenWrt Configuration``` set up those parameters:
- Set **Target System** to ```MediaTek Ralink MIPS```
- Set **Subtarget** to ```MT76x8 based boards```
- Set **Target profile** to ```Multiple devices```
- In **Target Devices** select:
  - ```Onion Omega2```
  - ```Onion Omega2+```
Now save your config to default file ```.config``` and exit config menu.

### 1.3. Compilation
Just run:
```
make
```
Or if you want using all your CPU cores/threads then use this (replace number by cores/threads that you want to use):
```
make -j2
```

This might take even few hours to build.

When compilation end successfully, you can follow to next point.

### 1.4. Prepare location and setup feeds for custom modules
*This way you can build any module and/or create yourself one.*

*I created directory ```omega2_kmods``` where I'm going to keep all those my custom modules.*

Create directory ```omega2_kmods``` in ```source``` directory:
```
me@localhost:~/onion/source$ mkdir omega2_kmods
me@localhost:~/onion/source$ cd omega2_kmods
```

Now edit ```feeds.conf``` and add path to custom kernel modules location, add this line at end of ```source/feeds.conf```:
```
src-link omega2_kmods /home/me/onion/source/omega2_kmods
```

Now update feeds (need to be done after creating each new module directory inside ```omega2_kmods``` ):
Run those commands being in ```source``` directory:
```
./scripts/feeds update -a
./scripts/feeds install -a
```
Or to install ony one feed package (with you module source):
```
./scripts/feeds install <dir_name>
```

You can also update feeds - check that project page at Onion Community how to do it.

### 1.5. Adding this module to build
*This way you can build any module and/or create yourself one.*

Hop into kmods directory, and create directory for this module:
```
me@localhost:~/onion/source$ cd omega2_kmods
me@localhost:~/onion/source/omega2_kmods$ mkdir w1_ds2413_2100h
me@localhost:~/onion/source/omega2_kmods$ cd w1_ds2413_2100h
```

Now clone repo into current directory (*```source/omega2_kmods/w1_ds2413_2100h/```* ):
```
me@localhost:~/onion/source/omega2_kmods/w1_ds2413_2100h$ git clone git@github.com:saper-2/oo-kmod-ds2413-2100h.git .
```

Update feeds and install source code of module - return to ```source/``` directory and:
```
./scripts/feeds update -a
./scripts/feeds install w1_ds2413_2100h
```
This should create symlinks in ```source/feeds/``` directory to the module source code.

### 1.6. Enable module
Now to compile this module you need to enable it in menuconfig, run it:
```
make menuconfig
```

Then go into **Kernel modules** -> **Other modules** and find on list this module:
```
kmod-w1_ds2413_2100h
```
And mark it to be build as **M**odule (in ```< >``` must be ```M``` letter: ```<M>```).

Save ```.config``` and exit menuconfig.

### 1.7. Build
You can build everything (the toolchain won't be re-build again :smile:) , or only compile this module. For first just use ```make``` , for building only the module use this (from ```source/``` directory):
```
make omega2_kmods/w1_ds2413_2100h/compile
```
*If for some reason it fails change ```compile``` to ```clean``` to cleanup module and build everything*

### 1.8. Built module
The result of compilation should be in:
```
./build_dir/target-mipsel_24kc_musl/linux-ramips_mt76x8/w1_ds2413_2100h/
```

Or look for the ```.ko``` file:
```
me@localhost:~/onion/source$ find . -iname "w1_ds2413_2100h.ko"
```
It should return few results :smile:

### 1.9. Copy module to Omega2+
I'll use scp (Omega2+ IP is ```192.168.19.197```):
```
cd build_dir/target-mipsel_24kc_musl/linux-ramips_mt76x8/w1_ds2413_2100h/

scp w1_ds2413_2100h.ko root@192.168.19.197:/root/.
```

## 2. Using module

I have based on article from Onion for set up 1-Wire, but before loading module that handle 1-wire bus, you have to **first** load this module to register chip ID handler.
Article: https://onion.io/2bt-reading-temperature-from-a-1-wire-sensor/

## 2.1. Load 2100H module
First insert this module ```w1_ds2413_2100h.ko``` (from root home directory):
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

## 2.2. Load Custom GPIO-based 1-Wire driver

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

## 2.3. Verify if driver is used for 2100H
Verify if driver is really loaded for 2100H device:
```
root@Omega-0C65:~# ls /sys/bus/w1/devices/85-1003c073b2be/
driver     id         name       output     state      subsystem  uevent
```
You should see in directory with 2100H, two files:
* output
* state
Those two prove that w1_ds2413_2100h kernel module driver is loaded successfully.

## 2.4. Using 2100H from bash/shell

### 2.4.1. Read 2100H PIOs
To read 2100H PIO state you just read the "state" file, it'll return a byte with PIO status, see DS2413 for the byte format.

E.g.: I have shorten PIOB to GND:
```
 dd bs=1 count=1 if=/sys/bus/w1/devices/85-1003c073b2be/state 2>/dev/null | hexdump -e '"%02x\n"'
 ```
 Result is ```4b``` which is ```0100 1011``` - this translate to - bits [3:0]:
 * PIOB output latch state = ```1```
 * PIOB pin state = ```0```
 * PIOA output latch state = ```1```
 * PIOB pin state = ```1```
 
 *High nibble [7:4] is inversion of low nibble [3:0]*

 Result is ```1e``` which is ```0001 1110```

 ### 2.4.2. Set 2100H PIOs
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
Result ```3c``` -> ```0b0011 1100```: Latch A=```0```, Pin A=```0``` , Latch B=```1``` , Pin B=```1```

# 3. Useful links
* http://community.onion.io/topic/2830/building-kernel-modules-for-the-omega2 
* https://docs.onion.io/omega2-docs/cross-compiling.html
* https://onion.io/2bt-reading-temperature-from-a-1-wire-sensor/


# 3. EOF
