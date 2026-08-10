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
const BuildingScript    = preload("res://scripts/buildings.gd")
const NPCScript         = preload("res://scripts/npc.gd")

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

	# 3.5 查找橘子镇中心位置（距离出生点 220~280 像素，确保在 grass/dirt 上）
	# 玩家需要走一段路才能找到小镇
	var town := _find_town_center(world, spawn)
	G.town_center = town
	print("[Orgc] 橘子镇中心：", town, " 地形=", world.tile_type_at(town))

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

	# 6. 资源节点（增加数量，让玩家有事可做）
	_spawn_resources(world, player.position)

	# 7. 锻造铁砧（放在橘子镇内东北角，玩家找到镇子就能发现铁砧）
	var anvil: Node2D = ForgeScript.new()
	anvil.name = "Anvil"
	anvil.position = G.town_center + Vector2(70, -70)
	add_child(anvil)
	G.forge = anvil

	# 8. 建筑物系统（橘子镇 + 野外避难所）
	var buildings: Node2D = BuildingScript.new()
	buildings.name = "Buildings"
	add_child(buildings)
	buildings.spawn_wild(player.position)  # 出生点附近的避难所

	# 9. NPC 系统（全部在橘子镇内）
	var npcs: Node2D = NPCScript.new()
	npcs.name = "NPCs"
	add_child(npcs)

	# 10. 任务系统
	var quest: Node = QuestScript.new()
	quest.name = "Quest"
	add_child(quest)
	G.quest = quest

	# 11. UI 层
	var ui: CanvasLayer = UIScript.new()
	ui.name = "HUD"
	add_child(ui)
	G.ui = ui

	# 12. 屏幕中心准星
	_spawn_crosshair(ui)

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
	# 增加资源数量，提升可玩性
	var cfg := [
		[ResourceNodeScript.Kind.TREE, 22],
		[ResourceNodeScript.Kind.BUSH, 14],
		[ResourceNodeScript.Kind.ROCK, 12],
		[ResourceNodeScript.Kind.IRON_ORE, 8],
		[ResourceNodeScript.Kind.WATER, 5],
	]
	for entry in cfg:
		var kind = entry[0]
		var count = entry[1]
		for i in range(count):
			var pos := _find_valid_pos(world, center)
			if pos == Vector2.ZERO: continue
			# 避免资源点正好落在橘子镇内（保留镇内空地）
			if pos.distance_to(G.town_center) < 110.0: continue
			var node: Area2D = ResourceNodeScript.new()
			node.kind = kind
			node.position = pos
			node.name = "Res_%d_%d" % [kind, i]
			add_child(node)

# 查找橘子镇中心：距离出生点 220~320 像素，地形为 grass/dirt
func _find_town_center(world: Node2D, spawn: Vector2) -> Vector2:
	var candidates := []
	# 候选方向：东南、东北、西南、西北（避免正好在出生点上方）
	for angle_deg in [45, 135, 225, 315]:
		var a := deg_to_rad(angle_deg)
		for r in range(220, 340, 20):
			candidates.append(spawn + Vector2(cos(a), sin(a)) * r)
	for pos in candidates:
		var t: String = world.tile_type_at(pos)
		if t == "grass" or t == "grass2" or t == "dirt":
			# 检查镇内 4 个角是否也大致可走
			var ok := true
			for off in [Vector2(70, -70), Vector2(70, 70), Vector2(-70, -70), Vector2(-70, 70)]:
				var tt: String = world.tile_type_at(pos + off)
				if tt == "water" or tt == "none":
					ok = false
					break
			if ok:
				return pos
	# 兜底：返回默认位置
	return Vector2(220, 160)

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

func _spawn_crosshair(parent: CanvasLayer) -> void:
	# 屏幕中心准星（十字形）
	var container := Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(container)
	# 用两个 ColorRect 组成十字
	var h_line := ColorRect.new()
	h_line.color = Color(1, 1, 1, 0.7)
	h_line.anchor_left = 0.5; h_line.anchor_right = 0.5
	h_line.anchor_top = 0.5; h_line.anchor_bottom = 0.5
	h_line.offset_left = -10; h_line.offset_right = 10
	h_line.offset_top = -1; h_line.offset_bottom = 1
	h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(h_line)
	var v_line := ColorRect.new()
	v_line.color = Color(1, 1, 1, 0.7)
	v_line.anchor_left = 0.5; v_line.anchor_right = 0.5
	v_line.anchor_top = 0.5; v_line.anchor_bottom = 0.5
	v_line.offset_left = -1; v_line.offset_right = 1
	v_line.offset_top = -10; v_line.offset_bottom = 10
	v_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(v_line)
	# 中心点
	var dot := ColorRect.new()
	dot.color = Color(1, 0.8, 0.2, 0.9)
	dot.anchor_left = 0.5; dot.anchor_right = 0.5
	dot.anchor_top = 0.5; dot.anchor_bottom = 0.5
	dot.offset_left = -2; dot.offset_right = 2
	dot.offset_top = -2; dot.offset_bottom = 2
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(dot)
