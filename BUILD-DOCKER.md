# Building Onion Omega 2(+) kernel driver for 2100h

This description is based on prepared docker container by Onion. Later part are almost identical on both methods.

## 0. Intro

Install docker image like described on https://github.com/OnionIoT/source
and run it:
```
docker run -it onion/omega2-source /bin/bash
```
**BUT** don't run "minimal-build" script yet, before you have to do some additional steps.

### 0.1 Short Docker usage info
This command:
```
docker run -it onion/omega2-source /bin/bash
```
Start a docker image with clean onion/omega2-source build system (like compilation never happened). Every time you exec it it'll create a **new container** with "vanilla onion/omega2 build system" , to connect to already created container, you need it's name or ID, to get list of all containers:
```
me@localhost:~$ docker ps -a
CONTAINER ID        IMAGE                 COMMAND             CREATED             STATUS                      PORTS               NAMES
80122a7d433c        onion/omega2-source   "/bin/bash"         About an hour ago   Created                                         bold_varahamihira
365dd17f9372        onion/omega2-source   "/bin/bash"         2 hours ago         Exited (0) 2 hours ago                          friendly_greider
059d6721afed        onion/omega2-source   "/bin/bash"         30 hours ago        Exited (0) 20 hours ago                       eloquent_burnell
```
And select the one you used, **in my case** it's ```059d6721afed``` (oldest one). Once you know the ID (it's the same as host name in command prompt when you're inside the container).

First start container (if it don't have status **```Up```** ):
```
docker start 059d6721afed
```
and connect to it's shell:
```
docker exec -it 059d6721afed /bin/bash
```
Replace my container ID (*```059d6721afed```*) with your container ID.

## 1. Update container source code

Before doing any compilation, you have to update code to latest from github.
Once you're in ```/root/source``` , run:
```
git pull origin openwrt-18.06
```
*Assuming that at this moment the current branch is 'openwrt-18.06'*

## 2. First build

Now, this is identical like building without docker container.

You can use a ready script that generate minimal configuration (like mentioned at https://github.com/OnionIoT/source ):
```
sh scripts/onion-minimal-build.sh
```

Or use menuconfig to setup build:
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

## 3. Build
Just run:
```
make
```
ANd wait, for first time it can easily take about 3-4 hours to build toolchain and system image for Omega2(+). There are moment when compilation staying on some elements, and this looks like it'd hang - just wait :relaxed: .


## 4. Prepare for custom modules build

Go to root directory, and create there directory for custom modules and return to source:
```
cd /root
mkdir omega2_kmods
cd /root/source
```

Now we need to edit feeds to tell build system where are our 'extras'.

Edit ```feeds.conf``` and add path to custom kernel modules location, add this line at end of ```source/feeds.conf```:
```
src-link omega2_kmods /root/omega2_kmods
```

Now update feeds running those scripts:
```
./scripts/feeds update -a
./scripts/feeds install -a
```
This might do a some updates (on kernel, toolchain and tools from Omega2 system - like 'python' or libs), if so, then re-run:
```
make menuconfig
```
Exit menuconfig and save it, then run again:
```
make
``` 

Once done continue.

## 5. Add this module to build

Go to ```omega2_kmods``` , create directory for this kernel module and update & install (more like 'apply') this module via feeds in build system:
```
cd /root/omega2_kmods
mkdir w1_ds2413_2100h
cd w1_ds2413_2100h
git clone https://github.com/saper-2/oo-kmod-ds2413-2100h.git .
```

Update feeds and install source code of module - return to ```source/``` directory and:
```
./scripts/feeds update -a
./scripts/feeds install w1_ds2413_2100h
```
This should create symlinks in ```source/feeds/``` directory to the module source code.

### 6. Enable module

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

### 7. Build

You can build everything (the toolchain won't be re-build again :smile:) , or only compile this module. For first just use ```make``` , for building only the module use this (from ```source/``` directory):
```
make package/w1_ds2413_2100h/compile
```

*If for some reason it fails change ```compile``` to ```clean``` to cleanup module and build everything*

The result of compilation should be in:
```
./staging_dir/target-mipsel_24kc_musl/root-ramips/lib/modules/4.14.81/
```

Or look for the ```.ko``` file:
```
me@localhost:~/onion/source$ find . -iname "w1_ds2413_2100h.ko"
```
It should return few results :smile:

## 8. Copy module to Omega2+
I'll use scp (Omega2+ IP is ```192.168.19.197```):
```
cd staging_dir/target-mipsel_24kc_musl/root-ramips/lib/modules/4.14.81/

scp w1_ds2413_2100h.ko root@192.168.19.197:/root/.
```

## 9. Usage
See the USAGE.md file.

# 10. EOF
