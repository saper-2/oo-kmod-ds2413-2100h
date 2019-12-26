# Kernel driver for 2100h for Onion Omega 2(+)

This is a driver for **2100H** chips that are Chinese clones of Dallas/Maxim DS2413 dual-IO 1-wire expanders.

Basically this is a copy-paste of DS2413 code with adjustments for 2100H :smile:.

## Build
This description was tested on firmware ```v0.3.2-b233``` and on Omega 2+ board. 

The build system source I used from git is from commit: [52a1594](https://github.com/OnionIoT/source/commit/52a1594fbbabbfeeaad12496eabcaee1a794fbd6) (2019-12-06 17:26).
I have tested this on Debian 10 (Buster).

You can find below my descriptions how to build on linux and using Docker image:
* [Compiling on Docker Image](BUILD-DOCKER.md)
* [Compiling on any linux (Debian-based)](BUILD.md)


## Useful links
* http://community.onion.io/topic/2830/building-kernel-modules-for-the-omega2 
* https://docs.onion.io/omega2-docs/cross-compiling.html
* https://onion.io/2bt-reading-temperature-from-a-1-wire-sensor/
* https://github.com/OnionIoT/source

## EOF
