extends CanvasLayer
class_name HUD

@export var db: ItemDatabase

# --- Node-Refs (wie in deinem Baum) ---
@onready var b_icon: TextureRect  = %"B Icon"
@onready var c_left:  TextureRect = %CLeft_Icon
@onready var c_right: TextureRect = %CRight_Icon
@onready var c_down:  TextureRect = %"CDown_ Icon"
@onready var a_text: Label = %A_text
@onready var c_left_count:  Label = $CGroup/Control2/CLeft/CLeft_count
@onready var c_right_count: Label = $CGroup/Control3/CRight/CRight_count
@onready var c_down_count:  Label = $CGroup/Control/CDown/CDown_count

func _ready() -> void:
	#TEST – später entfernen:
	Inventar.equip_c = {"left":"deku_nuss", "right":"bombe", "down":"bogen"}

# Besitzt/Anzahl über Inventory setzen (nicht InventoryState)
	Inventar.acquire("deku_nuss")
	Inventar.acquire("bombe")
	Inventar.set_amount("deku_nuss", 5)
	Inventar.set_amount("bombe", 3)
	Inventar.set_arrows(10)

# UI refresh
	Inventar.emit_signal("changed")
	
	
	print("HUD db:", db)
	if db:
		print("HUD db items:", db.items.size())
	for id in ["deku_nuss","bombe","bogen"]:
		var it = db.get_item(id)
		print("DB check", id, "-> item:", it, " icon:", (it.icon if it else null))




	add_to_group("hud")
	if a_text:
		a_text.text = ""

	# InventoryState anbinden (Autoload)
	if typeof(Inventar) != TYPE_NIL:
		Inventar.changed.connect(_on_inv_changed)
		_on_inv_changed()

	

# ---------- Helpers ----------
func _get_variant_for(id: String) -> String:
	# Bogen hat keine Varianten in deinem System
	if id == "bogen":
		return "default"
	# defensiv: falls 'variants' im Autoload nicht (mehr) existiert
	var v_any = Inventar.get("variants")  # returns null, if missing
	if typeof(v_any) == TYPE_DICTIONARY:
		return String((v_any as Dictionary).get(id, "default"))
	return "default"

func _get_amount_for(id: String) -> int:
	# Pfeile kommen aus eigener Property
	if id == "bogen":
		return int(Inventar.arrows)
	# sonst deine vorhandene Helper-Funktion nutzen
	if Inventar.has_method("get_amount"):
		return int(Inventar.get_amount(id))
	# Fallback: direkt owned lesen, wenn vorhanden
	var owned_any = Inventar.get("owned")
	if typeof(owned_any) == TYPE_DICTIONARY:
		return int((owned_any as Dictionary).get(id, 0))
	return 0

# ---------- Render ----------
func _on_inv_changed() -> void:
	if db == null:
		push_warning("HUD: db nicht gesetzt -> keine Icons")
		return

	# B-Icon
	if b_icon != null:
		var b_id := String(Inventar.equip_b)
		var b_tex: Texture2D = null
		if b_id != "":
			var b_var := _get_variant_for(b_id)
			b_tex = db.get_icon(b_id, b_var)
		b_icon.texture = b_tex

	# C-Icons
	_set_c_slot("left",  c_left)
	_set_c_slot("right", c_right)
	_set_c_slot("down",  c_down)

func _set_c_slot(dir: String, node: TextureRect) -> void:
	if node == null or db == null:
		return

	var id: String = String(Inventar.equip_c.get(dir, ""))
	if id == "":
		node.texture = null
		_set_c_count(dir, 0)
		return

	var variant := _get_variant_for(id)
	var tex: Texture2D = db.get_icon(id, variant)
	node.texture = tex

	var amount: int = _get_amount_for(id)
	_set_c_count(dir, amount)

func _set_c_count(dir: String, n: int) -> void:
	var label: Label = null
	match dir:
		"left":  label = c_left_count
		"right": label = c_right_count
		"down":  label = c_down_count
	if label:
		label.text = (str(n) if n > 0 else "")
		
# --- Action Prompt (A-Taste) ---
func set_action_text(text: String) -> void:
	if a_text:
		a_text.text = text
		a_text.visible = text != ""
