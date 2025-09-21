extends Node

signal health_changed(quarters:int)    # 4 Viertel = 1 Herz
signal magic_changed(value:float, max_value:float)
signal rupees_changed(n:int)

var max_hearts := 20
var health_quarters := max_hearts * 2
var magic := 0.0
var magic_max := 0.0
var rupees := 0

func set_health_quarters(q:int) -> void:
	health_quarters = clamp(q, 0, max_hearts*2)
	health_changed.emit(health_quarters)

func add_damage_quarters(q:int) -> void: set_health_quarters(health_quarters - q)
func heal_quarters(q:int) -> void:       set_health_quarters(health_quarters + q)

func set_magic_values(v:float, m:float) -> void:
	magic = clamp(v, 0.0, m); magic_max = max(m, 0.0)
	magic_changed.emit(magic, magic_max)

func add_rupees(delta:int) -> void:
	rupees = clamp(rupees + delta, 0, 999)
	rupees_changed.emit(rupees)
