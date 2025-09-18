@tool
extends Resource
class_name ItemDatabase

@export var items: Array[ItemData] = []
var _by_id := {}

func _ready() -> void:
	_index()

func _index() -> void:
	_by_id.clear()
	for it in items:
		if it and it.id != "":
			_by_id[it.id] = it

func get_item(id: String) -> ItemData:      # <— NEU: nicht "get"
	return _by_id.get(id)

func get_icon(id: String, variant: String = "default") -> Texture2D:
	var it := get_item(id)                  # <— hier anpassen
	if it == null:
		return null
	if variant != "default" and it.variants.has(variant):
		return it.variants[variant]
	return it.icon
