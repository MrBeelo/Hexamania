#--SETTINGS--

# Directory in which there are source files.
BASE_SOURCE_DIRECTORY := src

# Directory in which there are resources (like images, sounds, etc.).
RESOURCES_DIRECTORY := res

# Directory in which the program along with the resources will be outputted in.
BASE_OUTPUT_DIRECTORY := bin

# The executable's name (add .exe if on windows)
EXECUTABLE_NAME := Hexamania

# Run the project immediately after export?
RUN := true

# Type of optimization to use. Options: none, minimal, size, speed, aggressive
OPTIMIZATION := none

# Enforce string odin writing conventions?
STRICT := true

# What should be the target? Options: desktop, web
MODE := desktop

# Odin's path. (needed for web building only)
ODIN_PATH := $(shell odin root)

# Path to emscripten compiler. (needed for web building only)
EMCC := /usr/lib/emscripten/emcc

#--SCRIPT--

SOURCE_DIRECTORY := $(BASE_SOURCE_DIRECTORY)/$(MODE)
OUTPUT_DIRECTORY := $(BASE_OUTPUT_DIRECTORY)/$(MODE)
STRICT_FLAG := $(if $(filter true,$(STRICT)),-vet -strict-style)
build: build-$(MODE)

build-desktop:
	mkdir -p $(OUTPUT_DIRECTORY)
	odin build $(SOURCE_DIRECTORY) -out:$(OUTPUT_DIRECTORY)/$(EXECUTABLE_NAME) -o:$(OPTIMIZATION) $(STRICT_FLAG)
	cp -r $(RESOURCES_DIRECTORY) $(OUTPUT_DIRECTORY)

ifeq ($(RUN), true)
	./$(OUTPUT_DIRECTORY)/$(EXECUTABLE_NAME)
endif

ODIN_WEB_BUILD_FLAGS = -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -define:RAYGUI_WASM_LIB=env.o $(STRICT_FLAG) -out:$(OUTPUT_DIRECTORY)/game.wasm.obj
WEB_FILES := $(OUTPUT_DIRECTORY)/game.wasm.obj $(ODIN_PATH)/vendor/raylib/wasm/libraylib.web.a $(ODIN_PATH)/vendor/raylib/wasm/libraygui.a
WEB_FLAGS := -sEXPORTED_RUNTIME_METHODS=['HEAPF32'] -sALLOW_MEMORY_GROWTH=1 -sUSE_GLFW=3 -sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS --shell-file $(SOURCE_DIRECTORY)/shell.html --preload-file $(RESOURCES_DIRECTORY)

build-web:
	mkdir -p $(OUTPUT_DIRECTORY)
	odin build $(SOURCE_DIRECTORY) $(ODIN_WEB_BUILD_FLAGS)
	cp $(ODIN_PATH)/core/sys/wasm/js/odin.js $(OUTPUT_DIRECTORY)
	$(EMCC) -o $(OUTPUT_DIRECTORY)/index.html $(WEB_FILES) $(WEB_FLAGS)
	rm $(OUTPUT_DIRECTORY)/game.wasm.obj

ifeq ($(RUN), true)
	cd $(OUTPUT_DIRECTORY) && python -m http.server 8080
endif

clean:
	rm -rf $(BASE_OUTPUT_DIRECTORY)