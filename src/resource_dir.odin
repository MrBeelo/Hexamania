package main

import rl "vendor:raylib"

SearchAndSetResourceDir :: proc(folder_name: cstring) -> bool {
	if rl.DirectoryExists(folder_name) {
		rl.ChangeDirectory(folder_name)
		return true
	}
	
	app_dir := rl.GetApplicationDirectory()
	dirs := [?]cstring{"%s%s", "%s../%s", "%s../../%s", "%s../../../%s"}
	for dir in dirs do if ChangeAndCheckDir(rl.TextFormat(dir, app_dir, folder_name)) do return true
	
	return false
}

ChangeAndCheckDir :: proc(dir: cstring) -> bool {
	if rl.DirectoryExists(dir) {
		rl.ChangeDirectory(dir)
		return true
	}
	return false
}