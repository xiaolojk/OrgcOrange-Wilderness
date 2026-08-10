# resource_node.gd — 资源节点：树/灌木/岩石/铁矿/水源，可交互采集
# Orgc橘子工作室 · 《橘子荒野》
extends Area2D
class_name ResourceNode

enum Kind { TREE, BUSH, ROCK, IRON_ORE, WATER }

@export var kind: Kind = Kind.TREE
@export var yield_amount := 3
@export var max_harvests := 3
@export var regen_seconds := 60.0

var _remaining := 0
var _regen_timer := 0.0
var _sprite: Sprite2D

func _ready() -> void:
	_remaining = max_harvests
	_sprite = Sprite2D.new()
	_sprite.texture = G.pix.get_sprite(_sprite_key())
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = true
	# 放大 3 倍，让物品更醒目（主角看时不会像毛毛雨）
	_sprite.scale = Vector2(3, 3)
	add_child(_sprite)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 48)
	col.shape = rect
	add_child(col)
	add_to_group("interactable")

func _sprite_key() -> String:
	match kind:
		Kind.TREE: return "tree"
		Kind.BUSH: return "bush"
		Kind.ROCK: return "rock"
		Kind.IRON_ORE: return "iron_ore"
		Kind.WATER: return "water"
	return "stone"

func _yield_item() -> String:
	match kind:
		Kind.TREE: return "wood"
		Kind.BUSH: return "berry"
		Kind.ROCK: return "stone"
		Kind.IRON_ORE: return "iron_ore"
		Kind.WATER: return "water"
	return "wood"

func prompt() -> String:
	match kind:
		Kind.TREE: return "砍伐"
		Kind.BUSH: return "采集浆果"
		Kind.ROCK: return "开采石头"
		Kind.IRON_ORE: return "挖掘铁矿"
		Kind.WATER: return "喝水"
	return "采集"

func can_interact(_player) -> bool:
	if kind == Kind.WATER: return true
	return _remaining > 0

func interact(player) -> void:
	if kind == Kind.WATER:
		G.survival.eat(0.0, 35.0, 5.0)
		G.toast("你喝了清水，水分 +35")
		return
	if _remaining <= 0:
		G.toast("资源已耗尽，等待恢复…")
		return
	_remaining -= 1
	player.add_item(_yield_item(), yield_amount)
	G.toast("获得 %s ×%d" % [Items.display_name(_yield_item()), yield_amount])
	if _remaining <= 0:
		_sprite.visible = false
		_regen_timer = regen_seconds

func _process(dt: float) -> void:
	if _remaining <= 0 and kind != Kind.WATER:
		_regen_timer -= dt
		if _regen_timer <= 0.0:
			_remaining = max_harvests
			if _sprite != null:
				_sprite.visible = true
