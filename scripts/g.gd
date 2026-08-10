# g.gd — 全局游戏总线（Autoload 单例）
# 持有各系统引用 + 事件信号，供系统间松耦合通信。
# Orgc橘子工作室 · 《橘子荒野》
extends Node

const PixelArtScript = preload("res://scripts/pixel_art.gd")

var world: Node2D = null       # WorldSystem
var player: CharacterBody2D = null
var survival: Node = null      # SurvivalSystem
var forge: Node2D = null       # ForgeAnvil
var quest: Node = null         # QuestSystem
var pix: Node = null           # PixelArt
var ui: Node = null            # UI 根

# 事件
signal item_obtained(id, n)
signal item_consumed(id, n)
signal forge_complete(output_id)
signal toast_shown(msg)

func _ready() -> void:
	# 关键：Autoload 的 _ready 在所有场景节点之前执行，
	# 在此初始化 pix，保证 player._ready 等场景节点能立即使用。
	pix = PixelArtScript.new()
	pix.name = "PixelArt"
	add_child(pix)

# 便捷：发浮动提示
func toast(msg: String) -> void:
	emit_signal("toast_shown", msg)

func item_obtained_signal(id: String, n: int) -> void:
	emit_signal("item_obtained", id, n)

func item_consumed_signal(id: String, n: int) -> void:
	emit_signal("item_consumed", id, n)

func forge_complete_signal(out_id: String) -> void:
	emit_signal("forge_complete", out_id)
