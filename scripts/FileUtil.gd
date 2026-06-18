extends Node

class_name FileUtil

# Walk up the directory tree from `path`, returning the first .codex file found.
# Starts in the folder containing `path`, then goes up one folder at a time.
# Returns the full path to the .codex file, or null if none is found.
static func find_nearest_codex(path: String) -> Variant:
	var dir := path.get_base_dir()
	while dir != "":
		var found: Variant = _find_codex_in_dir(dir)
		if found != null:
			return found
		var parent := dir.get_base_dir()
		if parent == dir:
			break
		dir = parent
	return null

# Convert an absolute module `path` (e.g. from the file picker) into a path
# relative to the directory containing `codex_path`. The codex is always an
# ancestor of the module (find_nearest_codex walks up from the module), so a
# prefix strip is sufficient. Falls back to the original path if it is not
# under the codex directory.
static func relative_to_codex(codex_path: String, path: String) -> String:
	var codex_dir := codex_path.get_base_dir()
	if not codex_dir.ends_with("/"):
		codex_dir += "/"
	if path.begins_with(codex_dir):
		return path.substr(codex_dir.length())
	return path

static func _find_codex_in_dir(dir: String) -> Variant:
	var da := DirAccess.open(dir)
	if da == null:
		return null
	da.list_dir_begin()
	var file_name := da.get_next()
	while file_name != "":
		if not da.current_is_dir() and file_name.get_extension() == "codex":
			da.list_dir_end()
			return dir.path_join(file_name)
		file_name = da.get_next()
	da.list_dir_end()
	return null
