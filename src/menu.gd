extends Control

@onready var scr_mode = $Options/Grid/ScrMode
@onready var bg_mode = $Options/Grid/BgModes
@onready var cb_mode = $Options/Grid/CBModes
@onready var col_slider = $Options/Grid/VolSlider

func _ready():
	scr_mode._select_int(Global.scr_mode)
	if Global.scr_mode == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif Global.scr_mode == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	bg_mode._select_int(Global.bg_mode)
	$"../Qix".set_bg()
	
	cb_mode._select_int(Global.cb_mode)
	## TODO ##
	
	col_slider.value = Global.volume
	AudioServer.set_bus_volume_db(0, linear_to_db(Global.volume))

func _on_new_game_button_up():
	visible = false
	await get_tree().create_timer(0.5).timeout
	$"../Qix/Pause".visible = false
	$"../AnimationPlayer".play("new_game")
	await get_tree().create_timer(1.5).timeout
	$"../Qix".new_game()

func back_to_menu():
	$"../AnimationPlayer".play("back_to_menu")
	await get_tree().create_timer(1.5).timeout
	visible = true

func _on_options_button_up():
	$Initial.visible = false
	$Options.visible = true

func _on_back_button_up():
	$Initial.visible = true
	$Options.visible = false

func _on_scr_mode_item_selected(index):
	Global.set_scr_mode(index)
	if index == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	elif index == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_bg_modes_item_selected(index):
	Global.set_bg_mode(index)
	$"../Qix".set_bg(index)

func _on_cb_modes_item_selected(index):
	Global.set_cb_mode(index)
	## TODO ##
	# Place some colors as demonstration at the side of the button

func _on_vol_slider_value_changed(value):
	Global.set_vol(value)
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	## Audio test
	#if not $AudioStreamPlayer.is_playing():
		#$AudioStreamPlayer.play()
