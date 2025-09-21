extends CanvasLayer
class_name HUD

@export var db: ItemDatabase

# --- Node-Refs (genau wie in deinem Baum) ---
@onready var b_icon: TextureRect  = %"B Icon"
@onready var c_left:  TextureRect = %CLeft_Icon
@onready var c_right: TextureRect = %CRight_Icon
@onready var c_down:  TextureRect = %"CDown_ Icon"
@onready var a_text: Label = %A_text
@onready var c_left_count:  Label = $CGroup/Control2/CLeft/CLeft_count
@onready var c_right_count: Label = $CGroup/Control3/CRight/CRight_count
@onready var c_down_count:  Label = $CGroup/Control/CDown/CDown_count

func _ready() -> void:
	print("HUD db:", db)
	if db:
		print("HUD db items:", db.items.size())
	for id in ["deku_nuss","bombe","bogen"]:
		var it = db.get_item(id)
		print("DB check", id, "-> item:", it, " icon:", (it.icon if it else null))
	
	
	add_to_group("hud")
	if a_text:
		a_text.text = ""   # Default leeren
		
	# Wichtig: mit InventoryState verbinden + einmal initial zeichnen
	if Engine.has_singleton("InventoryState") or typeof(InventoryState) != TYPE_NIL:
		InventoryState.changed.connect(_on_inv_changed)
		_on_inv_changed() # initial
	
	# TEST — später wieder entfernen:
	InventoryState.equip_c = {"left":"deku_nuss", "right":"bombe", "down":"bogen"}
	InventoryState.owned["deku_nuss"] = 5
	InventoryState.owned["bombe"] = 3
	InventoryState.arrows = 10
	InventoryState.emit_signal("changed")

# --- öffentliche API: vom Player aufrufbar ---
func set_action_text(t: String) -> void:
	if a_text:
		a_text.text = t

# --- Icons für B und C aktualisieren (falls db gesetzt ist) ---
func _on_inv_changed() -> void:
	if db == null: 
		push_warning("HUD: db nicht gesetzt -> keine Icons")
		return
	_set_c_slot("left",  c_left)
	_set_c_slot("right", c_right)
	_set_c_slot("down",  c_down)
	# (B/A kannst du zusätzlich machen)

	# B-Icon
	if b_icon != null:
		var b_id := String(InventoryState.equip_b)
		var b_var := String(InventoryState.variants.get(b_id, "default"))
		var b_tex: Texture2D = null
		if b_id != "":
			b_tex = db.get_icon(b_id, b_var)
		b_icon.texture = b_tex

	# C-Icons
	_set_c_slot("left",  c_left)
	_set_c_slot("right", c_right)
	_set_c_slot("down",  c_down)

func _set_c_slot(dir: String, node: TextureRect) -> void:
	if node == null or db == null:
		return

	var id := String(InventoryState.equip_c.get(dir, ""))
	if id == "":
		node.texture = null
		_set_c_count(dir, 0)
		return

	# VARIANTE: Bogen ignoriert Varianten → immer "default"
	var variant := "default"
	if id != "bogen":
		variant = String(InventoryState.variants.get(id, "default"))

	var tex: Texture2D = db.get_icon(id, variant)
	node.texture = tex

	# Menge berechnen
	var amount := (InventoryState.arrows if id == "bogen" else InventoryState.get_amount(id))
	_set_c_count(dir, amount)

func _set_c_count(dir: String, n: int) -> void:
	var label: Label = null
	match dir:
		"left":  label = c_left_count
		"right": label = c_right_count
		"down":  label = c_down_count

	if label:
		label.text = (str(n) if n > 0 else "")
		
		
