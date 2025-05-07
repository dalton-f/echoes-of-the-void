# @tool allows the script to be executed within the editor which is helpful for debugging
@tool
extends Node3D

# Planet sphere base variables
const planet_radius := 250.0

const planet_resolution := 32

# Terrain variables
const noise_height := planet_radius / 2

const TERRAIN_GRADIENT_OFFSETS = [0.3, 0.85]

# Planet gravity variables
@onready var gravitational_influence_sphere = $Gravitational_Influence

# @export is used to mark variables that should be editable in the inspector
@export_group("Terrain")

@export var noise := FastNoiseLite.new():
	set(new_noise):
		noise = new_noise
		
		if noise:
			noise.changed.connect(generate_terrain_mesh)

@export var terrain_material: ShaderMaterial:
	set(new_terrain_material):
		terrain_material = new_terrain_material
		
		if terrain.get_surface_count():
			terrain.surface_set_material(0, terrain_material)

# Water sphere variables
var water_level := 0.0

var water_resolution := 16

const WATER_GRADIENT_OFFSETS = [0.2, 0.4, 0.85]

@export_group("Water")

@export var water_material: ShaderMaterial:
	set(new_water_material):
		water_material = new_water_material
		
		if water.get_surface_count():
			water.surface_set_material(0, water_material)


# To generate the mesh shape, we use an ArrayMesh as we have more control over the vertices o create surfaces
var terrain := ArrayMesh.new()
var water := ArrayMesh.new()

# _ready loads once when the node is loaded into the scene - this func takes no parameters and returns nothing
func _ready() -> void:
	prepare_meshes()
	randomise_values()
	
	#print_debugging_statements()

	generate_terrain_mesh()
	generate_water_mesh()
	
	randomize_colors()

# Set the corresponding ArrayMesh to each MeshInterface
func prepare_meshes() -> void:
	$Terrain/TerrainMesh.mesh = terrain
	$Water/WaterMesh.mesh = water

# Randomise some of the planet's properties by updating the noise seed and water level
func randomise_values() -> void:
	noise.seed = randi()
	
	water_level = randf_range(0.2, 0.7)
	
	gravitational_influence_sphere.gravity = randf_range(3.0, 12.0)

func print_debugging_statements() -> void:
	print("planet_radius: ", planet_radius)
	print("water_level: ", water_level)
	print("noise_height: ", noise_height)
	print("noise.seed: ", noise.seed)
	print("gravity: ", gravitational_influence_sphere.gravity)
	
func randomize_colors() -> void:
	var water_hue = randf()
	var water_saturation = randf_range(0.6, 1.0) 
	var water_value_start = randf_range(0.6, 1.0)
	
	var water_color_start = create_hsv_color(water_hue, water_saturation, water_value_start)
	var water_color_mid = create_hsv_color(water_hue, water_saturation, water_value_start, -0.4)
	var water_color_end = create_hsv_color(water_hue, water_saturation, water_value_start, -0.6)
	
	var water_gradient_texture = generate_gradient_texture([water_color_start, water_color_mid, water_color_end], WATER_GRADIENT_OFFSETS)

	# Duplicate the shader material so each instance of the planet has different colors
	var water_material_instance = water_material.duplicate(true) as ShaderMaterial
	# Apply the new gradient texture
	water_material_instance.set_shader_parameter("gradient", water_gradient_texture)
	water_material = water_material_instance
	
	# Ensure that the terrain hue is dissimilar enough from the water
	var terrain_hue = fmod(water_hue + 0.3, 1.0)
	var terrain_saturation = randf_range(0.5, 1.0)
	var terrain_value_start = randf_range(0.6, 1.0)
	
	var terrain_color_start = create_hsv_color(terrain_hue, terrain_saturation, terrain_value_start, -0.6)
	var terrain_color_end = create_hsv_color(terrain_hue, terrain_saturation, terrain_value_start, 0.4)
#
	var terrain_gradient_texture = generate_gradient_texture([terrain_color_start, terrain_color_end], TERRAIN_GRADIENT_OFFSETS)

	var terrain_material_instance = terrain_material.duplicate(true) as ShaderMaterial
	
	terrain_material_instance.set_shader_parameter("gradient", terrain_gradient_texture)
	terrain_material = terrain_material_instance

func create_hsv_color(hue: float, saturation: float, value_start: float, value_offset: float = 0.0) -> Color:
	return Color.from_hsv(hue, saturation, max(0.0, value_start + value_offset))

func generate_gradient_texture(colors: Array, offsets: Array) -> GradientTexture1D:
	var gradient = Gradient.new()
	
	gradient.set_colors(colors)
	gradient.set_offsets(offsets)
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	
	return gradient_texture
	
# Generates a basic Godot 3d sphere mesh given a radius and resolution to control the mesh subdivision detail
func create_sphere(sphere_radius: float, sphere_resolution: int) -> Array:
	var sphere := SphereMesh.new()
	sphere.radius = sphere_radius
	sphere.height = sphere_radius * 2
	
	sphere.radial_segments = sphere_resolution * 2
	sphere.rings = sphere_resolution
	
	return sphere.get_mesh_arrays()

# Return the noise value for each vertex remapped to a value between 0.0 and 1.0
func get_noise(vertex: Vector3) -> float:
	var noise_value = (noise.get_noise_3dv(vertex.normalized() * 2.0) + 1) / 2.0
	
	return noise_value * noise_height

func generate_terrain_mesh() -> void:
	if !terrain or !noise:
		return
		
	# Create a basic sphere given the planet radius and resolution
	var mesh_arrays := create_sphere(planet_radius, planet_resolution)
	# Extract the vertices data
	var vertices: PackedVector3Array = mesh_arrays[ArrayMesh.ARRAY_VERTEX]

	# Loop over each vertex and apply noise to it before updating the array
	for i: int in vertices.size():
		var vertex := vertices[i]
		vertex += vertex.normalized() * get_noise(vertex)

		vertices[i] = vertex
	
	# Clear any pre-existing ArrayMesh surfaces
	terrain.clear_surfaces()
	# Generate the new surface using triangles
	terrain.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	

	# Add the shader material
	terrain.surface_set_material(0, terrain_material)
	
	# Update the collision shape to match the new mesh
	$Terrain/TerrainCollisionShape.shape = $Terrain/TerrainMesh.mesh.create_trimesh_shape()
		
func generate_water_mesh() -> void:
	if !water:
		return
	
	# Generate the water_radius by using the water_level to generate a result between the minimum and maximum height of the planet
	var water_radius := lerpf(planet_radius, planet_radius + noise_height, water_level)
	var mesh_arrays := create_sphere(water_radius, water_resolution)
	
	water.clear_surfaces()
	water.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	water.surface_set_material(0, water_material)
	
	$Water/WaterCollisionShape.shape = 	$Water/WaterMesh.mesh.create_trimesh_shape()
