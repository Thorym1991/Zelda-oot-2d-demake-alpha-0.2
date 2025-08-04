extends CharacterBody2D

class_name Player

#region Variablen

@onready var tiefes_wasser: TileMapLayer = $"../TiefesWasser"
@onready var wasser: TileMapLayer = $"../wasser"
@export var speed = 100
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var wasser_tileset := wasser.tile_set

var last_input_dir = Vector2.DOWN
var klettern_möglich = false
var klettere_von_oben = false
var aktuelle_leiter: Node2D = null
var ist_am_klettern = false

#endregion

#region _ready

func _ready() -> void:
	print("Gefundene Leiter: ", get_tree().get_nodes_in_group("Leiter").size())
	Signalhub.connect("klettern_aktiviert", _on_klettern_aktiviert)
	Signalhub.connect("klettern_deaktiviert", _on_klettern_deaktiviert)

#endregion

#region _physics_process

func _physics_process(delta: float) -> void:
	var bewegung = Vector2.ZERO
	var is_attacking := Input.is_action_pressed("Attacke")
	var is_rolling := Input.is_action_pressed("Aktion")
	
	#endregion
	
	#region bewegungssteuerung 
	
	if Input.is_action_pressed("right"): # Bewegung nach rechts.
		bewegung.x += 1.0
	if Input.is_action_pressed("left"): # Bewegung nach Links.
		bewegung.x -= 1.0
	if Input.is_action_pressed("down"): # Bewegung nach Unten.
		bewegung.y += 1.0
	if Input.is_action_pressed("up"): # Bewegung nach Oben.
		bewegung.y -= 1.0
	
	#endregion
	
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
	elif is_on_deepwater:
		speed=65
		animation_tree.get("parameters/playback").travel("Swim")
		animation_tree.set("parameters/Swim/blend_position", last_input_dir)
	elif is_on_water and bewegung == Vector2.ZERO:
		animation_tree.get("parameters/playback").travel("water_Idle")
		animation_tree.set("parameters/water_Idle/blend_position", last_input_dir)
	elif is_on_water:
		speed=75
		animation_tree.get("parameters/playback").travel("Waten")
		animation_tree.set("parameters/Waten/blend_position", last_input_dir)
	elif bewegung == Vector2.ZERO:
		animation_tree.get("parameters/playback").travel("Idle")
		animation_tree.set("parameters/Idle/blend_position", last_input_dir)
	else:
		speed = 100
		animation_tree.get("parameters/playback").travel("Run")
		animation_tree.set("parameters/Run/blend_position", last_input_dir)

	if klettern_möglich and Input.is_action_just_pressed("Aktion"):
		ist_am_klettern = true
		velocity = Vector2.ZERO
		animation_tree.get("parameters/playback").travel("kletteren")


	move_and_slide()
	
	var current_tile_pos = wasser.local_to_map(global_position)
	if current_tile_pos != last_tile_pos:
		last_tile_pos = current_tile_pos
		check_environment(current_tile_pos)

#region check_environment

var is_on_water := false
var is_on_deepwater := false
var last_tile_pos: Vector2i = Vector2i(-999, -999)


func check_environment(pos: Vector2i) -> void:   
	# Wasser (flaches Wasser)
	var wasser_source_id = wasser.get_cell_source_id(pos)
	var wasser_atlas_coords = wasser.get_cell_atlas_coords(pos)
	var wasser_tile_data = null
	if wasser_source_id != -1:
		wasser_tile_data = wasser.tile_set.get_source(wasser_source_id).get_tile_data(wasser_atlas_coords, 0)

	is_on_water = wasser_tile_data and wasser_tile_data.get_custom_data("is_on_water") == true

	# Tiefes Wasser
	var tief_source_id = tiefes_wasser.get_cell_source_id(pos)
	var tief_atlas_coords = tiefes_wasser.get_cell_atlas_coords(pos)
	var tief_tile_data = null
	if tief_source_id != -1:
		tief_tile_data = tiefes_wasser.tile_set.get_source(tief_source_id).get_tile_data(tief_atlas_coords, 0)

	is_on_deepwater = tief_tile_data and tief_tile_data.get_custom_data("is_on_deepwater") == true

#endregion


func _on_klettern_aktiviert()->void:
	Signalhub.on_klettern_möglich.connect(_on_klettern_aktiviert)
	print("Klettern aktiviert")
	klettern_möglich = true
	
	

func _on_klettern_deaktiviert():
	klettern_möglich = false
	ist_am_klettern = false
	aktuelle_leiter = null


func _on_area_2d_area_entered(area: Area2D) -> void:
	Signalhub.on_klettern_möglich.connect(_on_klettern_aktiviert)
	print("Klettern aktiviert")
	klettern_möglich = true
