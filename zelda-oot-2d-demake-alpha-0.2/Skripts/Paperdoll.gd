extends Sprite2D
class_name Paperdoll

@export var inventory_path: NodePath = ^"/root/Inventar"
@export var equipmgr_path: NodePath = ^"/root/EquipMgr"
var _mgr: EquipmentManager
# Map: key -> {path, h, v, frame}
@export var sheets: Dictionary = {
	# --- Kind ---
	"kid_all":  {"path":"res://Art/Spieler/paperdolls/Kind/kid_all.png",              "h":2, "v":3, "frame":0},
	"kid_goron":{"path":"res://Art/Spieler/paperdolls/Kind/kid_goron_bracelet.png",   "h":2, "v":2, "frame":0},

	# --- Erwachsene (alle 4x5) ---
	"adult_green":       {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_green.png",        "h":4, "v":5, "frame":0},
	"adult_green_power": {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_green_power.png",  "h":4, "v":5, "frame":0},
	"adult_green_titan": {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_green_titan.png",  "h":4, "v":5, "frame":0},
	"adult_red":         {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_red.png",          "h":4, "v":5, "frame":0},
	"adult_red_power":   {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_red_power.png",    "h":4, "v":5, "frame":0},
	"adult_red_titan":   {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_red_titan.png",    "h":4, "v":5, "frame":0},
	"adult_blue":        {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_blue.png",         "h":4, "v":5, "frame":0},
	"adult_blue_power":  {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_blue_power.png",   "h":4, "v":5, "frame":0},
	"adult_blue_titan":  {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_blue_titan.png",   "h":4, "v":5, "frame":0},
}

# Optional zum Testen im Editor: Key manuell setzen
@export var override_key: StringName = &""
@export var apply_override_now: bool = false : set = _apply_override_flag

var _inv: Inventory

func _ready() -> void:
	_inv = get_node_or_null(inventory_path) as Inventory
	if _inv:
		if not _inv.changed.is_connected(_on_inventory_changed):
			_inv.changed.connect(_on_inventory_changed)
		if not _inv.equipment_changed.is_connected(_on_inventory_changed):
			_inv.equipment_changed.connect(_on_inventory_changed)
			_mgr = get_node_or_null(equipmgr_path) as EquipmentManager
	if _mgr:
		_mgr.changed.connect(_on_inventory_changed)
	_on_inventory_changed()

func _apply_override_flag(value: bool) -> void:
	if value and String(override_key) != "":
		set_key(String(override_key))
	apply_override_now = false

func _on_inventory_changed() -> void:
	if _inv == null:
		return
	# Inventory liefert den Key (das hast du bereits implementiert)
	var key := _mgr.get_paperdoll_key() if _mgr else _inv.get_paperdoll_key()
	set_key(key)

func set_key(key: String) -> void:
	var cfg_v: Variant = sheets.get(key, null)
	if cfg_v == null or not (cfg_v is Dictionary):
		push_warning("Paperdoll: Key '%s' nicht gefunden." % key)
		texture = null
		return

	var cfg: Dictionary = cfg_v as Dictionary
	var path: String = String(cfg.get("path", ""))
	if path == "":
		push_warning("Paperdoll '%s' ohne 'path'." % key)
		return

	var res: Resource = load(path)
	var tex := res as Texture2D
	if tex == null:
		push_warning("Paperdoll-Textur fehlt/kein Texture2D: %s" % path)
		return

	texture = tex
	region_enabled = false

	var hf: int = int(cfg.get("h", 1))
	var vf: int = int(cfg.get("v", 1))
	hframes = hf
	vframes = vf

	var total: int = max(1, hf * vf)
	var frm: int = clamp(int(cfg.get("frame", 0)), 0, total - 1)
	frame = frm

	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
