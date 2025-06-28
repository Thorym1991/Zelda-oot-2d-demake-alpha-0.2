extends CharacterBody2D

class_name Player

@export var speed = 100
@onready var animation_tree: AnimationTree = $AnimationTree


func _physics_process(delta: float) -> void:
	var velocity = Vector2.ZERO
	
	if Input.is_action_pressed("right"):
		velocity.x += 1.0
	if Input.is_action_pressed("left"):
		velocity.x -= 1.0
	if Input.is_action_pressed("down"):
		velocity.y += 1.0
	if Input.is_action_pressed("up"):
		velocity.y -= 1.0
	
	velocity = velocity.normalized()
	velocity = velocity * speed
	
	if velocity == Vector2.ZERO:
		animation_tree.get("parameters/playback").travel("Idel")
	else:
		animation_tree.get("parameters/playback").travel("Run")
		animation_tree.set("parameters/Idel/blend_position",velocity)
		animation_tree.set("parameters/Run/blend_position",velocity)
	
	move_and_slide()
	print(velocity)
