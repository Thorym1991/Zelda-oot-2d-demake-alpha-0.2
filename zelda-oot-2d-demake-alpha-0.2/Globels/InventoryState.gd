extends Node
signal changed

var owned: Dictionary = {}
var variants: Dictionary = {}
var is_child: bool = true

# Pfeile (für Bogen)
var _arrows: int = 0
var arrows: int:
	get: return _arrows
	set(value):
		_arrows = max(0, value)
		emit_signal("changed")

# Flaschen, Tausch, Maske
var bottles: Array[Dictionary] = []
var current_trade: String = ""
var current_mask: String = ""
# ─────────────────────────────────────────────────────────────────

# Helpers (damit das UI leicht aktualisiert)
func has(id: String) -> bool: return owned.get(id, 0) > 0
func get_amount(id: String) -> int: return int(owned.get(id, 0))

func set_bottles(arr: Array[Dictionary]) -> void:
	bottles = arr.duplicate()
	emit_signal("changed")

func set_current_trade(id: String) -> void:
	current_trade = id
	emit_signal("changed")

func set_current_mask(id: String) -> void:
	current_mask = id
	emit_signal("changed")

# Ausgewählte Items
var equip_a: String = ""   # z. B. "bombe"
var equip_b: String = ""   # z. B. "bogen"
var equip_c := {"left":"", "right":"", "down":""}

func set_equip_a(id: String) -> void:
	equip_a = id
	emit_signal("changed")

func set_equip_b(id: String) -> void:
	equip_b = id
	emit_signal("changed")

func set_equip_c(dir: String, id: String) -> void:
	if not equip_c.has(dir):
		return

	# 0) Löschen?
	if id == "":
		equip_c[dir] = ""
		emit_signal("changed")
		return

	# 1) Wo liegt dieses Item aktuell (falls überhaupt)?
	var src_dir := ""
	for k in equip_c.keys():
		if equip_c[k] == id:
			src_dir = k
			break

	var target_id := String(equip_c[dir])

	# 2) Falls Item ohnehin schon auf dem Zielslot liegt → nichts tun
	if src_dir == dir:
		return

	# 3) Swap-Fall: Item liegt bereits auf anderem Slot UND Zielslot ist belegt mit anderem Item
	if src_dir != "" and target_id != "" and target_id != id:
		# Tauschen
		equip_c[src_dir] = target_id
		equip_c[dir] = id

	# 4) Move-Fall: Item liegt auf anderem Slot, Ziel ist leer (oder identisch)
	elif src_dir != "" and (target_id == "" or target_id == id):
		equip_c[src_dir] = ""
		equip_c[dir] = id

	# 5) Replace-Fall: Item liegt noch auf keinem C-Slot → Ziel (leer oder belegt) übernehmen
	else:
		# Sicherheitsnetz: Duplikate entfernen, falls irgendwo doppelt
		for k in equip_c.keys():
			if k != dir and equip_c[k] == id:
				equip_c[k] = ""
		equip_c[dir] = id

	emit_signal("changed")
