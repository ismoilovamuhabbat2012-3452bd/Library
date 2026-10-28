extends CharacterBody3D

@export var walk_speed : float = 5.0
@onready var camera : Camera3D = $Camera3D
# Automatically references the FileDialog child node you just added
@onready var file_dialog : FileDialog = $FileDialog

const CLIMB_SPEED = 4.0
const GRAVITY = 9.8

var is_on_ladder: bool = false
var is_menu_open: bool = false

func _ready() -> void:
	# Connect the file dialog's selection engine programmatically
	file_dialog.file_selected.connect(_on_pdf_file_selected)
	# Connect close request in case player cancels the explorer window
	file_dialog.canceled.connect(_on_dialog_closed)

func _physics_process(delta: float) -> void:
	# If player is browsing documents, freeze game movement logic
	if is_menu_open:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# 1. Get player keyboard inputs
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.y += 1   # Forward
	if Input.is_key_pressed(KEY_S): input_dir.y -= 1   # Backward
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1   # Left
	if Input.is_key_pressed(KEY_D): input_dir.x += 1   # Right
	input_dir = input_dir.normalized()
	
	# 2. Split behavior based on whether we are on a ladder
	if is_on_ladder:
		velocity.y = 0.0 
		var forward = -global_transform.basis.z
		var right = global_transform.basis.x
		
		if input_dir.y > 0: 
			velocity.y = CLIMB_SPEED
			velocity.x = forward.x * walk_speed * 0.5
			velocity.z = forward.z * walk_speed * 0.5
		elif input_dir.y < 0: 
			velocity.y = -CLIMB_SPEED
			velocity.x = 0.0
			velocity.z = 0.0
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			
		if input_dir.x != 0:
			velocity.x += right.x * input_dir.x * walk_speed
			velocity.z += right.z * input_dir.x * walk_speed
		
	else:
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
			
		var forward = -global_transform.basis.z
		var right = global_transform.basis.x
		var direction = (forward * input_dir.y + right * input_dir.x).normalized()
		
		if direction != Vector3.ZERO:
			velocity.x = direction.x * walk_speed
			velocity.z = direction.z * walk_speed
		else:
			velocity.x = move_toward(velocity.x, 0, walk_speed)
			velocity.z = move_toward(velocity.z, 0, walk_speed)

	move_and_slide()


func _input(event: InputEvent) -> void:
	# Detect if the player presses the 'O' key to open documents
	if event is InputEventKey and event.pressed and event.keycode == KEY_O:
		toggle_file_explorer()
		return

	# Block standard FPS mouse looking if the file system layout is visible
	if is_menu_open:
		return

	# Click the game screen once to capture mouse cursor and look around
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.003)
		camera.rotate_x(-event.relative.y * 0.003)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))


# --- FILE EXPLORER / PDF SYSTEM ---
func toggle_file_explorer() -> void:
	is_menu_open = true
	# Release the mouse so the user can select their PDF files
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Open dialog directly pointing to the user's desktop/home documents profile directory
	file_dialog.current_dir = "user://"
	file_dialog.popup_centered()

func _on_pdf_file_selected(path: String) -> void:
	# Convert Godot path strings into absolute paths the operating system recognizes
	var universal_path = ProjectSettings.globalize_path(path)
	
	# Command Windows/Mac/Linux to launch this PDF inside their native reader app!
	OS.shell_open(universal_path)
	_on_dialog_closed()

func _on_dialog_closed() -> void:
	is_menu_open = false
	# Re-capture the mouse cursor automatically to resume fluid shooting/movement controls
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- LADDER SIGNALS ---
func _on_ladder_area_body_entered(body: Node3D) -> void:
	if body == self:
		is_on_ladder = true

func _on_ladder_area_body_exited(body: Node3D) -> void:
	if body == self:
		is_on_ladder = false
