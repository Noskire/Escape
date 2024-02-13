extends Control

func _ready():
	AudioServer.set_bus_volume_db(0, linear_to_db(Global.volume))

func to_menu():
	get_tree().change_scene_to_file("res://src/scene.tscn")
