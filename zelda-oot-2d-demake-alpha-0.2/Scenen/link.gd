extends CharacterBody2D

class_name Player

#region Variablen

@onready var tiefes_wasser: TileMapLayer = $"../TiefesWasser"
@onready var wasser: TileMapLayer = $"../wasser"
@export var speed: float = 100
@export var roll_speed: float = 200            # Geschwindigkeit während Roll
@export var roll_duration: float = 0.5         # Dauer des Rolls in Sekunden
@export var attack_duration: float = 0.3       # Dauer der Angriffsanimation
@export var climb_speed: float = 80            # Geschwindigkeit beim Klettern

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var wasser_tileset = wasser.tile_set

# State-Variablen
var is_rolling: bool = false
var roll_timer: float = 0.0
var is_attacking: bool = false
var attack_timer: float = 0.0
var is_climbing: bool = false
# Anzahl der überlappenden Kletterzonen
var climb_zone_count: int = 0

var last_input_dir: Vector2 = Vector2.DOWN

# Status Wasser
var is_on_water: bool = false
var is_on_deepwater: bool = false
var last_tile_pos: Vector2i = Vector2i(-999, -999)

# HUD Action Button
@onready var action_button: Control = get_node_or_null("/root/Main/HUD/ActionButton")

#endregion

#region _ready

func _ready() -> void:
	if action_button:
		action_button.set_action_text("Nichts")
	print("Player ready. Ladder zones found: ", climb_zone_count)

#endregion

#region _physics_process

func _physics_process(delta: float) -> void:
	# 1) Attack-State
	if is_attacking:
		attack_timer -= delta
		velocity = Vector2.ZERO
		animation_tree.get("parameters/playback").travel("Attacke")
		animation_tree.set("parameters/Attacke/blend_position", last_input_dir)
		move_and_slide()
		if attack_timer <= 0.0:
			is_attacking = false
			animation_tree.get("parameters/playback").travel("Idle")
		return

	# 2) Roll-State
	if is_rolling:
		roll_timer -= delta
		velocity = last_input_dir * roll_speed
		animation_tree.get("parameters/playback").travel("Roll")
		animation_tree.set("parameters/Roll/blend_position", last_input_dir)
		move_and_slide()
		if roll_timer <= 0.0:
			is_rolling = false
			animation_tree.get("parameters/playback").travel("Idle")
		return

	# 3) Climb-State
	if is_climbing:
		var input_y = Input.get_action_strength("down") - Input.get_action_strength("up")
		velocity = Vector2(0, input_y * climb_speed)
		animation_tree.get("parameters/playback").travel("kletteren")
		move_and_slide()
		if Input.is_action_just_pressed("Aktion"):
			exit_climb_state()
		return

	# 4) Normale Eingabe
	var move_input = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down")  - Input.get_action_strength("up")
	).normalized()

	if move_input != Vector2.ZERO:
		last_input_dir = move_input

	# Angriff starten
	if Input.is_action_just_pressed("Attacke") and not is_rolling and not is_attacking and not is_climbing:
		is_attacking = true
		attack_timer = attack_duration
		return

	# Roll starten
	if Input.is_action_just_pressed("Aktion") and move_input != Vector2.ZERO and not is_climbing:
		is_rolling = true
		roll_timer = roll_duration
		last_input_dir = move_input
		return

	# Climb-Entry nur wenn in Zone
	if climb_zone_count > 0 and Input.is_action_just_pressed("Aktion") and not is_rolling:
		enter_climb_state()
		return

	# Normale Bewegung und Animation
	velocity = move_input * speed
	_update_movement_animation(move_input)
	move_and_slide()

	# 5) Umwelt-Check (Wasser)
	var tile_pos = wasser.local_to_map(global_position)
	if tile_pos != last_tile_pos:
		last_tile_pos = tile_pos
		check_environment(tile_pos)

#endregion

#region Helpers

func _update_movement_animation(move_vec: Vector2) -> void:
	if is_on_deepwater:
		speed = 65
		animation_tree.get("parameters/playback").travel("Swim")
		animation_tree.set("parameters/Swim/blend_position", last_input_dir)
	elif is_on_water and move_vec == Vector2.ZERO:
		animation_tree.get("parameters/playback").travel("water_Idle")
		animation_tree.set("parameters/water_Idle/blend_position", last_input_dir)
	elif is_on_water:
		speed = 75
		animation_tree.get("parameters/playback").travel("Waten")
		animation_tree.set("parameters/Waten/blend_position", last_input_dir)
	elif move_vec == Vector2.ZERO:
		animation_tree.get("parameters/playback").travel("Idle")
		animation_tree.set("parameters/Idle/blend_position", last_input_dir)
	else:
		speed = 100
		animation_tree.get("parameters/playback").travel("Run")
		animation_tree.set("parameters/Run/blend_position", last_input_dir)

func enter_climb_state() -> void:
	is_climbing = true
	velocity = Vector2.ZERO
	# Deaktivierung aller Leiter-Collider
	for ladder in get_tree().get_nodes_in_group("Leiter"):
		var col = ladder.get_node_or_null("BlockerCollider")
		if col and col is CollisionShape2D:
			col.set_deferred("disabled", true)
	if action_button:
		action_button.set_action_text("Klettern")

func exit_climb_state() -> void:
	is_climbing = false
	# Reaktivierung aller Leiter-Collider
	for ladder in get_tree().get_nodes_in_group("Leiter"):
		var col = ladder.get_node_or_null("BlockerCollider")
		if col and col is CollisionShape2D:
			col.set_deferred("disabled", false)
	animation_tree.get("parameters/playback").travel("Idle")
	if action_button:
		action_button.set_action_text("Nichts")

func check_environment(pos: Vector2i) -> void:
	var id = wasser.get_cell_source_id(pos)
	var data = null
	if id != -1:
		var coords = wasser.get_cell_atlas_coords(pos)
		data = wasser_tileset.get_source(id).get_tile_data(coords, 0)
	is_on_water = data and data.get_custom_data("is_on_water") == true
	var id2 = tiefes_wasser.get_cell_source_id(pos)
	var data2 = null
	if id2 != -1:
		var coords2 = tiefes_wasser.get_cell_atlas_coords(pos)
		data2 = tiefes_wasser.tile_set.get_source(id2).get_tile_data(coords2, 0)
	is_on_deepwater = data2 and data2.get_custom_data("is_on_deepwater") == true

#endregion

#region Signale

func _on_area_entered(area: Area2D) -> void:
	climb_zone_count += 1
	if action_button:
		action_button.set_action_text("Klettern")

func _on_area_exited(area: Area2D) -> void:
	climb_zone_count = max(0, climb_zone_count - 1)
	if is_climbing and climb_zone_count == 0:
		exit_climb_state()
	if action_button:
		if climb_zone_count > 0:
			action_button.set_action_text("Klettern")
		else:
			action_button.set_action_text("Nichts")
#endregion
