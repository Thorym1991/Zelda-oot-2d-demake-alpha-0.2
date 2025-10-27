extends Node
class_name Inventory

signal changed
signal equipment_changed
signal owned_changed(id: String, has_item: bool)
signal equipped_slot_changed(slot: String, value: int) # "sword","shield","armor","boots"
signal meta_changed()                                  # age/strength/variants geändert
signal ammo_changed(id: String, amount: int)           # "arrows" oder item-id

enum Age { CHILD, ADULT }
enum Sword { NONE, KOKIRI, MASTER, BIGGORON }
enum Shield { NONE, DEKU, HYLIA, MIRROR }
enum Armor { GREEN, RED, BLUE }
enum Boots { NONE,LEATHER, IRON, HOVER }
enum GloveLevel { NONE, CHILD_BRACELET, POWER, TITAN }

# Passive/Upgrades (mit „keine“-Stufe)
enum PouchLevel { NONE, SMALL, MEDIUM, MAX }    # 0..3  (Kerne/Köcher/Bomben)
enum DiveScale  { NONE, SILVER, GOLD }           # 0..2

const ARMOR_NAMES := ["green","red","blue"]

# Optional: Kapazitäten (0 = keine Tasche)
const SEED_POUCH_CAP := [0, 30, 40, 50]  # Kind: Kerne
const QUIVER_CAP     := [0, 30, 40, 50]  # Erwachsen: Pfeile
const BOMB_BAG_CAP   := [0, 20, 30, 40]

# ------- Zustand --------
var age: int = Age.CHILD
var gloves: int = GloveLevel.NONE

# Passive-Levels
var seed_pouch_level = PouchLevel.NONE
var quiver_level     = PouchLevel.NONE
var bomb_bag_level   = PouchLevel.NONE
var dive_scale       = DiveScale.NONE
var strength         = GloveLevel.NONE

# Besitztabelle (nur das, was dein Menü braucht)
var owned: Dictionary = {
	# --- Waffen / Schilde / Rüstungen / Stiefel ---
	"kokiri_schwert": true,
	"master_schwert": true,
	"biggoron_schwert": true,

	"deku_schild": true,
	"hylia_schild": true,
	"spiegel_schild": true,

	"kokiri_rüstung": true,
	"goronen_rüstung": true,
	"zora_rüstung": true,

	"leder_stiefel": true,
	"eisen_stiefel": true,
	"gleit_stiefel": true,

	# --- Handschuhe ---
	"goron_bracelet": false,
	"power_gauntlets": false,
	"titan_gauntlets": false,

	# --- Magie & Spezialfähigkeiten ---
	"dins_feuerinferno": true,
	"farores_donnersturm": true,
	"nayrus_umarmun": true,

	# --- Fernkampf & Items ---
	"feenschleuder": true,
	"bogen": true,
	"feuerpfeil": true,
	"eispfeil": true,
	"lichtpfeil": true,
	"bumerang": true,
	"auge_der_wahrheit": true,
	"stahlhammer": true,
	"haken": true,

	# --- Standardverbrauchsitems ---
	"deku_stab": true,
	"deku_nuss": true,
	"bombe": true,
	"krabbelminen": true,
	"flasche": true,
	"tausch": true,

	# --- Utility & Sammelbares ---
	"wundererbsen": true,
	"okarina": true,
	"rutos_brief": true,
	"maske": true
}

# Ausgerüstet
var sword: int = Sword.NONE
var shield: int = Shield.NONE
var armor: int = Armor.GREEN
var boots: int  = Boots.LEATHER

# ------- API: Varianten --------
var variants: Dictionary = {}  # id -> String

func set_variant(id: String, v: String) -> void:
	variants[id] = v
	equipment_changed.emit()
	emit_signal("changed")

func get_variant(id: String) -> String:
	return String(variants.get(id, "default"))

# ------- API: Mengen/Ammo --------
var amounts: Dictionary = {}   # id -> int (z. B. "bomben" -> 15)
var arrows: int = 0

func get_amount(id: String) -> int:
	return int(amounts.get(id, 0))

# ------- API: Besitz/Equip --------
func has(id: String) -> bool:
	return bool(owned.get(id, false))

func acquire(id: String) -> void:
	if has(id):
		return

	owned[id] = true

	# -> NEU: gezieltes Besitz-Signal
	owned_changed.emit(id, true)

	# -> Altes Gesamt-Refresh-Signal beibehalten (Kompatibilität)
	changed.emit()

	# Auto-Mapping für Upgrades (dein bestehender Code)
	match id:
		# Kerne-Tasche (Kind)
		"seed_pouch_small":  set_seed_pouch_level(PouchLevel.SMALL)
		"seed_pouch_medium": set_seed_pouch_level(PouchLevel.MEDIUM)
		"seed_pouch_max":    set_seed_pouch_level(PouchLevel.MAX)

		# Köcher (Erwachsen)
		"quiver_small":  set_quiver_level(PouchLevel.SMALL)
		"quiver_medium": set_quiver_level(PouchLevel.MEDIUM)
		"quiver_max":    set_quiver_level(PouchLevel.MAX)

		# Bombentasche
		"bomb_bag_small":  set_bomb_bag_level(PouchLevel.SMALL)
		"bomb_bag_medium": set_bomb_bag_level(PouchLevel.MEDIUM)
		"bomb_bag_max":    set_bomb_bag_level(PouchLevel.MAX)

		# Taucher-Schuppen
		"silver_scale": set_dive_scale(DiveScale.SILVER)
		"gold_scale":   set_dive_scale(DiveScale.GOLD)

		# Stärke via Handschuhe
		"goron_bracelet":
			if strength < int(GloveLevel.CHILD_BRACELET):
				set_strength_level(int(GloveLevel.CHILD_BRACELET))
		"power_gauntlets":
			if strength < int(GloveLevel.POWER):
				set_strength_level(int(GloveLevel.POWER))
		"titan_gauntlets":
			set_strength_level(int(GloveLevel.TITAN))

func get_paperdoll_key() -> String:
	if age == int(Age.CHILD):
		return "kid_goron" if has("goron_bracelet") or strength >= int(GloveLevel.CHILD_BRACELET) else "kid_all"

	var col: String = String(ARMOR_NAMES[armor])
	if strength >= int(GloveLevel.TITAN):
		return "adult_%s_titan" % col
	if strength >= int(GloveLevel.POWER):
		return "adult_%s_power" % col
	return "adult_%s" % col

# ------- Schnellzugriff-Slots (A/B/C) --------
var equip_a: String = ""
var equip_b: String = ""
var equip_c := {"left": "", "right": "", "down": ""}

func set_equip_a(id: String) -> void:
	equip_a = id
	emit_signal("changed")

func set_equip_b(id: String) -> void:
	equip_b = id
	emit_signal("changed")

var b_override_id: String = ""  # "" = kein Override

func set_b_override(id: String) -> void:
	b_override_id = id
	equipment_changed.emit()
	changed.emit()

func clear_b_override() -> void:
	if b_override_id == "": return
	b_override_id = ""
	equipment_changed.emit()
	changed.emit()

func set_equip_c(dir: String, id: String) -> void:
	if not equip_c.has(dir): return

	if id == "":
		equip_c[dir] = ""
		emit_signal("changed")
		return

	var src_dir := ""
	for k in equip_c.keys():
		if equip_c[k] == id:
			src_dir = k
			break

	var target_id := String(equip_c[dir])

	if src_dir == dir:
		return
	elif src_dir != "" and target_id != "" and target_id != id:
		equip_c[src_dir] = target_id
		equip_c[dir] = id
	elif src_dir != "" and (target_id == "" or target_id == id):
		equip_c[src_dir] = ""
		equip_c[dir] = id
	else:
		for k in equip_c.keys():
			if k != dir and equip_c[k] == id:
				equip_c[k] = ""
		equip_c[dir] = id

	emit_signal("changed")

# ------- QoL: Kapazitäten --------
func get_seed_capacity() -> int:
	return SEED_POUCH_CAP[clamp(seed_pouch_level, 0, SEED_POUCH_CAP.size() - 1)]

func get_arrow_capacity() -> int:
	return QUIVER_CAP[clamp(quiver_level, 0, QUIVER_CAP.size() - 1)]

func get_bomb_capacity() -> int:
	return BOMB_BAG_CAP[clamp(bomb_bag_level, 0, BOMB_BAG_CAP.size() - 1)]

# Set-Helper fürs UI/Debug
func set_seed_pouch_level(level: int) -> void:
	level = clampi(level, 0, 3)
	var lv: Inventory.PouchLevel = level as Inventory.PouchLevel
	if seed_pouch_level == lv: return
	seed_pouch_level = lv
	equipment_changed.emit(); changed.emit()

func set_quiver_level(level: int) -> void:
	level = clampi(level, 0, 3)
	var lv: Inventory.PouchLevel = level as Inventory.PouchLevel
	if quiver_level == lv: return
	quiver_level = lv
	equipment_changed.emit(); changed.emit()

func set_bomb_bag_level(level: int) -> void:
	level = clampi(level, 0, 3)
	var lv: Inventory.PouchLevel = level as Inventory.PouchLevel
	if bomb_bag_level == lv: return
	bomb_bag_level = lv
	equipment_changed.emit(); changed.emit()

func set_dive_scale(level: int) -> void:
	level = clampi(level, 0, 2)
	var lv: Inventory.DiveScale = level as Inventory.DiveScale
	if dive_scale == lv: return
	dive_scale = lv
	equipment_changed.emit(); changed.emit()

func set_strength_level(level: int) -> void:
	level = clampi(level, 0, 3)
	var lv: Inventory.GloveLevel = level as Inventory.GloveLevel
	if strength == lv: return
	strength = lv
	meta_changed.emit()                    # ⬅️ neu
	equipment_changed.emit(); changed.emit()


func equip_sword(v: int) -> void:
	if sword == v: return
	sword = v
	equipped_slot_changed.emit("sword", sword)
	equipment_changed.emit(); changed.emit()

func equip_shield(v: int) -> void:
	if shield == v: return
	shield = v
	equipped_slot_changed.emit("shield", shield)
	equipment_changed.emit(); changed.emit()

func equip_armor(v: int) -> void:
	if armor == v: return
	armor = v
	equipped_slot_changed.emit("armor", armor)
	equipment_changed.emit(); changed.emit()

func equip_boots(v: int) -> void:
	if boots == v: return
	boots = v
	equipped_slot_changed.emit("boots", boots)
	equipment_changed.emit(); changed.emit()

func set_age(is_adult: bool) -> void:
	var new_age: int = int(Age.ADULT) if is_adult else int(Age.CHILD)
	if age == new_age: return
	age = new_age
	meta_changed.emit()
	equipment_changed.emit(); changed.emit()

func set_amount(id: String, n: int) -> void:
	n = max(0, n)
	amounts[id] = n
	ammo_changed.emit(id, n)
	equipment_changed.emit(); changed.emit()

func set_arrows(n: int) -> void:
	arrows = max(0, n)
	ammo_changed.emit("arrows", arrows)
	equipment_changed.emit(); changed.emit()
