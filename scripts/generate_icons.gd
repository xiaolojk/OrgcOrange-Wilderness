# generate_icons.gd — 程序化生成应用图标 + 启动画面
# 在 CI 中用 Godot headless 运行：godot --headless --script res://scripts/generate_icons.gd
# Orgc橘子工作室 · 《橘子荒野》
extends SceneTree

func _init() -> void:
	_ensure_dir("res://icons")
	_make_app_icon("res://icons/icon.png", 256)
	_make_app_icon("res://icons/icon_foreground.png", 256)
	_make_app_icon("res://icons/icon_background.png", 256)
	_make_splash("res://icons/splash.png", 1280, 720)
	print("[Orgc] 图标与启动画面已生成")
	quit()

func _ensure_dir(path: String) -> void:
	var d := DirAccess.open("res://")
	if not d.dir_exists(path):
		d.make_dir_recursive(path)

# 圆角方形图标：橙色渐变 + 橘子剪影 + "Orgc"字样
func _make_app_icon(path: String, sz: int) -> void:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	# 背景渐变（暖橙→深橙）
	for y in range(sz):
		var t := float(y) / sz
		var r := lerpf(0.96, 0.78, t)
		var g := lerpf(0.62, 0.36, t)
		var b := lerpf(0.18, 0.10, t)
		for x in range(sz):
			# 圆角：四角透明
			var corner := 0.18 * sz
			var alpha := 1.0
			if x < corner and y < corner:
				var d := Vector2(corner - x, corner - y).length()
				if d > corner: alpha = 0.0
			elif x > sz - corner and y < corner:
				var d := Vector2(x - (sz - corner), corner - y).length()
				if d > corner: alpha = 0.0
			elif x < corner and y > sz - corner:
				var d := Vector2(corner - x, y - (sz - corner)).length()
				if d > corner: alpha = 0.0
			elif x > sz - corner and y > sz - corner:
				var d := Vector2(x - (sz - corner), y - (sz - corner)).length()
				if d > corner: alpha = 0.0
			img.set_pixel(x, y, Color(r, g, b, alpha))
	# 中央橘子（圆 + 顶部叶子）
	var cx := sz / 2
	var cy := sz / 2 + sz * 0.04
	var rad := sz * 0.30
	for y in range(sz):
		for x in range(sz):
			var d := Vector2(x - cx, y - cy).length()
			if d < rad:
				# 橘子主体：亮橙带纹理
				var shade := 1.0 - (d / rad) * 0.25
				img.set_pixel(x, y, Color(0.98 * shade, 0.72 * shade, 0.28 * shade, 1.0))
			elif d < rad + 2:
				img.set_pixel(x, y, Color(0.70, 0.42, 0.12, 1.0))
	# 顶部叶子
	var leaf_y := cy - rad - sz * 0.04
	for y in range(int(leaf_y - sz * 0.03), int(leaf_y + sz * 0.05)):
		for x in range(cx - int(sz * 0.06), cx + int(sz * 0.10)):
			if x >= 0 and x < sz and y >= 0 and y < sz:
				var dx: float = abs(x - (cx + sz * 0.02)) / (sz * 0.08)
				var dy: float = abs(y - leaf_y) / (sz * 0.04)
				if dx + dy < 1.0:
					img.set_pixel(x, y, Color(0.30, 0.55, 0.18, 1.0))
	# "Orgc" 文字（底部，简化像素字）
	_draw_text(img, cx - sz * 0.12, sz - sz * 0.20, "ORGC", sz * 0.10)
	img.save_png(path)
	print("[Orgc] 已保存 %s" % path)

# 启动画面：横屏 1280x720，深色背景 + 橘子 + 工作室名
func _make_splash(path: String, w: int, h: int) -> void:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# 深色渐变背景
	for y in range(h):
		var t := float(y) / h
		var r := lerpf(0.10, 0.18, t)
		var g := lerpf(0.13, 0.22, t)
		var b := lerpf(0.18, 0.28, t)
		for x in range(w):
			img.set_pixel(x, y, Color(r, g, b, 1.0))
	# 中央大橘子
	var cx := w / 2
	var cy := h / 2 - 40
	var rad := 120
	for y in range(h):
		for x in range(w):
			var d := Vector2(x - cx, y - cy).length()
			if d < rad:
				var shade := 1.0 - (d / rad) * 0.2
				img.set_pixel(x, y, Color(0.98 * shade, 0.72 * shade, 0.28 * shade, 1.0))
			elif d < rad + 3:
				img.set_pixel(x, y, Color(0.70, 0.42, 0.12, 1.0))
	# 叶子
	var leaf_y := cy - rad - 12
	for y in range(leaf_y - 20, leaf_y + 20):
		for x in range(cx - 24, cx + 40):
			if x >= 0 and x < w and y >= 0 and y < h:
				var dx: float = abs(x - (cx + 8)) / 32.0
				var dy: float = abs(y - leaf_y) / 16.0
				if dx + dy < 1.0:
					img.set_pixel(x, y, Color(0.30, 0.55, 0.18, 1.0))
	# 工作室名
	_draw_text_big(img, cx - 200, cy + 180, "Orgc橘子工作室", 48, Color(0.98, 0.72, 0.28))
	_draw_text_big(img, cx - 160, cy + 250, "橘子荒野", 64, Color(1.0, 0.95, 0.55))
	img.save_png(path)
	print("[Orgc] 已保存 %s" % path)

# 简化像素字（大写字母 + 中文占位用矩形块）
func _draw_text(img: Image, x: int, y: int, text: String, sz: int) -> void:
	# 5x7 像素字体（大写字母）
	var FONT := {
		"O": ["01110","10001","10001","10001","10001","10001","01110"],
		"R": ["11110","10001","10001","11110","10100","10010","10001"],
		"G": ["01110","10001","10000","10111","10001","10001","01110"],
		"C": ["01110","10001","10000","10000","10000","10001","01110"],
	}
	var cx := x
	for ch in text:
		if FONT.has(ch):
			var glyph: Array = FONT[ch]
			for gy in range(7):
				var row: String = glyph[gy]
				for gx in range(5):
					if row[gx] == "1":
						for dy in range(sz):
							for dx in range(sz):
								var px := cx + gx * sz + dx
								var py := y + gy * sz + dy
								if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
									img.set_pixel(px, py, Color(1.0, 0.98, 0.92, 1.0))
			cx += 6 * sz
		else:
			cx += 4 * sz

# 大号像素字（用于启动画面，仅支持少量字符）
func _draw_text_big(img: Image, x: int, y: int, text: String, sz: int, color: Color) -> void:
	# 中文字符用矩形块近似显示（每个字一个色块）
	# 英文/数字用 5x7 像素字
	var FONT := {
		"O": ["01110","10001","10001","10001","10001","10001","01110"],
		"R": ["11110","10001","10001","11110","10100","10010","10001"],
		"G": ["01110","10001","10000","10111","10001","10001","01110"],
		"C": ["01110","10001","10000","10000","10000","10001","01110"],
	}
	var cx := x
	for ch in text:
		if FONT.has(ch):
			var glyph: Array = FONT[ch]
			for gy in range(7):
				var row: String = glyph[gy]
				for gx in range(5):
					if row[gx] == "1":
						for dy in range(sz):
							for dx in range(sz):
								var px := cx + gx * sz + dx
								var py := y + gy * sz + dy
								if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
									img.set_pixel(px, py, color)
			cx += 6 * sz
		elif ch == " ":
			cx += 3 * sz
		else:
			# 中文字符：绘制一个色块矩形（带描边）
			var block_w := sz * 8
			var block_h := sz * 8
			for dy in range(block_h):
				for dx in range(block_w):
					var px := cx + dx
					var py := y + dy
					if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
						var is_edge := dx < 2 or dy < 2 or dx >= block_w - 2 or dy >= block_h - 2
						if is_edge:
							img.set_pixel(px, py, Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, 1.0))
						else:
							img.set_pixel(px, py, Color(color.r * 0.85, color.g * 0.85, color.b * 0.85, 1.0))
			cx += block_w + sz
