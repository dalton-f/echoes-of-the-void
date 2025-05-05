@tool
extends Node3D

@export var planet_scene: PackedScene

var planet_count := 5
var spawn_radius := 5000

#func _ready():
	#spawn_planets()
#
#func spawn_planets() -> void:
	## Loop up to the amount of planets we want in space
	#for i in range(planet_count):
		## Ccreate a new instance of the planet scene
		#var planet_instance = planet_scene.instantiate()
		#
		## generate a new random position
		#var new_position = Vector3(randf_range(-spawn_radius,spawn_radius),randf_range(-spawn_radius, spawn_radius), randf_range(-spawn_radius, spawn_radius))
#
		#planet_instance.position = new_position
		#
		## add it as a child
		#add_child(planet_instance)
