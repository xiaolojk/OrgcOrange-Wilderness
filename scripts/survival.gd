# survival.gd — 生存系统：饥/渴/体力/生命/体温
# Orgc橘子工作室 · 《橘子荒野》
extends Node

class Stats:
	var hunger := 80.0
	var thirst := 80.0
	var stamina := 100.0
	var health := 100.0
	var temperature := 37.0
	
	func clamp_vals() -> void:
		hunger = clamp(hunger, 0, 100)
		thirst = clamp(thirst, 0, 100)
		stamina = clamp(stamina, 0, 100)
		health = clamp(health, 0, 100)

const HUNGER_DECAY := 0.45
const THIRST_DECAY := 0.55
const STAMINA_DECAY := 0.20
const HEALTH_REGEN := 1.2
const STARVE_DAMAGE := 0.8
const COLD_DAMAGE := 0.6

var stats := Stats.new()
var _tick := 0.0

signal stats_changed(hunger, thirst, stamina, health, temperature)
signal player_died

func tick(world, dt: float, moving: bool) -> void:
	stats.hunger -= HUNGER_DECAY * dt
	stats.thirst -= THIRST_DECAY * dt
	stats.stamina += ((-STAMINA_DECAY) if moving else (STAMINA_DECAY * 0.8)) * dt
	var env := world.temperature()
	stats.temperature = move_toward(stats.temperature, env, 0.5 * dt)
	
	var critical := stats.hunger <= 0.0 or stats.thirst <= 0.0
	var cold := stats.temperature < 34.0
	if critical: stats.health -= STARVE_DAMAGE * dt
	if cold: stats.health -= COLD_DAMAGE * dt
	if not critical and stats.hunger > 30.0 and stats.thirst > 30.0 and stats.health < 100.0:
		stats.health += HEALTH_REGEN * dt
	
	stats.clamp_vals()
	
	_tick += dt
	if _tick >= 0.25:
		_tick = 0.0
		emit_signal("stats_changed", stats.hunger, stats.thirst, stats.stamina, stats.health, stats.temperature)
	
	if stats.health <= 0.0:
		emit_signal("player_died")
		set_process(false)

func eat(food: float, water: float, stamina_boost: float = 0.0) -> void:
	stats.hunger = min(100.0, stats.hunger + food)
	stats.thirst = min(100.0, stats.thirst + water)
	stats.stamina = min(100.0, stats.stamina + stamina_boost)

func heal(hp: float) -> void:
	stats.health = min(100.0, stats.health + hp)
