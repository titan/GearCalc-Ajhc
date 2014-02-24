PROJECTNAME:=GearCalc
APPFOLDER:=/dev/shm/$(PROJECTNAME).app
INSTALLFOLDER:=$(PROJECTNAME).app

CC:=ios-clang
CPP:=ios-clang++
EXPECT:=expect
ECHO:=echo
DSYMUTIL:=dsymutil
HTLLC:=htllc -v ios6
AJHC:=ajhc

CFLAGS += -include $(SUPDIR)/*.pch
CFLAGS += -fobjc-arc
CFLAGS += -fblocks
CFLAGS += -g -O2
CFLAGS += -I"$(SRCDIR)" -I"$(BUILDDIR)"

CPPFLAGS += -include $(SUPDIR)/*.pch
CPPFLAGS += -fobjc-arc
CPPFLAGS += -fblocks
CPPFLAGS += -g -O2
CPPLAGS += -I"$(SRCDIR)" -I"$(BUILDDIR)"

LDFLAGS += -framework Foundation
LDFLAGS += -framework UIKit
LDFLAGS += -framework CoreGraphics
LDFLAGS += -framework QuartzCore
LDFLAGS += -framework SystemConfiguration

HSCFLAGS += -std=gnu99
HSCFLAGS += -falign-functions=4 -ffast-math -fno-strict-aliasing
HSCFLAGS += -D_GNU_SOURCE -DNDEBUG -D_JHC_GC=_JHC_GC_JGC -D_JHC_CONC=_JHC_CONC_PTHREAD -D_JHC_USE_OWN_STDIO -D_JHC_STANDALONE=0
HSCFLAGS += -I"$(BUILDDIR)/cbits" -I"$(BUILDDIR)"

BUILDDIR=/dev/shm/$(PROJECTNAME)-build
SRCDIR=Classes
SUBSRCDIR=$(shell find $(SRCDIR)/* -maxdepth 1 -type d)
SUPDIR=Supportings
SCRDIR=Scripts
TOOLDIR=Tools
HSDIR=Haskell
HSSRCS=$(wildcard $(HSDIR)/*.hs $(HSDIR)/*/*.hs $(HSDIR)/*/*/*.hs $(HSDIR)/*/*/*/*.hs)
HSCSRCS=$(addprefix $(BUILDDIR)/, hs_main.c rts/rts_support.c rts/jhc_rts.c rts/gc_jgc.c rts/stableptr.c rts/conc.c lib/lib_cbits.c)
HSCSRCS+=$(SUPDIR)/dummy4jhc.c
OBJS+=$(addprefix $(BUILDDIR)/, $(patsubst %.m,%.o,$(notdir $(wildcard $(SRCDIR)/*.m))))
OBJS+=$(addprefix $(BUILDDIR)/, $(patsubst %.m,%.o,$(notdir $(wildcard $(SRCDIR)/*/*.m))))
OBJS+=$(addprefix $(BUILDDIR)/, $(patsubst %.m,%.o,$(notdir $(wildcard $(SUPDIR)/main.m))))
OBJS+=$(addprefix $(BUILDDIR)/, $(patsubst %.c,%.o,$(notdir $(HSCSRCS))))
SNIPS+=$(addprefix $(BUILDDIR)/, $(patsubst %.htll,%.property.h,$(notdir $(wildcard $(SCRDIR)/*.htll))))
SNIPS+=$(addprefix $(BUILDDIR)/, $(patsubst %.htll,%.synthesize.h,$(notdir $(wildcard $(SCRDIR)/*.htll))))
SNIPS+=$(addprefix $(BUILDDIR)/, $(patsubst %.htll,%.view-did-load.h,$(notdir $(wildcard $(SCRDIR)/*.htll))))
SNIPS+=$(addprefix $(BUILDDIR)/, $(patsubst %.htll,%.view-will-appear.h,$(notdir $(wildcard $(SCRDIR)/*.htll))))
SNIPS+=$(addprefix $(BUILDDIR)/, $(patsubst %.htll,%.view-will-layout-subviews.h,$(notdir $(wildcard $(SCRDIR)/*.htll))))

vpath %.m $(SRCDIR)
#vpath %.m $(SUBSRCDIR) # uncomment it when there is at least one subdir in src dir
vpath %.m $(SUPDIR)
vpath %.o $(BUILDDIR)
vpath %.htll $(SCRDIR)
vpath %.hs $(HSDIR)
vpath %.c $(SUPDIR)
vpath %.c $(BUILDDIR)
vpath %.c $(BUILDDIR)/rts
vpath %.c $(BUILDDIR)/lib

INFOPLIST:=$(wildcard $(SUPDIR)/*Info.plist)

RESOURCES+=$(wildcard $(SUPDIR)/*.lproj)
RESOURCES+=$(wildcard ./Resources/*)
RESOURCES+=$(wildcard ./Resources/*/*)

LOCALCONFIG=Makefile.local

TARGET:=$(BUILDDIR)/$(PROJECTNAME)

ifeq ($(LOCALCONFIG), $(wildcard $(LOCALCONFIG)))
include $(LOCALCONFIG)
endif

all: $(TARGET)

$(BUILDDIR)/%.o: %.c
	@$(ECHO) Compiling $@ ...
	@$(CC) -c $(HSCFLAGS) $< -o $@

$(BUILDDIR)/%.o: %.m
	@$(ECHO) Compiling $@ ...
	@$(CC) -c $(CFLAGS) $< -o $@

$(BUILDDIR)/%.property.h: %.htll
	@$(ECHO) Generating property snippit $@ ...
	@$(HTLLC) property $< > $@

$(BUILDDIR)/%.synthesize.h: %.htll
	@$(ECHO) Generating synthesize snippit $@ ...
	@$(HTLLC) synthesize $< > $@

$(BUILDDIR)/%.view-did-load.h: %.htll
	@$(ECHO) Generating view-did-load snippit $@ ...
	@$(HTLLC) view-did-load $< > $@

$(BUILDDIR)/%.view-will-appear.h: %.htll
	@$(ECHO) Generating view-will-appear snippit $@ ...
	@$(HTLLC) view-will-appear $< > $@

$(BUILDDIR)/%.view-will-layout-subviews.h: %.htll
	@$(ECHO) Generating view-will-layout-subviews snippit $@ ...
	@$(HTLLC) view-will-layout-subviews $< > $@

$(BUILDDIR)/hs_main.c: $(HSSRCS)
	@$(ECHO) Compiling haskell codes to c ...
	@$(AJHC) -fffi -fpthread --include=$(HSDIR) --tdir=$(BUILDDIR) -C -o $@ $(HSSRCS)

# Generate dependencies for all files in project
$(BUILDDIR)/%.d: %.m | prebuild $(SNIPS)
	@$(ECHO) Generating dependence for $@ ...
	@$(CC) $(CFLAGS) $(INCLUDE) -MM $< | sed -e 's@^\(.*\)\.o:@$(BUILDDIR)/\1.d $(BUILDDIR)/\1.o:@' > $@

$(BUILDDIR)/%.d: %.c | prebuild hs_main.c
	@$(ECHO) Generating dependence for $@ ...
	@$(CC) $(HSCFLAGS) -MM $< | sed -e 's@^\(.*\)\.o:@$(BUILDDIR)/\1.d $(BUILDDIR)/\1.o:@' > $@

prebuild:
ifeq "$(wildcard $(BUILDDIR))" ""
	@mkdir -p $(BUILDDIR)
endif

$(TARGET): prebuild $(OBJS)
	@$(ECHO) Creating $@ ...
	@$(CC) $(CFLAGS) $(LDFLAGS) $(filter %.o,$^) -o $@

dist: $(TARGET)
	mkdir -p $(APPFOLDER)
#ifneq ($(RESOURCES),)
ifneq "$(RESOURCES)" "  "
	cp -r $(RESOURCES) $(APPFOLDER)
endif
	sed s/\$${EXECUTABLE_NAME}/${PROJECTNAME}/g $(INFOPLIST) > $(APPFOLDER)/Info.plist
	cp $(TARGET) $(APPFOLDER)
	find $(APPFOLDER) -name \*.png|xargs ios-pngcrush -c
	find $(APPFOLDER) -name \*.plist|xargs ios-plutil -c
	for i in `find $(APPFOLDER) -name \*.strings`; do java -jar $(TOOLDIR)/transform.jar $$i > $$i.xml; mv $$i.xml $$i; done
	find $(APPFOLDER) -name \*.strings|xargs ios-plutil -c

langs:
	ios-genLocalization

install-apponly: $(TARGET)
ifeq ($(IPHONE_IP),)
	@echo "Please set IPHONE_IP"
else
	@$(EXPECT) $(TOOLDIR)/install-apponly.remote $(IPHONE_IP) $(PASSWD) $(TARGET) $(INSTALLFOLDER)
	@echo "Application $(INSTALLFOLDER) installed"
endif

install: dist
ifeq ($(IPHONE_IP),)
	@echo "Please set IPHONE_IP"
else
	@$(EXPECT) $(TOOLDIR)/install.remote $(IPHONE_IP) $(PASSWD) $(APPFOLDER) $(INSTALLFOLDER)
	@echo "Application $(INSTALLFOLDER) installed"
endif

uninstall:
ifeq ($(IPHONE_IP),)
	@echo "Please set IPHONE_IP"
else
	@$(EXPECT) $(TOOLDIR)/uninstall.remote $(IPHONE_IP) $(PASSWD) $(INSTALLFOLDER)
	@echo "Application $(INSTALLFOLDER) uninstalled"
endif

debug: install-apponly
ifeq ($(SDK),)
	@echo "Please set SDK"
else
	@$(DSYMUTIL) $(TARGET) -o $(TARGET).dSYM
	@mkdir -p $(SDK)/Applications/$(INSTALLFOLDER)
	@cp -r $(TARGET).dSYM $(SDK)/Applications/$(INSTALLFOLDER)
	@cp $(TARGET) $(SDK)/Applications/$(INSTALLFOLDER)
	@echo "Please run the following command on remote machine"
	@echo "/Developer/usr/bin/debugserver 1000 /Applications/$(INSTALLFOLDER)/$(PROJECTNAME)"
	@echo "Please run arm-apple-darwin11-gdb on local machine"
	@echo "arm-apple-darwin11-gdb -ex 'file $(SDK)/Applications/$(INSTALLFOLDER)/$(PROJECTNAME)' -ex 'target remote-macosx $(IPHONE_IP):1000' "
endif

clean:
	@find $(BUILDDIR) -name \*.o | xargs rm -rf
	@find $(BUILDDIR) -name \*.d | xargs rm -rf
	@find $(BUILDDIR) -name \*.h | xargs rm -rf
	@find $(BUILDDIR) -name \*.c | xargs rm -rf
	@rm -rf $(APPFOLDER)
	@rm -f $(BUILDDIR)/$(PROJECTNAME)

.PHONY: all prebuild dist install uninstall clean install-apponly debug

ifneq "$(MAKECMDGOALS)" "clean"
# Include the list of dependancies generated for each object file
-include ${OBJS:.o=.d}
endif
