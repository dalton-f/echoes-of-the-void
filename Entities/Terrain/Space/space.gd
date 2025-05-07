extends Node3D

@export var planet_scene: PackedScene
@export var asteroid_cluster: PackedScene

@onready var pause_menu_ui = $Pause
var paused = false

var planet_count := 15
var spawn_radius := 35000
var asteroid_count := 5

func _ready():
	spawn_planets()
	spawn_asteroids()

func _process(_delta) -> void:
	if Input.is_action_just_pressed("pause"):
		pause_menu()

func spawn_planets() -> void:
	for i in range(planet_count):
		var planet_instance = planet_scene.instantiate()
		var new_position = Vector3(randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius))
		
		planet_instance.position = new_position
		add_child(planet_instance)

func spawn_asteroids() -> void:
	for i in range(asteroid_count):
		var asteroids = asteroid_cluster.instantiate()
		var new_position = Vector3(randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius))
		asteroids.position = new_position
		add_child(asteroids)

func pause_menu():
	if paused:
		pause_menu_ui.hide()
		Engine.time_scale = 1
		get_tree().paused = false
	else:
		pause_menu_ui.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Engine.time_scale = 0
		get_tree().paused = true

		
	paused = !paused
