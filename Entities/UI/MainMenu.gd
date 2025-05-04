extends Control

# Access the play and exit buttons by using their unique names (need to be toggled in the node tree)
func _ready():
	%Play.pressed.connect(play)
	%Quit.pressed.connect(exit)

# Load the main game scene
func play():
	get_tree().change_scene_to_file("res://Entities/Terrain/Space/Space.tscn")

# Quits the game	
func exit():
	get_tree().quit()
