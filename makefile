OBJECTS=pursue
TARGET=fs/Library/MobileSubstrate/DynamicLibraries/Pursue.dylib

PREFSOBJECTS=Prefs
PREFSTARGET=fs/System/Library/PreferenceBundles/Pursue.bundle/Pursue

export NEXT_ROOT=/var/sdk

COMPILER=arm-apple-darwin9-gcc

LDFLAGS= \
		-Wall -Werror \
		-Z \
		-F/var/sdk/System/Library/Frameworks \
		-F/var/sdk/System/Library/PrivateFrameworks \
		-L/var/sdk/lib \
		-L/var/sdk/usr/lib \
		-L/usr/lib \
		-framework CoreFoundation -framework Foundation -framework UIKit -framework CoreLocation \
		-lobjc \
		-multiply_defined suppress

CFLAGS= -I/var/root/Headers -I/var/sdk/include -I/var/include \
		-fno-common \
		-g0 -O2 \
		-std=c99

all:	install

clean:
		rm -f $(OBJECTS) $(PREFSOBJECTS) $(TARGET) $(PREFSTARGET)
		rm -rf package

%:	%.m
		$(COMPILER) -c $(CFLAGS) $(filter %.m,$^) -o $@

$(TARGET): $(OBJECTS)
		$(COMPILER) $(LDFLAGS) -dynamiclib -o $@ $^
		ldid -S $@

$(PREFSTARGET): $(PREFSOBJECTS)
		$(COMPILER) $(LDFLAGS) -bundle -framework Preferences -o $@ $^
		ldid -S $@
				
package: $(TARGET) $(PREFSTARGET) control
		rm -rf package
		mkdir -p package/DEBIAN
		cp -a control package/DEBIAN
		cp -a fs/* package
		dpkg-deb -b package $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
		
install: package
		dpkg -i $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
		killall MobileMail