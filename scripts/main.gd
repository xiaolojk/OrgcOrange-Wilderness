# main.gd — 游戏装配点：运行时程序化构建全部系统
# Orgc橘子工作室 · 《橘子荒野》
extends Node2D

const WorldScript       = preload("res://scripts/world.gd")
const PlayerScript      = preload("res://scripts/player.gd")
const SurvivalScript    = preload("res://scripts/survival.gd")
const ForgeScript       = preload("res://scripts/forge.gd")
const QuestScript       = preload("res://scripts/quest.gd")
const UIScript          = preload("res://scripts/ui.gd")
const TouchScript       = preload("res://scripts/touch_controls.gd")
const ForgePanelScript  = preload("res://scripts/forge_panel.gd")
const ResourceNodeScript= preload("res://scripts/resource_node.gd")

var _camera: Camera2D

func _ready() -> void:
	Engine.max_fps = 60

	# 0. 背景兜底层（即使地图没渲染也不会黑屏）
	var bg_layer := CanvasLayer.new()
	bg_layer.name = "Background"
	bg_layer.layer = -100
	add_child(bg_layer)
	var bg_rect := ColorRect.new()
	bg_rect.color = Color(0.16, 0.2, 0.26, 1)  # 深蓝绿，与默认 clear color 一致
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_layer.add_child(bg_rect)

	# 1. 像素图集（已在 Autoload G._ready 中初始化，此处不再重复）

	# 2. 世界
	var world: Node2D = WorldScript.new()
	world.name = "World"
	add_child(world)
	G.world = world

	# 3. 玩家（放在地图中心附近的草地）
	var player: CharacterBody2D = PlayerScript.new()
	player.name = "Player"
	# 找一个 grass/dirt 位置，避免玩家出生在水里
	var spawn := Vector2.ZERO
	for r in range(0, 200, 8):
		for a in range(0, 360, 30):
			var p := Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * r
			var t: String = world.tile_type_at(p)
			if t == "grass" or t == "grass2" or t == "dirt":
				spawn = p
				break
		if spawn != Vector2.ZERO:
			break
	player.position = spawn
	add_child(player)
	G.player = player
	print("[Orgc] 玩家出生点：", spawn, " 地形=", world.tile_type_at(spawn))

	# 4. 相机（直接作为 main 子节点，手动跟随玩家，最可靠）
	_camera = Camera2D.new()
	_camera.zoom = Vector2(2, 2)  # 降低放大倍数，避免视野过小
	_camera.position_smoothing_enabled = false  # 关闭平滑，手动跟随
	_camera.enabled = true
	_camera.position = spawn  # 初始位置对齐玩家
	add_child(_camera)
	# 用 call_deferred 确保在 scene tree 完全构建后设为 current
	call_deferred("_activate_camera")

	# 诊断日志（帮助定位显示问题）
	print("[Orgc] 世界节点: ", world, " 可见=", world.visible, " 子节点数=", world.get_child_count())
	print("[Orgc] 玩家节点: ", player, " 位置=", player.position, " 子节点数=", player.get_child_count())
	print("[Orgc] 相机: ", _camera, " enabled=", _camera.enabled, " position=", _camera.position)

	# 5. 生存系统
	var survival: Node = SurvivalScript.new()
	survival.name = "Survival"
	add_child(survival)
	G.survival = survival

	# 6. 资源节点
	_spawn_resources(world, player.position)

	# 7. 锻造铁砧
	var anvil: Node2D = ForgeScript.new()
	anvil.name = "Anvil"
	anvil.position = Vector2(80, -32)
	add_child(anvil)
	G.forge = anvil

	# 8. 任务系统
	var quest: Node = QuestScript.new()
	quest.name = "Quest"
	add_child(quest)
	G.quest = quest

	# 9. UI 层
	var ui: CanvasLayer = UIScript.new()
	ui.name = "HUD"
	add_child(ui)
	G.ui = ui

	# 触屏控制
	var touch: CanvasLayer = TouchScript.new()
	touch.name = "TouchControls"
	add_child(touch)
	touch.init(player)

	# 锻造面板
	var panel: CanvasLayer = ForgePanelScript.new()
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

func _spawn_resources(world: Node2D, center: Vector2) -> void:
	var cfg := [
		[ResourceNodeScript.Kind.TREE, 14],
		[ResourceNodeScript.Kind.BUSH, 8],
		[ResourceNodeScript.Kind.ROCK, 7],
		[ResourceNodeScript.Kind.IRON_ORE, 5],
		[ResourceNodeScript.Kind.WATER, 3],
	]
	for entry in cfg:
		var kind = entry[0]
		var count = entry[1]
		for i in range(count):
			var pos := _find_valid_pos(world, center)
			if pos == Vector2.ZERO: continue
			var node: Area2D = ResourceNodeScript.new()
			node.kind = kind
			node.position = pos
			node.name = "Res_%d_%d" % [kind, i]
			add_child(node)

func _find_valid_pos(world: Node2D, center: Vector2) -> Vector2:
	for _i in range(30):
		var r := randf_range(40.0, 240.0)
		var a := randf() * TAU
		var p := center + Vector2(cos(a), sin(a)) * r
		var t: String = world.tile_type_at(p)
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

func _activate_camera() -> void:
	# 在 scene tree 完全构建后激活相机
	if _camera != null:
		_camera.make_current()
		print("[Orgc] 相机已激活 is_current=", _camera.is_current())

func _process(_dt: float) -> void:
	# 手动让相机跟随玩家（不依赖 position_smoothing）
	if _camera != null and G.player != null:
		_camera.position = G.player.position
