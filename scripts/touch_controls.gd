# touch_controls.gd — 触屏控制：左半屏动态摇杆 + 右下行动按钮
# 直接读取 Input 缩放/触摸事件，低延迟灵敏。Orgc橘子工作室
extends CanvasLayer

var _player: CharacterBody2D
var _joy_base: Panel
var _joy_knob: Panel
var _joy_radius := 120.0
var _joy_active := false
var _joy_origin := Vector2.ZERO
var _joy_touch_idx := -1

func _ready() -> void:
	layer = 20
	_build()
	set_process_unhandled_input(true)

func init(player: CharacterBody2D) -> void:
	_player = player

func _build() -> void:
	# 摇杆底座（隐藏）
	_joy_base = Panel.new()
	_joy_base.custom_minimum_size = Vector2(_joy_radius*2, _joy_radius*2)
	_joy_base.modulate.a = 0.3
	_joy_base.visible = false
	add_child(_joy_base)
	_joy_knob = Panel.new()
	_joy_knob.custom_minimum_size = Vector2(_joy_radius, _joy_radius)
	_joy_knob.modulate.a = 0.6
	_joy_knob.visible = false
	add_child(_joy_knob)

	# 行动按钮（右下，橘色）
	var btn := Button.new()
	btn.text = "行动"
	btn.add_theme_font_size_override("font", 32)
	btn.custom_minimum_size = Vector2(180, 180)
	btn.anchor_left = 1; btn.anchor_right = 1
	btn.anchor_top = 1; btn.anchor_bottom = 1
	btn.offset_left = -220; btn.offset_right = -30
	btn.offset_top = -210; btn.offset_bottom = -30
	btn.modulate.a = 0.7
	add_child(btn)
	btn.pressed.connect(_on_action)

func _on_action() -> void:
	if _player != null:
		_player.interact()

func _unhandled_input(event: InputEvent) -> void:
	if _player == null: return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	elif event is InputEventMouseButton:
		_handle_mouse(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.5 and _joy_touch_idx == -1:
		_joy_touch_idx = event.index
		_joy_active = true
		_joy_origin = event.position
		_show_joy(_joy_origin)
	elif not event.pressed and event.index == _joy_touch_idx:
		_hide_joy()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _joy_touch_idx and _joy_active:
		_apply_joystick(event.position - _joy_origin)

func _handle_mouse(event: InputEventMouseButton) -> void:
	if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.5:
		_joy_active = true
		_joy_origin = event.position
		_joy_touch_idx = -2
		_show_joy(_joy_origin)
	elif not event.pressed and _joy_touch_idx == -2:
		_hide_joy()

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _joy_active and _joy_touch_idx == -2:
		_apply_joystick(event.position - _joy_origin)

func _show_joy(pos: Vector2) -> void:
	_joy_base.position = pos - Vector2(_joy_radius, _joy_radius)
	_joy_base.visible = true
	_joy_knob.position = pos - Vector2(_joy_radius/2, _joy_radius/2)
	_joy_knob.visible = true

func _hide_joy() -> void:
	_joy_active = false
	_joy_touch_idx = -1
	_joy_base.visible = false
	_joy_knob.visible = false
	_player.move_input = Vector2.ZERO

func _apply_joystick(delta: Vector2) -> void:
	if delta.length() > _joy_radius:
		delta = delta.normalized() * _joy_radius
	_joy_knob.position = _joy_origin + delta - Vector2(_joy_radius/2, _joy_radius/2)
	var input := delta / _joy_radius
	if input.length() < 0.18:
		input = Vector2.ZERO
	_player.move_input = input
