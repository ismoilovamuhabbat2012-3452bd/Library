
extends CharacterBody3D

@export var walk_speed : float = 6.0
@onready var camera : Camera3D = $Camera3D

func _physics_process(delta):
	var move_dir = Vector3.ZERO
	
	# Direct key overrides
	if Input.is_key_pressed(KEY_W): move_dir.z -= 1
	if Input.is_key_pressed(KEY_S): move_dir.z += 1
	if Input.is_key_pressed(KEY_A): move_dir.x -= 1
	if Input.is_key_pressed(KEY_D): move_dir.x += 1
	
	if move_dir != Vector3.ZERO:
		move_dir = move_dir.normalized()
		# Physically forces your player node to slide across coordinates
		global_position += move_dir * walk_speed * delta
