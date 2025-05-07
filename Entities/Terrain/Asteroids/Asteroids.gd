@tool
extends Node3D

@export var asteroid_count := 50
@export var belt_radius := 5000.0
@export var belt_thickness := 500.0
@export var asteroid_size_min := 10.0
@export var asteroid_size_max := 100.0
@export var asteroid_noise_height := 30.0

@export var noise := FastNoiseLite.new()

func _ready() -> void:
	randomise_values()
	
	for _i in asteroid_count:
		generate_asteroid()

func randomise_values() -> void:
	noise.seed = randi()

func get_noise(vertex: Vector3) -> float:
	var noise_value = (noise.get_noise_3dv(vertex.normalized() * 2.0) + 1) / 2.0
	return noise_value

func create_sphere(sphere_radius: float, sphere_resolution: int) -> Array:
	var sphere := SphereMesh.new()
	sphere.radius = sphere_radius
	sphere.height = sphere_radius * 2
	sphere.radial_segments = sphere_resolution / 2.0
	sphere.rings = sphere_resolution / 4.0
	return sphere.get_mesh_arrays()

func generate_asteroid() -> void:
	var asteroid_radius = randf_range(asteroid_size_min, asteroid_size_max)
	var mesh_arrays = create_sphere(asteroid_radius, 64.0)
	var vertices: PackedVector3Array = mesh_arrays[ArrayMesh.ARRAY_VERTEX]

	for i in vertices.size():
		var vertex = vertices[i]
		vertex += vertex.normalized() * get_noise(vertex) * asteroid_noise_height
		vertices[i] = vertex

	var asteroid_mesh = ArrayMesh.new()
	asteroid_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

	var asteroid_instance = MeshInstance3D.new()
	asteroid_instance.mesh = asteroid_mesh

	# Calculate random position within the belt
	var random_on_sphere = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * belt_radius
	var random_offset = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * belt_thickness / 2
	asteroid_instance.position = random_on_sphere + random_offset

	add_child(asteroid_instance)
