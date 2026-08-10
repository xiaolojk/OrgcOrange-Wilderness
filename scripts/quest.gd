# quest.gd — 主线「灰雾与橘子」五章
# Orgc橘子工作室 · 《橘子荒野》
class_name QuestSystem
extends Node

const CHAPTERS := ["ch1", "ch2", "ch3", "ch4", "ch5"]
const CHAPTER_NAMES := [
	"第一章 · 漂流上岸",
	"第二章 · 灰雾之源",
	"第三章 · 锻造传承",
	"第四章 · 净雾护符",
	"终章 · 橘子重生",
]
const OBJECTIVES := {
	"ch1": "采集浆果与木头搭建避难所，然后寻找橘子镇（东南/东北方向）",
	"ch2": "挖掘铁矿石，与橘子镇的商人对话获取锻造配方",
	"ch3": "在镇内铁砧上锻造铁锭，再锻出铁刃",
	"ch4": "锻造净雾护符（铁锭+铁刃+纤维），长老会给你线索",
	"ch5": "前往灰雾核心，净化橘子岛",
}

var current_chapter := "ch1"
var current_objective := OBJECTIVES.ch1
var ended := false

signal advanced(chapter)
signal objective_updated(desc)

func _ready() -> void:
	G.connect("item_obtained", _on_item_obtained)
	G.connect("forge_complete", _on_forge_complete)
	call_deferred("_announce")

func chapter_title() -> String:
	var idx := CHAPTERS.find(current_chapter)
	return CHAPTER_NAMES[idx] if idx >= 0 else current_chapter

func _announce() -> void:
	emit_signal("objective_updated", "%s\n%s" % [chapter_title(), current_objective])
	G.toast("新章节：%s" % chapter_title())

func _on_item_obtained(id: String, _n: int) -> void:
	if ended: return
	var p := G.player
	match current_chapter:
		"ch1":
			if p != null and p.count_item("wood") >= 5 and p.count_item("berry") >= 3:
				advance()
		"ch2":
			if id == "iron_ore" and p != null and p.count_item("iron_ore") >= 3:
				advance()

func _on_forge_complete(produced_id: String) -> void:
	if ended: return
	match current_chapter:
		"ch3":
			if produced_id == "iron_blade":
				advance()
		"ch4":
			if produced_id == "purify_amulet":
				advance()

func advance() -> void:
	if ended: return
	var idx := CHAPTERS.find(current_chapter)
	idx += 1
	if idx >= CHAPTERS.size():
		finish()
		return
	current_chapter = CHAPTERS[idx]
	current_objective = OBJECTIVES[current_chapter]
	emit_signal("advanced", current_chapter)
	_announce()

func set_objective(desc: String) -> void:
	current_objective = desc
	emit_signal("objective_updated", desc)

func finish() -> void:
	ended = true
	current_chapter = "done"
	current_objective = "橘子岛已重生，灰雾散尽。感谢游玩！"
	emit_signal("objective_updated", current_objective)
	G.toast("通关：橘子岛重生！")
