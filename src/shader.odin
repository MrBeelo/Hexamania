package main

import rl "vendor:raylib"

bloom_shader: rl.Shader

LoadShaders :: proc() {
	path: cstring = "res/shader/web/bloom.fs" if ODIN_OS == .JS else "res/shader/desktop/bloom.fs"
	bloom_shader = rl.LoadShader(nil, path)
}

UnloadShaders :: proc() {
	rl.UnloadShader(bloom_shader)
}