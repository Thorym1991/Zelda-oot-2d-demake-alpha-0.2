extends CharacterBody2D

class_name Player

@onready var wasser: TileMapLayer = $"../wasser"
@export var speed = 100
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var wasser_tileset := wasser.tile_set

var last_input_dir = Vector2.DOWN

func _physics_process(delta: float) -> void:
	var bewegung = Vector2.ZERO
	var is_attacking := Input.is_action_pressed("Attacke")
	var is_rolling := Input.is_action_pressed("Aktion")
	
	if Input.is_action_pressed("right"): # Bewegung nach rechts.
		bewegung.x += 1.0
	if Input.is_action_pressed("left"): # Bewegung nach Links.
		bewegung.x -= 1.0
	if Input.is_action_pressed("down"): # Bewegung nach Unten.
		bewegung.y += 1.0
	if Input.is_action_pressed("up"): # Bewegung nach Oben.
		bewegung.y -= 1.0
	
	
	bewegung = bewegung.normalized()
	velocity = bewegung * speed 
	
	# Letzte Blickrichtung speichern, falls Bewegung vorhanden
	if velocity != Vector2.ZERO:
		last_input_dir = velocity.normalized()
	
	if is_attacking:
		animation_tree.get("parameters/playback").travel("Attacke")
		animation_tree.set("parameters/Attacke/blend_position", last_input_dir)
	elif is_rolling:
		speed = 200
		animation_tree.get("parameters/playback").travel("Roll")
		animation_tree.set("parameters/Roll/blend_position", last_input_dir)
	elif bewegung == Vector2.ZERO:
		animation_tree.get("parameters/playback").travel("Idle")
		animation_tree.set("parameters/Idle/blend_position", last_input_dir)
	elif is_on_water:
		animation_tree.get("parameters/playback").travel("Waten")
		animation_tree.set("parameters/Waten/blend_position", last_input_dir)
	else:
		speed = 100
		animation_tree.get("parameters/playback").travel("Run")
		animation_tree.set("parameters/Run/blend_position", last_input_dir)

	move_and_slide()
	
	var current_tile_pos = wasser.local_to_map(global_position)
	if current_tile_pos != last_tile_pos:
		last_tile_pos = current_tile_pos
		check_environment(current_tile_pos)

	if is_on_water:
		print("Spieler steht auf Wasser")
	else:
		print("ist nicht")

var is_on_water := false
var last_tile_pos: Vector2i = Vector2i(-999, -999)

func check_environment(pos: Vector2i) -> void:
	var source_id = wasser.get_cell_source_id(pos)
	var atlas_coords = wasser.get_cell_atlas_coords(pos)

	if source_id == -1:
		is_on_water = false
		return

	var tile_data = wasser_tileset.get_source(source_id).get_tile_data(atlas_coords, 0)
	if tile_data:
		var env = tile_data.get_custom_data("is_on_water")
		is_on_water = bool(tile_data.get_custom_data("is_on_water"))
	else:
		is_on_water = false
