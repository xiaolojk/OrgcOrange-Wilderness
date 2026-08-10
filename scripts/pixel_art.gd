# pixel_art.gd — 像素画图集（星露谷物语风格化调色）
# CI 时预生成 PNG 到 res://assets/，运行时用 load() 加载
# （ImageTexture.create_from_image 在 Android 上不可靠，改用编辑器导入的纹理）
# Orgc橘子工作室 · 《橘子荒野》
class_name PixelArt
extends Node

const PX := 16
var _cache := {}

# 取精灵（缓存）
func get_sprite(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = load("res://assets/%s.png" % key)
	if tex == null:
		push_error("[Orgc] 无法加载精灵: res://assets/%s.png" % key)
		print("[Orgc] !!! 错误：无法加载精灵 %s !!!" % key)
		return null
	_cache[key] = tex
	print("[Orgc] 已加载精灵 %s 尺寸=%dx%d" % [key, tex.get_width(), tex.get_height()])
	return tex

# ============ 瓦片（程序化噪点 + 描边） ============
func _build_tile(name: String) -> Image:
	var img := Image.create(PX, PX, false, Image.FORMAT_RGBA8)
	# 星露谷式柔和饱和调色：基色 / 描边
	var cfg: Array = _tile_colors(name)
	var base: Color = cfg[0]
	var edge: Color = cfg[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name)
	for y in range(PX):
		for x in range(PX):
			var c: Color
			var n := rng.randi_range(-12, 12)
			var is_edge := x == 0 or y == 0 or x == PX-1 or y == PX-1
			if is_edge:
				c = edge
			else:
				c = Color(clamp(base.r*255+n,0,255)/255.0,
						  clamp(base.g*255+n,0,255)/255.0,
						  clamp(base.b*255+n,0,255)/255.0, 1.0)
			img.set_pixel(x, y, c)
	return img

func _tile_colors(name: String) -> Array:
	match name:
		"grass":  return [Color(0.42,0.67,0.25), Color(0.24,0.43,0.16)]
		"grass2": return [Color(0.48,0.74,0.31), Color(0.27,0.47,0.19)]
		"dirt":   return [Color(0.56,0.39,0.25), Color(0.35,0.25,0.16)]
		"sand":   return [Color(0.87,0.80,0.55), Color(0.71,0.63,0.39)]
		"stone":  return [Color(0.51,0.51,0.54), Color(0.31,0.31,0.35)]
		"water":  return [Color(0.27,0.51,0.82), Color(0.16,0.35,0.63)]
		"snow":   return [Color(0.91,0.94,0.97), Color(0.75,0.78,0.84)]
		"ash":    return [Color(0.38,0.34,0.38), Color(0.24,0.22,0.25)]
		_:        return [Color(0.63,0.63,0.63), Color(0.39,0.39,0.39)]

# ============ 角色/物品（ASCII 调色板手绘） ============
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
			# 像素画惯例：第0行为顶部，纹理顶部 = y 最大
			img.set_pixel(x, h-1-y, c)
	return img

# 16x16 像素图案（ASCII 调色板手绘）
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
		"player_walk": return [
			"                ",
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
			"   pPppPp       ",
			"    PP  P       ",
			"   SS   S       ",
			"   ##   ##      "]
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
