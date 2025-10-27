extends TextureButton
class_name EquipToggle

enum EquipType { SWORD, SHIELD, ARMOR, BOOTS, AMMO, BOMB_BAG, DIVE_SCALE, STRENGTH }

@export var type: EquipType = EquipType.SWORD
@export var value: int = 0
@export var owned_id: String = ""
@export var is_passive: bool = false

# Für passive Icons (Index == Level)
@export var passive_ids: Array[String] = []          # allgemeines Array (z. B. Bombenbeutel/Stärke/Tauchen)
@export var passive_ids_child: Array[String] = []    # AMMO (Kind)
@export var passive_ids_adult: Array[String] = []    # AMMO (Erwachsen)

@onready var _frame: Control = get_node_or_null(^"Frame")
@onready var _icon_node: Node = get_node_or_null(^"Icon")
@onready var _mgr: EquipmentManager = get_node_or_null(^"/root/EquipMgr")

func _ready() -> void:
	# passive Anzeige für diese Typen erzwingen
	if _is_forced_passive_type():
		is_passive = true

	toggle_mode = not is_passive
	focus_mode = Control.FOCUS_ALL
	if is_passive:
		focus_mode = Control.FOCUS_NONE

	if _frame:
		_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _icon_node is Control:
		var c := _icon_node as Control
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Manager-Signale
	if _mgr:
		if not _mgr.changed.is_connected(_refresh):
			_mgr.changed.connect(_refresh)
		if not _mgr.equipped_slot_changed.is_connected(_on_equipped_changed):
			_mgr.equipped_slot_changed.connect(_on_equipped_changed)
		if not _mgr.meta_changed.is_connected(_refresh):
			_mgr.meta_changed.connect(_refresh)

	# eigener Klick (nur für aktive)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

	_fix_frame_visuals()
	_refresh()

func _is_forced_passive_type() -> bool:
	return type == EquipType.AMMO \
		or type == EquipType.BOMB_BAG \
		or type == EquipType.DIVE_SCALE \
		or type == EquipType.STRENGTH

func _on_equipped_changed(slot: String, _v: int) -> void:
	var needs_refresh := false
	if slot == "sword" and type == EquipType.SWORD:
		needs_refresh = true
	elif slot == "shield" and type == EquipType.SHIELD:
		needs_refresh = true
	elif slot == "armor" and type == EquipType.ARMOR:
		needs_refresh = true
	elif slot == "boots" and type == EquipType.BOOTS:
		needs_refresh = true

	if needs_refresh:
		_refresh()

func _refresh() -> void:
	if _mgr == null:
		return

	# Passive sind reine Anzeige
	if is_passive:
		disabled = true
	else:
		# aktive Buttons ggf. per owned_id sperren
		disabled = false
		if owned_id != "":
			if not _mgr.has(owned_id):
				disabled = true

	var selected := false

	# Aktive Slots → Auswahlzustand
	if type == EquipType.SWORD:
		if not is_passive:
			selected = (_mgr.get_sword() == value)
	elif type == EquipType.SHIELD:
		if not is_passive:
			selected = (_mgr.get_shield() == value)
	elif type == EquipType.ARMOR:
		if not is_passive:
			selected = (_mgr.get_armor() == value)
	elif type == EquipType.BOOTS:
		if not is_passive:
			selected = (_mgr.get_boots() == value)
	else:
		# Passive: Icon setzen + selected zurück
		selected = _refresh_passive_icon_and_state()

	button_pressed = selected

	# Rahmen nur für aktive
	if _frame:
		if is_passive:
			_frame.visible = false
		else:
			_frame.visible = selected

func _refresh_passive_icon_and_state() -> bool:
	# Setzt Icon anhand Level und liefert "selected" (ob value == level)
	if _mgr == null:
		_apply_icon("")
		return false

	var level := 0
	var icon_id := ""

	if type == EquipType.AMMO:
		level = _mgr.get_ammo_level()
		var arr: Array[String] = passive_ids
		# Alter berücksichtigen
		if _mgr.is_adult():
			if passive_ids_adult.size() > 0:
				arr = passive_ids_adult
		else:
			if passive_ids_child.size() > 0:
				arr = passive_ids_child
		if level >= 0 and level < arr.size():
			icon_id = arr[level]

	elif type == EquipType.BOMB_BAG:
		level = _mgr.get_bomb_bag_level()
		if level >= 0 and level < passive_ids.size():
			icon_id = passive_ids[level]

	elif type == EquipType.DIVE_SCALE:
		level = _mgr.get_dive_scale_level()
		if level >= 0 and level < passive_ids.size():
			icon_id = passive_ids[level]

	elif type == EquipType.STRENGTH:
		level = _mgr.get_strength_level()
		if level >= 0 and level < passive_ids.size():
			icon_id = passive_ids[level]

	_apply_icon(icon_id)

	# Debug ohne ?-Operator
	var tname := "?"
	if type == EquipType.AMMO:
		tname = "AMMO"
	elif type == EquipType.BOMB_BAG:
		tname = "Bomben"
	elif type == EquipType.DIVE_SCALE:
		tname = "Tauchen"
	elif type == EquipType.STRENGTH:
		tname = "Stärke"

	if type == EquipType.AMMO:
		var age_str := "adult"
		if not _mgr.is_adult():
			age_str = "child"
		print_debug("[PASSIVE] ", tname, " age=", age_str, " level=", level, " id=", icon_id)
	else:
		print_debug("[PASSIVE] ", tname, " level=", level, " id=", icon_id)

	# Immer ein bool zurückgeben
	return level == value

func _apply_icon(id: String) -> void:
	if not (_icon_node is TextureRect):
		return
	var tr := _icon_node as TextureRect
	if id == "" or _mgr == null:
		tr.texture = null
		return
	var tex := _mgr.icon_for(id)
	tr.texture = tex

func _on_pressed() -> void:
	# Nur aktive Buttons reagieren auf Klick
	if is_passive or disabled or _mgr == null:
		return

	if type == EquipType.SWORD:
		_mgr.equip_sword(value)
	elif type == EquipType.SHIELD:
		_mgr.equip_shield(value)
	elif type == EquipType.ARMOR:
		_mgr.equip_armor(value)
	elif type == EquipType.BOOTS:
		_mgr.equip_boots(value)
	# passive Typen: keine Aktion

func _fix_frame_visuals() -> void:
	# Rahmen zuverlässig oben und vollflächig
	if _frame and _frame is Control:
		var f := _frame as Control
		f.z_index = 100
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.anchor_left = 0.0
		f.anchor_top = 0.0
		f.anchor_right = 1.0
		f.anchor_bottom = 1.0
		f.offset_left = 0.0
		f.offset_top = 0.0
		f.offset_right = 0.0
		f.offset_bottom = 0.0
