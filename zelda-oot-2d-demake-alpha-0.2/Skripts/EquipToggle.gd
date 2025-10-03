extends TextureButton
class_name EquipToggle

# Welche Kategorie schaltet dieser Button?
enum EquipType { SWORD, SHIELD, ARMOR, BOOTS }
@export var type: EquipType = EquipType.SWORD

# Welchen Enum-Wert setzt er? z. B. Inventar.Sword.KOKIRI
@export var value: int = 0

# Welche Besitz-ID muss vorhanden sein? z. B. "kokiri_schwert"
@export var owned_id: String = ""

# Altersanforderungen (nur setzen, wenn nötig)
@export var requires_child: bool = false
@export var requires_adult: bool = false

func _ready() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	pressed.connect(_on_accept)
	Inventar.changed.connect(_refresh)
	_refresh()

func _gui_input(e: InputEvent) -> void:
	# Nur A / Enter (ui_accept) selektiert
	if e.is_action_pressed("ui_accept"):
		_on_accept()

func _on_accept() -> void:
	if disabled:
		return
	match type:
		EquipType.SWORD:
			if owned_id == "" or Inventar.has(owned_id):
				Inventar.equip_sword(value)
				# nur beim Schwert: B-Icon setzen
				Inventar.set_equip_b(owned_id)  # z. B. "kokiri_schwert"
		EquipType.SHIELD:
			if owned_id == "" or Inventar.has(owned_id):
				Inventar.equip_shield(value)
		EquipType.ARMOR:
			Inventar.equip_armor(value)
		EquipType.BOOTS:
			if owned_id == "" or Inventar.has(owned_id):
				Inventar.equip_boots(value)

func _refresh() -> void:
	# Alterscheck
	if requires_child and Inventar.age != Inventar.Age.CHILD:
		disabled = true
		button_pressed = false
		return
	if requires_adult and Inventar.age != Inventar.Age.ADULT:
		disabled = true
		button_pressed = false
		return

	# Besitzcheck
	var has_item := true
	if owned_id != "":
		has_item = Inventar.has(owned_id)
	disabled = not has_item

	# pressed-State
	match type:
		EquipToggle.EquipType.SWORD:
			button_pressed = (Inventar.sword == value)
		EquipToggle.EquipType.SHIELD:
			button_pressed = (Inventar.shield == value)
		EquipToggle.EquipType.ARMOR:
			button_pressed = (Inventar.armor == value)
		EquipToggle.EquipType.BOOTS:
			button_pressed = (Inventar.boots == value)
