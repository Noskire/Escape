extends CharacterBody2D

var mov_velocity = 500
var accel = 7

func _process(delta):
	var dir = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	velocity = velocity.lerp(dir * mov_velocity, accel * delta)
	move_and_slide()
