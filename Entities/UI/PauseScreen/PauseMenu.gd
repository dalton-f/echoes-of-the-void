extends Control

@onready var main = $".."

func _ready():
	%Resume.pressed.connect(resume)
	%Quit.pressed.connect(exit)

func resume():
	main.pause_menu()

# Quits the game	
func exit():
	get_tree().quit()
