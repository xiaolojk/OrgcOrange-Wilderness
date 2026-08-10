# forge_panel.gd — 锻造面板：把材料放上铁砧 → 点击锻造
# 触屏友好。Orgc橘子工作室 · 《橘子荒野》
extends CanvasLayer

var _forge: Node2D = null
var _panel: Panel
var _inv_grid: GridContainer
var _anvil_grid: GridContainer

func _ready() -> void:
	layer = 30
	_build()
	visible = false
	# 监听铁砧打开（由 main 连接 forge.opened）

func open_forge(forge: Node2D) -> void:
	_forge = forge
	visible = true
	_refresh()

func _build() -> void:
	# 半透明背景
	var bg := ColorRect.new()
	bg.color = Color(0,0,0,0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_panel = Panel.new()
	_panel.custom_minimum_size = Vector2(720, 560)
	_panel.anchor_left = 0.5; _panel.anchor_right = 0.5
	_panel.anchor_top = 0.5; _panel.anchor_bottom = 0.5
	_panel.offset_left = -360; _panel.offset_right = 360
	_panel.offset_top = -280; _panel.offset_bottom = 280
	add_child(_panel)

	# 标题
	var title := Label.new()
	title.text = "铁砧锻造"
	title.add_theme_font_size_override("font", 30)
	title.add_theme_color_override("font_color", Color(1,0.7,0.3))
	title.position = Vector2(0, 15)
	title.size = Vector2(720, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(title)

	var hint := Label.new()
	hint.text = "把材料放上铁砧，点击锻造"
	hint.add_theme_font_size_override("font", 18)
	hint.add_theme_color_override("font_color", Color(0.8,0.8,0.8))
	hint.position = Vector2(0, 55)
	hint.size = Vector2(720, 25)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(hint)

	# 背包标签 + 网格
	var inv_lbl := Label.new()
	inv_lbl.text = "背包（点击放入铁砧）"
	inv_lbl.add_theme_font_size_override("font", 18)
	inv_lbl.position = Vector2(30, 95)
	inv_lbl.size = Vector2(330, 24)
	_panel.add_child(inv_lbl)
	_inv_grid = _make_grid(Vector2(30, 125), 4)
	_panel.add_child(_inv_grid)

	# 铁砧标签 + 网格
	var anvil_lbl := Label.new()
	anvil_lbl.text = "铁砧上的材料"
	anvil_lbl.add_theme_font_size_override("font", 18)
	anvil_lbl.position = Vector2(380, 95)
	anvil_lbl.size = Vector2(310, 24)
	_panel.add_child(anvil_lbl)
	_anvil_grid = _make_grid(Vector2(380, 125), 4)
	_panel.add_child(_anvil_grid)

	# 按钮
	_make_button("锻造", Vector2(120, 470), Color(0.95,0.55,0.18), _on_forge)
	_make_button("取回", Vector2(305, 470), Color(0.4,0.5,0.6), _on_takeback)
	_make_button("关闭", Vector2(490, 470), Color(0.5,0.2,0.2), _on_close)

func _make_grid(pos: Vector2, cols: int) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = cols
	grid.position = pos
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	return grid

func _make_button(text: String, pos: Vector2, color: Color, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font", 24)
	btn.position = pos
	btn.size = Vector2(140, 55)
	btn.modulate = color
	_panel.add_child(btn)
	btn.pressed.connect(cb)

func _on_forge() -> void:
	if _forge != null:
		_forge.try_forge()
		_refresh()

func _on_takeback() -> void:
	if _forge != null:
		_forge.clear_anvil()
		_refresh()

func _on_close() -> void:
	visible = false
	_forge = null

func _refresh() -> void:
	_clear_grid(_inv_grid)
	_clear_grid(_anvil_grid)
	var p := G.player
	if p == null: return
	# 背包（排除装备）
	for id in p.inventory.keys():
		if Items.category(id) == Items.Category.EQUIPMENT:
			continue
		var n := p.count_item(id)
		if n <= 0: continue
		_add_item_button(_inv_grid, id, n, func(): _forge.place_on_anvil(id, 1); _refresh())
	# 铁砧
	if _forge != null:
		for id in _forge.anvil.keys():
			var n := _forge.anvil[id]
			if n <= 0: continue
			_add_item_button(_anvil_grid, id, n, null)

func _clear_grid(grid: GridContainer) -> void:
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()

func _add_item_button(grid: GridContainer, id: String, count: int, cb: Variant) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(78, 78)
	var name := Items.display_name(id)
	btn.text = "%s\n×%d" % [name, count]
	btn.add_theme_font_size_override("font", 13)
	btn.clip_text = true
	if cb != null:
		btn.pressed.connect(cb)
	grid.add_child(btn)
