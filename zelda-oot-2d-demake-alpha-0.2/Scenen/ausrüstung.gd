# res://Skripts/AusruestungLean.gd
extends Control

@export var rows: Array[NodePath] = []            # deine 4 Reihen
@export var item_groups: Array[NodePath] = []     # Wurzeln, unter denen Icons/Buttons liegen
@export var db_gear_equippable: Resource
@export var db_gear_passive: Resource
@export var gray_out_locked := true
@export var placeholder_empty: Texture2D = null

# --- IDs für passive Stufen (falls du sie im Editor NICHT befüllst) ---
const PASSIVE_IDS_AMMO_CHILD := [
	"seed_pouch_none", "seed_pouch_small", "seed_pouch_medium", "seed_pouch_max"  # 0..3
]
const PASSIVE_IDS_AMMO_ADULT := [
	"quiver_none", "quiver_small", "quiver_medium", "quiver_max"                  # 0..3
]
const PASSIVE_IDS_BOMB_BAG := [
	"bomb_bag_none", "bomb_bag_small", "bomb_bag_medium", "bomb_bag_max"          # 0..3
]
const PASSIVE_IDS_DIVE := [
	"", "silver_scale", "gold_scale"                                              # 0..2 (0 = kein Icon)
]
const PASSIVE_IDS_STRENGTH := [
	"", "goron_bracelet", "power_gauntlets", "titan_gauntlets"                    # 0..3
]

# EquipType (spiegelt deine Buttons)
const ET_SWORD := 0
const ET_SHIELD := 1
const ET_ARMOR := 2
const ET_BOOTS := 3
const ET_AMMO := 4
const ET_BOMB_BAG := 5
const ET_DIVE_SCALE := 6
const ET_STRENGTH := 7

var _inv: Inventory
var _group_by_row := {}
var owned_id_aliases: Dictionary = {}  # falls du Aliase pflegst

func _ready() -> void:
	_inv = get_node("/root/Inventar") as Inventory
	if _inv:
		if not _inv.changed.is_connected(_on_inv):
			_inv.changed.connect(_on_inv)
		if not _inv.equipment_changed.is_connected(_on_inv):
			_inv.equipment_changed.connect(_on_inv)
	_on_inv()

func _on_inv() -> void:
	_refresh_icons()
	_wire_groups()
	_ensure_debug_actions()
	set_process_input(true)

# ------------------ Icons / Buttons ------------------

func _refresh_icons() -> void:
	for p in item_groups:
		var root := get_node_or_null(p)
		if root:
			_populate(root)

func _populate(n: Node) -> void:
	# 1) rekursiv in die Tiefe
	var kids: Array = n.get_children()
	for i in kids.size():
		_populate(kids[i])

	# 2) Buttons (inkl. passive-Autofill)
	if n is TextureButton:
		var btn: TextureButton = n as TextureButton

		var id: String = ""
		var v_owned: Variant = btn.get("owned_id")
		if v_owned != null:
			id = String(v_owned)

		if id == "" and btn.has_meta("item_id"):
			id = String(btn.get_meta("item_id"))

		var is_passive_btn: bool = _is_passive_button(btn)

		# Typ/Value nur fürs Logging/Backup
		var t_prop: Variant = btn.get("type")
		var v_prop: Variant = btn.get("value")
		var t: int = (int(t_prop) if t_prop != null else -1)
		var v: int = (int(v_prop) if v_prop != null else -1)

		# (t,v werden hier nicht mehr geloggt, nur falls du sie brauchst)

		# Passive Buttons: ID dynamisch ermitteln
		if id == "" and is_passive_btn:
			id = _resolve_passive_item_id(btn)
			if id != "":
				btn.set_meta("item_id", id)

		if id == "":
			# kein Icon zu setzen
			return

		_apply_icon(btn, id)
		return

	# Standalone-Icon (NICHT die Paperdoll)
	if (n is TextureRect) or (n is Sprite2D and not (n is Paperdoll)):
		var icon_id: String = (String(n.get_meta("item_id")) if n.has_meta("item_id") else "")
		if icon_id != "":
			_apply_icon(n, icon_id)
			return

# Suche Icon in DB-Resourcen
func _icon_from_db(id: String) -> Texture2D:
	if id == "" or id == null:
		return null

	var tex: Texture2D = null
	var db_list: Array = [db_gear_equippable, db_gear_passive]
	for db_val in db_list:
		var db: Resource = db_val as Resource
		if db == null:
			continue
		tex = _find_icon_in_resource_recursive(db, id, 0)
		if tex != null:
			return tex

	return null

func _find_icon_in_resource_recursive(res: Variant, wanted_id: String, depth: int) -> Texture2D:
	if res == null or depth > 8:
		return null

	# 1) Resource direkt prüfen
	if res is Resource:
		var r: Resource = res as Resource

		# ID lesen (mehrere mögliche Keys)
		var rid: String = ""
		var id_keys: Array = ["ID", "id", "Name", "name"]
		for i in range(id_keys.size()):
			var key: String = String(id_keys[i])
			var val_any: Variant = r.get(key)
			if val_any != null and String(val_any) != "":
				rid = String(val_any)
				break

		# ID-Match -> Icon auslesen
		if rid == wanted_id:
			var icon_keys: Array = ["Icon", "icon", "Texture", "texture"]
			for j in range(icon_keys.size()):
				var ik: String = String(icon_keys[j])
				var iv: Variant = r.get(ik)
				if iv is Texture2D:
					var tex_match: Texture2D = iv
					return tex_match
			# kein direktes Icon-Feld gefunden → weiter nachschauen

		# Eigenschaften rekursiv durchsuchen
		var props: Array = r.get_property_list()
		for p_i in range(props.size()):
			var p: Dictionary = props[p_i]
			var pname: String = String(p.get("name", ""))
			if pname == "":
				continue
			var pv: Variant = r.get(pname)
			if pv is Array or pv is Resource or pv is Dictionary:
				var found: Texture2D = _find_icon_in_resource_recursive(pv, wanted_id, depth + 1)
				if found != null:
					return found

	# 2) Array durchlaufen
	if res is Array:
		var arr: Array = res as Array
		for k in range(arr.size()):
			var found2: Texture2D = _find_icon_in_resource_recursive(arr[k], wanted_id, depth + 1)
			if found2 != null:
				return found2

	# 3) Dictionary durchlaufen
	if res is Dictionary:
		var d: Dictionary = res as Dictionary
		for key in d.keys():
			var found3: Texture2D = _find_icon_in_resource_recursive(d[key], wanted_id, depth + 1)
			if found3 != null:
				return found3

	return null

# Besitz prüfen (+ Alias-Unterstützung)
func _is_owned(item_id: String) -> bool:
	if _inv == null or item_id == "":
		return false
	# direkter Treffer?
	if _inv.has(item_id):
		return true
	# Alias?
	if owned_id_aliases.has(item_id):
		var alt_id: String = String(owned_id_aliases[item_id])
		if _inv.has(alt_id):
			return true
	return false

func _apply_icon(node: Node, item_id: String) -> void:
	if item_id == "" or item_id == null:
		_clear_node_texture(node)
		return

	var owned: bool = _is_owned(item_id)

	# Passive Buttons: Anzeige unabhängig vom Besitz
	if node is TextureButton and _is_passive_button(node as TextureButton):
		owned = true

	if not owned:
		_clear_node_texture(node)
		return

	var tex: Texture2D = _icon_from_db(item_id)
	if tex == null:
		_clear_node_texture(node)
		return

	_set_node_texture(node, tex)

	if node is TextureRect and gray_out_locked:
		(node as TextureRect).modulate.a = 1.0
	elif node is Sprite2D and gray_out_locked:
		(node as Sprite2D).modulate = Color(1,1,1,1.0)

# Helfer zum Setzen/Löschen
func _set_node_texture(node: Node, tex: Texture2D) -> void:
	if node is TextureButton:
		var b := node as TextureButton
		b.texture_normal = tex
		b.texture_hover = tex
		b.texture_pressed = tex
		b.texture_disabled = tex
	elif node is TextureRect:
		(node as TextureRect).texture = tex
	elif node is Sprite2D:
		(node as Sprite2D).texture = tex

func _clear_node_texture(node: Node) -> void:
	if node is TextureButton:
		var b := node as TextureButton
		b.texture_normal = null
		b.texture_hover = null
		b.texture_pressed = null
		b.texture_disabled = null
	elif node is TextureRect:
		(node as TextureRect).texture = null
	elif node is Sprite2D:
		(node as Sprite2D).texture = null

# Button-Gruppen (für togglende Equip-Buttons – passive Buttons ausnehmen)
func _wire_groups() -> void:
	_group_by_row.clear()
	for path in rows:
		var row := get_node_or_null(path)
		if row == null:
			continue

		var g := ButtonGroup.new()
		g.allow_unpress = false
		_group_by_row[row] = g

		for child in row.get_children():
			if child is TextureButton:
				var btn: TextureButton = child as TextureButton

				var passive: bool = false
				var v_meta: Variant = btn.get("is_passive")
				if v_meta != null:
					passive = bool(v_meta)

				if passive:
					btn.focus_mode = Control.FOCUS_NONE
					btn.toggle_mode = false
					btn.button_group = null
				else:
					btn.toggle_mode = true
					btn.button_group = g
					btn.focus_mode = Control.FOCUS_ALL

func _is_passive_button(btn: TextureButton) -> bool:
	var v: Variant = btn.get("is_passive")
	return v != null and bool(v)

# ID-Auflösung für passive Buttons anhand Inventar-Levels
func _resolve_passive_item_id(btn: TextureButton) -> String:
	# Button-Properties
	var t_prop: Variant = btn.get("type")
	var v_prop: Variant = btn.get("value")
	if t_prop == null or v_prop == null:
		return ""
	var t: int = int(t_prop)
	var v: int = int(v_prop)  # wird nur für Fallback genutzt

	# Editor-Arrays (falls gesetzt)
	var arr_single: Array = []
	var arr_child: Array = []
	var arr_adult: Array = []

	var a_single: Variant = btn.get("passive_ids")
	if a_single is Array:
		arr_single = a_single as Array

	var a_child: Variant = btn.get("passive_ids_child")
	if a_child is Array:
		arr_child = a_child as Array

	var a_adult: Variant = btn.get("passive_ids_adult")
	if a_adult is Array:
		arr_adult = a_adult as Array

	var idx: int = 0

	if t == ET_AMMO:
		if _inv != null and _inv.age == Inventory.Age.CHILD:
			if arr_child.size() == 0:
				return ""
			idx = clamp(_inv.seed_pouch_level, 0, arr_child.size() - 1)
			return String(arr_child[idx])
		else:
			if arr_adult.size() == 0:
				return ""
			idx = clamp(_inv.quiver_level, 0, arr_adult.size() - 1)
			return String(arr_adult[idx])

	elif t == ET_BOMB_BAG:
		if arr_single.size() == 0:
			return ""
		idx = clamp(_inv.bomb_bag_level, 0, arr_single.size() - 1)
		return String(arr_single[idx])

	elif t == ET_DIVE_SCALE:
		if arr_single.size() == 0:
			return ""
		idx = clamp(_inv.dive_scale, 0, arr_single.size() - 1)
		return String(arr_single[idx])

	elif t == ET_STRENGTH:
		if arr_single.size() == 0:
			return ""
		idx = clamp(_inv.strength, 0, arr_single.size() - 1)
		return String(arr_single[idx])

	# Fallbacks (falls Type falsch gesetzt ist)
	if arr_single.size() > 0:
		idx = clamp(v, 0, arr_single.size() - 1)
		return String(arr_single[idx])

	if _inv != null and _inv.age == Inventory.Age.CHILD and arr_child.size() > 0:
		idx = clamp(v, 0, arr_child.size() - 1)
		return String(arr_child[idx])

	if _inv != null and _inv.age == Inventory.Age.ADULT and arr_adult.size() > 0:
		idx = clamp(v, 0, arr_adult.size() - 1)
		return String(arr_adult[idx])

	return ""

# ------------------ kleine Debug-Steuerung (Zahlenreihe 1..9) ------------------

func _bind_key(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	# doppelte Einträge vermeiden
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.physical_keycode == key:
			return
	var e := InputEventKey.new()
	e.physical_keycode = key
	InputMap.action_add_event(action, e)

func _ensure_debug_actions() -> void:
	_bind_key("inv_toggle_age",     KEY_1)
	_bind_key("inv_ammo_up",        KEY_2)
	_bind_key("inv_ammo_down",      KEY_3)
	_bind_key("inv_bomb_up",        KEY_4)
	_bind_key("inv_bomb_down",      KEY_5)
	_bind_key("inv_dive_up",        KEY_6)
	_bind_key("inv_dive_down",      KEY_7)
	_bind_key("inv_strength_up",    KEY_8)
	_bind_key("inv_strength_down",  KEY_9)

func _input(event: InputEvent) -> void:
	var inv := get_node_or_null("/root/Inventar") as Inventory
	if inv == null:
		return

	# Alter (Kind/Erwachsen)
	if event.is_action_pressed("inv_toggle_age"):
		inv.set_age(inv.age != Inventory.Age.ADULT)
		print("AGE -> ", "ADULT" if inv.age == Inventory.Age.ADULT else "CHILD")

	# Munition (Kind=Kerne; Erwachsen=Pfeile)
	if event.is_action_pressed("inv_ammo_up"):
		if inv.age == Inventory.Age.CHILD:
			inv.set_seed_pouch_level(inv.seed_pouch_level + 1)
			print("seed_pouch_level -> ", inv.seed_pouch_level)
		else:
			inv.set_quiver_level(inv.quiver_level + 1)
			print("quiver_level -> ", inv.quiver_level)

	if event.is_action_pressed("inv_ammo_down"):
		if inv.age == Inventory.Age.CHILD:
			inv.set_seed_pouch_level(inv.seed_pouch_level - 1)
			print("seed_pouch_level -> ", inv.seed_pouch_level)
		else:
			inv.set_quiver_level(inv.quiver_level - 1)
			print("quiver_level -> ", inv.quiver_level)

	# Bombentasche
	if event.is_action_pressed("inv_bomb_up"):
		inv.set_bomb_bag_level(inv.bomb_bag_level + 1)
		print("bomb_bag_level -> ", inv.bomb_bag_level)

	if event.is_action_pressed("inv_bomb_down"):
		inv.set_bomb_bag_level(inv.bomb_bag_level - 1)
		print("bomb_bag_level -> ", inv.bomb_bag_level)

	# Taucher-Schuppen
	if event.is_action_pressed("inv_dive_up"):
		inv.set_dive_scale(inv.dive_scale + 1)
		print("dive_scale -> ", inv.dive_scale)

	if event.is_action_pressed("inv_dive_down"):
		inv.set_dive_scale(inv.dive_scale - 1)
		print("dive_scale -> ", inv.dive_scale)

	# Stärke (Handschuhe)
	if event.is_action_pressed("inv_strength_up"):
		inv.set_strength_level(inv.strength + 1)
		print("strength -> ", inv.strength)

	if event.is_action_pressed("inv_strength_down"):
		inv.set_strength_level(inv.strength - 1)
		print("strength -> ", inv.strength)
