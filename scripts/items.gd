# items.gd — 物品目录（数据驱动，Autoload 单例）
# Orgc橘子工作室 · 《橘子荒野》
extends Node

# 物品类别
enum Category { RESOURCE, FOOD, DRINK, TOOL, FORGE_INPUT, EQUIPMENT }

# 物品定义：id -> {name, category, sprite_key}
const DEFS := {
	"wood":         {"name": "木头",   "cat": Category.RESOURCE,   "key": "wood"},
	"stone":        {"name": "石头",   "cat": Category.RESOURCE,   "key": "stone"},
	"fiber":        {"name": "纤维",   "cat": Category.RESOURCE,   "key": "fiber"},
	"iron_ore":     {"name": "铁矿石", "cat": Category.RESOURCE,   "key": "iron_ore"},
	"charcoal":     {"name": "木炭",   "cat": Category.FORGE_INPUT,"key": "charcoal"},
	"iron_ingot":   {"name": "铁锭",   "cat": Category.FORGE_INPUT,"key": "iron_ingot"},
	"berry":        {"name": "浆果",   "cat": Category.FOOD,       "key": "berry"},
	"meat":         {"name": "兽肉",   "cat": Category.FOOD,       "key": "meat"},
	"water":        {"name": "清水",   "cat": Category.DRINK,      "key": "water"},
	"iron_blade":   {"name": "铁刃",   "cat": Category.TOOL,       "key": "iron_blade"},
	"purify_amulet":{"name": "净雾护符","cat": Category.EQUIPMENT, "key": "purify_amulet"},
}

func display_name(item_id: String) -> String:
	if DEFS.has(item_id):
		return DEFS[item_id].name
	return item_id

func sprite_key(item_id: String) -> String:
	if DEFS.has(item_id):
		return DEFS[item_id].key
	return item_id

func category(item_id: String) -> int:
	if DEFS.has(item_id):
		return DEFS[item_id].cat
	return Category.RESOURCE
