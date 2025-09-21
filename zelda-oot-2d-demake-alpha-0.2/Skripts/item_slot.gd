extends TextureButton

@onready var icon: TextureRect = $Icon
@onready var label: Label = $Icon/Label



func clear_item() -> void:
	icon.texture = null
	label.text = ""

func set_item(_id: String, tex: Texture2D, count: int = 1) -> void:
	icon.texture = tex
	label.text = "" if count <= 1 else str(count)
