ARCHS = arm64 arm64e
TARGET = iphone:clang::11.0
include $(THEOS)/makefiles/common.mk

TOOL_NAME = tweakdisabler
tweakdisabler_FILES = main.m
tweakdisabler_CFLAGS = -fobjc-arc
tweakdisabler_CODESIGN_FLAGS = -Sent.xml
tweakdisabler_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tool.mk