extends Node
class_name EquipmentManager

@export var inventory_path: NodePath = ^"/root/Inventar"
@export var itemdb_path:    NodePath = ^"/root/ItemDB"

signal changed
signal equipped_slot_changed(slot: String, value: int) # sword/shield/armor/boots/b_override
signal meta_changed()
signal ammo_changed(id: String, amount: int)
signal owned_changed(id: String, has_item: bool)

var _inv: Inventory
var _db: ItemDB

func _ready() -> void:
	_inv = get_node_or_null(^"/root/Inventar") as Inventory
	if _inv and not _inv.changed.is_connected(_on_inv_changed):
		_inv.changed.connect(_on_inv_changed)
	call_deferred("_link_once")


func _link_once() -> void:
	_try_link()
	if _db == null:
		push_warning("EquipMgr: ItemDB nicht gefunden unter %s" % str(itemdb_path))
	if _inv == null:
		push_warning("EquipMgr: Inventar noch nicht bereit – versuche erneut beim ersten Zugriff.")


func _try_link() -> void:
	# Versuche, Inventar/DB zu finden
	if _inv == null:
		_inv = get_node_or_null(inventory_path) as Inventory
	if _db == null:
		_db = get_node_or_null(itemdb_path) as ItemDB
	# Signale verbinden
	if _inv:
		if not _inv.changed.is_connected(_on_inv_changed):
			_inv.changed.connect(_on_inv_changed)
		if _inv.has_signal("equipped_slot_changed") and not _inv.equipped_slot_changed.is_connected(_on_equipped_slot_changed):
			_inv.equipped_slot_changed.connect(_on_equipped_slot_changed)
		if _inv.has_signal("meta_changed") and not _inv.meta_changed.is_connected(_on_meta_changed):
			_inv.meta_changed.connect(_on_meta_changed)
		if _inv.has_signal("ammo_changed") and not _inv.ammo_changed.is_connected(_on_ammo_changed):
			_inv.ammo_changed.connect(_on_ammo_changed)
		if _inv.has_signal("owned_changed") and not _inv.owned_changed.is_connected(_on_owned_changed):
			_inv.owned_changed.connect(_on_owned_changed)
		if _inv:
		# Nach dem Verbinden einen initialen Refresh stoßen
			print_debug("[EquipMgr] initial refresh after link")
			changed.emit()
		# optional gezielt spiegeln, falls dein UI darauf hört:
		# meta_changed.emit()

func _ensure_inv() -> bool:
	if _inv == null:
		_try_link()
	return _inv != null

func _on_inv_changed() -> void:
	changed.emit()

func _on_equipped_slot_changed(slot: String, v: int) -> void:
	# print("[EquipMgr] equipped_slot_changed:", slot, v)
	equipped_slot_changed.emit(slot, v)
	changed.emit()

func _on_meta_changed() -> void:
	print_debug("[EquipMgr] meta_changed  ammo_lv=%d bomb=%d dive=%d str=%d" % [
		get_ammo_level(), get_bomb_bag_level(), get_dive_scale_level(), get_strength_level()
	])
	meta_changed.emit()
	changed.emit()

func _on_ammo_changed(id: String, n: int) -> void:
	ammo_changed.emit(id, n)
	changed.emit()

func _on_owned_changed(id: String, has_item: bool) -> void:
	owned_changed.emit(id, has_item)
	changed.emit()

# ----------------- WRITE API -----------------
func equip_sword(v: int) -> void:
	print("[EquipMgr] equip_sword(", v, ")")
	if not _ensure_inv(): return
	_inv.equip_sword(v)

func equip_shield(v: int) -> void:
	if not _ensure_inv(): return
	_inv.equip_shield(v)

func equip_armor(v: int) -> void:
	if not _ensure_inv(): return
	_inv.equip_armor(v)

func equip_boots(v: int) -> void:
	if not _ensure_inv(): return
	_inv.equip_boots(v)

func set_age(adult: bool) -> void:
	if not _ensure_inv(): return
	_inv.set_age(adult)

func set_c(dir: String, id: String) -> void:
	if not _ensure_inv(): return
	_inv.set_equip_c(dir, id)

func set_b_override(id: String) -> void:
	if not _ensure_inv(): return
	if _inv.has_method("set_b_override"):
		_inv.set_b_override(id)

func clear_b_override() -> void:
	if not _ensure_inv(): return
	if _inv.has_method("clear_b_override"):
		_inv.clear_b_override()

# ----------------- READ API -----------------
func get_sword() -> int:
	return _inv.sword if _ensure_inv() else 0

func get_shield() -> int:
	return _inv.shield if _ensure_inv() else 0

func get_armor() -> int:
	return _inv.armor if _ensure_inv() else 0

func get_boots() -> int:
	return _inv.boots if _ensure_inv() else 0

func is_adult() -> bool:
	return (_inv.age == int(Inventory.Age.ADULT)) if _ensure_inv() else false

func get_ammo_level() -> int:
	if not _ensure_inv(): return 0
	var adult_mode := (_inv.age == int(Inventory.Age.ADULT))
	return (_inv.quiver_level if adult_mode else _inv.seed_pouch_level)

func get_bomb_bag_level() -> int:
	return _inv.bomb_bag_level if _ensure_inv() else 0

func get_dive_scale_level() -> int:
	return _inv.dive_scale if _ensure_inv() else 0

func get_strength_level() -> int:
	return _inv.strength if _ensure_inv() else 0

func get_c(dir: String) -> String:
	return String(_inv.equip_c.get(dir, "")) if _ensure_inv() else ""

func has(id: String) -> bool:
	return _inv.has(id) if _ensure_inv() else false

func get_amount(id: String) -> int:
	return _inv.get_amount(id) if _ensure_inv() else 0

func get_arrows() -> int:
	return _inv.arrows if _ensure_inv() else 0

func get_b_icon_id() -> String:
	if not _ensure_inv(): return ""
	if _inv.b_override_id != "":
		return _inv.b_override_id
	match _inv.sword:
		Inventory.Sword.KOKIRI:   return "kokiri_schwert"
		Inventory.Sword.MASTER:   return "master_schwert"
		Inventory.Sword.BIGGORON: return "biggoron_schwert"
		_: return ""

func get_paperdoll_key() -> String:
	return _inv.get_paperdoll_key() if _ensure_inv() else ""

func icon_for(id: String, variant: String = "default") -> Texture2D:
	return _db.get_icon(id, variant) if (_db and id != "") else null

# Kompatibilitäts-Aliase (falls Toggles noch alte Namen verwenden)
func is_owned(id: String) -> bool:
	return has(id)

func amount_for(id: String) -> int:
	return get_amount(id)
