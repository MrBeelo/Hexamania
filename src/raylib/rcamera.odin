/*******************************************************************************************
*
*   rcamera - Basic camera system with support for multiple camera modes
*
*   CONFIGURATION:
*       #define RCAMERA_IMPLEMENTATION
*           Generates the implementation of the library into the included file.
*           If not defined, the library is in header only mode and can be included in other headers
*           or source files without problems. But only ONE file should hold the implementation.
*
*       #define RCAMERA_STANDALONE
*           If defined, the library can be used as standalone as a camera system but some
*           functions must be redefined to manage inputs accordingly.
*
*   CONTRIBUTORS:
*       Ramon Santamaria:   Supervision, review, update and maintenance
*       Christoph Wagner:   Complete redesign, using raymath (2022)
*       Marc Palau:         Initial implementation (2014)
*
*
*   LICENSE: zlib/libpng
*
*   Copyright (c) 2022-2026 Christoph Wagner (@Crydsch) and Ramon Santamaria (@raysan5)
*
*   This software is provided "as-is", without any express or implied warranty. In no event
*   will the authors be held liable for any damages arising from the use of this software.
*
*   Permission is granted to anyone to use this software for any purpose, including commercial
*   applications, and to alter it and redistribute it freely, subject to the following restrictions:
*
*     1. The origin of this software must not be misrepresented; you must not claim that you
*     wrote the original software. If you use this software in a product, an acknowledgment
*     in the product documentation would be appreciated but is not required.
*
*     2. Altered source versions must be plainly marked as such, and must not be misrepresented
*     as being the original software.
*
*     3. This notice may not be removed or altered from any source distribution.
*
**********************************************************************************************/
package raylib

when ODIN_OS == .Windows {
	@(extra_linker_flags="/NODEFAULTLIB:" + ("msvcrt" when RAYLIB_SHARED else "libcmt"))
	foreign import lib {
		(
			"lib/win64_msvc16/raylibdll.lib" when RAYLIB_SHARED && ODIN_ARCH == .amd64 else 
			"lib/win64_msvc16/raylib.lib" when ODIN_ARCH == .amd64 else 
			"lib/win32_msvc16/raylibdll.lib" when RAYLIB_SHARED && ODIN_ARCH == .i386 else 
			"lib/win32_msvc16/raylib.lib" when ODIN_ARCH == .i386 else 
			"lib/winarm64_msvc16/raylibdll.lib" when RAYLIB_SHARED && ODIN_ARCH == .arm64 else 
			"lib/winarm64_msvc16/raylib.lib" when ODIN_ARCH == .arm64 else
			"system:raylib"
		),
		"system:Winmm.lib",
		"system:Gdi32.lib",
		"system:User32.lib",
		"system:Shell32.lib",
	}
} else when ODIN_OS == .Linux {
	// Note(bumbread): I'm not sure why in `linux/` folder there are
	// multiple copies of raylib.so, but since these bindings are for
	// particular version of the library, I better specify it. Ideally,
	// though, it's best specified in terms of major (.so.4)
	foreign import lib {
		(
			"lib/linux_amd64/libraylib.so.6.0.0" when RAYLIB_SHARED && ODIN_ARCH == .amd64 else 
			"lib/linux_amd64/libraylib.a" when ODIN_ARCH == .amd64 else 
			"lib/linux_i386/libraylib.a" when ODIN_ARCH == .i386 else 
			"lib/linux_arm64/libraylib.so.6.0.0" when RAYLIB_SHARED && ODIN_ARCH == .arm64 else 
			"lib/linux_arm64/libraylib.a" when ODIN_ARCH == .arm64 else
			"system:raylib"
		),
		"system:dl",
		"system:pthread",
		"system:X11",
	}
} else when ODIN_OS == .Darwin {
	foreign import lib {
		"lib/macos/libraylib.6.0.0.dylib" when RAYLIB_SHARED else "lib/macos/libraylib.a",
		"system:Cocoa.framework",
		"system:OpenGL.framework",
		"system:IOKit.framework",
	}
} else when ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32 {
	foreign import lib {
		RAYLIB_WASM_LIB,
	}
} else {
	foreign import lib "system:raylib"
}

@(default_calling_convention="c")
foreign lib {
	GetCameraForward :: proc(camera: ^Camera) -> Vector3 ---
	GetCameraUp      :: proc(camera: ^Camera) -> Vector3 ---
	GetCameraRight   :: proc(camera: ^Camera) -> Vector3 ---

	// Camera movement
	CameraMoveForward  :: proc(camera: ^Camera, distance: f32, moveInWorldPlane: bool) ---
	CameraMoveUp       :: proc(camera: ^Camera, distance: f32) ---
	CameraMoveRight    :: proc(camera: ^Camera, distance: f32, moveInWorldPlane: bool) ---
	CameraMoveToTarget :: proc(camera: ^Camera, delta: f32) ---

	// Camera rotation
	CameraYaw                 :: proc(camera: ^Camera, angle: f32, rotateAroundTarget: bool) ---
	CameraPitch               :: proc(camera: ^Camera, angle: f32, lockView: bool, rotateAroundTarget: bool, rotateUp: bool) ---
	CameraRoll                :: proc(camera: ^Camera, angle: f32) ---
	GetCameraViewMatrix       :: proc(camera: ^Camera) -> Matrix ---
	GetCameraProjectionMatrix :: proc(camera: ^Camera, aspect: f32) -> Matrix ---
}

