################################################################################
 # Copyright (C) 2016 Maxim Integrated Products, Inc., All Rights Reserved.
 #
 # Permission is hereby granted, free of charge, to any person obtaining a
 # copy of this software and associated documentation files (the "Software"),
 # to deal in the Software without restriction, including without limitation
 # the rights to use, copy, modify, merge, publish, distribute, sublicense,
 # and/or sell copies of the Software, and to permit persons to whom the
 # Software is furnished to do so, subject to the following conditions:
 #
 # The above copyright notice and this permission notice shall be included
 # in all copies or substantial portions of the Software.
 #
 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 # OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 # IN NO EVENT SHALL MAXIM INTEGRATED BE LIABLE FOR ANY CLAIM, DAMAGES
 # OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 # ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 # OTHER DEALINGS IN THE SOFTWARE.
 #
 # Except as contained in this notice, the name of Maxim Integrated
 # Products, Inc. shall not be used except as stated in the Maxim Integrated
 # Products, Inc. Branding Policy.
 #
 # The mere transfer of this software does not imply any licenses
 # of trade secrets, proprietary technology, copyrights, patents,
 # trademarks, maskwork rights, or any other form of intellectual
 # property whatsoever. Maxim Integrated Products, Inc. retains all
 # ownership rights.
 #
 # $Date: 2020-01-30 01:13:28 +0300 (Thu, 30 Jan 2020) $ 
 # $Revision: 51262 $
 #
 ###############################################################################

# The build directory
ifeq "$(BUILD_DIR)" ""
BUILD_DIR=$(CURDIR)/build
endif

# Create output object file names
SRCS_NOPATH := $(foreach NAME,$(SRCS),$(basename $(notdir $(NAME))).c)
BINS_NOPATH := $(foreach NAME,$(BINS),$(basename $(notdir $(NAME))).bin)
OBJS_NOPATH := $(SRCS_NOPATH:.c=.o)
OBJS_NOPATH += $(BINS_NOPATH:.bin=.o)
OBJS        := $(OBJS_NOPATH:%.o=$(BUILD_DIR)/%.o)

################################################################################
# Goals

# The default goal, which causes the example to be built.
.DEFAULT_GOAL :=
.PHONY: all
all: mkbuildir
all: ${BUILD_DIR}/${PROJECT}.elf

# Goal to build for release without debug
.PHONY: release
release: mkbuildir
release: ${BUILD_DIR}/${PROJECT}.elf
release: ${BUILD_DIR}/${PROJECT}.srec
release: ${BUILD_DIR}/${PROJECT}.hex
release: ${BUILD_DIR}/${PROJECT}.bin
release: ${BUILD_DIR}/${PROJECT}.dasm

# The goal to build as a library
.PHONY: lib
lib: mkbuildir
lib: ${BUILD_DIR}/${PROJECT}.a

# The goal to create the target directory.
.PHONY: mkbuildir
mkbuildir:
	@mkdir -p ${BUILD_DIR}

# The goal to clean out all the build products.
.PHONY: clean
clean:
	@rm -rf ${BUILD_DIR} ${wildcard *~}

${BUILD_DIR}/${PROJECT}.elf: ${LIBS} ${OBJS} ${LINKERFILE}
${BUILD_DIR}/${PROJECT}.a: ${OBJS}

# Create a goal to exercise the library build dependencies
.PHONY: FORCE
FORCE:

# Include the automatically generated dependency files.
ifneq (${MAKECMDGOALS},clean)
-include ${wildcard ${BUILD_DIR}/*.d} __dummy__
endif

################################################################################
# Get the operating system name.  If this is Cygwin, the .d files will be
# munged to convert c: into /cygdrive/c so that "make" will be happy with the
# auto-generated dependencies. Also if this is Cygwin, file paths for ARM GCC
# will be converted from /cygdrive/c to C:.
################################################################################
ifneq ($(findstring CYGWIN, ${shell uname -s}), )
CYGWIN=True
endif

# Get the prefix for the tools to use.
ifeq "$(TOOL_DIR)" ""
PREFIX=arm-none-eabi
else
PREFIX=$(TOOL_DIR)/arm-none-eabi
endif

# The command for calling the compiler.
CC=${PREFIX}-gcc
CPP=${PREFIX}-g++

# The flags passed to the assembler.
AFLAGS=-mthumb         \
       -mcpu=cortex-m4 \
       -MD
ifneq "$(HEAP_SIZE)" ""
AFLAGS+=-D__HEAP_SIZE=$(HEAP_SIZE)
endif
ifneq "$(STACK_SIZE)" ""
AFLAGS+=-D__STACK_SIZE=$(STACK_SIZE)
endif
ifneq "$(SRAM_SIZE)" ""
AFLAGS+=-D__SRAM_SIZE=$(SRAM_SIZE)
endif
AFLAGS+=$(PROJ_AFLAGS)

ifeq "$(MXC_OPTIMIZE_CFLAGS)" ""
# Default is optimize for size
MXC_OPTIMIZE_CFLAGS = -Os
endif

ifeq "$(MFLOAT_FLAGS)" ""
# Default is softfp for maximum compatibility
MFLOAT_FLAGS = softfp
endif

ifeq "$(MFPU_FLAGS)" ""
# Default is softfp for maximum compatibility
MFPU_FLAGS = fpv4-sp-d16
endif

# The flags passed to the compiler.
# fno-isolate-erroneous-paths-dereference disables the check for pointers with the value of 0
#  add this below when gcc-arm-none-eabi version is past 4.8       -fno-isolate-erroneous-paths-dereference

CFLAGS=-mthumb                                                                 \
       -mcpu=cortex-m4                                                         \
       -mfloat-abi=$(MFLOAT_FLAGS)                                                      \
       -mfpu=$(MFPU_FLAGS)                                                       \
       -Wa,-mimplicit-it=thumb                                                 \
       $(MXC_OPTIMIZE_CFLAGS)                                                  \
       $(CMD_CFLAGS)                                                           \
       -ffunction-sections                                                     \
       -fdata-sections                                                         \
       -fsingle-precision-constant                                             \
       -MD                                                                     \
       -Wall                                                                   \
       -Wdouble-promotion                                                      \
       -Wno-format                                                             \
       -fno-isolate-erroneous-paths-dereference                                \
       -c

ifneq "$(TARGET)" ""
CFLAGS+=-DTARGET=$(shell echo $(TARGET) | tr -d '[:alpha:]')
CXXFLAGS+=-DTARGET=$(shell echo $(TARGET) | tr -d '[:alpha:]')
endif

ifneq "$(TARGET_REV)" ""
CFLAGS+=-DTARGET_REV=$(TARGET_REV)
endif

# Exclude debug for 'release' builds
ifneq (${MAKECMDGOALS},release)
ifneq (${DEBUG},0)
CFLAGS+=-g3 -ggdb -DDEBUG
endif
endif

CFLAGS+=$(PROJ_CFLAGS)

# The command for calling the library archiver.
AR=${PREFIX}-ar

# The command for calling the linker.
LD=${PREFIX}-gcc

# the command for striping objects.
STRIP=$(PREFIX)-strip

# the utility to fix debug info file paths in finished executables.
FIXDBGPATHS=$(wildcard $(shell which fixdbgpaths 2>/dev/null))

# The flags passed to the linker.
LDFLAGS=-mthumb                                                                \
        -mcpu=cortex-m4                                                        \
        -mfloat-abi=$(MFLOAT_FLAGS)                                                      \
        -mfpu=$(MFPU_FLAGS)                                                       \
        -Xlinker --gc-sections                                                 \
	-Xlinker -Map -Xlinker ${BUILD_DIR}/$(PROJECT).map
LDFLAGS+=$(PROJ_LDFLAGS)

# Include math library
STD_LIBS=-lc -lm

# Determine if any C++ files are in the project sources, and add libraries as appropriate
ifneq "$(findstring cpp, ${SRCS})" ""
STD_LIBS+=-lsupc++ -lstdc++
endif

# Finally, resolve any newlib system calls with libnosys
STD_LIBS+=-lnosys

PROJ_LIBS:=$(addprefix -l, $(PROJ_LIBS))

# The command for extracting images from the linked executables.
OBJCOPY=${PREFIX}-objcopy
OBJDUMP=${PREFIX}-objdump

ifeq "$(CYGWIN)" "True"
fixpath=$(shell echo $(1) | sed -r 's/\/cygdrive\/([A-Na-n])/\U\1:/g' )
else
fixpath=$(1)
endif

# Determine whether to include stripping of
# debug symbols from generated archive files.
gcc_strip_libraries=
ifeq ($(STRIP_LIBRARIES),0)
else
ifneq ($(STRIP_LIBRARIES),)
gcc_strip_libraries=1
else
endif
endif

# Add the include file paths to AFLAGS and CFLAGS.
AFLAGS+=${patsubst %,-I%,$(call fixpath,$(IPATH))}
CFLAGS+=${patsubst %,-I%,$(call fixpath,$(IPATH))}
LDFLAGS+=${patsubst %,-L%,$(call fixpath,$(LIBPATH))}

################################################################################
# The rule for building the object file from each C source file.
${BUILD_DIR}/%.o: %.c
	@if [ 'x${ECLIPSE}' != x ]; 																			\
	then 																									\
		echo ${CC} ${CFLAGS} -o $(call fixpath,${@}) $(call fixpath,${<}) | sed 's/-I\/\(.\)\//-I\1:\//g' ; \
	elif [ 'x${VERBOSE}' != x ];                                               								\
	then 																									\
	    echo ${CC} ${CFLAGS} -o $(call fixpath,${@}) $(call fixpath,${<});     								\
	elif [ 'x${QUIET}' != x ];                                                                       		\
	then																									\
		:;																									\
	else																									\
	    echo "  CC    ${<}";                                                   								\
	fi
	@${CC} ${CFLAGS} -o $(call fixpath,${@}) $(call fixpath,${<})
ifneq ($(FIXDBGPATHS),)
ifneq ($(FIXDBGPATHS_MATCH)$(FIXDBGPATHS_REPLACE),)
	@if [ ! -e $(call fixpath,${@}) ]; \
	then \
		false; \
	elif [ 'x${ECLIPSE}' != x ]; \
	then \
	        echo $(FIXDBGPATHS) -f $(call fixpath,${@}) \
	                -m '$(FIXDBGPATHS_MATCH)' \
	                -r '$(FIXDBGPATHS_REPLACE)'; \
	elif [ 'x${VERBOSE}' != x ]; \
	then \
	    echo $(FIXDBGPATHS) -f $(call fixpath,${@}) \
	            -m '$(FIXDBGPATHS_MATCH)' \
	            -r '$(FIXDBGPATHS_REPLACE)'; \
	elif [ 'x${QUIET}' != x ]; \
	then \
		:; \
	else \
	    echo "  FIXDBGPATHS ${@}"; \
	fi
	@$(FIXDBGPATHS) -f $(call fixpath,${@}) \
		-m '$(FIXDBGPATHS_MATCH)' \
		-r '$(FIXDBGPATHS_REPLACE)'
endif
endif
ifeq "$(CYGWIN)" "True"
	@sed -i -r -e 's/([A-Na-n]):/\/cygdrive\/\L\1/g' -e 's/\\([A-Za-z])/\/\1/g' ${@:.o=.d}
endif

# The rule to build an object file from a C++ source file
${BUILD_DIR}/%.o: %.cpp
	@if [ 'x${ECLIPSE}' != x ]; 																			 \
	then 																									 \
		echo ${CPP} ${CFLAGS} -o $(call fixpath,${@}) $(call fixpath,${<}) | sed 's/-I\/\(.\)\//-I\1:\//g' ; \
	elif [ 'x${VERBOSE}' != x ];                                               								 \
	then 																									 \
	    echo ${CPP} ${CFLAGS} -o $(call fixpath,${@}) $(call fixpath,${<});     						     \
	elif [ 'x${QUIET}' != x ];                                                                       		 \
	then 																									 \
		:; 																									 \
	else 																									 \
	    echo "  CC    ${<}";                                                   								 \
	fi
	@${CPP} ${CFLAGS} -o $(call fixpath,${@}) $(call fixpath,${<})
ifeq "$(CYGWIN)" "True"
	@sed -i -r -e 's/([A-Na-n]):/\/cygdrive\/\L\1/g' -e 's/\\([A-Za-z])/\/\1/g' ${@:.o=.d}
endif

# The rule for building the object file from each assembly source file.
${BUILD_DIR}/%.o: %.S
	@if [ 'x${VERBOSE}' = x ];                                                  \
	then                                                                        \
	    echo "  AS    ${<}";                                                    \
	elif [ 'x${QUIET}' != x ];                                                  \
	then 																		\
		:;																		\
	else 																		\
	    echo ${CC} ${AFLAGS} -o $(call fixpath,${@}) -c $(call fixpath,${<});   \
	fi
	@${CC} ${AFLAGS} -o $(call fixpath,${@}) -c $(call fixpath,${<})
ifeq "$(CYGWIN)" "True"
	@sed -i -r -e 's/([A-Na-n]):/\/cygdrive\/\L\1/g' -e 's/\\([A-Za-z])/\/\1/g' ${@:.o=.d}
endif

# The rule for building the object file from binary source file.
# Resulting object will have the following symbols
# _binary_<file_name>_bin_start
# _binary_<file_name>_bin_end
# _binary_<file_name>_bin_size
${BUILD_DIR}/%.o: %.bin
	@if [ 'x${VERBOSE}' = x ];                                                  \
	then                                                                        \
	    echo "  CP    ${<}";                                                    \
	elif [ 'x${QUIET}' != x ];                                                  \
	then 																		\
		:;																		\
	else 																		\
	    echo ${OBJCOPY} -I binary -B arm -O elf32-littlearm --rename-section    \
	    .data=.text $(call fixpath,${<}) $(call fixpath,${@});                  \
	fi
	@${OBJCOPY} -I binary -B arm -O elf32-littlearm --rename-section            \
	.data=.text $(call fixpath,${<}) $(call fixpath,${@})
ifeq "$(CYGWIN)" "True"
	@sed -i -r -e 's/([A-Na-n]):/\/cygdrive\/\L\1/g' -e 's/\\([A-Za-z])/\/\1/g' ${@:.o=.d}
endif

# The rule for creating an object library.
${BUILD_DIR}/%.a:
	@if [ 'x${VERBOSE}' = x ];                                                  \
	 then                                                                       \
	    echo "  AR    ${@}";                                                    \
	elif [ 'x${QUIET}' != x ];                                                  \
	then	 																	\
		:;																		\
	else 																		\
	    echo ${AR} -cr $(call fixpath,${@}) $(call fixpath,${^});               \
	fi
	@${AR} -cr $(call fixpath,${@}) $(call fixpath,${^})
ifneq ($(gcc_strip_libraries),)
ifneq ($(STRIP),)
	@if [ 'x${ECLIPSE}' != x ];                                                 \
	 then                                                                        \
	    echo ${STRIP} $(call fixpath,${@}) | sed 's/-I\/\(.\)\//-I\1:\//g' ;    \
	elif [ 'x${VERBOSE}' != x ];                                                \
	then                                                                        \
	    echo ${STRIP} --strip-unneeded $(call fixpath,${@});                                     \
	elif [ 'x${QUIET}' != x ];                                                  \
	then                                                                        \
	    :;                                                                      \
	else                                                                        \
	    echo "  STRIP ${@}";                                                    \
	fi
	@${STRIP} --strip-unneeded $(call fixpath,${@})
endif
endif

# The rule for linking the application.
${BUILD_DIR}/%.elf:
	@if [ 'x${VERBOSE}' = x ];                                                  \
	 then                                                                       \
	     echo "  LD    ${@} ${LNK_SCP}";                                        \
	 else                                                                       \
	     echo ${LD} -T $(call fixpath,${LINKERFILE})                            \
	          --entry ${ENTRY}                                                  \
	          $(call fixpath,${LDFLAGS})                                        \
	          -o $(call fixpath,${@})                                           \
	          $(call fixpath,$(filter %.o, ${^}))                               \
	          -Xlinker --start-group                                            \
	          $(call fixpath,$(filter %.a, ${^}))                               \
	          ${PROJ_LIBS}                                                      \
	          ${STD_LIBS}                                                       \
	          -Xlinker --end-group;                                             \
	 fi;                                                                        \
	${LD} -T $(call fixpath,${LINKERFILE})                                      \
	      --entry ${ENTRY}                                                      \
	      $(call fixpath,${LDFLAGS})                                            \
	      -o $(call fixpath,${@})                                               \
	      $(call fixpath,$(filter %.o, ${^}))                                   \
	      -Xlinker --start-group                                                \
	      $(call fixpath,$(filter %.a, ${^}))                                   \
	      ${PROJ_LIBS}                                                          \
	      ${STD_LIBS}                                                           \
	      -Xlinker --end-group

# Create S-Record output file
%.srec: %.elf
	@if [ 'x${VERBOSE}' = x ];                                                  \
	 then                                                                       \
	     echo "Creating ${@}";                                                  \
	 else                                                                       \
	     echo ${OBJCOPY} -O srec $(call fixpath,${<}) $(call fixpath,${@});     \
	 fi
	@$(OBJCOPY) -O srec $< $(call fixpath,${@})

# Create Intex Hex output file
%.hex: %.elf
	@if [ 'x${VERBOSE}' = x ];                                                  \
	 then                                                                       \
	     echo "Creating ${@}";                                                  \
	 else                                                                       \
	     echo ${OBJCOPY} -O ihex $(call fixpath,${<}) $(call fixpath,${@});     \
	 fi
	@$(OBJCOPY) -O ihex $< $(call fixpath,${@})

# Create binary output file
%.bin: %.elf
	@if [ 'x${VERBOSE}' = x ];                                                  \
	 then                                                                       \
	     echo "Creating ${@}";                                                  \
	 else                                                                       \
	     echo ${OBJCOPY} -O binary $(call fixpath,${<}) $(call fixpath,${@});   \
	 fi
	@$(OBJCOPY) -O binary $< $(call fixpath,${@})

# Create disassembly file
%.dasm: %.elf
	@if [ 'x${VERBOSE}' = x ];                                                  \
	 then                                                                       \
	     echo "Creating ${@}";                                                  \
	 else                                                                       \
	     echo $(OBJDUMP) -S $(call fixpath,${<}) $(call fixpath,${@});        	\
	 fi
	@$(OBJDUMP) -S $< > $(call fixpath,${@})

################################################################################
.PHONY: debug
debug:
	@echo CYGWIN = ${CYGWIN}
	@echo
	@echo BUILD_DIR = ${BUILD_DIR}
	@echo
	@echo SRCS = ${SRCS}
	@echo
	@echo SRCS_NOPATH = ${SRCS_NOPATH}
	@echo
	@echo OBJS_NOPATH = ${OBJS_NOPATH}
	@echo
	@echo OBJS = ${OBJS}
	@echo
	@echo LIBS = ${LIBS}
	@echo
	@echo VPATH = ${VPATH}
	@echo
	@echo IPATH = ${IPATH}
