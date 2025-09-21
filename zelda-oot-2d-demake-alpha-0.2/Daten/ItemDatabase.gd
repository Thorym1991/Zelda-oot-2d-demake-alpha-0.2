@tool
extends Resource
class_name ItemDatabase

# Wenn sich das Array im Inspector ändert, Index neu aufbauen
@export var items: Array[ItemData] = []:
	set(value):
		items = value
		_rebuild_index()

var _by_id: Dictionary = {}

# Wird beim Laden der Resource aufgerufen (auch im Editor)
func _init() -> void:
	_rebuild_index()

func _rebuild_index() -> void:
	_by_id.clear()
	for it in items:
		if it != null and it.id != "":
			_by_id[it.id] = it
	# Debug (optional)
	# print("[DB] indexed ", _by_id.size(), " items")

func get_item(id: String) -> ItemData:
	# schneller Lookup über Dictionary
	var it: ItemData = _by_id.get(id)
	if it != null:
		return it
	# Fallback: linear suchen (hilft, falls Index noch nicht gebaut)
	for x in items:
		if x != null and x.id == id:
			return x
	return null

func get_icon(id: String, variant: String = "default") -> Texture2D:
	var it := get_item(id)
	if it == null:
		return null
	if variant != "default" and it.variants.has(variant):
		return it.variants[variant]
	return it.icon
