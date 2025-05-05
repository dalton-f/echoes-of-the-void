# https://github.com/RyanRemer/ship_controller/blob/main/ship_controller/player_v5.gd
extends CharacterBody3D

@export var max_speed = 75.0;
@export var acceleration = 20.0;
@export var rotation_speed = 5.0;

var gravity = 9.8;

@onready var ship_body : Node3D = $InfraredFurtive;

const BACKWARD_RATIO = 0.5;

var speed = 0;
var drift_direction = Vector3.FORWARD;

func _process(delta):
	if GameManager.ship_state == GameManager.ShipState.OUTSIDE_SHIP:
		# Apply gravity to the ship
		velocity.y -= gravity * delta
		# Stop any momentum
		velocity.x = 0
		velocity.z = 0
	
		move_and_slide()
		
		return
		
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
	$Camera3D.make_current()


	# Rotate Player
	var relative_mouse = _get_relative_mouse();
	var new_basis = transform.basis;
	basis = new_basis.rotated(basis.x, relative_mouse.y * rotation_speed * delta);
	basis = new_basis.rotated(basis.y, -relative_mouse.x * rotation_speed * delta);
	basis = new_basis.orthonormalized();
	transform.basis = new_basis;
		
	# Rotate Ship
	var ship_basis = Basis.IDENTITY;
	var new_scale = ship_body.scale;
	ship_basis = ship_basis.rotated(Vector3.UP, -relative_mouse.x * rotation_speed / 2.0);
	ship_basis = ship_basis.rotated(Vector3.RIGHT, relative_mouse.y * rotation_speed);
	ship_basis = ship_basis.rotated(ship_basis.z, relative_mouse.x * rotation_speed);
	ship_basis = ship_basis.orthonormalized();
	ship_body.basis = ship_basis;
	ship_body.scale = new_scale;
	
	_move_forward(delta)
			
func _move_forward(delta):
	var forward = ship_body.global_transform.basis.z.normalized();
	
	if Input.is_action_pressed("forward"):
		speed = min(speed + acceleration * delta, max_speed);
	elif Input.is_action_pressed("backward"):
		speed = max(speed - acceleration * delta, -max_speed * BACKWARD_RATIO);
	else:
		speed -= speed * delta;
	
	velocity = forward * speed;
	
	move_and_slide();

func _get_relative_mouse() -> Vector2:
	var viewport = get_viewport();
	var mouse_position = viewport.get_mouse_position();
	var center = viewport.size / 2.0;
	var mouse_direction = mouse_position - center;
	
	var size = max(viewport.size.x, viewport.size.y);
	return mouse_direction / size;
