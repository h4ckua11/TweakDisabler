ARCHS = arm64 arm64e
TARGET = iphone:clang:13.3:11.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = TweakDisabler

TweakDisabler_FILES = $(wildcard *.m */*.m)
TweakDisabler_FRAMEWORKS = UIKit
TweakDisabler_PRIVATE_FRAMEWORKS = Preferences
TweakDisabler_EXTRA_FRAMEWORKS += Cephei CepheiPrefs
TweakDisabler_INSTALL_PATH = /Library/PreferenceBundles
TweakDisabler_CFLAGS = -fobjc-arc
#TweakDisabler_LIBRARIES =

include $(THEOS_MAKE_PATH)/bundle.mk
