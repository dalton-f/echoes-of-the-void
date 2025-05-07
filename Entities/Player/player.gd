extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 20.0
const SENSITIVITY = 0.004
const ROTATION_SPEED = 50.0

var gravity_direction = Vector3.DOWN

var ship_ref = CharacterBody3D

@onready var mesh = $PlayerMesh
@onready var head = $PlayerHead
@onready var camera = $PlayerHead/Camera3D

func _ready() -> void:
	ship_ref = get_tree().get_root().get_node("Space/Ship")

func _process(_delta):
	if GameManager.ship_state == GameManager.ShipState.INSIDE_SHIP:
		# Ensure the player ends up at the same position of the ship after exiting
		position.x = ship_ref.position.x * 1.05
		position.z = ship_ref.position.z * 1.05
		position.y = ship_ref.position.y
		visible = false
		$PlayerCollision.disabled = true
		
		return
	
	# Set the correct camera to current and enable collisions
	camera.make_current()
	$PlayerCollision.disabled = false

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Get gravity from the default physics engine (and any Area3D nodes)
	gravity_direction = get_gravity().normalized()
	
	# Ensure to keep up_direction correct
	set_up_direction(-gravity_direction)
	
# Handles mouse movement
func _unhandled_input(event):
	if GameManager.ship_state == GameManager.ShipState.INSIDE_SHIP:
		return
		
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	if GameManager.ship_state == GameManager.ShipState.INSIDE_SHIP:
		return
		
	var direction = _get_oriented_input()
	
	# If we are grounded, move in the correct direction
	if is_on_floor():
		if direction:
			velocity = direction * SPEED
		# Apply some smoother deceleration
		else: 
			velocity = velocity.lerp(Vector3.ZERO, 7.0 * delta)
	
	# Allow movement while in the air
	else:
		velocity = lerp(velocity, direction * SPEED, delta * 3.0)
		
	# If we are in the air, apply gravity over time
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Apply a jump force in the opposite direction of gravity
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity += -gravity_direction * JUMP_VELOCITY

	rotate_player(delta)
	move_and_slide()

func rotate_player(delta) -> void:
	var target_transform = Transform3D()
	target_transform.origin = global_position
		
	# Find the left hand side of the player
	# - gravity_direction represents the relative up, transform.basis.z represents forward.
	# .cross() finds the direction pependicular to these two directions to find the left direction
	var left_axis = -gravity_direction.cross(transform.basis.z).normalized()
	# Keep the z axis the same
	var my_z = global_transform.basis.z
	# Set target rotation with a basis (setting left, up and forward)
	target_transform.basis = Basis(left_axis, -gravity_direction, my_z).orthonormalized()
	
	# Iterpolate between the target quaternion and the current quaternion
	var current_rotation = global_transform.basis.get_rotation_quaternion()
	var target_rotation = target_transform.basis.get_rotation_quaternion()

	var interpolated_rotation = current_rotation.slerp(target_rotation, delta * ROTATION_SPEED) 
	
	# Applies the rotation to the player
	global_transform.basis = Basis(interpolated_rotation)

func _get_oriented_input() -> Vector3:
	# Get the raw input vector from the player
	var input_dir = Input.get_vector("left", "right", "backward", "forward")

	# Get the rotation of the camera
	var camera_basis = camera.global_basis
	# Get the relative up direction
	var ground_normal = -gravity_direction

	# Compute a directional vector that travels along this gravitational plane using vector projection
	# Literally slide the camera's forward direction along the ground to get the z direction
	var direction_z = -camera_basis.z.slide(ground_normal).normalized()
	# Get a cross product of the forawrd direction and the ground to find x
	var direction_x = direction_z.cross(ground_normal).normalized()

	# Combine the two to get the direction
	var dir = (direction_x * input_dir.x + direction_z * input_dir.y).normalized()
	
	return dir
