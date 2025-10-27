extends CanvasLayer
class_name HUD
@onready var EquipMgr: EquipmentManager = get_node(^"/root/EquipMgr")

@export var db: ItemDatabase
@export var db_gear_equippable: Resource
@export var db_gear_passive: Resource

# --- Node-Refs ---

@onready var b_icon: TextureRect  = %"B Icon"
@onready var c_left:  TextureRect = %CLeft_Icon
@onready var c_right: TextureRect = %CRight_Icon
@onready var c_down:  TextureRect = %"CDown_ Icon"
@onready var a_text: Label = %A_text
@onready var c_left_count:  Label = $CGroup/Control2/CLeft/CLeft_count
@onready var c_right_count: Label = $CGroup/Control3/CRight/CRight_count
@onready var c_down_count:  Label = $CGroup/Control/CDown/CDown_count
@onready var b_knopf: TextureRect = $"Root/ActionGroup/B Knopf"

func _ready() -> void:
	if EquipMgr:
		if not EquipMgr.changed.is_connected(_on_inv_changed):
			EquipMgr.changed.connect(_on_inv_changed)
		if not EquipMgr.equipped_slot_changed.is_connected(_on_equipped_slot_changed):
			EquipMgr.equipped_slot_changed.connect(_on_equipped_slot_changed)
		if not EquipMgr.ammo_changed.is_connected(_on_ammo_changed):
			EquipMgr.ammo_changed.connect(_on_ammo_changed)
		if not EquipMgr.meta_changed.is_connected(_on_inv_changed):
			EquipMgr.meta_changed.connect(_on_inv_changed)

	# HUD zur Gruppe hinzufügen (Player holt sich das später)
	add_to_group("hud")
	if a_text:
		a_text.text = ""

	# Inventar-Signale verbinden (robust, keine Doppel-Verbindungen)
	if typeof(Inventar) != TYPE_NIL:
		if not Inventar.changed.is_connected(_on_inv_changed):
			Inventar.changed.connect(_on_inv_changed)

		if Inventar.has_signal("equipped_slot_changed"):
			if not Inventar.equipped_slot_changed.is_connected(_on_equipped_slot_changed):
				Inventar.equipped_slot_changed.connect(_on_equipped_slot_changed)

		if Inventar.has_signal("ammo_changed"):
			if not Inventar.ammo_changed.is_connected(_on_ammo_changed):
				Inventar.ammo_changed.connect(_on_ammo_changed)

		if Inventar.has_signal("owned_changed"):
			if not Inventar.owned_changed.is_connected(_on_owned_changed):
				Inventar.owned_changed.connect(_on_owned_changed)

		if Inventar.has_signal("meta_changed"):
			if not Inventar.meta_changed.is_connected(_on_inv_changed):
				Inventar.meta_changed.connect(_on_inv_changed)

	# ---------- DEBUG-Setup (nur im Debug-Build) ----------
	if OS.is_debug_build():
		Inventar.acquire("deku_nuss")
		Inventar.acquire("bombe")
		Inventar.acquire("bogen")
		Inventar.set_amount("deku_nuss", 5)
		Inventar.set_amount("bombe", 3)
		Inventar.set_arrows(10)
		Inventar.set_equip_c("left",  "deku_nuss")
		Inventar.set_equip_c("right", "bombe")
		Inventar.set_equip_c("down",  "bogen")

	# Erstes Rendern
	_on_inv_changed()

	# Debug-Ausgabe zur DB
	print("HUD db:", db)
	if db:
		print("HUD db items:", db.items.size())
	for id in ["deku_nuss","bombe","bogen"]:
		var it = db.get_item(id)
		print("DB check", id, "-> item:", it, " icon:", (it.icon if it else null))

# ---------- Helpers ----------
func _get_variant_for(id: String) -> String:
	if id == "bogen":
		return "default"
	var v_any = Inventar.get("variants")
	if typeof(v_any) == TYPE_DICTIONARY:
		return String((v_any as Dictionary).get(id, "default"))
	return "default"

func _get_amount_for(id: String) -> int:
	if id == "bogen":
		return int(Inventar.arrows)
	if Inventar.has_method("get_amount"):
		return int(Inventar.get_amount(id))
	var owned_any = Inventar.get("owned")
	if typeof(owned_any) == TYPE_DICTIONARY:
		return int((owned_any as Dictionary).get(id, 0))
	return 0

# ---------- Render ----------
func _on_inv_changed() -> void:
	_refresh_b_icon()
	_set_c_slot("left",  c_left)
	_set_c_slot("right", c_right)
	_set_c_slot("down",  c_down)

func _set_c_slot(dir: String, node: TextureRect) -> void:
	if node == null or db == null or EquipMgr == null:
		return

	var id := EquipMgr.get_c(dir)

	if id != "":
		node.texture = db.get_icon(id, _get_variant_for(id))
		var amount := 0
		if id == "bogen":
			amount = EquipMgr.get_arrows()
		else:
			amount = EquipMgr.get_amount(id)
		_set_c_count(dir, amount)
	else:
		node.texture = null
		_set_c_count(dir, 0)

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

func _refresh_b_icon() -> void:
	print("[HUD] _refresh_b_icon() called. db=", db, " b_icon=", b_icon, " EquipMgr=", EquipMgr)
	if b_icon == null:
		push_warning("HUD: b_icon ist null – Node-Pfad prüfen!"); return
	if EquipMgr == null:
		push_warning("HUD: EquipMgr ist null"); return
	# Wenn du den Gear-DB-Fallback nutzt:
	# if db == null and db_gear_equippable == null:
	#     push_warning("HUD: keine DBs zugewiesen"); return

	var id: String = EquipMgr.get_b_icon_id()
	print("[HUD] B-Icon ID:", id)

	var tex: Texture2D = null
	if id != "" and db != null:
		tex = db.get_icon(id, "default")
	if tex == null:
		tex = _icon_from_gear_dbs(id)  # nur, wenn du den Fallback eingebaut + zugewiesen hast

	print("[HUD] B-Icon TEX:", tex)
	b_icon.texture = tex


func _on_equipped_slot_changed(slot: String, v: int) -> void:
	print("[HUD] equipped_slot_changed:", slot, v)
	_refresh_b_icon()  # immer refreshen – passt


func _on_ammo_changed(_id: String, _amount: int) -> void:
	# C-Slots neu zeichnen (Icons/Counts)
	_on_inv_changed()

func _on_owned_changed(_id: String, _has_item: bool) -> void:
	# Falls ein C-Item neu erworben/verloren wurde
	_on_inv_changed()

func _icon_from_gear_dbs(id: String) -> Texture2D:
	if id == "":
		return null
	var tex: Texture2D = null
	if db_gear_equippable != null:
		tex = _find_icon_in_res_recursive(db_gear_equippable, id, 0)
		if tex != null: return tex
	if db_gear_passive != null:
		tex = _find_icon_in_res_recursive(db_gear_passive, id, 0)
		if tex != null: return tex
	return null

func _find_icon_in_res_recursive(res: Variant, wanted_id: String, depth: int = 0) -> Texture2D:
	if res == null or depth > 8:
		return null
	if res is Resource:
		var r := res as Resource
		for key in ["ID","id","Name","name"]:
			var v = r.get(key)
			if v != null and String(v) == wanted_id:
				for ik in ["Icon","icon","Texture","texture"]:
					var iv = r.get(ik)
					if iv is Texture2D: return iv
		for p in r.get_property_list():
			var pname := String(p.get("name","")); if pname == "": continue
			var pv = r.get(pname)
			if pv is Array or pv is Resource or pv is Dictionary:
				var f := _find_icon_in_res_recursive(pv, wanted_id, depth+1)
				if f != null: return f
	if res is Array:
		for it in (res as Array):
			var f2 := _find_icon_in_res_recursive(it, wanted_id, depth+1)
			if f2 != null: return f2
	if res is Dictionary:
		for k in (res as Dictionary).keys():
			var f3 := _find_icon_in_res_recursive((res as Dictionary)[k], wanted_id, depth+1)
			if f3 != null: return f3
	return null
