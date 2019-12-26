# Onion Omega 2 kernel driver for 2100h

## 1. Prereqisites
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

### 2. Setup Build System
Go to ```source``` directory and first update feeds:
```
cd source
./scripts/feeds update -a
```

ANd then start menuconfig.
```
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

## 3. Compilation
Just run:
```
make
```
Or if you want using all your CPU cores/threads then use this (replace number by cores/threads that you want to use or you have available):
```
make -j2
```

This might take even few hours to build. 
There is few steps at first build when it looks like compiler hung, but it take a bloody long time to finish those steps - so just wait...

When compilation end successfully, you can follow to next point.

## 4. Prepare location and setup feeds for custom modules
*This way you can build any module and/or create yourself one.*

*I created directory ```omega2_kmods``` where I'm going to keep all those my custom modules.*

Create directory ```omega2_kmods``` outside ```source``` directory:
```
me@localhost:~/onion$ mkdir omega2_kmods
me@localhost:~/onion$ cd omega2_kmods
```

Now edit ```feeds.conf``` and add path to custom kernel modules location, add this line at end of ```source/feeds.conf```:
```
src-link omega2_kmods /home/me/onion/omega2_kmods
```

Now update feeds (need to be done after creating each new module directory inside ```omega2_kmods``` ):
Run those commands being in ```source``` directory:
```
./scripts/feeds update -a
```

## 5. Adding this module to build
*This way you can build any module and/or create yourself one.*

Hop into kmods directory, and create directory for this module:
```
me@localhost:~/onion$ cd omega2_kmods
me@localhost:~/onion/omega2_kmods$ mkdir w1_ds2413_2100h
me@localhost:~/onion/omega2_kmods$ cd w1_ds2413_2100h
```

Now clone repo into current directory (*```omega2_kmods/w1_ds2413_2100h/```*):
```
me@localhost:~/onion/omega2_kmods/w1_ds2413_2100h$ git clone https://github.com/saper-2/oo-kmod-ds2413-2100h.git .
```

Update feeds and install source code of module - return to ```source/``` directory and:
```
./scripts/feeds update -a
./scripts/feeds install w1_ds2413_2100h
```
This should create symlinks in ```source/feeds/``` directory to the module source code.

## 6. Enable module
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

## 7. Build
You can build everything (the toolchain won't be re-build again :smile:) , or only compile this module. For first just use ```make``` , for building only the module use this (from ```source/``` directory):
```
make package/w1_ds2413_2100h/compile
```
*If for some reason it fails change ```compile``` to ```clean``` to cleanup module and build everything. If still fails with building only the module build everything via ```make```*

## 8. Compiled module
The result of compilation should be in:
```
./staging_dir/target-mipsel_24kc_musl/root-ramips/lib/modules/4.14.81/
```

Or look for the ```.ko``` file:
```
me@localhost:~/onion/source$ find . -iname "w1_ds2413_2100h.ko"
```
It should return few results :smile:

## 9. Copy module to Omega2+
I'll use scp (Omega2+ IP is ```192.168.19.197```):
```
cd staging_dir/target-mipsel_24kc_musl/root-ramips/lib/modules/4.14.81/

scp w1_ds2413_2100h.ko root@192.168.19.197:/root/.
```

## 10. Usage
See the USAGE.md file.

# 4. EOF
