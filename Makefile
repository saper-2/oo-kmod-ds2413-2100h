# Copyright (C) 2006-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

# name
PKG_NAME:=w1_ds2413_2100h
# version of what we are downloading
PKG_VERSION:=1.0
# version of this makefile
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)
PKG_CHECK_FORMAT_SECURITY:=0

include $(INCLUDE_DIR)/package.mk

define KernelPackage/$(PKG_NAME)
	SUBMENU:=Other modules
	DEPENDS:=@(TARGET_ramips_mt76x8||TARGET_ramips_mt7688)
	DEPENDS:= +kmod-w1
	TITLE:=2100h driver (DS2413 clone)
	FILES:= $(PKG_BUILD_DIR)/w1_ds2413_2100h.ko
endef

define KernelPackage/$(PKG_NAME)/description
	Driver for 2100h dual-IO on 1-wire bus (clone of DS2413)
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

MAKE_OPTS:= \
	ARCH="$(LINUX_KARCH)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	SUBDIRS="$(PKG_BUILD_DIR)"

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

$(eval $(call KernelPackage,$(PKG_NAME)))
