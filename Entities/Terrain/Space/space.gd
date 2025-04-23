@tool
extends Node3D

@export var planet_scene: PackedScene

func _ready():
	spawn_planets()

func spawn_planets() -> void:
	var new_planet_instance = planet_scene.instantiate()
	
	add_child(new_planet_instance)
