extends Control

var progress = []
var sceneName

var scene_load_status = 0

func _ready():
	# Use multiple threads to load the main scene
	sceneName = "res://Entities/Terrain/Space/Space.tscn"
	ResourceLoader.load_threaded_request(sceneName)

# Check the progress of the loading every frame -> 1 means the scene has finished loading
func _process(_delta):
	scene_load_status = ResourceLoader.load_threaded_get_status(sceneName, progress)
	# Convert progress to a percentage
	$CenterContainer/Label.text = str(floor(progress[0] * 100)) + "%"
	
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var newScene = ResourceLoader.load_threaded_get(sceneName)
		get_tree().change_scene_to_packed(newScene)
	
