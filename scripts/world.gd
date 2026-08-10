# world.gd — 世界系统：程序化地形 + 昼夜 + 天气
# Orgc橘子工作室 · 《橘子荒野》
# 用 _draw() 直接绘制地形（避免 TileSet/TileMapLayer 在 Android 上的兼容问题）
class_name WorldSystem
extends Node2D

const WORLD_SIZE := 80
const TILE_PX := 16  # 每格 16 像素
const TILE_SCALE := 0.08
const OCTAVES := 4
const DAY_LENGTH := 240.0  # 一天 240 秒

var time_of_day := 0.3  # 从清晨开始
var weather := "晴"
var _weather_timer := 0.0
var _seed_x := 1000.0
var _seed_y := 2000.0

# 地形数据：二维数组存 tile 类型名
var _grid: Array = []
# tile 类型名 -> ImageTexture
var _tile_textures: Dictionary = {}

signal time_changed(t)
signal weather_changed(w)

func _ready() -> void:
	_build_tile_textures()
	_generate_terrain()
	# 设置可绘制区域足够大
	z_index = -10

func is_night() -> bool:
	return time_of_day < 0.22 or time_of_day > 0.78

func temperature() -> float:
	var t := 37.0
	if is_night(): t -= 4.0
	if weather == "雨": t -= 3.0
	if weather == "雾": t -= 1.0
	return t

# 环境色（驱动背景/氛围）
func ambient_color() -> Color:
	var d: float = abs((time_of_day - 0.5) * 2.0)  # 0=正午 1=午夜
	var light: float = lerpf(1.0, 0.35, d)
	if weather == "雨": light *= 0.85
	if weather == "雾": light *= 0.92
	return Color(light, light * 0.96, light * 1.02, 1.0)

# ============ 地形纹理 ============
func _build_tile_textures() -> void:
	var tiles := {
		"water":  [Color(0.27,0.51,0.82), Color(0.16,0.35,0.63)],
		"sand":   [Color(0.87,0.80,0.55), Color(0.71,0.63,0.39)],
		"grass":  [Color(0.42,0.67,0.25), Color(0.24,0.43,0.16)],
		"grass2": [Color(0.48,0.74,0.31), Color(0.27,0.47,0.19)],
		"dirt":   [Color(0.56,0.39,0.25), Color(0.35,0.25,0.16)],
		"stone":  [Color(0.51,0.51,0.54), Color(0.31,0.31,0.35)],
		"snow":   [Color(0.91,0.94,0.97), Color(0.75,0.78,0.84)],
	}
	for tname in tiles:
		var img := _make_tile_image(tiles[tname][0], tiles[tname][1], tname)
		var tex := ImageTexture.new()
		tex.create_from_image(img)
		_tile_textures[tname] = tex

func _make_tile_image(base: Color, edge: Color, name: String) -> Image:
	var img := Image.create(TILE_PX, TILE_PX, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	for y in range(TILE_PX):
		for x in range(TILE_PX):
			var c: Color
			var n := rng.randi_range(-12, 12)
			var is_edge := x == 0 or y == 0 or x == TILE_PX-1 or y == TILE_PX-1
			if is_edge:
				c = edge
			else:
				c = Color(clamp(base.r*255+n,0,255)/255.0,
						  clamp(base.g*255+n,0,255)/255.0,
						  clamp(base.b*255+n,0,255)/255.0, 1.0)
			img.set_pixel(x, y, c)
	return img

# ============ 地形生成 ============
func _generate_terrain() -> void:
	_grid.clear()
	var half := WORLD_SIZE / 2
	for y in range(WORLD_SIZE):
		var row: Array = []
		for x in range(WORLD_SIZE):
			var h := _fbm((_seed_x + x) * TILE_SCALE, (_seed_y + y) * TILE_SCALE, OCTAVES)
			row.append(_choose_tile(h))
		_grid.append(row)
	# 生成后立即重绘
	queue_redraw()

func _choose_tile(h: float) -> String:
	if h < 0.30: return "water"
	if h < 0.36: return "sand"
	if h < 0.55: return "grass"
	if h < 0.62: return "grass2"
	if h < 0.74: return "dirt"
	if h < 0.88: return "stone"
	return "snow"

# ============ 绘制 ============
func _draw() -> void:
	var half := WORLD_SIZE / 2
	for y in range(WORLD_SIZE):
		for x in range(WORLD_SIZE):
			var tname: String = _grid[y][x]
			var tex: Texture2D = _tile_textures.get(tname)
			if tex == null:
				continue
			var px: float = (x - half) * TILE_PX
			var py: float = (y - half) * TILE_PX
			draw_texture(tex, Vector2(px, py))

# Simplex 风格噪声（GDScript 实现，确定性）
func _noise2d(x: float, y: float) -> float:
	var xi: int = int(floor(x)) & 255
	var yi: int = int(floor(y)) & 255
	var xf: float = x - floor(x)
	var yf: float = y - floor(y)
	var u: float = xf * xf * xf * (xf * (xf * 6.0 - 15.0) + 10.0)
	var v: float = yf * yf * yf * (yf * (yf * 6.0 - 15.0) + 10.0)
	var a: float = _grad(_hash(xi, yi), xf, yf)
	var b: float = _grad(_hash(xi+1, yi), xf-1, yf)
	var c: float = _grad(_hash(xi, yi+1), xf, yf-1)
	var d: float = _grad(_hash(xi+1, yi+1), xf-1, yf-1)
	var n: float = lerpf(lerpf(a, b, u), lerpf(c, d, u), v)
	return 0.5 + 0.5 * n

func _hash(x: int, y: int) -> int:
	var h := (x * 374761393 + y * 668265263) & 0x7FFFFFFF
	return h

func _grad(hash_val: int, x: float, y: float) -> float:
	var h: int = hash_val & 7
	var u: float = x if h < 4 else y
	var v: float = y if h < 4 else x
	return ((-u) if (h & 1) else u) + ((-2.0*v) if (h & 2) else (2.0*v))

func _fbm(x: float, y: float, octaves: int) -> float:
	var amp := 0.5
	var freq := 1.0
	var sum := 0.0
	var norm := 0.0
	for i in range(octaves):
		sum += amp * _noise2d(x * freq, y * freq)
		norm += amp
		amp *= 0.5
		freq *= 2.0
	return sum / norm

# 查询某格地形类型（world_pos -> tile 名）
func tile_type_at(world_pos: Vector2) -> String:
	var half := WORLD_SIZE / 2
	var tx: int = int(floor(world_pos.x / TILE_PX)) + half
	var ty: int = int(floor(world_pos.y / TILE_PX)) + half
	if tx < 0 or tx >= WORLD_SIZE or ty < 0 or ty >= WORLD_SIZE:
		return "none"
	return _grid[ty][tx]

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / TILE_PX)), int(floor(world_pos.y / TILE_PX)))

func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE_PX + TILE_PX * 0.5, cell.y * TILE_PX + TILE_PX * 0.5)

func _process(dt: float) -> void:
	time_of_day += dt / DAY_LENGTH
	if time_of_day >= 1.0: time_of_day -= 1.0
	emit_signal("time_changed", time_of_day)
	_weather_timer += dt
	if _weather_timer >= 30.0:
		_weather_timer = 0.0
		_roll_weather()

func _roll_weather() -> void:
	var r := randf()
	var prev := weather
	if r < 0.6: weather = "晴"
	elif r < 0.85: weather = "雨"
	else: weather = "雾"
	if weather != prev:
		emit_signal("weather_changed", weather)
