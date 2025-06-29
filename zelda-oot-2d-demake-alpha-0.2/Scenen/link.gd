extends CharacterBody2D

class_name Player

@export var speed = 100
@onready var animation_tree: AnimationTree = $Animation/AnimationTree

var last_input_dir = Vector2.DOWN

func _physics_process(delta: float) -> void:
	var velocity = Vector2.ZERO
	var is_attacking := Input.is_action_pressed("Attacke")
	var is_rolling := Input.is_action_pressed("Aktion")
	
	if Input.is_action_pressed("right"): # Bewegung nach rechts.
		velocity.x += 1.0
	if Input.is_action_pressed("left"): # Bewegung nach Links.
		velocity.x -= 1.0
	if Input.is_action_pressed("down"): # Bewegung nach Unten.
		velocity.y += 1.0
	if Input.is_action_pressed("up"): # Bewegung nach Oben.
		velocity.y -= 1.0
	
	
	velocity = velocity.normalized()
	velocity = velocity * speed
	
	# Letzte Blickrichtung speichern, falls Bewegung vorhanden
	if velocity != Vector2.ZERO:
		last_input_dir = velocity
	
	if is_attacking:
		animation_tree.get("parameters/playback").travel("Attacke")
		animation_tree.set("parameters/Attacke/blend_position",last_input_dir)
	elif is_rolling:
		animation_tree.get("parameters/playback").travel("Roll")
		animation_tree.set("parameters/Roll/blend_position", last_input_dir)
	elif velocity == Vector2.ZERO:
		animation_tree.get("parameters/playback").travel("Idle")
		animation_tree.set("parameters/Idle/blend_position", last_input_dir)
	else:
		animation_tree.get("parameters/playback").travel("Run")
		animation_tree.set("parameters/Run/blend_position",last_input_dir)
	
	
	move_and_slide()
