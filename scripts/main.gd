# main.gd — 游戏装配点：运行时程序化构建全部系统
# Orgc橘子工作室 · 《橘子荒野》
extends Node2D

var _camera: Camera2D

func _ready() -> void:
	Engine.max_fps = 60
	# 像素艺术设置
	get_viewport().position_smoothing_enabled = false

	# 1. 像素图集（全局）
	G.pix = preload("res://scripts/pixel_art.gd").new()
	G.pix.name = "PixelArt"
	add_child(G.pix)

	# 2. 世界
	var world := preload("res://scripts/world.gd").new()
	world.name = "World"
	add_child(world)
	G.world = world

	# 3. 玩家
	var PlayerScript := preload("res://scripts/player.gd")
	var player := PlayerScript.new()
	player.name = "Player"
	player.position = Vector2.ZERO
	add_child(player)
	G.player = player

	# 4. 相机
	_camera = Camera2D.new()
	_camera.zoom = Vector2(3, 3)  # 放大像素
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 6.0
	player.add_child(_camera)

	# 5. 生存系统
	var SurvivalScript := preload("res://scripts/survival.gd")
	var survival := SurvivalScript.new()
	survival.name = "Survival"
	add_child(survival)
	G.survival = survival

	# 6. 资源节点
	_spawn_resources(world, player.position)

	# 7. 锻造铁砧
	var ForgeScript := preload("res://scripts/forge.gd")
	var anvil := ForgeScript.new()
	anvil.name = "Anvil"
	anvil.position = Vector2(80, -32)
	add_child(anvil)
	G.forge = anvil

	# 8. 任务系统
	var QuestScript := preload("res://scripts/quest.gd")
	var quest := QuestScript.new()
	quest.name = "Quest"
	add_child(quest)
	G.quest = quest

	# 9. UI 层
	var UIScript := preload("res://scripts/ui.gd")
	var ui := UIScript.new()
	ui.name = "HUD"
	add_child(ui)
	G.ui = ui

	# 触屏控制
	var TouchScript := preload("res://scripts/touch_controls.gd")
	var touch := TouchScript.new()
	touch.name = "TouchControls"
	add_child(touch)
	touch.init(player)

	# 锻造面板
	var PanelScript := preload("res://scripts/forge_panel.gd")
	var panel := PanelScript.new()
	panel.name = "ForgePanel"
	add_child(panel)
	# 铁砧打开时打开面板
	anvil.connect("opened", panel.open_forge)

	# 物品变化时刷新面板
	G.connect("item_obtained", func(_id,_n): if panel.visible: panel._refresh())
	G.connect("item_consumed", func(_id,_n): if panel.visible: panel._refresh())
	G.connect("forge_complete", func(_id): if panel.visible: panel._refresh())

	# 死亡处理
	survival.connect("player_died", _on_player_died)

	print("[Orgc] 橘子荒野 启动完成 — Orgc橘子工作室")

func _spawn_resources(world, center: Vector2) -> void:
	var ResourceScript := preload("res://scripts/resource_node.gd")
	var cfg := [
		[ResourceScript.Kind.TREE, 14],
		[ResourceScript.Kind.BUSH, 8],
		[ResourceScript.Kind.ROCK, 7],
		[ResourceScript.Kind.IRON_ORE, 5],
		[ResourceScript.Kind.WATER, 3],
	]
	for entry in cfg:
		var kind = entry[0]
		var count = entry[1]
		for i in range(count):
			var pos := _find_valid_pos(world, center)
			if pos == Vector2.ZERO: continue
			var node := ResourceScript.new()
			node.kind = kind
			node.position = pos
			node.name = "Res_%d_%d" % [kind, i]
			add_child(node)

func _find_valid_pos(world, center: Vector2) -> Vector2:
	for _i in range(30):
		var r := randf_range(40.0, 240.0)
		var a := randf() * TAU
		var p := center + Vector2(cos(a), sin(a)) * r
		var cell := world.world_to_cell(p)
		var t := world.tile_type_at(cell)
		if t == "grass" or t == "dirt" or t == "sand":
			if p.distance_to(center) > 25.0:
				return p
		if t == "water" and randf() < 0.5:
			return p
	return Vector2.ZERO

func _on_player_died() -> void:
	G.toast("你倒下了…游戏结束")
	# 简单处理：3 秒后重启
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
