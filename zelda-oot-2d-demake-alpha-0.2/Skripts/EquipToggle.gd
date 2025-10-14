extends TextureButton
class_name EquipToggle

# Auswahl- und Anzeige-Slots
enum EquipType {
	SWORD, SHIELD, ARMOR, BOOTS,
	AMMO, BOMB_BAG, DIVE_SCALE, STRENGTH
}


@export var type: EquipType = EquipType.SWORD
@export var value: int = 0                 # Level/Index je nach Slot
@export var owned_id: String = ""          # optional: Besitzprüfung für echte Items
@export var is_passive: bool = false       # reine Anzeige? (nicht gruppieren/anklickbar)

@onready var _frame: Control = get_node_or_null(^"Frame")
@onready var _icon_node: Node = get_node_or_null(^"Icon")

# --- Editor-konfigurierbare IDs für passive Anzeigen ---
@export var passive_ids: Array[String] = []           # für BOMB_BAG, DIVE_SCALE, STRENGTH (Reihenfolge = Level-Index)
@export var passive_ids_child: Array[String] = []     # für AMMO (Kind)  Index 0..3 = keine/klein/mittel/max
@export var passive_ids_adult: Array[String] = []     # für AMMO (Erwachsen)

func _ready() -> void:
	# Erzwinge Passiv-Verhalten für stufige Anzeige-Typen
	if _is_forced_passive_type():
		is_passive = true

	toggle_mode = not is_passive
	focus_mode = Control.FOCUS_ALL if not is_passive else Control.FOCUS_NONE

	if _frame:
		_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _icon_node is Control:
		(_icon_node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	if has_node("/root/Inventar"):
		var inv: Inventory = get_node("/root/Inventar") as Inventory
		if not inv.changed.is_connected(_refresh):
			inv.changed.connect(_refresh)
		if not inv.equipment_changed.is_connected(_refresh):
			inv.equipment_changed.connect(_refresh)

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	_refresh()

func _is_forced_passive_type() -> bool:
	return type == EquipType.AMMO \
		or type == EquipType.BOMB_BAG \
		or type == EquipType.DIVE_SCALE \
		or type == EquipType.STRENGTH

func _refresh() -> void:
	var inv: Inventory = get_node_or_null("/root/Inventar") as Inventory
	if inv == null:
		return

	# Standard: Frame aus
	if _frame:
		_frame.visible = false

	# Passive Buttons sind deaktiviert (nur Anzeige)
	disabled = is_passive

	# Besitz-Check nur für echte ausrüstbare Items
	if owned_id.length() > 0 and not _is_forced_passive_type():
		if not inv.has(owned_id):
			disabled = true

	match type:
		# --- aktive, wählbare Slots ---
		EquipType.SWORD:
			if not is_passive:
				var cur: int = int(inv.sword)
				button_pressed = (cur == value)
				if _frame: _frame.visible = button_pressed

		EquipType.SHIELD:
			if not is_passive:
				var cur: int = int(inv.shield)
				button_pressed = (cur == value)
				if _frame: _frame.visible = button_pressed

		EquipType.ARMOR:
			if not is_passive:
				var cur: int = int(inv.armor)
				button_pressed = (cur == value)
				if _frame: _frame.visible = button_pressed

		EquipType.BOOTS:
			if not is_passive:
				var cur: int = int(inv.boots)
				button_pressed = (cur == value)
				if _frame: _frame.visible = button_pressed

		# --- passive, stufige Slots (nur Anzeige) ---
		EquipType.AMMO:
			# Kind → Kerne-Tasche; Erwachsen → Köcher (0..3 inkl. „keine“)
			var is_child: bool = (int(inv.age) == int(Inventory.Age.CHILD))
			var seed_lvl: int = int(inv.seed_pouch_level)  # 0..3
			var quiver_lvl: int = int(inv.quiver_level)    # 0..3

			var lvl: int = 0
			if is_child:
				lvl = seed_lvl
			else:
				lvl = quiver_lvl

			button_pressed = (lvl == value)
			if _frame: _frame.visible = (lvl == value)

		EquipType.BOMB_BAG:
			var bb: int = int(inv.bomb_bag_level)  # 0..3
			button_pressed = (bb == value)
			if _frame: _frame.visible = (bb == value)

		EquipType.DIVE_SCALE:
			var ds: int = int(inv.dive_scale)  # 0..2 (0=keine,1=silber,2=gold)
			button_pressed = (ds == value)
			if _frame: _frame.visible = (ds == value)

		EquipType.STRENGTH:
			var st: int = int(inv.strength)  # 0=keine,1=Armband,2=Kraft,3=Titan
			button_pressed = (st == value)
			if _frame: _frame.visible = (st == value)

func _on_pressed() -> void:
	if is_passive or disabled:
		return
	var inv: Inventory = get_node("/root/Inventar") as Inventory
	match type:
		EquipType.SWORD:  inv.equip_sword(value)
		EquipType.SHIELD: inv.equip_shield(value)
		EquipType.ARMOR:  inv.equip_armor(value)
		EquipType.BOOTS:  inv.equip_boots(value)
		_:
			pass  # passive Typen: keine Aktion
