extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

@onready var camera_mount = $CameraMount
@onready var camera = $CameraMount/Camera3D
@onready var mesh = $MeshInstance3D

func _enter_tree():
	# Set the initial multiplayer authority
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if is_multiplayer_authority():
		print("Setting up local player: ", name)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		camera.current = true
		if mesh and mesh.get_surface_override_material(0):
			var material = mesh.get_surface_override_material(0).duplicate()
			material.albedo_color = Color.BLUE
			mesh.set_surface_override_material(0, material)
	else:
		print("Setting up remote player: ", name)
		camera.current = false
		if mesh and mesh.get_surface_override_material(0):
			var material = mesh.get_surface_override_material(0).duplicate()
			material.albedo_color = Color.RED
			mesh.set_surface_override_material(0, material)

func _unhandled_input(event):
	if !is_multiplayer_authority(): 
		return
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_mount.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, -PI/2, PI/2)
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	if !is_multiplayer_authority(): 
		return
	
	# Add gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
