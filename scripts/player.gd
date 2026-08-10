# player.gd — 玩家：触屏摇杆 + 键盘移动 + 交互
# Orgc橘子工作室 · 《橘子荒野》
extends CharacterBody2D

const MOVE_SPEED := 180.0
const INTERACT_RADIUS := 56.0

var move_input := Vector2.ZERO  # 由 TouchControls 写入；键盘叠加
var sprite: Sprite2D
var nearby: Node2D = null  # IInteractable 节点

# 背包：id -> 数量
var inventory := {}

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = G.pix.get_sprite("player")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	# 碰撞
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	col.shape = rect
	add_child(col)

func _process(_dt: float) -> void:
	# 键盘输入（PC 测试），与触屏叠加
	var kx := Input.get_axis("move_left", "move_right")
	var ky := Input.get_axis("move_up", "move_down")
	if abs(kx) > 0.01 or abs(ky) > 0.01:
		move_input = Vector2(kx, ky).normalized()
	_update_nearby()
	if Input.is_action_just_pressed("interact"):
		interact()

func _physics_process(dt: float) -> void:
	velocity = move_input * MOVE_SPEED
	move_and_slide()
	if abs(move_input.x) > 0.01:
		sprite.flip_h = move_input.x < 0.0
	var moving := velocity.length_squared() > 25.0
	if G.world != null and G.survival != null:
		G.survival.tick(G.world, dt, moving)

func interact() -> void:
	if nearby != null and nearby.has_method("can_interact") and nearby.can_interact(self):
		nearby.interact(self)
	else:
		G.toast("附近没有可交互的对象")

func _update_nearby() -> void:
	nearby = null
	var space := get_world_2d().direct_space_state
	# 用 Area2D 检测：遍历交互节点
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("interactable"):
		if not node.has_method("can_interact"):
			continue
		if not node.can_interact(self):
			continue
		var d := global_position.distance_squared_to(node.global_position)
		if d < INTERACT_RADIUS * INTERACT_RADIUS and d < best_dist:
			best_dist = d
			nearby = node

# —— 背包接口 ——
func count_item(id: String) -> int:
	return inventory.get(id, 0)

func add_item(id: String, n: int) -> void:
	inventory[id] = count_item(id) + n
	G.emit_signal("item_obtained", id, n)

func remove_item(id: String, n: int) -> bool:
	if count_item(id) < n:
		return false
	inventory[id] -= n
	if inventory[id] <= 0:
		inventory.erase(id)
	G.emit_signal("item_consumed", id, n)
	return true

func has_item(id: String, n: int = 1) -> bool:
	return count_item(id) >= n
