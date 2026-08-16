package main

import rl "raylib"

search_and_set_resource_dir :: proc(folder_name: cstring) -> bool {
	if rl.DirectoryExists(folder_name) {
		rl.ChangeDirectory(folder_name)
		return true
	}
	
	app_dir := rl.GetApplicationDirectory()
	dirs := [?]cstring{"%s%s", "%s../%s", "%s../../%s", "%s../../../%s"}
	for dir in dirs do if change_and_check_dir(rl.TextFormat(dir, app_dir, folder_name)) do return true
	
	return false
}

@(private = "file")
change_and_check_dir :: proc(dir: cstring) -> bool {
	if rl.DirectoryExists(dir) {
		rl.ChangeDirectory(dir)
		return true
	}
	return false
}