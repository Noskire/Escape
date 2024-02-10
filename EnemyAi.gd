extends Sprite2D

var mov_velocity = 500
var state = "Moving" # "Choosing", "Attacking"
var dir = Vector2(1, 0)

func _ready():
	pass # Replace with function body.

func _process(delta):
	if state == "Moving":
		var movement = round(mov_velocity * delta)
		var func_return = $"..".can_move(position, dir, movement)
		position = func_return[1]
		if not func_return[0]:
			state = "Choosing"
	elif state == "Choosing":
		dir = Vector2(0, 1)
		state = "Moving"
