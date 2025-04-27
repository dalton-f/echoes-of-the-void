# @tool allows us to use extra debugging options within a script
@tool
extends Node3D

@export var player_scene: PackedScene

# ----- SPHERE -----

@export var radius := 500

var resolution := 32.0

# ----- TERRAIN -----

var height := radius / 2

@export_group("Terrain")

@export var noise := FastNoiseLite.new():
	set(new_noise):
		noise = new_noise
		
		if noise:
			noise.changed.connect(update_terrain)

@export var terrain_material: ShaderMaterial:
	set(new_terrain_material):
		terrain_material = new_terrain_material
		
		if terrain.get_surface_count():
			terrain.surface_set_material(0, terrain_material)

# ----- WATER -----

var water_level := 0.0

var water_resolution := 16.0

@export_group("Water")

@export var water_material: ShaderMaterial:
	set(new_water_material):
		water_material = new_water_material
		
		if water.get_surface_count():
			water.surface_set_material(0, water_material)

# we are creating a new ArrayMesh to ues as the terrain
var terrain := ArrayMesh.new()
var water := ArrayMesh.new()

# when the script loads for the first time, assign the correspondng mesh to the mesh instance
func _ready() -> void:
	$Terrain.mesh = terrain
	$Water.mesh = water
	
	# Randomize noise parameters here if desired
	noise.seed = randi() # Example: randomize the noise seed

	# Randomize water level
	water_level = randf_range(0.3, 0.6)

	# Debugging statements (will now run on each scene load)
	print("Planet radius: ", radius)
	print("Water level: ", water_level)
	print("Noise height: ", height)
	print("Noise seed: ", noise.seed) # Debugging noise seed
	
	update_terrain()
	update_water()
	
	randomize_colors()

func randomize_colors() -> void:
	# generate a random hue for the water
	var water_hue = randf()
	var water_saturation = randf_range(0.6, 1.0) 
	var water_value_start = randf_range(0.6, 1.0)
	
	var water_color_1 = Color.from_hsv(water_hue, water_saturation, water_value_start)
	var water_color_2 = Color.from_hsv(water_hue, water_saturation, max(0.0, water_value_start - 0.4)) # Slightly darker
	var water_color_3 = Color.from_hsv(water_hue, water_saturation, max(0.0, water_value_start - 0.8)) # Even darker

	var gradient = Gradient.new()
	
	gradient.set_colors([water_color_1, water_color_2, water_color_3])
	gradient.set_offsets([0.2, 0.4, 0.85])

	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	
	var water_material_instance = water_material.duplicate(true) as ShaderMaterial
	
	water_material_instance.set_shader_parameter("gradient", gradient_texture)
	water_material = water_material_instance
	
	var terrain_hue = fmod(water_hue + 0.2, 1.0)
	var terrain_saturation = randf_range(0.3, 1.0)
	var terrain_value_start = randf_range(0.6, 1.0)
	
	var terrain_color_1 = Color.from_hsv(terrain_hue, terrain_saturation, terrain_value_start - 0.55)
	var terrain_color_3 = Color.from_hsv(terrain_hue, terrain_saturation, max(0.0, terrain_value_start))
#
	var terrain_gradient = Gradient.new()
	
	terrain_gradient.set_colors([terrain_color_1, terrain_color_3])
	terrain_gradient.set_offsets([0.4, 0.85])
	
	var terrain_gradient_texture = GradientTexture1D.new()
	terrain_gradient_texture.gradient = terrain_gradient
	
	var terrain_material_instance = terrain_material.duplicate(true) as ShaderMaterial
	
	terrain_material_instance.set_shader_parameter("gradient", terrain_gradient_texture)
	terrain_material = terrain_material_instance

func create_sphere(sphere_radius: float, sphere_resolution: int) -> Array:
	# create a new primitive sphere mesh
	var sphere := SphereMesh.new()
	# set the size according to our default values
	sphere.radius = sphere_radius
	sphere.height = sphere_radius * 2
	
	# set the radial segments and rings based on our selected resolution to control the detail
	sphere.radial_segments = sphere_resolution * 2
	sphere.rings = sphere_resolution
	
	# return the mesh arrays used to make up the surface of this mesh
	return sphere.get_mesh_arrays()

func get_noise(vertex: Vector3) -> float:
	# First layer of noise
	var noise_value = (noise.get_noise_3dv(vertex.normalized() * 2.0) + 1) / 2.0
	
	return noise_value * height

# update_terrain is a function that takes no input and returns nothing
func update_terrain() -> void:
	if !terrain or !noise:
		return

	var mesh_arrays := create_sphere(radius, resolution)
	var vertices: PackedVector3Array = mesh_arrays[ArrayMesh.ARRAY_VERTEX]

	for i: int in vertices.size():
		var vertex := vertices[i]
		vertex += vertex.normalized() * get_noise(vertex)

		vertices[i] = vertex
		
	# remove any pre-existing surfaces from the mesh	
	terrain.clear_surfaces()
	# use the generated mesh arrays to convert out primitive sphere mesh into an array mesh
	terrain.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	# add the material to the planet after generating a random color
	terrain.surface_set_material(0, terrain_material)
	
	# create a collision shape with create_trimesh_shape and attach it to a static body 3d as a child of the terrain
	var collision = CollisionShape3D.new()
	collision.shape = $Terrain.mesh.create_trimesh_shape()

	var static_body = StaticBody3D.new()
	static_body.add_child(collision)
	
	$Terrain.add_child(static_body)
		
func update_water() -> void:
	if !water:
		return
	
	# radius is the minimum point of the terrain, radius + height is the maximum point
	var water_radius := lerpf(radius, radius + height, water_level)
	# create another sphere mesh representing where the water would be
	var mesh_arrays := create_sphere(water_radius, water_resolution)
	
	# add the mesh
	water.clear_surfaces()
	water.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	water.surface_set_material(0, water_material)
	
	var water_collision = CollisionShape3D.new()
	water_collision.shape = $Water.mesh.create_trimesh_shape()

	var water_static_body = StaticBody3D.new()
	water_static_body.add_child(water_collision)
	
	$Water.add_child(water_static_body)
