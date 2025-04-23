# @tool allows us to use extra debugging options within a script
@tool
extends Node3D

# export_groups allow us to organise many variables that we are making editable through the inspector
@export_group("Sphere")
# export_range allows us to define a minimum and maximum value without having to use maxi() or maxf()
@export_range(1, 256, 1) var radius := 8.0:
	# using set() in godot means that whenever the variable is changed, the code below will run
	set(new_radius):
		radius = maxf(1.0, new_radius)
		update_terrain()

# resolution of the sphere referes to how many vertices/subdivisions the sphere will have
@export_range(4, 256, 4) var resolution := 64:
	set(new_resolution):
		resolution = new_resolution
		update_terrain()

# we are creating a new ArrayMesh to ues as the terrain
var terrain := ArrayMesh.new()

# when the script loads for the first time, assign the correspondng mesh to the mesh instance
func _ready() -> void:
	$Terrain.mesh = terrain
	
	update_terrain()

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
	
# update_terrain is a function that takes no input and returns nothing
func update_terrain() -> void:
	if !terrain:
		return
	
	var mesh_arrays := create_sphere(radius, resolution)
	terrain.clear_surfaces()
	# use the generated mesh arrays to convert out primitive sphere mesh into an array mesh
	terrain.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	
