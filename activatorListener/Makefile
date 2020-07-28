ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = activatorListener

activatorListener_FILES = Listener.x
activatorListener_LIBRARIES = activator
activatorListener_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
