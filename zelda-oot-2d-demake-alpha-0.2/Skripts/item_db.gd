extends Node
class_name ItemDB   # optional, falls du’s als Autoload nutzen willst

@onready var db: ItemDatabase = load("res://Daten/Items/Itemdb.tres") as ItemDatabase

func get_icon(id: String, variant: String = "default") -> Texture2D:
	if db == null:
		push_error("ItemDB: Resource nicht geladen!")
		return null
	return db.get_icon(id, variant)
