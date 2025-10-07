extends Control

# === Datenbanken ===
@export var db_gear_equippable: Resource     # akzeptiert jede DB-Klasse
@export var db_gear_passive: Resource        # (hast du schon so)

# === Paperdoll ===
@export var paperdoll_path: NodePath
@onready var doll: Sprite2D = get_node_or_null(paperdoll_path)


# === Navigation ===
@export var left_category_buttons: Array[NodePath] = []  # Reihenfolge top->bottom
@export var grid_rows: Array[NodePath] = []              # jeder Eintrag ist ein HBox/Grid mit Slot-Buttons

@export var wrap_navigation := true
@export var skip_locked_slots := true

@export var close_action := "ui_cancel"
@export var accept_action := "Aktion"
@export var up_action := "up"
@export var down_action := "down"
@export var left_action := "left"
@export var right_action := "right"

enum Zone { LEFT, RIGHT }
var _zone: int = Zone.LEFT
var _left_index := 0
var _row := 0
var _col := 0
var _focus_bootstrapped := false

# === Alias-Mapping für Datenbank-Schlüssel ===
const DB_ALIAS_BY_ID := {
	#"inventar_id" : "db_key"
	# Beispiel:
	"kleine_kern_tasche": "kleine_kern_tasche",
	"goron_bracelet": "goronen_armband",
	"kleine_bombentasche": "bomben_tasche_klein",
	"silberne_schuppe": "silberne_schuppe",
}

# === Paperdoll Sheets ===
const SHEETS := {
	# Kind
	"kid_all":        {"path":"res://Art/Spieler/paperdolls/Kind/kid_all.png",            "h":3, "v":3},
	"kid_goron":      {"path":"res://Art/Spieler/paperdolls/Kind/kid_goron_bracelet.png", "h":2, "v":1},

	# Erwachsene
	"adult_green":       {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_green.png",       "h":4, "v":5},
	"adult_red":         {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_red.png",         "h":4, "v":5},
	"adult_blue":        {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_blue.png",        "h":4, "v":5},
	"adult_green_power": {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_green_power.png", "h":4, "v":5},
	"adult_red_power":   {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_red_power.png",   "h":4, "v":5},
	"adult_blue_power":  {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_blue_power.png",  "h":4, "v":5},
	"adult_green_titan": {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_green_titan.png", "h":4, "v":5},
	"adult_red_titan":   {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_red_titan.png",   "h":4, "v":5},
	"adult_blue_titan":  {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_blue_titan.png",  "h":4, "v":5},
}

# === ID -> Enum Mapping für Gear ===
const SWORD_BY_ID := {
	"kokiri_schwert": Inventory.Sword.KOKIRI,
	"master_schwert": Inventory.Sword.MASTER,
	"biggoron_schwert": Inventory.Sword.BIGGORON,
}
const SHIELD_BY_ID := {
	"deku_schild": Inventory.Shield.DEKU,
	"hylia_schild": Inventory.Shield.HYLIA,
	"spiegel_schild": Inventory.Shield.MIRROR,
}
const ARMOR_BY_ID := {
	"kokiri_rüstung": Inventory.Armor.GREEN,
	"goronen_rüstung": Inventory.Armor.RED,
	"zora_rüstung": Inventory.Armor.BLUE,
}
const BOOTS_BY_ID := {
	"leder_stiefel": Inventory.Boots.LEATHER,
	"eisen_stiefel": Inventory.Boots.IRON,
	"gleit_stiefel": Inventory.Boots.HOVER,
}

# === Quickslots ===
const QUICK_EQUIPPABLE := {
	"deku_stab": true, "deku_nuss": true,
	"bumerang": true, "feenschleuder": true, "bogen": true, "bombe": true,
	"stahlhammer": true, "auge_der_wahrheit": true,
	"feuerpfeil": true, "eispfeil": true, "lichtpfeil": true,
	"ocarina_fairy": true, "ocarina_time": true
}

@export var default_quick_target := "B"
var quick_target := "B"

# --- INVENTAR ---
@export var inventory_path: NodePath
var _inv: Inventory

# --- ICON-LOADER ---
@export var item_groups: Array[NodePath] = []
@export var gray_out_locked := true

# === READY ===
func _ready() -> void:
	
	if inventory_path != NodePath():
		_inv = get_node(inventory_path) as Inventory
	elif has_node("/root/Inventar"):
		_inv = get_node("/root/Inventar") as Inventory
	elif has_node("/root/Inventory"):
		_inv = get_node("/root/Inventory") as Inventory

	if _inv:
		_inv.changed.connect(_on_inventory_changed)
		_inv.equipment_changed.connect(_on_inventory_changed)

	_on_inventory_changed()
	_refresh_item_groups()
	_update_focus_visuals()
	_set_initial_focus()
	if not self.visibility_changed.is_connected(_on_visibility_changed):
		self.visibility_changed.connect(_on_visibility_changed)
	call_deferred("_force_focus_bootstrap")  # direkt beim Start

# === PAPERDOLL ===
func _on_inventory_changed() -> void:
	var key: String = "kid_all"
	if _inv != null:
		key = _inv.get_paperdoll_key()
	update_paperdoll(key, 0)
	_refresh_item_groups()

func update_paperdoll(key: String, frame: int = 0) -> void:
	if doll == null:
		push_warning("Paperdoll-Node nicht gesetzt.")
		return

	if not SHEETS.has(key):
		push_warning("Unbekanntes Sheet: " + key)
		return

	var cfg: Dictionary = SHEETS[key]
	var path: String = String(cfg["path"])
	var tex: Texture2D = load(path) as Texture2D

	if tex:
		doll.texture = tex
		doll.hframes = int(cfg["h"])
		doll.vframes = int(cfg["v"])
		doll.frame = clamp(frame, 0, doll.hframes * doll.vframes - 1)
		doll.centered = true
	else:
		push_warning("Paperdoll-Texture nicht gefunden: " + path)

# === ICONS ===
func _refresh_item_groups() -> void:
	for p in item_groups:
		var root := get_node_or_null(p)
		if root:
			_populate_group(root)
			_zone = Zone.LEFT
			_left_index = 0
			_row = 0
			_col = 0
			_update_focus_visuals()

func _icon_target_for(n: Node) -> Node:
	# Wenn ein TextureButton ein Kind namens "Icon" hat, benutze dieses Kind als Ziel
	if n is TextureButton:
		var icon := n.get_node_or_null(^"Icon")
		if icon and (icon is TextureRect or icon is Sprite2D):
			return icon
	return n

func _populate_group(root: Node) -> void:
	for child: Node in root.get_children():
		# rekursiv zuerst
		_populate_group(child)

		# 1) Buttons: IDs vom Button (oder Icon-Kind als Fallback) → Icon auf Kind setzen
		if child is TextureButton:
			var ids: Array[String] = _get_item_ids_for_node(child)
			if ids.is_empty():
				var icon_node: Node = _icon_target_for(child)
				ids = _get_item_ids_for_node(icon_node)

			if ids.is_empty():
				continue

			var item_id: String = _resolve_best_id(ids)
			var target: Node = _icon_target_for(child)  # meist das Kind "Icon"
			_apply_icon(target, item_id)

			var btn := child as TextureButton
			if not btn.has_meta("_handler_set"):
				btn.set_meta("_handler_set", true)
				btn.pressed.connect(_on_any_item_button_pressed.bind(btn))

		# 2) Standalone-Icons (kein Parent-Button)
		elif (child is TextureRect or child is Sprite2D) and not (child.get_parent() is TextureButton):
			var ids2: Array[String] = _get_item_ids_for_node(child)
			if ids2.is_empty():
				continue
			var item_id2: String = _resolve_best_id(ids2)
			_apply_icon(child, item_id2)


func _get_item_ids_for_node(n: Node) -> Array[String]:
	var result: Array[String] = []

	# 0) HARDCODE: EquipToggle-Buttons → nimm owned_id (verhindert falsche Zuordnung)
	if n is TextureButton:
		# Script hängt auf dem Button; owned_id ist direkte Property
		var owned: Variant = n.get("owned_id")
		if owned != null and String(owned) != "":
			result.append(_norm_id(String(owned)))
			return result
		# Falls kein owned_id gesetzt, dann optional Meta am Button lesen
		if n.has_meta("item_id"):
			result.append(_norm_id(String(n.get_meta("item_id"))))
			return result
		if n.has_meta("item_ids"):
			var arr_btn: Array = n.get_meta("item_ids")
			for v in arr_btn:
				result.append(_norm_id(String(v)))
			return result

	# 1) Normale (Standalone-)Icons: Metas direkt am Node
	if n.has_meta("item_ids"):
		var arr: Array = n.get_meta("item_ids")
		for v in arr:
			result.append(_norm_id(String(v)))
		return result

	if n.has_meta("item_id"):
		result.append(_norm_id(String(n.get_meta("item_id"))))
		return result

	# 2) Fallback: beim Parent nachsehen (z. B. Icon-Kind unter Button ohne eigenes Meta)
	var p := n.get_parent()
	if p != null:
		# wenn Parent ein Button (EquipToggle) ist → wieder owned_id bevorzugen
		if p is TextureButton:
			var owned2: Variant = p.get("owned_id")
			if owned2 != null and String(owned2) != "":
				result.append(_norm_id(String(owned2)))
				return result
			if p.has_meta("item_id"):
				result.append(_norm_id(String(p.get_meta("item_id"))))
				return result
			if p.has_meta("item_ids"):
				var arr2: Array = p.get_meta("item_ids")
				for v2 in arr2:
					result.append(_norm_id(String(v2)))
				return result

		# sonst normale Metas am Parent (falls vorhanden)
		if p.has_meta("item_id"):
			result.append(_norm_id(String(p.get_meta("item_id"))))
			return result
		if p.has_meta("item_ids"):
			var arr3: Array = p.get_meta("item_ids")
			for v3 in arr3:
				result.append(_norm_id(String(v3)))
			return result

	return result

func _resolve_best_id(ids: Array[String]) -> String:
	if _inv != null:
		for id in ids:
			if _inv.has(id):
				return id
	return ids[0]

# === ICON ANWENDEN ===
var _EMPTY_TEX: Texture2D

func _get_empty_tex() -> Texture2D:
	if _EMPTY_TEX:
		return _EMPTY_TEX
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0,0))
	_EMPTY_TEX = ImageTexture.create_from_image(img)
	return _EMPTY_TEX

func _apply_icon(node: Node, item_id: String) -> void:
	var tex: Texture2D = _icon_from_dbs(item_id)
	if tex == null:
		tex = _get_empty_tex()
	if tex == null:
		return

	var owned: bool = (_inv != null and _inv.has(item_id))

	if node is TextureButton:
		var b := node as TextureButton
		b.texture_normal = tex
		b.texture_hover = tex
		b.texture_pressed = tex
		b.texture_disabled = tex
		b.disabled = (not owned) and gray_out_locked
		if gray_out_locked:
			if owned:
				b.modulate.a = 1.0
			else:
				b.modulate.a = 0.35

	elif node is TextureRect:
		var r := node as TextureRect
		r.texture = tex
		if gray_out_locked:
			if owned:
				r.modulate.a = 1.0
			else:
				r.modulate.a = 0.35

	elif node is Sprite2D and node != doll:
		var s := node as Sprite2D
		s.texture = tex
		if gray_out_locked:
			if owned:
				s.modulate = Color(1, 1, 1, 1)
			else:
				s.modulate = Color(1, 1, 1, 0.35)

	# --- Ausgewähltes Gear hervorheben (ohne Ternary/Python-If) ---
	var selected: bool = false
	if has_method("_is_equipped_id"):
		selected = _is_equipped_id(item_id)

	if selected:
		if node is TextureButton or node is TextureRect:
			node.modulate.a = 1.0
		elif node is Sprite2D:
			node.modulate = Color(1, 1, 1, 1)

	

func _on_any_item_button_pressed(btn: TextureButton) -> void:
	var ids: Array[String] = _get_item_ids_for_node(btn)
	if ids.is_empty():
		return
	var item_id: String = _resolve_best_id(ids)
	_on_item_pressed(item_id)

func _on_item_pressed(item_id: String) -> void:
	if _inv == null:
		return

	var owned := _inv.has(item_id)
	var is_gear := SWORD_BY_ID.has(item_id) or SHIELD_BY_ID.has(item_id) or ARMOR_BY_ID.has(item_id) or BOOTS_BY_ID.has(item_id)
	var is_quick := QUICK_EQUIPPABLE.has(item_id)

	if not owned and not is_gear:
		return

	if SWORD_BY_ID.has(item_id):
		_inv.equip_sword(SWORD_BY_ID[item_id]); return
	if SHIELD_BY_ID.has(item_id):
		_inv.equip_shield(SHIELD_BY_ID[item_id]); return
	if ARMOR_BY_ID.has(item_id):
		_inv.equip_armor(ARMOR_BY_ID[item_id]); return
	if BOOTS_BY_ID.has(item_id):
		_inv.equip_boots(BOOTS_BY_ID[item_id]); return

	if is_quick:
		_assign_quick(item_id)

func _assign_quick(item_id: String) -> void:
	if quick_target == null or String(quick_target) == "":
		quick_target = default_quick_target
	match quick_target:
		"A":    _inv.set_equip_a(item_id)
		"B":    _inv.set_equip_b(item_id)
		"left", "right", "down":
			_inv.set_equip_c(quick_target, item_id)
		_:      _inv.set_equip_b(item_id)

# === ICONS AUS DATENBANK ===
func _icon_from_dbs(id: String) -> Texture2D:
	if id == "":
		return null
	var key := String(DB_ALIAS_BY_ID.get(id, id))
	#print("🔍 Suche Icon für:", id, " (key:", key, ")")

	var tex := _icon_from_array_db(db_gear_equippable, key)
	if tex:
		#print("✅ Gefunden in EQUIPPABLE:", key)
		return tex

	tex = _icon_from_array_db(db_gear_passive, key)
	if tex:
		#print("✅ Gefunden in PASSIVE:", key)
		return tex

	#print("❌ Nichts gefunden für:", key)
	return null

func _icon_from_array_db(db: Resource, key: String) -> Texture2D:
	if db == null:
		return null

	var list_prop: String = ""
	for p in db.get_property_list():
		var n: String = String(p.get("name", ""))
		if n == "Items" or n == "items":
			list_prop = n
			break
	if list_prop == "":
		return null

	var arr: Array = db.get(list_prop) as Array
	for it in arr:
		if it == null:
			continue

		var id_val: Variant = it.get("ID")
		if id_val == null or String(id_val) == "":
			id_val = it.get("id")
		if id_val == null or String(id_val) == "":
			id_val = it.get("Name")
		if id_val == null or String(id_val) == "":
			id_val = it.get("name")

		var id_in_res: String = String(id_val)
		if id_in_res == key:
			var ic: Variant = it.get("Icon")
			if ic == null:
				ic = it.get("icon")
			if ic is Texture2D:
				return ic as Texture2D
			else:
				push_warning("Eintrag '%s' hat kein gültiges Icon." % id_in_res)
				return null

	return null

# === HILFSFUNKTIONEN ===
func _is_equipped_id(item_id: String) -> bool:
	if _inv == null:
		return false
	if SWORD_BY_ID.has(item_id):
		return _inv.sword == int(SWORD_BY_ID[item_id])
	if SHIELD_BY_ID.has(item_id):
		return _inv.shield == int(SHIELD_BY_ID[item_id])
	if ARMOR_BY_ID.has(item_id):
		return _inv.armor == int(ARMOR_BY_ID[item_id])
	if BOOTS_BY_ID.has(item_id):
		return _inv.boots == int(BOOTS_BY_ID[item_id])
	return false

func _norm_id(s: String) -> String:
	var t := String(s).strip_edges()
	if t.begins_with('"') and t.ends_with('"') and t.length() >= 2:
		t = t.substr(1, t.length() - 2)
	t = t.replace('"', "")
	return t

# --- FOKUS-HILFSMETHODEN ---

func _focusable_of(n: Node) -> TextureButton:
	if n == null:
		return null
	if n is TextureButton:
		return n as TextureButton
	var p: Node = n.get_parent()
	if p != null and p is TextureButton:
		return p as TextureButton
	return null


func _visible_enabled(n: Node) -> bool:
	if n == null:
		return false
	var btn: TextureButton = _focusable_of(n)
	if btn == null:
		return n.visible
	return btn.visible and not (skip_locked_slots and btn.disabled)

func _current_target() -> Control:
	if _zone == Zone.LEFT:
		if _left_index >= 0 and _left_index < left_category_buttons.size():
			return get_node_or_null(left_category_buttons[_left_index]) as Control
		return null
	else:
		var m: Array = _get_grid_matrix()
		if _row < 0 or _row >= m.size():
			return null
		var row: Array = m[_row] as Array
		if row.is_empty():
			return null
		var col: int = clampi(_col, 0, row.size() - 1)  # <— WICHTIG: int + clampi
		return row[col] as Control

func _get_grid_matrix() -> Array:
	var matrix: Array = []
	for row_path in grid_rows:
		var row_node := get_node_or_null(row_path)
		var line: Array = []
		if row_node:
			for c in row_node.get_children():
				if c is Control:
					line.append(c)
		matrix.append(line)
	return matrix
	
func _update_focus_visuals() -> void:
	var tgt: Control = _current_target()
	if tgt == null:
		return
	var btn: TextureButton = _focusable_of(tgt)
	if btn != null:
		btn.grab_focus()

func _skip_invalid_in_row(step: int) -> void:
	var m := _get_grid_matrix()
	if _row < 0 or _row >= m.size():
		return
	var row: Array = m[_row] as Array
	if row.is_empty():
		return
	var tries := row.size()
	while tries > 0 and not _visible_enabled(row[_col]):
		_col += step
		if wrap_navigation:
			if _col < 0: _col = row.size() - 1
			if _col >= row.size(): _col = 0
		else:
			_col = clamp(_col, 0, row.size() - 1)
			break
		tries -= 1

func _nav(dx: int, dy: int) -> void:
	if _zone == Zone.LEFT:
		if dy != 0:
			var count := left_category_buttons.size()
			if count == 0: return
			_left_index += dy
			if wrap_navigation:
				if _left_index < 0: _left_index = count - 1
				if _left_index >= count: _left_index = 0
			else:
				_left_index = clamp(_left_index, 0, count - 1)
		if dx > 0:
			_zone = Zone.RIGHT
			_focus_first_right()
	elif _zone == Zone.RIGHT:
		var m: Array = _get_grid_matrix()
		if m.is_empty(): return
		if dy != 0:
			_row += dy
			if wrap_navigation:
				if _row < 0: _row = m.size() - 1
				if _row >= m.size(): _row = 0
			else:
				_row = clamp(_row, 0, m.size() - 1)
			_col = 0
			_skip_invalid_in_row(+1)
		if dx != 0:
			_col += dx
			var size: int = (m[_row] as Array).size()
			if size == 0: return
			if wrap_navigation:
				if _col < 0: _col = size - 1
				if _col >= size: _col = 0
			else:
				_col = clamp(_col, 0, size - 1)
			_skip_invalid_in_row(dx)
	_update_focus_visuals()

func _find_first_focusable() -> TextureButton:
	# ZUERST linke Kategorie/Passive-Buttons
	for i in range(left_category_buttons.size()):
		var n: Node = get_node_or_null(left_category_buttons[i])
		if n is TextureButton and n.visible and not (n as TextureButton).disabled and n.focus_mode != Control.FOCUS_NONE:
			_zone = Zone.LEFT
			_left_index = i
			return n as TextureButton

	# Dann rechte Ausrüstungs-Buttons
	var m: Array = _get_grid_matrix()
	for r in range(m.size()):
		var row: Array = m[r] as Array
		for c in range(row.size()):
			var btn: TextureButton = _focusable_of(row[c])
			if btn != null and btn.visible and not btn.disabled and btn.focus_mode != Control.FOCUS_NONE:
				_zone = Zone.RIGHT
				_row = r
				_col = c
				return btn
	return null



func _force_focus_bootstrap() -> void:
	if _focus_bootstrapped:
		return
	# mehrstufig, damit es wirklich greift
	await get_tree().process_frame
	var btn := _find_first_focusable()
	if btn != null:
		btn.grab_focus()
		_focus_bootstrapped = true
		return

	# falls beim ersten Frame noch nichts da war, noch 2 Versuche
	await get_tree().process_frame
	btn = _find_first_focusable()
	if btn != null:
		btn.grab_focus()
		_focus_bootstrapped = true
		return

	# letzter Versuch „auf Nummer sicher“
	call_deferred("_deferred_grab_focus")


func _deferred_grab_focus() -> void:
	var btn := _find_first_focusable()
	if btn != null:
		btn.grab_focus()
		_focus_bootstrapped = true


func _set_initial_focus() -> void:
	var btn: TextureButton = null

	# 1) erst linke Kategorien durchsuchen
	for i in range(left_category_buttons.size()):
		var n: Node = get_node_or_null(left_category_buttons[i])
		if n is TextureButton and n.visible and not (n as TextureButton).disabled:
			btn = n as TextureButton
			_zone = Zone.LEFT
			_left_index = i
			break

	# 2) sonst erstes nutzbares Feld rechts suchen
	if btn == null:
		var m: Array = _get_grid_matrix()
		for r in range(m.size()):
			var row: Array = m[r] as Array
			for c in range(row.size()):
				var fb: TextureButton = _focusable_of(row[c])
				if fb != null and fb.visible and not fb.disabled:
					btn = fb
					_zone = Zone.RIGHT
					_row = r
					_col = c
					break
			if btn != null:
				break

	# 3) Fokus setzen
	if btn != null:
		btn.grab_focus()

func _focus_first_right() -> void:
	_row = 0
	_col = 0
	_skip_invalid_in_row(+1)
	_update_focus_visuals()

func _select_current() -> void:
	var tgt := _current_target()
	if tgt == null:
		return
	# Linke Seite: Kategorie
	if _zone == Zone.LEFT:
		_on_category_selected(_left_index)
		return
	# Rechte Seite: Button drücken
	var btn := _focusable_of(tgt)
	if btn:
		btn.emit_signal("pressed")

func _on_category_selected(idx: int) -> void:
	# Hier könntest du filtern/umschalten; vorerst nur Fokus rüber setzen:
	_zone = Zone.RIGHT
	_focus_first_right()

func _on_visibility_changed() -> void:
	if visible:
		_focus_bootstrapped = false
		_force_focus_bootstrap()   # beim Öffnen erneut Fokus setzen


func _unhandled_input(e: InputEvent) -> void:
	var owner := get_viewport().gui_get_focus_owner()
	if owner == null or not is_instance_valid(owner):
		_force_focus_bootstrap()
	if e.is_action_pressed(close_action):
		visible = false
		get_viewport().set_input_as_handled()
		return

	if e.is_action_pressed(accept_action):
		_select_current()
		get_viewport().set_input_as_handled()
		return

	if e.is_action_pressed(up_action):
		_nav(0, -1); get_viewport().set_input_as_handled(); return
	if e.is_action_pressed(down_action):
		_nav(0, +1); get_viewport().set_input_as_handled(); return
	if e.is_action_pressed(left_action):
		_nav(-1, 0); get_viewport().set_input_as_handled(); return
	if e.is_action_pressed(right_action):
		_nav(+1, 0); get_viewport().set_input_as_handled(); return
