extends CharacterBody2D

@export var target_path: NodePath 
@export var follow_speed: float = 75.0
@export var follow_distance: float = 50.0


var target: Node2D
var last_input_dir = Vector2.DOWN

func _ready():
	target = get_node(target_path)

func _process(delta):
	if not target:
		return

	var distance = global_position.distance_to(target.global_position)

# Letzte Blickrichtung speichern, falls Bewegung vorhanden
	if velocity != Vector2.ZERO:
		last_input_dir = velocity


	if distance > follow_distance:
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * follow_speed * delta
