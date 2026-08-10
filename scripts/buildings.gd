# buildings.gd — 建筑物系统：围绕橘子镇中心建围墙、房屋、帐篷
# 玩家出生在野外，需要寻找才能发现小镇。Orgc橘子工作室
class_name BuildingSystem
extends Node2D

var _buildings: Array = []  # 所有建筑节点

func _ready() -> void:
	_spawn_buildings()

func _spawn_buildings() -> void:
	var c: Vector2 = G.town_center
	# 围墙（栅栏）— 围绕小镇形成方形围栏，留一个南向入口
	var fence_scale := Vector2(1.5, 1.5)
	# 北墙
	for i in range(-3, 4):
		_add_building("fence", c + Vector2(i * 30, -90), fence_scale)
	# 东墙
	for i in range(-2, 3):
		_add_building("fence", c + Vector2(90, i * 30), fence_scale)
	# 西墙
	for i in range(-2, 3):
		_add_building("fence", c + Vector2(-90, i * 30), fence_scale)
	# 南墙（留中间 2 格作为入口）
	for i in range(-3, -1):
		_add_building("fence", c + Vector2(i * 30, 90), fence_scale)
	for i in range(2, 4):
		_add_building("fence", c + Vector2(i * 30, 90), fence_scale)

	# 房屋（镇内北侧）
	_add_building("house", c + Vector2(-45, -55), Vector2(1.4, 1.4))
	_add_building("house", c + Vector2(45, -55), Vector2(1.4, 1.4))
	# 帐篷（镇内南侧）
	_add_building("tent", c + Vector2(-45, 55), Vector2(1.4, 1.4))
	_add_building("tent", c + Vector2(45, 55), Vector2(1.4, 1.4))
	# 中心广场：篝火 + 水井
	_add_building("campfire", c + Vector2(-20, 0), Vector2(1.3, 1.3))
	_add_building("well", c + Vector2(20, 0), Vector2(1.3, 1.3))

	# 野外零星建筑（玩家出生点附近，给前期提示）
	# 在 main.gd 设置 G.player 后调用 _spawn野外
	print("[Orgc] 橘子镇已建成，建筑数=%d 镇中心=%s" % [_buildings.size(), c])

# 玩家出生点附近的野外建筑（避难所用）
func spawn_wild(spawn: Vector2) -> void:
	_add_building("campfire", spawn + Vector2(40, -30), Vector2(1.2, 1.2))
	_add_building("tent", spawn + Vector2(-50, 40), Vector2(1.2, 1.2))
	print("[Orgc] 野外避难所已放置，出生点=%s" % spawn)

func _add_building(btype: String, pos: Vector2, sc: Vector2) -> void:
	var building := Sprite2D.new()
	building.texture = G.pix.get_sprite(btype)
	building.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	building.position = pos
	building.centered = true
	# 增强后 48x48，缩小到星露谷比例（约 1.5-2 瓦片）
	building.scale = sc * 0.4
	building.z_index = 5
	add_child(building)
	_buildings.append(building)
