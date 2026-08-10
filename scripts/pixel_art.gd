# pixel_art.gd — 像素画图集（星露谷物语风格化调色）
# CI 时预生成 PNG 到 res://assets/，运行时用 load() 加载
# 程序化添加描边 + 高光 + 阴影 + 2x 放大，提升画质
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

# ============ 调色板 ============
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

# ============ 角色/物品（ASCII 调色板手绘 + 程序化增强） ============
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
			img.set_pixel(x, h-1-y, c)
	# 程序化增强：描边 + 高光 + 阴影 + 2x 放大
	return _enhance_pixel_art(img)

# 增强像素画：添加描边、高光、阴影，然后 2x 放大
func _enhance_pixel_art(img: Image) -> Image:
	var w := img.get_width()
	var h := img.get_height()
	# 1. 添加描边：在非透明像素的外围透明位置画深色轮廓
	var outlined := Image.create(w, h, false, Image.FORMAT_RGBA8)
	outlined.fill(Color(0,0,0,0))
	var outline_color := Color(0.06, 0.04, 0.08, 1.0)
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			if c.a > 0:
				outlined.set_pixel(x, y, c)
			else:
				var has_neighbor := false
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0: continue
						var nx := x + dx
						var ny := y + dy
						if nx >= 0 and nx < w and ny >= 0 and ny < h:
							if img.get_pixel(nx, ny).a > 0:
								has_neighbor = true
								break
					if has_neighbor: break
				if has_neighbor:
					outlined.set_pixel(x, y, outline_color)
	# 2. 高光：顶部 1/3 的非透明像素亮度提升
	var enhanced := Image.create(w, h, false, Image.FORMAT_RGBA8)
	enhanced.fill(Color(0,0,0,0))
	for y in range(h):
		for x in range(w):
			var c := outlined.get_pixel(x, y)
			if c.a > 0:
				if y < h / 3:
					# 高光区：亮度 +18%
					c.r = clamp(c.r * 1.18, 0, 1)
					c.g = clamp(c.g * 1.18, 0, 1)
					c.b = clamp(c.b * 1.18, 0, 1)
				elif y > h * 2 / 3:
					# 阴影区：亮度 -15%
					c.r = clamp(c.r * 0.85, 0, 1)
					c.g = clamp(c.g * 0.85, 0, 1)
					c.b = clamp(c.b * 0.85, 0, 1)
				enhanced.set_pixel(x, y, c)
	# 3. 2x 放大，保持像素感
	enhanced.resize(w * 2, h * 2, Image.INTERPOLATE_NEAREST)
	return enhanced

# 建筑物也走增强流程
func _build_building_figure(key: String) -> Image:
	var rows: Array = _building_pattern(key)
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
			img.set_pixel(x, h-1-y, c)
	return _enhance_pixel_art(img)

# 建筑物图案（24x24，比普通精灵大）
func _building_pattern(key: String) -> Array:
	match key:
		"house": return [
			"                        ",
			"                        ",
			"          rrrr          ",
			"         rRRRRr         ",
			"        rRRrrRRr        ",
			"       rRRrrrrRRr       ",
			"      rRRrrrrrrRRr      ",
			"     rRRrrrrrrrrRRr     ",
			"    rRRrrrrrrrrrrRRr    ",
			"   rRRrrrrrrrrrrrrRRr   ",
			"  rRRrrrrrrrrrrrrrrRRr  ",
			" rrrrrrrrrrrrrrrrrrrrr  ",
			"  WWWWWWWWWWWWWWWWWWWW  ",
			"  WlllllllllllllllllW  ",
			"  WlllllllllllllllllW  ",
			"  WlllllllllllllllllW  ",
			"  WlllllWWWWWWllllllW  ",
			"  WlllllWlllllWllllllW  ",
			"  WlllllWlllllWllllllW  ",
			"  WlllllWWWWWWWlllllW  ",
			"  WlllllllllllllllllW  ",
			"  WWWWlllllllllllWWWW  ",
			"  WWWWlllllllllllWWWW  ",
			"  WWWWlllllllllllWWWW  "]
		"tent": return [
			"                        ",
			"                        ",
			"                        ",
			"           w            ",
			"          www           ",
			"         wWwww          ",
			"        wWwwwww         ",
			"       wwwWwwwww        ",
			"      wwwWwwwwwww       ",
			"     wwwwWwwwwwwww      ",
			"    wwwwwWwwwwwwwwww    ",
			"   wwwwwwWwwwwwwwwwww   ",
			"  wwwwwwwWwwwwwwwwwwww  ",
			" wwwwwwwwWwwwwwwwwwwwww ",
			" llllllllllllllllllllll ",
			" llllllllllllllllllllll ",
			" llllllllllllllllllllll ",
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
			"           x            ",
			"          xxx           ",
			"         xMxMx          ",
			"        xMMMxMx         ",
			"         xMxMMx         ",
			"          xMx           ",
			"           x            ",
			"      WWWWWWWWWW        ",
			"     WllllllllllW       ",
			"    WllllllllllllW      ",
			"   WWWWWWWWWWWWWWWW     ",
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
			"     WWW      WWW       ",
			"    WlllW    WlllW      ",
			"   WlllllWWWWWWlllW     ",
			"   WllllllllllllllW     ",
			"    WllllllllllllW      ",
			"     WllllllllllW       ",
			"      WqqqqqqqqW        ",
			"       WQQQQQQW         ",
			"        WqqqqW          ",
			"     WWWWWWWWWWWW       ",
			"    WllllllllllllW      ",
			"   WllllllllllllllW     ",
			"  WWWWWWWWWWWWWWWWWW    ",
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
			"           w            ",
			"           w            ",
			"       wWwwWw           ",
			"        wwww            ",
			"       wWwwWw           ",
			"        wwww            ",
			"       wWwwWw           ",
			"        wwww            ",
			"       wWwwWw           ",
			"        wwww            ",
			"       wWwwWw           ",
			"       WWWWWW           ",
			"       llllll           ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        ",
			"                        "]
		_: return [
			"                        ",
			"                        ",
			"      ##########        ",
			"     #..........#       ",
			"    #............#      ",
			"    #..?????????.#      ",
			"    #..?........?#      ",
			"    #..?........?#      ",
			"    #..?........?#      ",
			"    #..?........?#      ",
			"    #..?????????.#      ",
			"    #............#      ",
			"     #..........#       ",
			"      ##########        ",
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
		# NPC 图案（服装颜色区分）
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
		"npc_villager2": return [
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
			"   pPppPp       ",
			"    PP  P       ",
			"   SS   S       ",
			"   ##   ##      ",
			"                "]
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
		"npc_merchant2": return [
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
			"   pPppPp       ",
			"    PP  P       ",
			"   SS   S       ",
			"   ##   ##      ",
			"                "]
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
		"npc_hunter2": return [
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
			"   pPppPp       ",
			"    PP  P       ",
			"   SS   S       ",
			"   ##   ##      ",
			"                "]
		"npc_elder": return [
			"                ",
			"     WWWWW      ",
			"    WWhhhWW     ",
			"    WhHHHWw     ",
			"    sssSsss     ",
			"    s s s s     ",
			"   #MMMMMMM#    ",
			"  #MmmmmmmmM#   ",
			"  #MmmmmmmmM#   ",
			"  #MmmMmMmmM#   ",
			"   #MMMMMMM#    ",
			"    pppppp      ",
			"    PP  PP      ",
			"    PP  PP      ",
			"    SS  SS      ",
			"    ##  ##      "]
		"npc_elder2": return [
			"     WWWWW      ",
			"    WWhhhWW     ",
			"    WhHHHWw     ",
			"    sssSsss     ",
			"    s s s s     ",
			"   #MMMMMMM#    ",
			"  #MmmmmmmmM#   ",
			"  #MmmmmmmmM#   ",
			"  #MmmMmMmmM#   ",
			"   #MMMMMMM#    ",
			"    pppppp      ",
			"   PP  PP       ",
			"   SS  SS       ",
			"   ##  ##       ",
			"                ",
			"                "]
		"npc_child": return [
			"                ",
			"                ",
			"     hhhhh      ",
			"    hhHHHhh     ",
			"    sssSsss     ",
			"    s s s s     ",
			"   #rrrrrrr#    ",
			"  #rRRRRRRRr#   ",
			"  #rRRRrRRRr#   ",
			"   #rrrrrrr#    ",
			"    pppppp      ",
			"    pPppPp      ",
			"    PP  PP      ",
			"                ",
			"                ",
			"                "]
		"npc_child2": return [
			"                ",
			"     hhhhh      ",
			"    hhHHHhh     ",
			"    sssSsss     ",
			"    s s s s     ",
			"   #rrrrrrr#    ",
			"  #rRRRRRRRr#   ",
			"  #rRRRrRRRr#   ",
			"   #rrrrrrr#    ",
			"    pppppp      ",
			"   pPppPp       ",
			"   PP  P        ",
			"   S    S       ",
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
