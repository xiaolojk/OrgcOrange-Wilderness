# ui.gd — HUD：属性条 + 任务 + 提示 + 品牌 + 时钟（全中文）
# Orgc橘子工作室 · 《橘子荒野》
class_name HUD
extends CanvasLayer

var _hunger_fill: ProgressBar
var _thirst_fill: ProgressBar
var _stamina_fill: ProgressBar
var _health_fill: ProgressBar
var _objective: Label
var _toast: Label
var _clock: Label
var _brand: Label
var _toast_tween: Tween
var _weather_label := "晴"

func _ready() -> void:
	layer = 10
	_build()
	G.survival.connect("stats_changed", _on_stats)
	G.quest.connect("objective_updated", _on_objective)
	G.connect("toast_shown", _on_toast)
	G.world.connect("time_changed", _on_time)
	G.world.connect("weather_changed", _on_weather)

func _build() -> void:
	# 左上：属性条
	_hunger_fill  = _make_bar("饱食", Color(0.90,0.55,0.20), 0)
	_thirst_fill  = _make_bar("水分", Color(0.30,0.60,0.92), 1)
	_stamina_fill = _make_bar("体力", Color(0.45,0.80,0.35), 2)
	_health_fill  = _make_bar("生命", Color(0.85,0.20,0.25), 3)

	# 右上：品牌
	_brand = _make_label("橘子荒野\nOrgc橘子工作室", 22, Color(1,0.7,0.3))
	_brand.anchor_left = 1; _brand.anchor_right = 1
	_brand.anchor_top = 0; _brand.anchor_bottom = 0
	_brand.offset_left = -200; _brand.offset_right = -20
	_brand.offset_top = 20; _brand.offset_bottom = 70
	_brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# 右上下：时钟
	_clock = _make_label("晴 · 清晨", 24, Color.WHITE)
	_clock.anchor_left = 1; _clock.anchor_right = 1
	_clock.offset_left = -200; _clock.offset_right = -20
	_clock.offset_top = 75; _clock.offset_bottom = 110
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# 顶部中央：任务目标
	_objective = _make_label("", 24, Color(1,0.95,0.7))
	_objective.anchor_left = 0.5; _objective.anchor_right = 0.5
	_objective.offset_left = -300; _objective.offset_right = 300
	_objective.offset_top = 15; _objective.offset_bottom = 90
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 底部中央：浮动提示
	_toast = _make_label("", 28, Color.WHITE)
	_toast.anchor_left = 0.5; _toast.anchor_right = 0.5
	_toast.anchor_top = 1; _toast.anchor_bottom = 1
	_toast.offset_left = -360; _toast.offset_right = 360
	_toast.offset_top = -120; _toast.offset_bottom = -70
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0

func _make_bar(name: String, color: Color, idx: int) -> ProgressBar:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(220, 28)
	row.position = Vector2(20, 20 + idx * 36)
	add_child(row)
	var hb := HBoxContainer.new()
	hb.offset_left = 4; hb.offset_right = -4
	hb.offset_top = 2; hb.offset_bottom = -2
	row.add_child(hb)
	var lbl := Label.new()
	lbl.text = name
	lbl.custom_minimum_size = Vector2(50, 0)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	hb.add_child(lbl)
	var bar := ProgressBar.new()
	bar.min_value = 0; bar.max_value = 100
	bar.value = 100
	bar.custom_minimum_size = Vector2(150, 20)
	bar.show_percentage = false
	hb.add_child(bar)
	return bar

func _make_label(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font", size)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
	return lbl

func _on_stats(h, t, s, hp, _temp) -> void:
	_hunger_fill.value = h
	_thirst_fill.value = t
	_stamina_fill.value = s
	_health_fill.value = hp

func _on_objective(desc: String) -> void:
	_objective.text = desc

func _on_toast(msg: String) -> void:
	_toast.text = msg
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.modulate.a = 1
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0, 0.6)

func _on_time(t: float) -> void:
	var phase: String
	if t < 0.22: phase = "深夜"
	elif t < 0.30: phase = "黎明"
	elif t < 0.45: phase = "清晨"
	elif t < 0.55: phase = "正午"
	elif t < 0.70: phase = "午后"
	elif t < 0.78: phase = "黄昏"
	else: phase = "夜晚"
	_clock.text = "%s · %s" % [_weather_label, phase]

func _on_weather(w: String) -> void:
	_weather_label = w
	if G.world != null:
		_on_time(G.world.time_of_day)
