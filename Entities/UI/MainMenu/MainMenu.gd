extends Control

# Access the play and exit buttons by using their unique names (need to be toggled in the node tree)
func _ready():
	%Play.pressed.connect(play)
	%Quit.pressed.connect(exit)

# Load the main game scene after it has been loaded
func play():
	var loadingScreen = load("res://Entities/UI/LoadingScreen/LoadingScreen.tscn")
	
	get_tree().change_scene_to_packed(loadingScreen)

# Quits the game	
func exit():
	get_tree().quit()
