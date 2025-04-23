# @tool allows us to use extra debugging options within a script
@tool
extends Node3D

# ----- SPHERE -----

# export_groups allow us to organise many variables that we are making editable through the inspector
@export_group("Sphere")
# export_range allows us to define a minimum and maximum value without having to use maxi() or maxf()
@export_range(1.0, 256.0, 1.0) var radius := 8.0:
	# using set() in godot means that whenever the variable is changed, the code below will run
	set(new_radius):
		radius = new_radius
		update_terrain()
		update_water()

# resolution of the sphere referes to how many vertices/subdivisions the sphere will have
@export_range(4.0, 256.0, 4.0) var resolution := 64:
	set(new_resolution):
		resolution = new_resolution
		update_terrain()

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

# ----- WATER -----

@export_group("Water")

@export_range(0.0, 1.0, 0.05) var water_level := 0.0:
	set(new_water_level):
		water_level = new_water_level
		update_water()

@export_range(4.0, 256.0, 4.0) var water_resolution := 64:
	set(new_water_resolution):
		water_resolution  = new_water_resolution
		update_water()

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

func update_water() -> void:
	if !water or water_level == 0.0:
		$Water.visible = false
		return
		
	$Water.visible = true
	
	# radius is the minimum point of the terrain, radius + height is the maximum point
	var water_radius := lerpf(radius, radius + height, water_level)
	
	var mesh_arrays := create_sphere(water_radius, water_resolution)
	
	water.clear_surfaces()
	water.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)

	
