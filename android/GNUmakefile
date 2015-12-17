# Copyright (c) 2011-2015 CrystaX.
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
# THIS SOFTWARE IS PROVIDED BY CrystaX ''AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CrystaX OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are those of the
# authors and should not be interpreted as representing official policies, either expressed
# or implied, of CrystaX.

override MYDIR := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))

include $(MYDIR)/settings.mk
sinclude $(MYDIR)/local.mk

#==============================================================================================================

override empty :=
override space := $(empty) $(empty)
override comma := ,

define commas-to-spaces
$(subst $(comma),$(space),$(1))
endef

define spaces-to-commas
$(subst $(space),$(comma),$(1))
endef

define delete-files
$(if $(wildcard $(1)),rm -Rf $(wildcard $(1)))
endef

#==============================================================================================================

define android-sdk
$(strip $(or \
    $(wildcard $(SDK)),\
    $(wildcard $(ANDROID_SDK_ROOT)),\
    $(error Cannot detect Android SDK!)\
))
endef

define android-ndk
$(strip $(or \
    $(wildcard $(NDK)),\
    $(wildcard $(ANDROID_NDK_ROOT)),\
    $(error Cannot detect Android NDK!)\
))
endef

define crystax-ndk
$(strip \
    $(eval __crystax_ndk := $(call android-ndk))\
    $(if $(wildcard $(__crystax_ndk)/sources/crystax),\
        $(__crystax_ndk),\
        $(error Found NDK '$(__crystax_ndk)' is not CrystaX NDK!)\
    )\
)
endef

define ant
$(strip $(or \
    $(strip $(ANT)),\
    ant\
))
endef

define adb
$(call android-sdk)/platform-tools/adb
endef

#==============================================================================================================

.PHONY: all
all: apk

.PHONY: clean
clean:
	-$(call delete-files,$(addprefix $(MYDIR)/,build.xml assets/ bin/ gen/ obj/ $(addprefix libs/,$(call commas-to-spaces,$(ABIS)))))
	@rmdir $(MYDIR)/libs/ 2>/dev/null || true
	@find $(MYDIR)/src -name OpenGLApplication.java -delete

.PHONY: generate-ant-files
generate-ant-files: $(MYDIR)/build.xml native

$(MYDIR)/build.xml:
	$(android-sdk)/tools/android update project --name $(APP_NAME) --path $(MYDIR)

.PHONY: generate-java-sources
generate-java-sources: native
	$(eval __appsrc := $(MYDIR)/src/$(subst .,/,$(PACKAGE_NAME))/OpenGLApplication.java)
	mkdir -p $(dir $(__appsrc))
	{ \
		echo '// WARNING!!! THIS IS AUTO-GENERATED FILE!!! DO NOT EDIT IT MANUALLY!!!'; \
		echo 'package $(PACKAGE_NAME);'; \
		echo 'public class OpenGLApplication extends android.app.Application {'; \
		echo 'static {'; \
		$(foreach __lib,crystax objc CoreServices CFNetwork CoreFoundation CoreGraphics CoreData CoreText CoreVideo Foundation,\
		echo 'System.loadLibrary("$(__lib)");'; \
		)\
		echo '}'; \
		echo '}'; \
	} >$(__appsrc)

.PHONY: generate-assets
generate-assets: $(MYDIR)/assets native
	rsync -a --delete $(MYDIR)/../shaders/ $(MYDIR)/assets/

$(MYDIR)/assets:
	mkdir -p $@

.PHONY: fix-android-manifest
fix-android-manifest: native
	$(eval __tmpmanifest := $(MYDIR)/AndroidManifest-$(shell uuidgen).xml)
	trap "rm -f $(__tmpmanifest)" EXIT INT QUIT ABRT TERM; \
	cat $(MYDIR)/AndroidManifest.xml | sed -e 's,package="[^"]*",package="$(PACKAGE_NAME)",' >$(__tmpmanifest) && \
	mv -f $(__tmpmanifest) $(MYDIR)/AndroidManifest.xml

.PHONY: apk
apk: generate-ant-files generate-java-sources generate-assets fix-android-manifest native
	$(ant) debug

.PHONY: native
native:
	+$(crystax-ndk)/ndk-build -C $(MYDIR) NDK_TOOLCHAIN_VERSION=clang APP_ABI=$(call spaces-to-commas,$(ABIS)) V=1 -$(MAKEFLAGS)

.PHONY: install
install: apk
	$(adb) install -r $(MYDIR)/bin/$(APP_NAME)-debug.apk

.PHONY: uninstall
uninstall:
	$(adb) shell pm uninstall $(PACKAGE_NAME)

.PHONY: run
run: install
	$(adb) shell am start -S -W -n $(PACKAGE_NAME)/android.app.NativeActivity

.PHONY: stop
stop:
	$(adb) shell am force-stop $(PACKAGE_NAME)
