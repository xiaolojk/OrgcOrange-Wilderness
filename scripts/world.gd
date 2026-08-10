# world.gd — 世界系统：程序化地形 TileMap + 昼夜 + 天气
# Orgc橘子工作室 · 《橘子荒野》
extends Node2D

const WORLD_SIZE := 80
const TILE_SCALE := 0.08
const OCTAVES := 4
const DAY_LENGTH := 240.0  # 一天 240 秒

var time_of_day := 0.3  # 从清晨开始
var weather := "晴"
var _weather_timer := 0.0
var _seed_x := 1000.0
var _seed_y := 2000.0

var _tilemap: TileMapLayer
var _tile_set: TileSet
# tile 类型名 -> TileSetSource id
var _tile_ids := {}

signal time_changed(t)
signal weather_changed(w)

func _ready() -> void:
	_build_tileset()
	_build_tilemap()
	_generate_terrain()

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
	var d := abs((time_of_day - 0.5) * 2.0)  # 0=正午 1=午夜
	var light := lerpf(1.0, 0.35, d)
	if weather == "雨": light *= 0.85
	if weather == "雾": light *= 0.92
	return Color(light, light * 0.96, light * 1.02, 1.0)

# ============ 地形 ============
func _build_tileset() -> void:
	_tile_set = TileSet.new()
	_tile_set.tile_size = Vector2i(16, 16)
	_tile_set.tile_shape = TileSet.TILE_SHAPE_SQUARE
	# 为每种地形创建一个图源
	var tiles := {
		"water":  [Color(0.27,0.51,0.82), Color(0.16,0.35,0.63)],
		"sand":   [Color(0.87,0.80,0.55), Color(0.71,0.63,0.39)],
		"grass":  [Color(0.42,0.67,0.25), Color(0.24,0.43,0.16)],
		"grass2": [Color(0.48,0.74,0.31), Color(0.27,0.47,0.19)],
		"dirt":   [Color(0.56,0.39,0.25), Color(0.35,0.25,0.16)],
		"stone":  [Color(0.51,0.51,0.54), Color(0.31,0.31,0.35)],
		"snow":   [Color(0.91,0.94,0.97), Color(0.75,0.78,0.84)],
	}
	var idx := 0
	for name in tiles:
		var img := _make_tile_image(tiles[name][0], tiles[name][1], name)
		var tex := ImageTexture.new()
		tex.create_from_image(img)
		var src := TileSetAtlasSource.new()
		src.texture = tex
		src.create_tile(Vector2i(0,0))
		var sid := _tile_set.add_source(src)
		_tile_ids[name] = sid
		idx += 1

func _make_tile_image(base: Color, edge: Color, name: String) -> Image:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	for y in range(16):
		for x in range(16):
			var c: Color
			var n := rng.randi_range(-12, 12)
			var is_edge := x == 0 or y == 0 or x == 15 or y == 15
			if is_edge:
				c = edge
			else:
				c = Color(clamp(base.r*255+n,0,255)/255.0,
						  clamp(base.g*255+n,0,255)/255.0,
						  clamp(base.b*255+n,0,255)/255.0, 1.0)
			img.set_pixel(x, y, c)
	return img

func _build_tilemap() -> void:
	_tilemap = TileMapLayer.new()
	_tilemap.name = "Terrain"
	_tilemap.tile_set = _tile_set
	add_child(_tilemap)

func _generate_terrain() -> void:
	var half := WORLD_SIZE / 2
	for y in range(WORLD_SIZE):
		for x in range(WORLD_SIZE):
			var h := _fbm((_seed_x + x) * TILE_SCALE, (_seed_y + y) * TILE_SCALE, OCTAVES)
			var tname := _choose_tile(h)
			_tilemap.set_cell(Vector2i(x - half, y - half), _tile_ids[tname], Vector2i(0,0))

func _choose_tile(h: float) -> String:
	if h < 0.30: return "water"
	if h < 0.36: return "sand"
	if h < 0.55: return "grass"
	if h < 0.62: return "grass2"
	if h < 0.74: return "dirt"
	if h < 0.88: return "stone"
	return "snow"

# Simplex 风格噪声（GDScript 实现，确定性）
func _noise2d(x: float, y: float) -> float:
	# 简化的梯度噪声：用 sin/cos 哈希
	var xi := int(floor(x)) & 255
	var yi := int(floor(y)) & 255
	var xf := x - floor(x)
	var yf := y - floor(y)
	var u := xf * xf * xf * (xf * (xf * 6.0 - 15.0) + 10.0)
	var v := yf * yf * yf * (yf * (yf * 6.0 - 15.0) + 10.0)
	var a := _grad(_hash(xi, yi), xf, yf)
	var b := _grad(_hash(xi+1, yi), xf-1, yf)
	var c := _grad(_hash(xi, yi+1), xf, yf-1)
	var d := _grad(_hash(xi+1, yi+1), xf-1, yf-1)
	var n := lerp(lerp(a, b, u), lerp(c, d, u), v)
	return 0.5 + 0.5 * n

func _hash(x: int, y: int) -> int:
	var h := (x * 374761393 + y * 668265263) & 0x7FFFFFFF
	return h

func _grad(hash_val: int, x: float, y: float) -> float:
	var h := hash_val & 7
	var u := x if h < 4 else y
	var v := y if h < 4 else x
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

# 查询某格地形类型
func tile_type_at(cell: Vector2i) -> String:
	var data := _tilemap.get_cell_source_id(cell)
	for tname in _tile_ids:
		if _tile_ids[tname] == data:
			return tname
	return "none"

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return _tilemap.local_to_map(world_pos - global_position)

func cell_center(cell: Vector2i) -> Vector2:
	return _tilemap.map_to_local(cell) + global_position

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
