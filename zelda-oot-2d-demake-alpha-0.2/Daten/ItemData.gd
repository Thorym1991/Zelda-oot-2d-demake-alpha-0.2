@tool
extends Resource
class_name ItemData

enum UserGroup { KIND, ERWA, BEIDE }

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var variants: Dictionary = {}   # z.B. {"fairy":Texture2D,"time":Texture2D}
@export var usable_by: UserGroup = UserGroup.BEIDE
@export var stackable: bool = false
@export var max_stack: int = 1
