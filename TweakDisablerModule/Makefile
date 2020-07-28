ARCHS = arm64 arm64e
TARGET = iphone:clang:13.3:11.0
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = TweakDisablerModule
TweakDisablerModule_FILES = $(wildcard *.m)
TweakDisablerModule_INSTALL_PATH = /Library/ControlCenter/Bundles
TweakDisablerModule_CFLAGS = -fobjc-arc
TweakDisablerModule_FRAMEWORKS = UIKit
TweakDisablerModule_PRIVATE_FRAMEWORKS = ControlCenterUIKit

include $(THEOS_MAKE_PATH)/bundle.mk