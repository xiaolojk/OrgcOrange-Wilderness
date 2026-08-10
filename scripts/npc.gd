# npc.gd — NPC 系统：村民、商人、猎人，可交互对话
# Orgc橘子工作室 · 《橘子荒野》
class_name NPCSystem
extends Node2D

var _npcs: Array = []

func _ready() -> void:
	_spawn_npcs()

func _spawn_npcs() -> void:
	# NPC 配置：[类型, 位置, 对话]
	var configs := [
		["npc_villager", Vector2(110, -50), "村民：欢迎来到橘子荒野！小心夜晚的寒冷。"],
		["npc_villager", Vector2(-95, 85), "村民：铁砧在东边，可以去锻造工具。"],
		["npc_merchant", Vector2(145, 35), "商人：收集更多材料，我可以教你新配方。"],
		["npc_hunter", Vector2(-75, -95), "猎人：森林里有浆果和树木，注意补充体力。"],
		["npc_hunter", Vector2(65, 105), "猎人：水边可以喝水，但要小心温度。"],
	]
	for cfg in configs:
		var npc_type: String = cfg[0]
		var pos: Vector2 = cfg[1]
		var dialog: String = cfg[2]
		var npc := _create_npc(npc_type, pos, dialog)
		add_child(npc)
		_npcs.append(npc)
	# 加入 interactable 组
	add_to_group("interactable")
	print("[Orgc] 已放置 %d 个 NPC" % _npcs.size())

func _create_npc(npc_type: String, pos: Vector2, dialog: String) -> Node2D:
	var npc := Node2D.new()
	npc.position = pos
	npc.z_index = 6
	# 精灵
	var sprite := Sprite2D.new()
	sprite.texture = G.pix.get_sprite(npc_type)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	npc.add_child(sprite)
	# 存储对话数据
	npc.set_meta("dialog", dialog)
	npc.set_meta("is_npc", true)
	npc.set_meta("npc_type", npc_type)
	# 加入交互组
	npc.add_to_group("interactable")
	# 上下浮动动画
	var tween := npc.create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -2.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	return npc

# 可交互接口
func can_interact(_player: Node2D) -> bool:
	return true

func interact(_player: Node2D) -> void:
	# 查找最近的 NPC
	var nearest: Node2D = null
	var best_dist := 80.0
	for npc in _npcs:
		var d: float = _player.global_position.distance_to(npc.global_position)
		if d < best_dist:
			best_dist = d
			nearest = npc
	if nearest != null:
		var dialog: String = nearest.get_meta("dialog", "...")
		G.toast(dialog)
	else:
		G.toast("附近没有 NPC")
