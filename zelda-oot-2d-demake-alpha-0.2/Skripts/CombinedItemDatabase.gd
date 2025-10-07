extends Resource
class_name CombinedItemDatabase

@export var sources: Array[Resource] = []   # deine ItemDatabase-Ressourcen hier zuweisen
@export var aliases: Dictionary = {}        # optional: {"kokiri_schwert":"Kokiri-Schwert", ...}

func _resolve_id(id: String) -> String:
	return String(aliases.get(id, id))

func get_item(id: String) -> Variant:
	var key := _resolve_id(id)
	for db in sources:
		if db == null: continue
		if db.has_method("get_item"):
			var it = db.get_item(key)
			if it != null: return it
		# Fallback: direktes items-Dict (du hast "db.items.size()" benutzt → vorhanden)
		if "items" in db and typeof(db.items) == TYPE_DICTIONARY and db.items.has(key):
			return db.items[key]
	return null

func get_icon(id: String, variant: String = "default") -> Texture2D:
	var key := _resolve_id(id)
	for db in sources:
		if db == null: continue
		if db.has_method("get_icon"):
			var tex: Texture2D = db.get_icon(key, variant)
			if tex != null: return tex
		if db.has_method("get_item"):
			var it = db.get_item(key)
			if it and "icon" in it and it.icon != null:
				return it.icon
		if "items" in db and typeof(db.items) == TYPE_DICTIONARY and db.items.has(key):
			var raw = db.items[key]
			if typeof(raw) == TYPE_DICTIONARY and raw.has("icon"):
				return raw["icon"]
	return null

func has_item(id: String) -> bool:
	return get_item(id) != null

func all_ids() -> PackedStringArray:
	var set := {}
	for db in sources:
		if db == null: continue
		if "items" in db and typeof(db.items) == TYPE_DICTIONARY:
			for k in db.items.keys():
				set[String(k)] = true
	return PackedStringArray(set.keys())
