extends Sprite2D
class_name Paperdoll

@export var equipmgr_path: NodePath = ^"/root/EquipMgr"

@export var frame_size: Vector2i = Vector2i(64, 64)
@export var sheet_columns: int = 8
@export var auto_columns: bool = true

# Inspector-Daten
@export var sheets: Dictionary = {}              # key -> Texture2D
@export var idle_index_by_key: Dictionary = {}   # key -> int (optional)
@export var combo_index_by_key: Dictionary = {}  # key -> { "S|H|B": int }  (nur S/H/B!)
# default sizes/cols pro Altersgruppe
@export var child_default_frame_size: Vector2i = Vector2i(200, 200)
@export var adult_default_frame_size: Vector2i = Vector2i(200, 200)
@export var child_default_columns: int = 8
@export var adult_default_columns: int = 8

# optionale per-Key Overrides (vor allem für KID-Sheets)
@export var frame_size_by_key: Dictionary = {}   # z.B. { "kid_all": Vector2i(192,192), "kid_goron": Vector2i(200,200) }
@export var columns_by_key: Dictionary = {}      # z.B. { "kid_all": 8, "kid_goron": 10 }

@onready var _mgr: EquipmentManager = get_node_or_null(equipmgr_path) as EquipmentManager


func _ready() -> void:
	if _mgr:
		if not _mgr.changed.is_connected(_refresh):
			_mgr.changed.connect(_refresh)
		if not _mgr.meta_changed.is_connected(_refresh):
			_mgr.meta_changed.connect(_refresh)
		if not _mgr.equipped_slot_changed.is_connected(_on_equipped_slot_changed):
			_mgr.equipped_slot_changed.connect(_on_equipped_slot_changed)
	# Debug-Hilfe: zeigt, ob dieses Exemplar gefüllt ist
	# print_debug("[Paperdoll] _ready sheets.keys=", sheets.keys())
	_refresh()


func _on_equipped_slot_changed(_slot: String, _v: int) -> void:
	_refresh()


func _refresh() -> void:
	if _mgr == null:
		return
	if sheets.is_empty():
		push_warning("[Paperdoll] Sheets ist leer – bitte in der geladenen Instanz im Inspector füllen.")
		return
	var key := _mgr.get_paperdoll_key()
	_set_key_and_frame(key)


func _set_key_and_frame(key: String) -> void:
	var tex: Texture2D = _get_sheet_texture(key)
	if tex == null:
		texture = null
		push_error("[Paperdoll] Kein Sheet im Dictionary für Key: " + key)
		return

	# Spalten bestimmen
	var cols := sheet_columns
	if auto_columns:
		if frame_size.x > 0:
			cols = max(1, tex.get_width() / frame_size.x)

	# Frame-Index: zuerst Kombi (S|H|B), dann Idle, sonst 0
	var idx := _get_combo_frame_index_for_key(key)
	if idx < 0:
		if idle_index_by_key.has(key):
			idx = int(idle_index_by_key[key])
		else:
			idx = 0

	var region := _region_for_index(idx, cols)

	# Bounds-Check
	var max_w := tex.get_width()
	var max_h := tex.get_height()
	if region.position.x + region.size.x > max_w or region.position.y + region.size.y > max_h:
		push_warning("[Paperdoll] Frame außerhalb Textur. key=" + key + " idx=" + str(idx) + " region=" + str(region) + " tex=" + str(max_w) + "x" + str(max_h))
		idx = 0
		region = _region_for_index(idx, cols)

	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = region
	texture = atlas


# ---- Mapping nur über S|H|B (Armor/Stärke stecken im Sheet-Key) ----
func _get_combo_frame_index_for_key(key: String) -> int:
	if not combo_index_by_key.has(key):
		return -1
	var map_for_key = combo_index_by_key[key]
	if typeof(map_for_key) != TYPE_DICTIONARY:
		return -1

	var s := 0
	var h := 0
	var b := 0
	if _mgr:
		s = _mgr.get_sword()
		h = _mgr.get_shield()
		b = _mgr.get_boots()

	var combo3 := str(s) + "|" + str(h) + "|" + str(b)
	if map_for_key.has(combo3):
		return int(map_for_key[combo3])

	# Optional: falls irgendwo 5-Teiler existieren, aus Key inferieren und probieren
	var inferred := _infer_from_sheet_key(key)
	var a := int(inferred["armor"])
	var stren := int(inferred["strength"])
	var combo5 := combo3 + "|" + str(a) + "|" + str(stren)
	if map_for_key.has(combo5):
		return int(map_for_key[combo5])

	return -1


# Armor/Stärke aus dem Sheet-Key ableiten (kid_/adult_*_power/_titan)
func _infer_from_sheet_key(key: String) -> Dictionary:
	var is_child := key.begins_with("kid_")
	# Armor-Index ggf. an deine Inventar-Enums anpassen:
	# 0=green, 1=red, 2=blue
	var armor := 0
	var strength := 0

	if is_child:
		armor = 0
		if key.find("kid_goron") != -1:
			strength = 1
	else:
		if key.find("_red") != -1:
			armor = 1
		elif key.find("_blue") != -1:
			armor = 2
		else:
			armor = 0

		if key.find("_titan") != -1:
			strength = 2
		elif key.find("_power") != -1:
			strength = 1
		else:
			strength = 0

	return {"is_child": is_child, "armor": armor, "strength": strength}


# ---- Helper: Texture aus Dictionary holen (kein Pfad-Fallback) ----
func _get_sheet_texture(key: String) -> Texture2D:
	if sheets.has(key):
		var v = sheets[key]
		if v is Texture2D:
			return v as Texture2D
		# Falls mal versehentlich ein String eingetragen wurde: sanfter Hinweis
		if typeof(v) == TYPE_STRING:
			push_warning("[Paperdoll] Value für '" + key + "' ist ein String. Bitte im Inspector eine Texture2D zuweisen.")
	return null


# ---- Helper: Frame-Region berechnen ----
func _region_for_index(index: int, cols: int) -> Rect2i:
	if index < 0:
		index = 0
	if cols <= 0:
		cols = 1
	var col := index % cols
	var row := index / cols
	var x := col * frame_size.x
	var y := row * frame_size.y
	return Rect2i(x, y, frame_size.x, frame_size.y)
