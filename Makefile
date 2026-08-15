#------------------#
#     SETTINGS     #
#------------------#

# What should be the target? Options: desktop, web
MODE ?= desktop

# The executable's name. (without any extensions)
EXECUTABLE_NAME ?= Hexamania

# Adds the .exe extension to the executable. Definitely use if on windows.
ADD_EXE ?= false

# Run the project immediately after export?
RUN ?= true

# Type of optimization to use. Options: none, minimal, size, speed, aggressive
OPTIMIZATION ?= none

# Enforce strict odin writing conventions?
STRICT ?= true

# Enable debug? (adds debug symbols and runs with gdb, if it exists)
DEBUG ?= true

# Copy resources over to the output directory? (desktop only)
COPY_RESOURCES ?= true

# Directory in which there are source files.
SOURCE_DIRECTORY ?= src

# Directory in which there are resources. (like images, sounds, etc.)
RESOURCES_DIRECTORY ?= res

# Directory in which the program along with the resources will be outputted in.
OUTPUT_DIRECTORY ?= bin

#----------------#
#     SCRIPT     #
#----------------#

# This reroutes the source directory to a subfolder, as there are two 'main' procs.
NAMED_SOURCE_DIRECTORY := $(SOURCE_DIRECTORY)/$(MODE)

# This is used for convenience if building on multiple platforms.
NAMED_OUTPUT_DIRECTORY := $(OUTPUT_DIRECTORY)/$(MODE)

# Add the strict flag if STRICT is true.
STRICT_FLAG := $(if $(filter true,$(STRICT)),-vet -strict-style)

# Ditto with DEBUG.
DEBUG_FLAG := $(if $(filter true,$(DEBUG)),-debug)

# Add .exe extension.
ifeq ($(ADD_EXE), true)
	EXECUTABLE_NAME := $(EXECUTABLE_NAME).exe
endif

# Decide whether the program should be run with gdb.
CAN_RUN_DEBUG := true
ifneq ($(DEBUG), true)
	CAN_RUN_DEBUG = false
endif
ifeq (, $(shell which gdb))
	CAN_RUN_DEBUG = false
endif

# Change the build target depending on the platform.
build: build-$(MODE)

# Desktop Build
build-desktop:
	# Make the output directory if it doesn't already exist.
	mkdir -p $(NAMED_OUTPUT_DIRECTORY)

	# Build command.
	odin build $(NAMED_SOURCE_DIRECTORY) -out:$(NAMED_OUTPUT_DIRECTORY)/$(EXECUTABLE_NAME) -o:$(OPTIMIZATION) $(STRICT_FLAG) $(DEBUG_FLAG)

# Copy the resources to the output directory. If this wasn't done, the user
# would have to manually copy over the resource folder to the final build.
ifeq ($(COPY_RESOURCES), true)
	cp -r $(RESOURCES_DIRECTORY) $(NAMED_OUTPUT_DIRECTORY)
endif

# If RUN is set to true, run the program.
ifeq ($(RUN), true)

# Attempt to debug with gdb if it exists.
ifeq ($(CAN_RUN_DEBUG), true)
	gdb -q -ex 'set pagination off' ./$(NAMED_OUTPUT_DIRECTORY)/$(EXECUTABLE_NAME) -ex 'set debuginfod enabled on' -ex run
else
	./$(NAMED_OUTPUT_DIRECTORY)/$(EXECUTABLE_NAME)
endif

endif

# Additional build flags needed for web building. Generates an obj file that emscripten will take.
ODIN_WEB_BUILD_FLAGS := -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -define:RAYGUI_WASM_LIB=env.o $(STRICT_FLAG) $(DEBUG_FLAG) -out:$(NAMED_OUTPUT_DIRECTORY)/game.wasm.obj

# Outputted obj file and raylib library.
WEB_FILES := $(NAMED_OUTPUT_DIRECTORY)/game.wasm.obj $(SOURCE_DIRECTORY)/raylib/lib/webassembly/libraylib.web.a $(SOURCE_DIRECTORY)/raylib/lib/webassembly/libraygui.web.a

# Some additional flags for emscripten.
WEB_FLAGS := -sEXPORTED_RUNTIME_METHODS=['HEAPF32'] -sALLOW_MEMORY_GROWTH=1 -sUSE_GLFW=3 -sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS --shell-file $(NAMED_SOURCE_DIRECTORY)/shell.html --preload-file $(RESOURCES_DIRECTORY)

# Web build
build-web:
	# Make the output directory if it doesn't already exist.
	mkdir -p $(NAMED_OUTPUT_DIRECTORY)

	# First pass: odin build command.
	odin build $(NAMED_SOURCE_DIRECTORY) $(ODIN_WEB_BUILD_FLAGS)

	# Copy over odin.js to the output directory.
	cp $(NAMED_SOURCE_DIRECTORY)/odin.js $(NAMED_OUTPUT_DIRECTORY)

	# Second pass: emcc build command.
	emcc -o $(NAMED_OUTPUT_DIRECTORY)/$(EXECUTABLE_NAME).html $(WEB_FILES) $(WEB_FLAGS)

	# Since the project has been built, we can get rid of the obj file.
	rm $(NAMED_OUTPUT_DIRECTORY)/game.wasm.obj

	# Rename name.html to index.html for itch.io
	mv $(NAMED_OUTPUT_DIRECTORY)/$(EXECUTABLE_NAME).html $(NAMED_OUTPUT_DIRECTORY)/index.html

# If RUN is set to true, start a web server on the output directory.
ifeq ($(RUN), true)
	cd $(NAMED_OUTPUT_DIRECTORY) && emrun .
endif

# Clean the output directory.
# Can be called with 'make clean'.
clean:
	rm -rf $(OUTPUT_DIRECTORY)