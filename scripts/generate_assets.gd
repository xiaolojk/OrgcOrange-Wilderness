# generate_assets.gd — 预生成所有精灵 + 地图 PNG 到 res://assets/
# CI 中运行：godot --headless --script res://scripts/generate_assets.gd
# 编辑器随后导入这些 PNG，运行时用 load() 加载（最可靠，兼容所有设备）
# Orgc橘子工作室 · 《橘子荒野》
extends SceneTree

const PX := 16

# 调色板（与 pixel_art.gd 完全一致）
const PAL := {
	" ": Color(0,0,0,0),
	"#": Color(0.10,0.10,0.12,1),
	"o": Color(0.25,0.20,0.16,1),
	"s": Color(0.96,0.78,0.60,1), "S": Color(0.82,0.62,0.46,1),
	"h": Color(0.30,0.18,0.10,1), "H": Color(0.20,0.12,0.06,1),
	"c": Color(0.95,0.55,0.18,1), "C": Color(0.78,0.40,0.10,1), "e": Color(1.00,0.72,0.34,1),
	"p": Color(0.20,0.28,0.46,1), "P": Color(0.14,0.20,0.34,1),
	"w": Color(0.62,0.42,0.24,1), "W": Color(0.42,0.28,0.16,1), "l": Color(0.78,0.56,0.32,1),
	"g": Color(0.52,0.52,0.56,1), "G": Color(0.34,0.34,0.38,1),
	"i": Color(0.74,0.78,0.84,1), "I": Color(0.50,0.54,0.60,1),
	"r": Color(0.86,0.20,0.26,1), "R": Color(0.62,0.10,0.16,1), "b": Color(0.36,0.66,0.30,1),
	"q": Color(0.30,0.60,0.92,1), "Q": Color(0.18,0.42,0.72,1),
	"k": Color(0.18,0.18,0.20,1), "K": Color(0.10,0.10,0.12,1),
	"m": Color(0.98,0.84,0.30,1), "M": Color(0.80,0.62,0.16,1), "x": Color(1.0,0.95,0.55,1),
	"a": Color(0.42,0.44,0.48,1), "A": Color(0.28,0.30,0.34,1), "d": Color(0.58,0.60,0.64,1),
	"u": Color(0.86,0.56,0.50,1), "U": Color(0.66,0.36,0.32,1),
}

func _init() -> void:
	_ensure_dir("res://assets")
	# 1. 生成所有精灵 PNG（16x16）
	var sprites := ["player","wood","stone","fiber","iron_ore","charcoal","iron_ingot",
		"berry","meat","water","iron_blade","purify_amulet","tree","bush","rock","anvil"]
	for key in sprites:
		_save_sprite(key, "res://assets/%s.png" % key)
	# 2. 生成建筑物 PNG（32x32，比普通精灵大）
	var buildings := ["house","tent","campfire","well","fence"]
	for key in buildings:
		_save_building(key, "res://assets/%s.png" % key)
	# 3. 生成 NPC PNG（16x16，不同颜色服装）
	var npcs := ["npc_villager","npc_merchant","npc_hunter"]
	for key in npcs:
		_save_sprite(key, "res://assets/%s.png" % key)
	# 4. 生成地图 PNG（固定种子，与 world.gd 一致）
	_save_map("res://assets/map.png")
	print("[Orgc] 所有资源 PNG 已生成到 res://assets/")
	quit()

func _save_building(key: String, path: String) -> void:
	var img := _build_building(key)
	img.save_png(path)
	print("[Orgc] 已保存 %s (%dx%d)" % [path, img.get_width(), img.get_height()])

# 32x32 建筑物图案
func _build_building(key: String) -> Image:
	var rows: Array = _building_pattern(key)
	var h: int = rows.size()
	var w: int = rows[0].length() if h > 0 else 32
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var row: String = rows[y]
		for x in range(w):
			var ch := " "
			if x < row.length():
				ch = row[x]
			var c: Color = PAL.get(ch, Color(0,0,0,0))
			img.set_pixel(x, y, c)
	return img

func _building_pattern(key: String) -> Array:
	match key:
		"house": return [
			"        rrrrrrrr        ",
			"       rRRRRRRRRr       ",
			"      rRRRRRRRRRRr      ",
			"     rRRRRRRRRRRRRr     ",
			"    rRRRRRRRRRRRRRRr    ",
			"   rRRRRRRRRRRRRRRRRr   ",
			"  rRRRRRRRRRRRRRRRRRRr  ",
			" rRRRRRRRRRRRRRRRRRRRRr ",
			"  WWWWWWWWWWWWWWWWWWWW  ",
			"  W##################W  ",
			"  W##WWWWWWWWWWWWWW##W  ",
			"  W##WsssssssssssW##W  ",
			"  W##WssSSSSSSSssW##W  ",
			"  W##WssSSSSSSSssW##W  ",
			"  W##WssSSSSSSSssW##W  ",
			"  W##WWWWWWWWWWWW##W  ",
			"  W##################W  ",
			"  W##WWWWWW##WWWWW##W  ",
			"  W##WWWWWW##WWWWW##W  ",
			"  W##WWWWWWWWWWWWW##W  ",
			"  W##################W  ",
			"  WWWWWWWWWWWWWWWWWWWW  ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        "]
		"tent": return [
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"           c            ",
			"          ccc           ",
			"         ccccc          ",
			"        ccccccc         ",
			"       ccccccccc        ",
			"      cccccccccc        ",
			"     cccccccccccc       ",
			"    cccccccccccccc      ",
			"   cccccccccccccccc     ",
			"  cccccccccccccccccc    ",
			" ccccccccccccccccccccc   ",
			"ccccccccccccccccccccccccc",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        "]
		"campfire": return [
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"           x            ",
			"          xxx           ",
			"         xxxxx          ",
			"          xxx           ",
			"        WWWWWWW         ",
			"       WWWWWWWWW        ",
			"      WWkkkkkkkWW       ",
			"       WWWWWWWWW        ",
			"        WWWWWWW         ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        "]
		"well": return [
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"     d          d       ",
			"    ddd        ddd      ",
			"   dddAAAAAAAAAdddd     ",
			"   dAAAAAAAAAAAAAAd     ",
			"   dAqqqqqqqqqqqAd     ",
			"   dAqQQQQQQQQQqAd     ",
			"   dAqQQQQQQQQQqAd     ",
			"   dAqQQQQQQQQQqAd     ",
			"   dAqqqqqqqqqqqAd     ",
			"   dAAAAAAAAAAAAAAd     ",
			"   dddddddddddddddd     ",
			"    dddddddddddddd      ",
			"     dddddddddddd       ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        "]
		"fence": return [
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"  W     W     W     W   ",
			"  W     W     W     W   ",
			"  W     W     W     W   ",
			"  WWWWWWWWWWWWWWWWWWW   ",
			"  W     W     W     W   ",
			"  W     W     W     W   ",
			"  WWWWWWWWWWWWWWWWWWW   ",
			"  W     W     W     W   ",
			"  W     W     W     W   ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        "]
		_: return _pattern("anvil")

func _ensure_dir(path: String) -> void:
	var d := DirAccess.open("res://")
	if not d.dir_exists(path):
		d.make_dir_recursive(path)

func _save_sprite(key: String, path: String) -> void:
	var img := _build_figure(key)
	img.save_png(path)
	print("[Orgc] 已保存 %s (%dx%d)" % [path, img.get_width(), img.get_height()])

func _build_figure(key: String) -> Image:
	var rows: Array = _pattern(key)
	var h: int = rows.size()
	var w: int = rows[0].length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var row: String = rows[y]
		for x in range(w):
			var ch := " "
			if x < row.length():
				ch = row[x]
			var c: Color = PAL.get(ch, Color(0,0,0,0))
			# PNG y=0 在顶部，图案数组第0行也是顶部，无需翻转
			img.set_pixel(x, y, c)
	return img

# ============ 地图生成（与 world.gd 逻辑一致，固定种子） ============
const WORLD_SIZE := 80
const TILE_PX := 16
const TILE_SCALE := 0.08
const OCTAVES := 4

func _save_map(path: String) -> void:
	var tile_colors := {
		"water":  [Color(0.27,0.51,0.82), Color(0.16,0.35,0.63)],
		"sand":   [Color(0.87,0.80,0.55), Color(0.71,0.63,0.39)],
		"grass":  [Color(0.42,0.67,0.25), Color(0.24,0.43,0.16)],
		"grass2": [Color(0.48,0.74,0.31), Color(0.27,0.47,0.19)],
		"dirt":   [Color(0.56,0.39,0.25), Color(0.35,0.25,0.16)],
		"stone":  [Color(0.51,0.51,0.54), Color(0.31,0.31,0.35)],
		"snow":   [Color(0.91,0.94,0.97), Color(0.75,0.78,0.84)],
	}
	# 预生成 tile 图
	var tile_images: Dictionary = {}
	for tname in tile_colors:
		tile_images[tname] = _make_tile_image(tile_colors[tname][0], tile_colors[tname][1], tname)
	# 生成地形
	var seed_x := 1000.0
	var seed_y := 2000.0
	var map_size := WORLD_SIZE * TILE_PX
	var map_img := Image.create(map_size, map_size, false, Image.FORMAT_RGBA8)
	var half := WORLD_SIZE / 2
	for y in range(WORLD_SIZE):
		for x in range(WORLD_SIZE):
			var h := _fbm((seed_x + x) * TILE_SCALE, (seed_y + y) * TILE_SCALE, OCTAVES)
			var tname := _choose_tile(h)
			var tile_img: Image = tile_images[tname]
			var dst_x := (x - half) * TILE_PX + map_size / 2
			var dst_y := (y - half) * TILE_PX + map_size / 2
			map_img.blit_rect(tile_img, Rect2i(0, 0, TILE_PX, TILE_PX), Vector2i(dst_x, dst_y))
	map_img.save_png(path)
	print("[Orgc] 已保存 %s (%dx%d)" % [path, map_img.get_width(), map_img.get_height()])

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

func _choose_tile(h: float) -> String:
	if h < 0.30: return "water"
	if h < 0.36: return "sand"
	if h < 0.55: return "grass"
	if h < 0.62: return "grass2"
	if h < 0.74: return "dirt"
	if h < 0.88: return "stone"
	return "snow"

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

# ============ 精灵图案（与 pixel_art.gd 完全一致） ============
func _pattern(key: String) -> Array:
	match key:
		"player": return [
			"     hhhhh      ",
			"    hhHHHhh     ",
			"    hHHHHHh     ",
			"    sssSsss     ",
			"    s s s s     ",
			"   #ccccccc#    ",
			"  #ccecccccc#   ",
			"  #ccccccccc#   ",
			"  #cCCccccCCc#  ",
			"   #ccccccc#    ",
			"    pppppp      ",
			"    pPppPp      ",
			"    pPppPp      ",
			"    PP  PP      ",
			"    SS  SS      ",
			"    ##  ##      "]
		"wood": return [
			"                ",
			"   llllllll     ",
			"  lwwwwwwwwl    ",
			" lwwwwwwwwwwl   ",
			" lwwWWWWWWWwl   ",
			" lwwwWWWWWwwl   ",
			" lwwwwWWWwwwl   ",
			" lwwwwWWWWwwl   ",
			" lwwWWWWWWwwl   ",
			" lwwwWWWWWwwl   ",
			"  lwwwwwwwwl    ",
			"   llllllll     ",
			"                ",
			"                ",
			"                ",
			"                "]
		"stone": return [
			"                ",
			"                ",
			"     gggg       ",
			"    gGggGg      ",
			"   gGggggGg     ",
			"  ggGgggGgg     ",
			"  gGgggggGg     ",
			"  gggGggggg     ",
			"  gGgggGggg     ",
			"   ggGgggg      ",
			"    ggggg       ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                "]
		"fiber": return [
			"       b        ",
			"      bbb       ",
			"     bbbbb      ",
			"      bbb       ",
			"     bbbbb      ",
			"      bbb       ",
			"     bbbbb      ",
			"      bbb       ",
			"     bbbbb      ",
			"      bbb       ",
			"     bbbbb      ",
			"      bbb       ",
			"       b        ",
			"                ",
			"                ",
			"                "]
		"iron_ore": return [
			"                ",
			"    gggGggg     ",
			"   gGiiIiiGg    ",
			"  gIiiiiiiIg    ",
			"  giiIIiiiig    ",
			"  giIiiiiIig    ",
			"  giiiiIIiig    ",
			"  gIiiiiiIig    ",
			"  giiIIiiiig    ",
			"  gGiiiiiiGg    ",
			"   gGggggGg     ",
			"    gggggg      ",
			"                ",
			"                ",
			"                ",
			"                "]
		"charcoal": return [
			"                ",
			"      kkk       ",
			"    kkKkkKk     ",
			"   kKkkkkkkk    ",
			"  kkkKkkKkkk    ",
			"  kKkkkkkkKk    ",
			"  kkkkKkkkkk    ",
			"  kKkkkkKkkk    ",
			"  kkkKkkkkKk    ",
			"   kkKkkkkk     ",
			"    kkkkk       ",
			"     kkk        ",
			"                ",
			"                ",
			"                ",
			"                "]
		"iron_ingot": return [
			"                ",
			"                ",
			"                ",
			"   IIIIIIIII    ",
			"  IiiiiiiiiI    ",
			" IiiIIIIiiiI    ",
			" IiIIiiIIIiI    ",
			" IiIIiiIIIiI    ",
			" IiiiIIIIiiI    ",
			"  IiiiiiiiI     ",
			"   IIIIIII      ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                "]
		"berry": return [
			"                ",
			"       b        ",
			"      bbb       ",
			"     b R b      ",
			"    b RR b      ",
			"    RrRrRb      ",
			"   rRrRrRr      ",
			"   RrRrRrR      ",
			"    rRrRr       ",
			"     rRr        ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                "]
		"meat": return [
			"                ",
			"     uuuu       ",
			"    uUUUUUu     ",
			"   uUUuuuUUu    ",
			"   uUuuuuuUu    ",
			"   uUUuuuUUu    ",
			"   uUUUUUUUu    ",
			"    uUUUUUu     ",
			"     uuuuu      ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                "]
		"water": return [
			"                ",
			"   qqqqqqqq     ",
			"  qQQQQQQQQq    ",
			" qQQqqqqqQQQq   ",
			" qQqqQQqqqQQq   ",
			" qqqqQQQqqqQq   ",
			" qQqqqqQQqqqq   ",
			" qQQqqqqqQQQq   ",
			" qQQQqqqqqQQq   ",
			"  qQQQQQQQQq    ",
			"   qqqqqqqq     ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                "]
		"iron_blade": return [
			"          i     ",
			"         iI     ",
			"        iIi     ",
			"       iIii     ",
			"      iIIii     ",
			"     iIIiii     ",
			"    iIIiiii     ",
			"   iIIiiiii     ",
			"  iIIiiiiii     ",
			" iIIiiiiiii     ",
			"  WWWWWWWWW     ",
			"  WlllllllW     ",
			"                ",
			"                ",
			"                ",
			"                "]
		"purify_amulet": return [
			"                ",
			"      xxx       ",
			"    xxMMMxx     ",
			"   xMmmmmmMx    ",
			"  xMmxMMMxmMx   ",
			"  MmxMx xMxmM   ",
			"  MmxMx xMxmM   ",
			"  xMmxMMMxmMx   ",
			"   xMmmmmmMx    ",
			"    xxMMMxx     ",
			"      xxx       ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                "]
		"tree": return [
			"       b        ",
			"      bbb       ",
			"     bbbbb      ",
			"    bbbbbbb     ",
			"   bb bbbbbb    ",
			"  bbb b bbbbb   ",
			"  bbb   bbbbb   ",
			"   bb   bbbb    ",
			"       w        ",
			"       wW       ",
			"       ww       ",
			"      wWw       ",
			"      www       ",
			"     wWwww      ",
			"    wwwwwww     ",
			"   wwwwwwwww    "]
		"bush": return [
			"                ",
			"                ",
			"      bbb       ",
			"    bbbbbbbb    ",
			"   bbbRbbbbbb   ",
			"  bbbRbRbbbbbb  ",
			"  bbbRbbbbRbb   ",
			"  bbbbbbbRbbb   ",
			"   bbbRbbbbb    ",
			"    bbbbbbb     ",
			"     bbbbb      ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                "]
		"rock": return [
			"                ",
			"                ",
			"      ggg       ",
			"    gggGGgg     ",
			"   gGgggggGg    ",
			"  gGgggGggGg    ",
			"  ggggGgggGg    ",
			"  gGggggGggg    ",
			"  ggggGggggg    ",
			"   gGggggGg     ",
			"    gGggGg      ",
			"                ",
			"                ",
			"                ",
			"                ",
			"                "]
		"anvil": return [
			"                ",
			"   dAAAAAAAA    ",
			"  dAAAdddddAA   ",
			" dAAAAAddddAA   ",
			"  AAAAAAAAAAA   ",
			"   AAAAAAAAA    ",
			"    AAAAAA      ",
			"    Aa  aA      ",
			"    Aa  aA      ",
			"   AAA  AAA     ",
			"  AAAAAaAAAA    ",
			"  AAAAAAAAAA    ",
			"                ",
			"                ",
			"                ",
			"                "]
		"npc_villager": return [
			"                ",
			"     hhhhh      ",
			"    hhHHHhh     ",
			"    hHHHHHh     ",
			"    sssSsss     ",
			"    s s s s     ",
			"   #bbbbbbb#    ",
			"  #bBBBBBBBb#   ",
			"  #bBBBBBBBb#   ",
			"  #bBBBbBBBb#   ",
			"   #bbbbbbb#    ",
			"    pppppp      ",
			"    pPppPp      ",
			"    pPppPp      ",
			"    PP  PP      ",
			"    SS  SS      "]
		"npc_merchant": return [
			"                ",
			"     hhhhh      ",
			"    hhHHHhh     ",
			"    hHHHHHh     ",
			"    sssSsss     ",
			"    s s s s     ",
			"   #mmmmmmm#    ",
			"  #mMMMMMMMm#   ",
			"  #mMMMMMMMm#   ",
			"  #mMMMmMMMm#   ",
			"   #mmmmmmm#    ",
			"    pppppp      ",
			"    pPppPp      ",
			"    pPppPp      ",
			"    PP  PP      ",
			"    SS  SS      "]
		"npc_hunter": return [
			"                ",
			"     HHHHH      ",
			"    HHhhhHH     ",
			"    HhhhhhH     ",
			"    sssSsss     ",
			"    s s s s     ",
			"   #ggggggg#    ",
			"  #gGGGGGGGg#   ",
			"  #gGGGGGGGg#   ",
			"  #gGGGgGGGg#   ",
			"   #ggggggg#    ",
			"    pppppp      ",
			"    pPppPp      ",
			"    pPppPp      ",
			"    PP  PP      ",
			"    SS  SS      "]
		_: return [
			"                ",
			"    ########    ",
			"   #........#   ",
			"  #..........#  ",
			"  #..?????...#  ",
			"  #..?....?..#  ",
			"  #..?....?..#  ",
			"  #..?....?..#  ",
			"  #..?????...#  ",
			"  #..........#  ",
			"   #........#   ",
			"    ########    ",
			"                ",
			"                ",
			"                ",
			"                "]
