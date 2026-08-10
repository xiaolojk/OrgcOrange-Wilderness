# npc.gd — NPC 系统：全部集中在橘子镇，玩家需寻找
# 走近自动弹对话框 + 双帧动作动画。Orgc橘子工作室 · 《橘子荒野》
class_name NPCSystem
extends Node2D

const TALK_RADIUS := 70.0  # 进入此半径自动弹对话框
const FRAME_TIME := 0.5    # 动作帧切换间隔

var _npcs: Array = []  # 所有 NPC 节点
var _current_talker: Node2D = null  # 当前正在显示对话的 NPC
var _dialog_label: Label = null
var _dialog_bg: Panel = null
var _dialog_layer: CanvasLayer = null
var _frame_timer := 0.0

func _ready() -> void:
	_spawn_npcs()
	_build_dialog_box()
	set_process(true)

func _spawn_npcs() -> void:
	# 小镇中心由 main.gd 通过 G.town_center 设置（默认东南方）
	var center: Vector2 = G.town_center
	# NPC 配置：[类型, 相对小镇中心的偏移, 名字, 对话]
	# 全部聚集在小镇内，玩家需要走到镇上才能找到
	var configs := [
		["npc_villager", Vector2(-30, -20), "村民老张", "欢迎来到橘子镇！小心夜晚的灰雾，记得生火取暖。"],
		["npc_villager", Vector2(40, 30), "村民阿珍", "镇子东北角的铁砧，可以去锻造工具。"],
		["npc_merchant", Vector2(-50, 10), "商人王富贵", "收集更多材料，我可以教你新配方。木头+木头=木炭！"],
		["npc_merchant", Vector2(60, -10), "商人徒弟小六", "师傅说：铁矿石+木炭=铁锭，再铁锭+木头=铁刃。"],
		["npc_hunter", Vector2(-40, 40), "猎人李大胆", "森林在西边，浆果和树木很多，注意补充体力。"],
		["npc_hunter", Vector2(50, -40), "猎人张大弓", "水边可以喝水，但夜晚降温快，别在外面过夜。"],
		["npc_elder", Vector2(0, -40), "橘子镇长老", "灰雾笼罩小岛已多年…需要净雾护符才能深入裂隙。铁锭+铁刃+纤维=护符！"],
		["npc_child", Vector2(20, 50), "小橘", "大哥哥！你见过会发光的铁刃吗？听说能劈开灰雾！"],
	]
	for cfg in configs:
		var npc_type: String = cfg[0]
		var pos: Vector2 = center + cfg[1]
		var name: String = cfg[2]
		var dialog: String = cfg[3]
		var npc := _create_npc(npc_type, pos, name, dialog)
		add_child(npc)
		_npcs.append(npc)
	add_to_group("interactable")
	print("[Orgc] 已在橘子镇放置 %d 个 NPC，镇中心=%s" % [_npcs.size(), center])

func _create_npc(npc_type: String, pos: Vector2, npc_name: String, dialog: String) -> Node2D:
	var npc := Node2D.new()
	npc.position = pos
	npc.z_index = 6
	# 主帧精灵
	var sprite := Sprite2D.new()
	sprite.texture = G.pix.get_sprite(npc_type)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	sprite.scale = Vector2(1, 1)  # 32x32 增强图，1x 显示
	npc.add_child(sprite)
	# 第二帧（动作）— key 加 "2"
	var sprite2 := Sprite2D.new()
	sprite2.texture = G.pix.get_sprite(npc_type + "2")
	sprite2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite2.centered = true
	sprite2.scale = Vector2(1, 1)
	sprite2.visible = false
	npc.add_child(sprite2)
	# 名字标签（悬浮头顶）
	var name_lbl := Label.new()
	name_lbl.text = npc_name
	name_lbl.add_theme_font_size_override("font", 14)
	name_lbl.add_theme_color_override("font_color", Color(1, 1, 0.85, 0.95))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	name_lbl.position = Vector2(-40, -70)
	name_lbl.add_theme_font_size_override("font", 14)
	npc.add_child(name_lbl)
	# 存储数据
	npc.set_meta("dialog", dialog)
	npc.set_meta("npc_name", npc_name)
	npc.set_meta("is_npc", true)
	npc.set_meta("npc_type", npc_type)
	npc.set_meta("sprite", sprite)
	npc.set_meta("sprite2", sprite2)
	npc.add_to_group("interactable")
	# 上下浮动动画（轻微，加强生动感）
	var tween := npc.create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -2.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite2, "position:y", -2.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite2, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	return npc

func _build_dialog_box() -> void:
	# 用 CanvasLayer 包装，确保对话框按屏幕坐标定位
	_dialog_layer = CanvasLayer.new()
	_dialog_layer.layer = 15  # 在 HUD 之上
	add_child(_dialog_layer)
	# 屏幕底部对话框（自动显示/隐藏）
	_dialog_bg = Panel.new()
	_dialog_bg.anchor_left = 0.1; _dialog_bg.anchor_right = 0.9
	_dialog_bg.anchor_top = 0.78; _dialog_bg.anchor_bottom = 0.92
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	style.border_width_left = 4; style.border_width_right = 4
	style.border_width_top = 4; style.border_width_bottom = 4
	style.border_color = Color(0.95, 0.55, 0.18, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_dialog_bg.add_theme_stylebox_override("panel", style)
	_dialog_bg.visible = false
	_dialog_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不挡触摸
	_dialog_layer.add_child(_dialog_bg)
	_dialog_label = Label.new()
	_dialog_label.anchor_left = 0.02; _dialog_label.anchor_right = 0.98
	_dialog_label.anchor_top = 0.15; _dialog_label.anchor_bottom = 0.85
	_dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialog_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_label.add_theme_font_size_override("font", 18)
	_dialog_label.add_theme_color_override("font_color", Color(1, 1, 0.9, 1))
	_dialog_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不挡触摸
	_dialog_bg.add_child(_dialog_label)

func _process(dt: float) -> void:
	# 全局动作帧切换（所有 NPC 同步，简化逻辑）
	_frame_timer += dt
	if _frame_timer >= FRAME_TIME:
		_frame_timer = 0.0
		for npc in _npcs:
			var s1: Sprite2D = npc.get_meta("sprite")
			var s2: Sprite2D = npc.get_meta("sprite2")
			s1.visible = not s1.visible
			s2.visible = not s2.visible
	# 自动检测玩家靠近 NPC
	_check_player_near()

func _check_player_near() -> void:
	if G.player == null:
		return
	var nearest: Node2D = null
	var best_dist := TALK_RADIUS
	for npc in _npcs:
		var d: float = G.player.global_position.distance_to(npc.global_position)
		if d < best_dist:
			best_dist = d
			nearest = npc
	if nearest != _current_talker:
		# 切换对话目标
		_current_talker = nearest
		if nearest != null:
			var name: String = nearest.get_meta("npc_name", "???")
			var dialog: String = nearest.get_meta("dialog", "...")
			_dialog_label.text = "%s：%s" % [name, dialog]
			_dialog_bg.visible = true
		else:
			_dialog_bg.visible = false

# 可交互接口（保留：手动按行动键也能触发对话）
func can_interact(_player: Node2D) -> bool:
	return _current_talker != null

func interact(_player: Node2D) -> void:
	if _current_talker != null:
		var name: String = _current_talker.get_meta("npc_name", "???")
		var dialog: String = _current_talker.get_meta("dialog", "...")
		# 重新弹一次（防止刚进入还没显示）
		_dialog_label.text = "%s：%s" % [name, dialog]
		_dialog_bg.visible = true
