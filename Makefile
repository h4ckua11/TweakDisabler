ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TweakDisabler
TweakDisabler_CFLAGS = -fobjc-arc

SUBPROJECTS += tweakdisabler Prefs activatorListener Prefs TweakDisablerModule
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	find . -name ".DS_Store" -type f -delete

after-install::
	install.exec "killall -9 SpringBoard"