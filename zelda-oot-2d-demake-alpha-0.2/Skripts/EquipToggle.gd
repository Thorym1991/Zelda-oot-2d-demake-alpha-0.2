extends TextureButton
class_name EquipToggle

# --- Equippable ---
enum EquipType { SWORD, SHIELD, ARMOR, BOOTS }
@export var type: EquipType = EquipType.SWORD
@export var value: int = 0
@export var owned_id: String = ""  # Inventar-ID für equippable

# --- Passive-Mode ---
# Wenn != [], läuft der Slot im PASSIVE-MODE (höchste Stufe wird angezeigt)
@export var passive_ids: Array[String] = []
@export var passive_ids_child: Array[String] = []
@export var passive_ids_adult: Array[String] = []

# Name/Pfad des Icon-Knotens unter diesem Button
@export var icon_node_path: NodePath = ^"Icon"
@onready var _icon: Node = get_node_or_null(icon_node_path)

# Altersanforderungen
@export var requires_child: bool = false
@export var requires_adult: bool = false

func _use_passive_mode() -> bool:
	return passive_ids.size() > 0 or passive_ids_child.size() > 0 or passive_ids_adult.size() > 0

func _update_passive_meta() -> void:
	if _icon == null: 
		return
	var ids: Array[String] = []
	if passive_ids_child.size() > 0 or passive_ids_adult.size() > 0:
		var is_child: bool = (typeof(Inventar) != TYPE_NIL and Inventar.age == Inventar.Age.CHILD)
		ids = passive_ids_child if is_child else passive_ids_adult   # <-- hier statt "? :"
	else:
		ids = passive_ids
	_icon.set_meta("item_ids", ids)

func _ready() -> void:
	set_meta("_handler_set", true)

	# Alters-/Sichtbarkeits-Gating einmal initial werten
	if typeof(Inventar) != TYPE_NIL:
		Inventar.changed.connect(_refresh)
		Inventar.equipment_changed.connect(_refresh)

	if _use_passive_mode():
		# PASSIVE MODE
		toggle_mode = false
		focus_mode = Control.FOCUS_ALL   # ← Fokus erlauben
		disabled = false                 # ← NICHT disabled, sonst kein Fokus
		_update_passive_meta()
		_refresh()
		return

	# EQUIPPABLE MODE
	# Falls item_id im Node fehlt, aus owned_id ergänzen (für Icon-Loader)
	if owned_id != "" and (not has_meta("item_id") or String(get_meta("item_id")) == ""):
		set_meta("item_id", owned_id)

	toggle_mode = true
	focus_mode = Control.FOCUS_ALL

	# WICHTIG: Signal nur EINMAL verbinden – auf self (TextureButton)!
	if not pressed.is_connected(_on_accept):
		pressed.connect(_on_accept)

	_refresh()

func _refresh() -> void:
	if typeof(Inventar) != TYPE_NIL:
		if requires_child and Inventar.age != Inventar.Age.CHILD:
			visible = true
			disabled = true
			modulate.a = 0.35
		return
	if requires_adult and Inventar.age != Inventar.Age.ADULT:
		visible = true
		disabled = true
		modulate.a = 0.35
		return

# freigegeben
	visible = true
	disabled = false
	modulate.a = 1.0

	# --- EQUIPPABLE: Besitz-/Pressed-Status aktualisieren ---
	# Besitzcheck
	var has_item: bool = true
	if owned_id != "":
		has_item = Inventar.has(owned_id)
	disabled = not has_item

	# pressed-State je nach Typ
	if typeof(Inventar) != TYPE_NIL:
		match type:
			EquipType.SWORD:
				button_pressed = (Inventar.sword == value)
			EquipType.SHIELD:
				button_pressed = (Inventar.shield == value)
			EquipType.ARMOR:
				button_pressed = (Inventar.armor == value)
			EquipType.BOOTS:
				button_pressed = (Inventar.boots == value)

func _gui_input(e: InputEvent) -> void:
	if _use_passive_mode():
		# Fokus ja, Aktion nein (hier könntest du später Tooltip/Info öffnen)
		# if e.is_action_pressed("ui_accept"): show_info(...)
		return
	if e.is_action_pressed("ui_accept") and not disabled:
		_on_accept()

func _on_accept() -> void:
	if _use_passive_mode() or disabled:
		return

	match type:
		EquipType.SWORD:
			if owned_id == "" or Inventar.has(owned_id):
				Inventar.equip_sword(value)
				if owned_id != "":
					Inventar.set_equip_b(owned_id) # optional: auf Quickslot B
		EquipType.SHIELD:
			if owned_id == "" or Inventar.has(owned_id):
				Inventar.equip_shield(value)
		EquipType.ARMOR:
			Inventar.equip_armor(value)
		EquipType.BOOTS:
			if owned_id == "" or Inventar.has(owned_id):
				Inventar.equip_boots(value)

	_refresh()
