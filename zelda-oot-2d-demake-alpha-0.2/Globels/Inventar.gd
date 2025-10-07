# res://Skripts/Inventar.gd
extends Node
class_name Inventory

# =========================
# Enums
# =========================
enum Age { CHILD, ADULT }

# Upgrades / Progress
enum GloveLevel { NONE, CHILD_BRACELET, POWER, TITAN }
enum KernelPouch { NONE, START, UPGRADE, MAX }
enum Quiver { NONE, START, UPGRADE, MAX }
enum BombBag { NONE, START, UPGRADE, MAX }
enum Scale { NONE, SILVER, GOLD }
enum Wallet { START, UPGRADE, MAX }
enum Hook { NONE, CLAWSHOT, HOOKSHOT }
enum Magic { NONE, NORMAL, DOUBLE }
enum Ocarina { NONE, FAIRY, TIME }

# Wechselbare Ausrüstung
enum Sword { NONE, KOKIRI, MASTER, BIGGORON }
enum Shield { NONE, DEKU, HYLIA, MIRROR }
enum Armor { GREEN, RED, BLUE }
enum Boots { LEATHER, IRON, HOVER }

# Flaschen-Inhalte (wenn du Slots + Inhalt nutzen willst)
enum BottleContent {
	NONE, EMPTY,
	RED, GREEN, BLUE,  # Tränke
	FAIRY, MILK, MILK_HALF,
	FISH, RUTO_LETTER, BLUE_FIRE, BUG, POE, BIG_POE
}

# Für Paperdoll-Key
const ARMOR_NAMES: PackedStringArray = ["green", "red", "blue"]

# --- ID-Aliase, um DB/Spiel-IDs auf Inventory-IDs zu mappen ---
const ID_ALIAS := {
	"goronen_armband": "goron_bracelet",
	# ...falls du noch weitere Unterschiede hast, hier ergänzen
}

func _norm_id(id: String) -> String:
	return String(ID_ALIAS.get(id, id))


# =========================
# Signale
# =========================
signal item_acquired(id: String)
signal equipment_changed()
signal changed    # Kompatibilität zu altem InventoryState.gd

# =========================
# Globaler Spielzustand
# =========================
var age: int = Age.CHILD
var armor: int = Armor.GREEN
var gloves: int = GloveLevel.NONE

var variants: Dictionary = {}

# Besitz (binäre Items)
var owned: Dictionary = {
	# Schwerter
	"kokiri_schwert": true,
	"master_schwert": false,
	"biggoron_schwert": false,

	# Schilde
	"deku_schild": false,
	"hylia_schild": false,
	"spiegel_schild": false,

	# Tuniken
	"kokiri_rüstung": true,
	"goronen_rüstung": false,
	"zora_rüstung": false,

	# Schuhe
	"leder_stiefel": true,
	"eisen_stiefel": false,
	"gleit_stiefel": false,

	# Waffen/Items
	"feenschleuder": false,   # → KernelPouch auf 1 beim Acquire
	"bogen": false,           # → Quiver auf 1 beim Acquire
	"bombe": false,           # → BombBag auf 1 beim Acquire

	"bumerang": false,
	"deku_stab": false,
	"deku_nuss": false,

	"feuerpfeil": false,
	"dins_feuerinferno": false,
	"farores_donnersturm": false,
	"nayrus_umarmung": false,
	"eispfeil": false,
	"lichtpfeil": false,
	"auge_der_wahrheit": false,
	"wundererbsen": false,
	"stahlhammer": false,

	# Handschuh-IDs (für has() / acquire())
	"goron_bracelet": false,
	"power_gauntlets": false,
	"titan_gauntlets": false,

	# Okarinas (als IDs; Logik nutzt Enum)
	"ocarina_fairy": false,
	"ocarina_time": false,
}

# Mengen/Ammo
var amounts: Dictionary = {}   # id -> int (z. B. "bomben" -> 15)
var arrows: int = 0

# --- aktuell ausgerüstete Ausrüstung (für Ausrüstungsmenü) ---
var sword: int = Sword.NONE
var shield: int = Shield.NONE
var boots: int = Boots.LEATHER
# armor (Tunika) hast du bereits als: var armor: int = Armor.GREEN

func equip_sword(v: int) -> void:
	sword = v
	equipment_changed.emit()
	emit_signal("changed")

func equip_shield(v: int) -> void:
	shield = v
	equipment_changed.emit()
	emit_signal("changed")

func equip_armor(v: int) -> void:
	armor = v
	equipment_changed.emit()
	emit_signal("changed")

func equip_boots(v: int) -> void:
	boots = v
	equipment_changed.emit()
	emit_signal("changed")

# falls du fürs B-Icon beim Schwert etwas setzt:
#func set_equip_b(id: String) -> void:
#	equip_b = id
#	emit_signal("changed")

# =========================
# Flaschen & Auswahlslots (aus InventoryState.gd zusammengeführt)
# =========================
# Flaschen-Variante A: echte Slots mit Inhalt
var bottles: Array[int] = []   # Inhalte aus BottleContent (Index = Slot)

# (Optional) Wenn du noch alte Daten als Array[Dictionary] bekommst:
func set_bottles_legacy(arr: Array[Dictionary]) -> void:
	# akzeptiert [{content:int}, ...] und übersetzt in bottles:Array[int]
	bottles.clear()
	for d in arr:
		if d.has("content"):
			bottles.append(int(d["content"]))
	emit_signal("changed")
	equipment_changed.emit()

# Trading / Masken (einfach als Strings)
var current_trade: String = ""
var current_mask: String = ""

# Schnellzugriff-Slots (A/B/C) – IDs von Items
var equip_a: String = ""
var equip_b: String = ""
var equip_c := {"left":"", "right":"", "down":""}

# =========================
# API – Besitz/Acquire
# =========================
func has(id: String) -> bool:
	id = _norm_id(id)
	return bool(owned.get(id, false))

func acquire(id: String) -> void:
	id = _norm_id(id)
	# doppelte Erfassung vermeiden, aber Upgrades trotzdem verarbeiten
	var was_new := not has(id)
	if was_new:
		owned[id] = true

	match id:
		# Handschuhe (Upgrade-Kette)
		"goron_bracelet":
			if gloves < GloveLevel.CHILD_BRACELET:
				gloves = GloveLevel.CHILD_BRACELET
		"power_gauntlets":
			if gloves < GloveLevel.POWER:
				gloves = GloveLevel.POWER
		"titan_gauntlets":
			gloves = GloveLevel.TITAN

		# Okarina (Upgrade)
		"ocarina_fairy":
			set_ocarina(Ocarina.FAIRY)
		"ocarina_time":
			set_ocarina(Ocarina.TIME)

		# Starttaschen beim Einsammeln der Waffe
		"feenschleuder":
			set_kernel_pouch(max(get_kernel_pouch(), KernelPouch.START))
		"bogen":
			set_quiver(max(get_quiver(), Quiver.START))
		"bombe":
			set_bomb_bag(max(get_bomb_bag(), BombBag.START))

		# ============================
		#  Passive Upgrades
		# ============================

		# Tauch-Schuppen
		"silberne_schuppe", "silber_schuppe":
			set_scale(max(get_scale(), Scale.SILVER))
		"goldene_schuppe", "gold_schuppe":
			set_scale(Scale.GOLD)

		# Köcher (falls du die Upgrades auch als Items einsammelst)
		"klein_koecher", "klein_köcher", "quiver_start":
			set_quiver(max(get_quiver(), Quiver.START))
		"mittlerer_koecher", "mittlerer_köcher", "quiver_upgrade":
			set_quiver(max(get_quiver(), Quiver.UPGRADE))
		"gross_koecher", "groß_köcher", "quiver_max":
			set_quiver(Quiver.MAX)

		# Bombentasche
		"bomben_tasche_klein", "bomb_bag_start":
			set_bomb_bag(max(get_bomb_bag(), BombBag.START))
		"mittlere_bombentasche", "bomb_bag_upgrade":
			set_bomb_bag(max(get_bomb_bag(), BombBag.UPGRADE))
		"grosse_bombentasche", "große_bombentasche", "bomb_bag_max":
			set_bomb_bag(BombBag.MAX)

		# Kern-Tasche
		"kleine_kern_tasche", "kernel_pouch_start":
			set_kernel_pouch(max(get_kernel_pouch(), KernelPouch.START))
		"mittlere_kerntasche", "kernel_pouch_upgrade":
			set_kernel_pouch(max(get_kernel_pouch(), KernelPouch.UPGRADE))
		"grosse_kerntasche", "große_kerntasche", "kernel_pouch_max":
			set_kernel_pouch(KernelPouch.MAX)

		_:
			pass

	if was_new:
		item_acquired.emit(id)
	equipment_changed.emit()
	emit_signal("changed")

# =========================
# API – Alter/Tunika
# =========================
func set_age(is_adult: bool) -> void:
	age = Age.ADULT if is_adult else Age.CHILD
	equipment_changed.emit()
	emit_signal("changed")

func set_tunic_color(a: int) -> void:
	# a: Armor.GREEN/RED/BLUE
	armor = a
	equipment_changed.emit()
	emit_signal("changed")



# =========================
# API – Paperdoll Key
# =========================
func get_paperdoll_key() -> String:
	if age == Age.CHILD:
		return "kid_goron" if has("goron_bracelet") or gloves >= GloveLevel.CHILD_BRACELET else "kid_all"
	var col: String = ARMOR_NAMES[armor]  # "green"/"red"/"blue"
	if gloves >= GloveLevel.TITAN:
		return "adult_%s_titan" % col
	if gloves >= GloveLevel.POWER:
		return "adult_%s_power" % col
	return "adult_%s" % col

# =========================
# API – Mengen/Ammo
# =========================
func get_amount(id: String) -> int:
	return int(amounts.get(id, 0))

func set_amount(id: String, n: int) -> void:
	amounts[id] = max(0, n)
	equipment_changed.emit()
	emit_signal("changed")

func set_arrows(n: int) -> void:
	arrows = max(0, n)
	equipment_changed.emit()
	emit_signal("changed")

# =========================
# API – Okarina/Wallet/Beutel (Level-Variablen)
# =========================
var ocarina_level: int = Ocarina.NONE
var wallet_level: int = Wallet.START
var kernel_pouch_level: int = KernelPouch.NONE
var quiver_level: int = Quiver.NONE
var bomb_bag_level: int = BombBag.NONE
var scale_level: int = Scale.NONE

func set_ocarina(level: int) -> void:
	ocarina_level = max(ocarina_level, level)
	equipment_changed.emit()
	emit_signal("changed")

func get_wallet_capacity() -> int:
	match wallet_level:
		Wallet.START: return 99     # Start laut deinem Plan
		Wallet.UPGRADE: return 200  # 10 Skulltulas
		Wallet.MAX: return 500      # 30 Skulltulas (oder 50 je nach Regel)
	return 99

func set_wallet(level: int) -> void:
	wallet_level = level
	equipment_changed.emit()
	emit_signal("changed")

func get_kernel_pouch() -> int:
	return kernel_pouch_level
func set_kernel_pouch(level: int) -> void:
	kernel_pouch_level = level
	equipment_changed.emit()
	emit_signal("changed")

func get_quiver() -> int:
	return quiver_level
func set_quiver(level: int) -> void:
	quiver_level = level
	equipment_changed.emit()
	emit_signal("changed")

func get_scale() -> int:
	return scale_level
func set_scale(level: int) -> void:
	scale_level = clamp(level, Scale.NONE, Scale.GOLD)
	equipment_changed.emit()
	emit_signal("changed")


func get_bomb_bag() -> int:
	return bomb_bag_level
func set_bomb_bag(level: int) -> void:
	bomb_bag_level = level
	equipment_changed.emit()
	emit_signal("changed")

# =========================
# API – Flaschen
# =========================
func acquire_bottle() -> void:
	if bottles.size() < 4:
		bottles.append(BottleContent.EMPTY)
		equipment_changed.emit()
		emit_signal("changed")

func fill_bottle(index: int, content: int) -> void:
	if index < bottles.size():
		bottles[index] = content
		equipment_changed.emit()
		emit_signal("changed")

func empty_bottle(index: int) -> void:
	if index < bottles.size():
		bottles[index] = BottleContent.EMPTY
		equipment_changed.emit()
		emit_signal("changed")

# =========================
# API – Trade/Masken & Equip-Slots (aus InventoryState)
# =========================
func set_current_trade(id: String) -> void:
	current_trade = id
	emit_signal("changed")

func set_current_mask(id: String) -> void:
	current_mask = id
	emit_signal("changed")

func set_equip_a(id: String) -> void:
	equip_a = id
	emit_signal("changed")

func set_equip_b(id: String) -> void:
	equip_b = id
	emit_signal("changed")

func _bottle_content_to_string(content: int) -> String:
	match content:
		BottleContent.EMPTY: return "leer"
		BottleContent.FAIRY: return "fee"
		BottleContent.MILK: return "milch"
		BottleContent.MILK_HALF: return "milch_halb"
		BottleContent.FISH: return "fisch"
		BottleContent.RUTO_LETTER: return "rutos_brief"
		BottleContent.BLUE_FIRE: return "blaues_feuer"
		BottleContent.BUG: return "käfer"
		BottleContent.POE: return "poe"
		BottleContent.BIG_POE: return "großer_poe"
		BottleContent.RED: return "trank_rot"
		BottleContent.GREEN: return "trank_grün"
		BottleContent.BLUE: return "trank_blau"
		_: return "none"

func _string_to_bottle_content(s: String) -> int:
	match s.to_lower():
		"leer": return BottleContent.EMPTY
		"fee": return BottleContent.FAIRY
		"milch": return BottleContent.MILK
		"milch_halb": return BottleContent.MILK_HALF
		"fisch": return BottleContent.FISH
		"rutos_brief": return BottleContent.RUTO_LETTER
		"blaues_feuer": return BottleContent.BLUE_FIRE
		"käfer": return BottleContent.BUG
		"poe": return BottleContent.POE
		"großer_poe": return BottleContent.BIG_POE
		"trank_rot": return BottleContent.RED
		"trank_grün": return BottleContent.GREEN
		"trank_blau": return BottleContent.BLUE
		_: return BottleContent.NONE


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

	# 3) Swap-Fall
	if src_dir != "" and target_id != "" and target_id != id:
		equip_c[src_dir] = target_id
		equip_c[dir] = id

	# 4) Move-Fall
	elif src_dir != "" and (target_id == "" or target_id == id):
		equip_c[src_dir] = ""
		equip_c[dir] = id

	# 5) Replace-Fall (Item lag auf keinem C-Slot)
	else:
		for k in equip_c.keys():
			if k != dir and equip_c[k] == id:
				equip_c[k] = ""
		equip_c[dir] = id

	emit_signal("changed")
