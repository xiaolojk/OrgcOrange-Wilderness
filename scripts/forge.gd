# forge.gd — 锻造铁砧：把材料放铁砧 → 点击锻造
# 核心玩法。Orgc橘子工作室 · 《橘子荒野》
extends Area2D
class_name ForgeAnvil

# 铁砧上的材料：id -> 数量
var anvil := {}

# 配方：[[(input_id, count), ...], output_id, output_count]
const RECIPES := [
	[[["iron_ore", 2], ["charcoal", 1]], "iron_ingot", 1],
	[[["iron_ingot", 1], ["wood", 1]], "iron_blade", 1],
	[[["wood", 2]], "charcoal", 1],
	[[["iron_ingot", 2], ["iron_blade", 1], ["fiber", 3]], "purify_amulet", 1],
]

signal opened(anvil_ref)
signal forge_start
signal forge_complete(output_id)

func _ready() -> void:
	var sprite := Sprite2D.new()
	sprite.texture = G.pix.get_sprite("anvil")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	sprite.scale = Vector2(1.5, 1.5)  # HQ 图 64x64
	add_child(sprite)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 40)
	col.shape = rect
	add_child(col)
	add_to_group("interactable")

func prompt() -> String:
	return "锻造"

func can_interact(_player) -> bool:
	return true

func interact(_player) -> void:
	emit_signal("opened", self)

# —— IForge 接口 ——
func place_on_anvil(id: String, n: int) -> bool:
	var player := G.player
	if player == null: return false
	if player.count_item(id) < n: return false
	player.remove_item(id, n)
	anvil[id] = anvil_count(id) + n
	return true

func anvil_count(id: String) -> int:
	return anvil.get(id, 0)

func try_forge() -> String:
	var recipe: Variant = _match_recipe()
	if recipe == null:
		G.toast("铁砧上的材料不匹配任何锻造配方")
		return ""
	emit_signal("forge_start")
	# 消耗材料
	for input in recipe[0]:
		_remove_from_anvil(input[0], input[1])
	# 产出
	var out_id: String = recipe[1]
	var out_n: int = recipe[2]
	if G.player != null:
		G.player.add_item(out_id, out_n)
	G.emit_signal("forge_complete", out_id)
	G.toast("锻造成功：%s ×%d" % [Items.display_name(out_id), out_n])
	return out_id

func clear_anvil() -> void:
	var player := G.player
	for id in anvil.keys():
		if anvil[id] > 0:
			player.add_item(id, anvil[id])
	anvil.clear()

func _remove_from_anvil(id: String, n: int) -> void:
	if not anvil.has(id): return
	anvil[id] -= n
	if anvil[id] <= 0:
		anvil.erase(id)

func _match_recipe():
	for recipe in RECIPES:
		if _has_inputs(recipe[0]):
			return recipe
	return null

func _has_inputs(inputs) -> bool:
	for input in inputs:
		if anvil_count(input[0]) < input[1]:
			return false
	return true
