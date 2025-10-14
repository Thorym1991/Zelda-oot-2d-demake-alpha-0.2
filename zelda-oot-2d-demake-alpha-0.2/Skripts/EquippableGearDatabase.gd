extends Resource
class_name EquippableGearDatabase

@export var Items: Array[Resource] = []

func get_item(id: String) -> Resource:
	for it in Items:
		if it == null: continue
		var key := ""
		if it.has("id"): key = String(it.get("id"))
		elif it.has("name"): key = String(it.get("name"))
		else: key = String(it.resource_path.get_file().trim_suffix(".tres"))
		if key == id:
			return it
	return null

func get_icon(id: String = "default") -> Texture2D:
	var it := get_item(id)
	if it and it.has("icon"):
		return it.get("icon") as Texture2D
	return null
