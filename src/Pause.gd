extends Control

func _input(event):
	if event.is_action_pressed("Escape"):
		#get_tree().paused = !get_tree().is_paused()
		$"..".game_over()

func _on_animation_finished(_anim_name):
	get_tree().paused = false
