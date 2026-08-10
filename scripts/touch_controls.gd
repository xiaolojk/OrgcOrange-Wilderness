# touch_controls.gd — 触屏控制：动态摇杆 + 行动/锻造按钮
# 触摸左半屏任意位置，摇杆出现在那里。最可靠的触屏方案。
# Orgc橘子工作室 · 《橘子荒野》
class_name TouchControls
extends CanvasLayer

var _player: CharacterBody2D
var _joy_base: Panel
var _joy_knob: Panel
var _joy_radius := 80.0
var _joy_center := Vector2.ZERO
var _joy_active := false
var _joy_touch_idx := -1

func _ready() -> void:
	layer = 20
	_build()
	set_process_unhandled_input(true)

func init(player: CharacterBody2D) -> void:
	_player = player

func _build() -> void:
	# === 动态摇杆（初始隐藏，触摸时出现在触摸点）===
	_joy_base = Panel.new()
	_joy_base.custom_minimum_size = Vector2(_joy_radius*2, _joy_radius*2)
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(1, 1, 1, 0.12)
	base_style.border_width_left = 3
	base_style.border_width_right = 3
	base_style.border_width_top = 3
	base_style.border_width_bottom = 3
	base_style.border_color = Color(1, 1, 1, 0.35)
	base_style.corner_radius_top_left = 80
	base_style.corner_radius_top_right = 80
	base_style.corner_radius_bottom_left = 80
	base_style.corner_radius_bottom_right = 80
	_joy_base.add_theme_stylebox_override("panel", base_style)
	_joy_base.visible = false
	_joy_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_joy_base)

	_joy_knob = Panel.new()
	_joy_knob.custom_minimum_size = Vector2(_joy_radius, _joy_radius)
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.95, 0.55, 0.18, 0.85)
	knob_style.corner_radius_top_left = 40
	knob_style.corner_radius_top_right = 40
	knob_style.corner_radius_bottom_left = 40
	knob_style.corner_radius_bottom_right = 40
	_joy_knob.add_theme_stylebox_override("panel", knob_style)
	_joy_knob.visible = false
	_joy_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_joy_knob)

	# 提示文字
	var hint := Label.new()
	hint.text = "触摸左侧移动"
	hint.add_theme_font_size_override("font", 16)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
	hint.anchor_left = 0; hint.anchor_right = 0
	hint.anchor_top = 1; hint.anchor_bottom = 1
	hint.offset_left = 20; hint.offset_top = -30
	hint.offset_right = 200; hint.offset_bottom = -10
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

	# === 右下角行动按钮（橘色）===
	_make_action_button("行动", Vector2(-260, -220), Color(0.95, 0.55, 0.18), "_on_action")
	# === 右下角锻造按钮（灰色）===
	_make_action_button("锻造", Vector2(-260, -420), Color(0.5, 0.5, 0.6), "_on_forge")

func _make_action_button(text: String, offset: Vector2, color: Color, method: String) -> void:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font", 36)
	btn.custom_minimum_size = Vector2(180, 180)
	btn.anchor_left = 1; btn.anchor_right = 1
	btn.anchor_top = 1; btn.anchor_bottom = 1
	btn.offset_left = offset.x; btn.offset_right = offset.x + 180
	btn.offset_top = offset.y; btn.offset_bottom = offset.y + 180
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = color
	btn_style.corner_radius_top_left = 90
	btn_style.corner_radius_top_right = 90
	btn_style.corner_radius_bottom_left = 90
	btn_style.corner_radius_bottom_right = 90
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.modulate.a = 0.9
	add_child(btn)
	btn.pressed.connect(Callable(self, method))

func _on_action() -> void:
	if _player != null:
		_player.interact()

func _on_forge() -> void:
	if G.forge != null:
		G.forge.interact(_player)

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

func _is_left_side(pos: Vector2) -> bool:
	# 左半屏 = 摇杆区域
	var screen_w := get_viewport().get_visible_rect().size.x
	return pos.x < screen_w * 0.5

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed and _is_left_side(event.position) and _joy_touch_idx == -1:
		# 触摸左半屏 → 摇杆出现在触摸点
		_joy_touch_idx = event.index
		_joy_active = true
		_joy_center = event.position
		_show_joy_at(event.position)
		_apply_joystick(Vector2.ZERO)  # 初始无方向
	elif not event.pressed and event.index == _joy_touch_idx:
		_hide_joy()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _joy_touch_idx and _joy_active:
		_apply_joystick(event.position - _joy_center)

func _handle_mouse(event: InputEventMouseButton) -> void:
	if event.pressed and _is_left_side(event.position):
		_joy_active = true
		_joy_touch_idx = -2
		_joy_center = event.position
		_show_joy_at(event.position)
		_apply_joystick(Vector2.ZERO)
	elif not event.pressed and _joy_touch_idx == -2:
		_hide_joy()

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _joy_active and _joy_touch_idx == -2:
		_apply_joystick(event.position - _joy_center)

func _show_joy_at(pos: Vector2) -> void:
	_joy_base.global_position = pos - Vector2(_joy_radius, _joy_radius)
	_joy_knob.global_position = pos - Vector2(_joy_radius/2, _joy_radius/2)
	_joy_base.visible = true
	_joy_knob.visible = true

func _apply_joystick(delta: Vector2) -> void:
	if delta.length() > _joy_radius:
		delta = delta.normalized() * _joy_radius
	# 旋钮位置 = 中心 + delta - 旋钮半径
	_joy_knob.global_position = _joy_center + delta - Vector2(_joy_radius/2, _joy_radius/2)
	var input := delta / _joy_radius
	if input.length() < 0.15:
		input = Vector2.ZERO
	_player.move_input = input

func _hide_joy() -> void:
	_joy_active = false
	_joy_touch_idx = -1
	_joy_base.visible = false
	_joy_knob.visible = false
	_player.move_input = Vector2.ZERO
