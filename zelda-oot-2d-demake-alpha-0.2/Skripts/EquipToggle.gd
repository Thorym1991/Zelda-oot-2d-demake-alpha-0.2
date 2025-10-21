extends TextureButton
class_name EquipToggle

enum EquipType { SWORD, SHIELD, ARMOR, BOOTS, AMMO, BOMB_BAG, DIVE_SCALE, STRENGTH }

@export var type: EquipType = EquipType.SWORD
@export var value: int = 0                     # Enum-Index je nach Slot
@export var owned_id: String = ""              # Besitzprüfung für aktive Items
@export var is_passive: bool = false           # reine Anzeige?

@export var manager_path: NodePath = ^"/root/EquipMgr"  # <— HIER
var _mgr: EquipmentManager                                    # <— HIER

@onready var _frame: Control = get_node_or_null(^"Frame")
@onready var _icon_node: Node = get_node_or_null(^"Icon")

@export var passive_ids: Array[String] = []
@export var passive_ids_child: Array[String] = []
@export var passive_ids_adult: Array[String] = []

func _ready() -> void:
	print("[EquipToggle] ready name=", name)
	# Manager auflösen (Export-Pfad ODER Fallback auf Autoload)
	_mgr = get_node_or_null(manager_path) as EquipmentManager
	if _mgr == null:
		_mgr = get_node_or_null(^"/root/EquipMgr") as EquipmentManager
	print("[EquipToggle] mgr=", _mgr)

	# pressed-Handler verbinden
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	print("[EquipToggle] pressed connected? ", pressed.is_connected(_on_pressed))

	# Rest…
	_refresh()
	# Passive erzwingen für Level-Anzeigen
	if type in [EquipType.AMMO, EquipType.BOMB_BAG, EquipType.DIVE_SCALE, EquipType.STRENGTH]:
		is_passive = true

	toggle_mode = not is_passive
	focus_mode = Control.FOCUS_ALL if not is_passive else Control.FOCUS_NONE
	if _frame: _frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _icon_node is Control: (_icon_node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	# --- Manager holen: erst Export, dann Fallback über Autoload-Namen ---
	_mgr = get_node_or_null(manager_path) as EquipmentManager
	if _mgr == null:
		_mgr = get_node_or_null(^"/root/EquipMgr") as EquipmentManager
	if _mgr == null:
		push_error("[EquipToggle] EquipMgr nicht gefunden. Setze 'manager_path' auf /root/EquipMgr oder prüfe Autoload.")
	else:
		if not _mgr.changed.is_connected(_refresh):
			_mgr.changed.connect(_refresh)
		if not _mgr.equipped_slot_changed.is_connected(_on_equipped_slot_changed):
			_mgr.equipped_slot_changed.connect(_on_equipped_slot_changed)

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	_refresh()

func _on_testpressed() -> void:
	print("[EquipToggle] PRESSED type=", type, " value=", value, " disabled=", disabled, " mgr=", _mgr)
	if is_passive or disabled or _mgr == null: 
		return
	match type:
		EquipType.SWORD:  _mgr.equip_sword(value)
		EquipType.SHIELD: _mgr.equip_shield(value)
		EquipType.ARMOR:  _mgr.equip_armor(value)
		EquipType.BOOTS:  _mgr.equip_boots(value)
	# Passive erzwingen für Level-Anzeigen
	if type in [EquipType.AMMO, EquipType.BOMB_BAG, EquipType.DIVE_SCALE, EquipType.STRENGTH]:
		is_passive = true

	toggle_mode = not is_passive
	focus_mode = Control.FOCUS_ALL if not is_passive else Control.FOCUS_NONE
	if _frame: _frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _icon_node is Control: (_icon_node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	_mgr = get_node_or_null(manager_path) as EquipmentManager
	if _mgr:
		if not _mgr.changed.is_connected(_refresh):
			_mgr.changed.connect(_refresh)
		if not _mgr.equipped_slot_changed.is_connected(_on_equipped_slot_changed):
			_mgr.equipped_slot_changed.connect(_on_equipped_slot_changed)

	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	_refresh()

func _refresh() -> void:
	if _mgr == null:
		return

	# Standard: Frame aus
	if _frame:
		_frame.visible = false

	# Passive Buttons: nur Anzeige
	disabled = (owned_id != "" and not _mgr.has(owned_id)) if _mgr else true

	# Besitz-Check nur für aktive Equip-Slots
	if owned_id != "" and not _is_forced_passive_type():
		if not _mgr.has(owned_id):
			disabled = true

	match type:
		EquipType.SWORD:
			if not is_passive:
				button_pressed = (_mgr.get_sword() == value)
		EquipType.SHIELD:
			if not is_passive:
				button_pressed = (_mgr.get_shield() == value)
		EquipType.ARMOR:
			if not is_passive:
				button_pressed = (_mgr.get_armor() == value)
		EquipType.BOOTS:
			if not is_passive:
				button_pressed = (_mgr.get_boots() == value)

	# passive Anzeigen (nur Status, kein Klick)
		EquipType.AMMO:
			button_pressed = (_mgr.get_ammo_level() == value)
		EquipType.BOMB_BAG:
			button_pressed = (_mgr.get_bomb_bag_level() == value)
		EquipType.DIVE_SCALE:
			button_pressed = (_mgr.get_dive_scale_level() == value)
		EquipType.STRENGTH:
			button_pressed = (_mgr.get_strength_level() == value)


	if _frame and not is_passive:
		_frame.visible = button_pressed

func _on_pressed() -> void:
	print("[EquipToggle] _on_pressed name=", name, " type=", type, " value=", value, " mgr=", _mgr, " disabled=", disabled, " passive=", is_passive)
	if is_passive or disabled or _mgr == null:
		return
	match type:
		EquipType.SWORD:  _mgr.equip_sword(value)
		EquipType.SHIELD: _mgr.equip_shield(value)
		EquipType.ARMOR:  _mgr.equip_armor(value)
		EquipType.BOOTS:  _mgr.equip_boots(value)
		_:
			pass

func _on_equipped_slot_changed(slot: String, _v: int) -> void:
	match type:
		EquipType.SWORD:  if slot == "sword":  _refresh()
		EquipType.SHIELD: if slot == "shield": _refresh()
		EquipType.ARMOR:  if slot == "armor":  _refresh()
		EquipType.BOOTS:  if slot == "boots":  _refresh()

	if _frame:
		_frame.visible = button_pressed
	if not _frame:
		self.modulate = Color(1, 1, 1, 0.85)


func _is_forced_passive_type() -> bool:
	return type == EquipType.AMMO \
		or type == EquipType.BOMB_BAG \
		or type == EquipType.DIVE_SCALE \
		or type == EquipType.STRENGTH
