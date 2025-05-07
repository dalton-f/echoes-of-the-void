extends Node

enum ShipState {
	OUTSIDE_SHIP,
	INSIDE_SHIP
}

var ship_state = ShipState.OUTSIDE_SHIP

func _process(_delta: float) -> void:
	# Very simple way to switch between flying and walking
	if Input.is_action_just_pressed("interact"):
		if ship_state == ShipState.OUTSIDE_SHIP:
			ship_state = ShipState.INSIDE_SHIP
		elif ship_state == ShipState.INSIDE_SHIP:
			ship_state = ShipState.OUTSIDE_SHIP
