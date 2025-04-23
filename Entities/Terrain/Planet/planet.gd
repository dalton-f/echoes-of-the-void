# @tool allows us to use extra debugging options within a script
@tool
extends Node3D

# ----- SPHERE -----
		
var radius := randf_range(10.0, 256.0)

var resolution := 64.0

# ----- TERRAIN -----

@export_group("Terrain")

@export var noise := FastNoiseLite.new():
	set(new_noise):
		noise = new_noise
		
		if noise:
			noise.changed.connect(update_terrain)
			
@export_range(1.0, 256.0, 1.0) var height := 1.0:
	set(new_height):
		height = new_height
		
		update_terrain()
		update_water()

@export var terrain_material: Material:
	set(new_terrain_material):
		terrain_material = new_terrain_material
		
		if terrain.get_surface_count():
			terrain.surface_set_material(0, terrain_material)

# ----- WATER -----

var water_level := randf_range(0.2, 0.8)

var water_resolution := 64.0

@export_group("Water")

@export var water_material: Material:
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
	
	# Generate a random hue for the water
	var water_hue = randf()
	var water_saturation = randf_range(0.5, 1.0) # Keep saturation relatively high
	var water_value = randf_range(0.5, 1.0)
	var water_color = Color.from_hsv(water_hue, water_saturation, water_value)
	water_material.albedo_color = water_color

	# Ensure the terrain hue is significantly different (e.g., opposite on the wheel)
	var terrain_hue = fmod(water_hue + 0.5, 1.0) # Adding 0.5 puts it on the opposite side
	var terrain_saturation = randf_range(0.5, 1.0)
	var terrain_value = randf_range(0.5, 1.0)
	var terrain_color = Color.from_hsv(terrain_hue, terrain_saturation, terrain_value)
	terrain_material.albedo_color = terrain_color
	
	# Debugging statements
	
	print("Planet radius: ", radius)
	print("Water level: ", water_level)
	
	update_terrain()
	update_water()

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
	# essentially this code just gets a noise value for a vertex from a value between 0 and 1
	return (noise.get_noise_3dv(vertex.normalized() * 2.0) + 1) / 2 * height

# update_terrain is a function that takes no input and returns nothing
func update_terrain() -> void:
	if !terrain or !noise:
		return
	
	var mesh_arrays := create_sphere(radius, resolution)
	# extract the vertex array from the mesh arrays
	var vertices: PackedVector3Array = mesh_arrays[ArrayMesh.ARRAY_VERTEX]
		
	# loop over each vertex to add noise
	for i:int in vertices.size():
		# select the current vertex
		var vertex := vertices[i]
		# add noise to the vertex
		vertex += vertex.normalized() * get_noise(vertex)
		# update the vertices array used to generate the mesh
		vertices[i] = vertex
		
	# remove any pre-existing surfaces from the mesh	
	terrain.clear_surfaces()
	# use the generated mesh arrays to convert out primitive sphere mesh into an array mesh
	terrain.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	# add the material to the planet after generating a random color
	terrain.surface_set_material(0, terrain_material)

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
