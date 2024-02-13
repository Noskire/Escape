extends Node

## Menu
var scr_mode = 0
var bg_mode = 1
var volume = 0.3

## Game
var best_score = 0

## Config
var save_path = "user://led.save"

func _ready():
	load_data()

func set_scr_mode(value):
	scr_mode = value
	save_data()

func set_bg_mode(value):
	bg_mode = value
	save_data()

func set_vol(value):
	volume = value
	save_data()

func set_best_score(value):
	best_score = value

func save_data():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(scr_mode)
	file.store_var(bg_mode)
	file.store_var(volume)
	file.store_var(best_score)

func load_data():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		scr_mode = file.get_var(scr_mode)
		bg_mode = file.get_var(bg_mode)
		volume = file.get_var(volume)
		best_score = file.get_var(best_score)
