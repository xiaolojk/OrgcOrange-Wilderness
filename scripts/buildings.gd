# buildings.gd — 建筑物系统：程序化放置房屋、帐篷、篝火等
# Orgc橘子工作室 · 《橘子荒野》
class_name BuildingSystem
extends Node2D

var _buildings: Array = []  # 所有建筑节点

func _ready() -> void:
	# 程序化放置建筑（在玩家出生点附近）
	_spawn_buildings()

func _spawn_buildings() -> void:
	# 建筑配置：[类型, 相对偏移]
	var configs := [
		["house", Vector2(120, -60)],
		["house", Vector2(-100, 80)],
		["tent", Vector2(60, 100)],
		["tent", Vector2(-80, -100)],
		["campfire", Vector2(30, 40)],
		["campfire", Vector2(-50, -60)],
		["well", Vector2(150, 30)],
		["fence", Vector2(100, -60)],
		["fence", Vector2(-100, 80)],
	]
	for cfg in configs:
		var btype: String = cfg[0]
		var offset: Vector2 = cfg[1]
		var building := Sprite2D.new()
		building.texture = G.pix.get_sprite(btype)
		building.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		building.position = offset
		building.centered = true
		# 建筑物放大 1.5 倍
		building.scale = Vector2(1.5, 1.5)
		building.z_index = 5
		add_child(building)
		_buildings.append(building)
	print("[Orgc] 已放置 %d 个建筑" % _buildings.size())
