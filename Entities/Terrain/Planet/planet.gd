# @tool allows us to use extra debugging options within a script
@tool
extends Node3D

var rng = RandomNumberGenerator.new()

# ----- SPHERE -----
		
var radius := rng.randf_range(10.0, 256.0)

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

var water_level := rng.randf_range(0.2, 0.8)

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
	var albedo = Color(randf(), randf(), randf())
	terrain_material.albedo_color = albedo
	terrain.surface_set_material(0, terrain_material)

func update_water() -> void:
	if !water:
		return

	if water_level == 0.0:
		$Water.visible = false
		return

	$Water.visible = true
	
	# radius is the minimum point of the terrain, radius + height is the maximum point
	var water_radius := lerpf(radius, radius + height, water_level)
	# create another sphere mesh representing where the water would be
	var mesh_arrays := create_sphere(water_radius, water_resolution)
	
	# add the mesh
	water.clear_surfaces()
	water.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	# add the material to the planet after generating a random color
	var albedo = Color(randf(), randf(), randf())
	water_material.albedo_color = albedo
	water.surface_set_material(0, water_material)
