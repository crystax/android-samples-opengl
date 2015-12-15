# Copyright (c) 2011-2015 CrystaX .NET.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of
# conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list
# of conditions and the following disclaimer in the documentation and/or other materials
# provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY CrystaX .NET ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CrystaX .NET OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are those of the
# authors and should not be interpreted as representing official policies, either expressed
# or implied, of CrystaX .NET.

LOCAL_PATH := $(call my-dir)

COMMON_SRCPATH  := ../../common

COMMON_SRCFILES  := \
	AppController.m \

ANDROID_SRCFILES := \
	engine.m        \
	main.m          \
	platform.m      \

NOARC_SRCFILES   := \
	legacy.m        \

include $(CLEAR_VARS)

LOCAL_MODULE := legacy
LOCAL_SRC_FILES := legacy.m
LOCAL_OBJCFLAGS := -fno-objc-arc -fno-objc-exception

include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE     := app-native
LOCAL_SRC_FILES  := $(ANDROID_SRCFILES) $(addprefix $(COMMON_SRCPATH)/,$(COMMON_SRCFILES))
LOCAL_C_INCLUDES := $(LOCAL_PATH)/$(COMMON_SRCPATH)
LOCAL_CFLAGS     := -Wall -Werror -DGL_GLEXT_PROTOTYPES=1
LOCAL_LDLIBS     := -llog -landroid -lEGL -lGLESv2
LOCAL_STATIC_LIBRARIES := android_native_app_glue
LOCAL_STATIC_LIBRARIES += legacy

include $(BUILD_SHARED_LIBRARY)

$(call import-module,android/native_app_glue)
