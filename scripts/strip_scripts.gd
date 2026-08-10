# strip_scripts.gd — 剥离脚本注释和调试 print，防反编译辅助
# 在导出前运行，配合 script_export_mode=2 加密
# Orgc橘子工作室
extends SceneTree

func _init() -> void:
	var dir := DirAccess.open("res://scripts")
	if dir == null:
		print("[Orgc] 无法打开 scripts 目录")
		quit()
		return
	_strip_dir("res://scripts")
	print("[Orgc] 脚本剥离完成")
	quit()

func _strip_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null: return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if dir.current_is_dir():
			if fname != "." and fname != "..":
				_strip_dir(path + "/" + fname)
		elif fname.ends_with(".gd"):
			_strip_file(path + "/" + fname)
		fname = dir.get_next()
	dir.list_dir_end()

func _strip_file(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return
	var content := f.get_as_text()
	f.close()
	var lines := content.split("\n")
	var out := []
	for line in lines:
		var stripped := line.strip_edges()
		# 跳过纯注释行（保留 #! shebang）
		if stripped.begins_with("#") and not stripped.begins_with("#!"):
			continue
		# 跳过调试 print（保留 [Orgc] 关键日志）
		if stripped.begins_with("print(") and "[Orgc]" in stripped:
			continue
		if stripped.begins_with("print("):
			continue
		# 剥离行内注释（简单处理，不处理字符串内的 #）
		var hash_idx := line.find("#")
		if hash_idx >= 0:
			# 检查 # 是否在字符串内（简单启发式）
			var before := line.substr(0, hash_idx)
			var quote_count := before.count('"')
			if quote_count % 2 == 0:
				line = before.rstrip(" \t")
		out.append(line)
	var new_content := "\n".join(out)
	# 压缩多余空行
	while new_content.find("\n\n\n") >= 0:
		new_content = new_content.replace("\n\n\n", "\n\n")
	var f2 := FileAccess.open(path, FileAccess.WRITE)
	if f2 != null:
		f2.store_string(new_content)
		f2.close()
