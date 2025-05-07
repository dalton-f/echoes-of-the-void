# https://github.com/RyanRemer/ship_controller/blob/main/ship_controller/player_v5.gd
extends CharacterBody3D

@export var max_speed = 500.0;
@export var acceleration = 300.0;
@export var rotation_speed = 20.0;

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

	var relative_mouse = _get_relative_mouse();

	 #Rotate Player
	var player_basis = Basis.IDENTITY
	player_basis = player_basis.rotated(Vector3.UP, -relative_mouse.x * rotation_speed / 2.0)
	player_basis = player_basis.rotated(Vector3.RIGHT, relative_mouse.y * rotation_speed)
	transform.basis = player_basis.orthonormalized()
	
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
