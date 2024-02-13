extends Node2D

@onready var text_rect = $TextureRect

@onready var focus_label = $Control/Focus
@onready var decrease_label = $Control/Decrease
@onready var focus_anim = $Control/FocusAnim

@onready var score_label = $Control/Score
@onready var increase_label = $Control/Increase
@onready var increase_anim = $Control/ScoreAnim

@onready var go_highscore_label = $Pause/VBox/HighScore
@onready var go_score_label = $Pause/VBox/Score

@onready var player = $Player
@onready var pause_menu = $Pause

@onready var audio_player = $AudioStreamPlayer

var hit_path = preload("res://assets/hit_enemy.wav")
var loop_path = preload("res://assets/close_loop.wav")

var array = []
	# 0 - empty
	# 1 - line
	# 2 - making line
	# 3 - fill
	# 4+ - enemy line id
var size = Vector2(1920, 1080)

var image
var line_color = Color("#000000")
var path_color = Color("#ffffff")
var fill_color = Color("#172561") #253b99

var filled_area = 0.0
var total_area = 2073600.0
var pct # Percentage
var min_focus = 35

var score = 0
var score_time = 0
var score_delay = 1.0
var highscore = false

var enemy_path = preload("res://src/enemy_ai.tscn")
var safe_dist = 500
var new_enemy_time = 0
var new_enemy_delay = 15.0
var num_enemies = 0

func _ready():
	reset_game()

func set_bg():
	var value = Global.bg_mode
	if value == 0:
		$TextureRect.set_texture(load("res://assets/bg_empty.png"))
	elif value == 1:
		$TextureRect.set_texture(load("res://assets/bg_gauss.png"))

func reset_game():
	set_bg()
	image = text_rect.get_texture().get_image()
	
	array.clear()
	for x in size.x:
		array.append([])
		for y in size.y:
			if x == 0 or x == 1919 or y == 0 or y == 1079:
				array[x].append(1) # line
				image.set_pixel(x, y, line_color)
			else:
				array[x].append(0) # empty
	
	score = 0
	score_time = 0
	highscore = false
	score_label.set_text("Entertainment: 0")
	filled_area = 0
	focus_label.set_text("Focus: 100%")
	pct = 100
	var lines = $Lines.get_children()
	for l in lines:
		l.queue_free()
	
	new_enemy_time = 0
	remove_enemies()
	$LineTemp.clear_points()
	add_enemy(Vector2(0, 0), 4)
	num_enemies = 1
	
	update_board()
	
	get_tree().paused = true

func update_board():
	#if image.get_pixel(0, 0).is_equal_approx(Color("#FFFFFF")):
	var texture = ImageTexture.create_from_image(image)
	text_rect.set_texture(texture)
	
	var diff = pct
	pct = round((1.0 - (filled_area / total_area)) * 100)
	if diff > pct:
		focus_label.set_text("Focus: " + str(pct) + "%")
		diff -= pct
		decrease_label.set_text("-" + str(diff))
		focus_anim.play("decrease")
		
		if pct < min_focus:
			game_over()

func add_enemy(pos, id):
	var enemy = enemy_path.instantiate()
	$Enemies.add_child(enemy)
	enemy.position = pos
	enemy.id = id
	enemy.set_frame(id % 3)
	var enemy_line = Line2D.new()
	find_child("Lines").add_child(enemy_line)
	enemy.line = enemy_line

func remove_enemies():
	var enemies = $Enemies.get_children()
	for e in enemies:
		e.queue_free()

func _process(delta):
	score_time += delta
	if score_time > score_delay:
		score_time -= score_delay
		score += pct
		score_label.set_text("Entertainment: " + str(round(score)))
		
		increase_label.set_text("+" + str(round(pct)))
		increase_anim.play("increase")
	
	new_enemy_time += delta
	if new_enemy_time > new_enemy_delay:
		new_enemy_time -= new_enemy_delay
		var pos
		if num_enemies % 4 == 0:
			pos = Vector2(0, 0)
		elif num_enemies % 4 == 1:
			pos = Vector2(0, size.y-1)
		elif num_enemies % 4 == 2:
			pos = Vector2(size.x-1, size.y-1)
		elif num_enemies % 4 == 3:
			pos = Vector2(size.x-1, 0)
		add_enemy(pos, 4+num_enemies)
		num_enemies += 1

## Get enemy position, finds and returns the number of paths (and which) it can choose
## Returns an array with: [num_options, up, right, down, left], the last four will be 1 if an option, -1 otherwise
func get_dirs(pos):
	var result = [0, -1, -1, -1, -1]
	if pos.y > 0: # Up
		if array[pos.x][pos.y-1] == 1:
			result[0] += 1 # More one option
			result[1] = 1 # This way is valid
	if pos.x < size.x-1: # Right
		if array[pos.x+1][pos.y] == 1:
			result[0] += 1
			result[2] = 1
	if pos.y < size.y-1: # Down
		if array[pos.x][pos.y+1] == 1:
			result[0] += 1 # More one option
			result[3] = 1 # This way is valid
	if pos.x > 0: # Left
		if array[pos.x-1][pos.y] == 1:
			result[0] += 1
			result[4] = 1
	return result

## Get enemy position, direction and how much it wants to move... Checks how far it can move
## Returns an array with two values: [bool, new_position], will be true if all 'movement' was used, false otherwise
func move(pos, dir, movement):
	if dir == Vector2(0, -1): # Up
		for y in range(1, movement+1):
			if pos.y-y < 0:
				return [false, Vector2(pos.x, pos.y-y+1)] # Returns previous point
			if array[pos.x][pos.y-y] != 1: # Can't move beyond that point
				return [false, Vector2(pos.x, pos.y-y+1)] # Returns previous point
			## Checks for intersection
			if pos.x+1 < size.x: # Right
				if array[pos.x+1][pos.y-y] == 1: # Intersection
					return [false, Vector2(pos.x, pos.y-y)] # Returns actual point
			if pos.x > 0: # Left
				if array[pos.x-1][pos.y-y] == 1: # Intersection
					return [false, Vector2(pos.x, pos.y-y)] # Returns actual point
		return [true, Vector2(pos.x, pos.y-movement)]
	elif dir == Vector2(1, 0): # Right
		for x in range(1, movement+1):
			if pos.x+x >= size.x:
				return [false, Vector2(pos.x+x-1, pos.y)]
			if array[pos.x+x][pos.y] != 1: # Can't move beyond that point
				return [false, Vector2(pos.x+x-1, pos.y)]
			## Checks for intersection
			if pos.y > 0: # Up
				if array[pos.x+x][pos.y-1] == 1:
					return [false, Vector2(pos.x+x, pos.y)]
			if pos.y+1 < size.y: # Down
				if array[pos.x+x][pos.y+1] == 1:
					return [false, Vector2(pos.x+x, pos.y)]
		return [true, Vector2(pos.x+movement, pos.y)]
	elif dir == Vector2(0, 1): # Down
		for y in range(1, movement+1):
			if pos.y+y >= size.y:
				return [false, Vector2(pos.x, pos.y+y-1)]
			if array[pos.x][pos.y+y] != 1: # Can't move beyond that point
				return [false, Vector2(pos.x, pos.y+y-1)]
			## Checks for intersection
			if pos.x+1 < size.x: # Right
				if array[pos.x+1][pos.y+y] == 1: # Intersection
					return [false, Vector2(pos.x, pos.y+y)] # Returns actual point
			if pos.x > 0: # Left
				if array[pos.x-1][pos.y+y] == 1: # Intersection
					return [false, Vector2(pos.x, pos.y+y)] # Returns actual point
		return [true, Vector2(pos.x, pos.y+movement)]
	else: #dir == Vector2(-1, 0): # Left
		for x in range(1, movement+1):
			if pos.x-x < 0:
				return [false, Vector2(pos.x-x+1, pos.y)]
			if array[pos.x-x][pos.y] != 1: # Can't move beyond that point
				return [false, Vector2(pos.x-x+1, pos.y)]
			## Checks for intersection
			if pos.y > 0: # Up
				if array[pos.x-x][pos.y-1] == 1:
					return [false, Vector2(pos.x-x, pos.y)]
			if pos.y+1 < size.y: # Down
				if array[pos.x-x][pos.y+1] == 1:
					return [false, Vector2(pos.x-x, pos.y)]
		return [true, Vector2(pos.x-movement, pos.y)]

## Get enemy position, direction and how much it wants to attack... Checks how far it can attack
## Returns an array with two values: [int, new_position], will be 0 if all 'movement' was used, -1 if invalid path, 1 if close line
func attack(enemy, pos, dir, movement, id):
	if dir == Vector2(0, -1): # Up
		for y in range(1, movement+1):
			if pos.y-y < 0:
				return [-1, Vector2(pos.x, pos.y-y+1)] # Invalid path, returns previous point
			if array[pos.x][pos.y-y] == 1: # Stops on the line
				close_loop(id)
				return [1, Vector2(pos.x, pos.y-y)] # Closed loop
			if array[pos.x][pos.y-y] != 0: # Invalid path
				return [-1, Vector2(pos.x, pos.y-y+1)] # Returns previous point
			# if array(pos) == 0, then empty space, do nothing
			## Draw line
			array[pos.x][pos.y-y] = id
			enemy.pts.append(Vector2(pos.x, pos.y-y))
		return [0, Vector2(pos.x, pos.y-movement)] # Used all movement
	elif dir == Vector2(1, 0): # Right
		for x in range(1, movement+1):
			if pos.x+x >= size.x:
				return [-1, Vector2(pos.x+x-1, pos.y)]
			if array[pos.x+x][pos.y] == 1: # Stops on the line
				close_loop(id)
				return [1, Vector2(pos.x+x, pos.y)] # Closed loop
			if array[pos.x+x][pos.y] != 0: # Can't move beyond that point
				return [-1, Vector2(pos.x+x-1, pos.y)]
			array[pos.x+x][pos.y] = id
			enemy.pts.append(Vector2(pos.x+x, pos.y))
		return [0, Vector2(pos.x+movement, pos.y)]
	elif dir == Vector2(0, 1): # Down
		for y in range(1, movement+1):
			if pos.y+y >= size.y:
				return [-1, Vector2(pos.x, pos.y+y-1)]
			if array[pos.x][pos.y+y] == 1:
				close_loop(id)
				return [1, Vector2(pos.x, pos.y+y)] # Closed loop
			if array[pos.x][pos.y+y] != 0: # Can't move beyond that point
				return [-1, Vector2(pos.x, pos.y+y-1)]
			array[pos.x][pos.y+y] = id
			enemy.pts.append(Vector2(pos.x, pos.y+y))
		return [0, Vector2(pos.x, pos.y+movement)]
	else: #dir == Vector2(-1, 0): # Left
		for x in range(1, movement+1):
			if pos.x-x < 0:
				return [-1, Vector2(pos.x-x+1, pos.y)]
			if array[pos.x-x][pos.y] == 1:
				close_loop(id)
				return [1, Vector2(pos.x-x, pos.y)] # Closed loop
			if array[pos.x-x][pos.y] != 0: # Can't move beyond that point
				return [-1, Vector2(pos.x-x+1, pos.y)]
			array[pos.x-x][pos.y] = id
			enemy.pts.append(Vector2(pos.x-x, pos.y))
		return [0, Vector2(pos.x-movement, pos.y)]

func close_loop(id):
	var enemies = $Enemies.get_children()
	for e in enemies:
		if e.id == id:
			for pt in e.pts:
				array[pt.x][pt.y] = 1
				image.set_pixel(pt.x, pt.y, line_color)
			break
	audio_player.set_stream(loop_path)
	audio_player.play()
	update_board()

func close_rect(loop_points):
	if loop_points.size() == 2: # Line
		if loop_points[0].x == loop_points[1].x: # Vertical Line
			var y
			var dir
			var dist = -1
			if  loop_points[0].y > loop_points[1].y:
				y = loop_points[1].y + round((loop_points[0].y - loop_points[1].y) / 2)
			else:
				y = loop_points[0].y + round((loop_points[1].y - loop_points[0].y) / 2)
			for x in range(loop_points[0].x+1, size.x): # Right
				if array[x][y] != 0: # Not empty
					# Saves dir and 'best' dist until now
					dist = x - loop_points[0].x
					dir = 1
					break
			for x in range(loop_points[0].x-1, -1, -1): # Left
				if array[x][y] != 0: # Not Empty
					# If best distance, then left. Else, mantain right
					if (loop_points[0].x - x) < dist:
						dir = -1
					break
			if dir == -1:
				loop_points.append(Vector2(0, 0))
				loop_points.append(Vector2(0, size.y))
			else:
				loop_points.append(Vector2(size.x, 0))
				loop_points.append(size)
		else: #if loop_points[0].y == loop_points[1].y: # Horizontal Line
			var x
			var dir
			var dist = -1
			if  loop_points[0].x > loop_points[1].x:
				x = loop_points[1].x + round((loop_points[0].x - loop_points[1].x) / 2)
			else:
				x = loop_points[0].x + round((loop_points[1].x - loop_points[0].x) / 2)
			for y in range(loop_points[0].y+1, size.y): # Down
				if array[x][y] != 0: # Not empty
					# Saves dir and 'best' dist until now
					dist = y - loop_points[0].y
					dir = 1
					break
			for y in range(loop_points[0].y-1, -1, -1): # Up
				if array[x][y] != 0: # Not Empty
					# If best distance, then up. Else, mantain down
					if (loop_points[0].y - y) < dist:
						dir = -1
					break
			if dist == 1: # Anti bug
				loop_points.append(loop_points[0])
				loop_points.append(loop_points[1])
			elif dir == -1:
				loop_points.append(Vector2(0, 0))
				loop_points.append(Vector2(size.x, 0))
			else:
				loop_points.append(Vector2(0, size.y))
				loop_points.append(size)
	else: # 3 points, L shape
		loop_points.append(loop_points[0])
	fill_area(loop_points)

func fill_area(loop_points):
	var min_x = min(loop_points[0].x, loop_points[1].x, loop_points[2].x, loop_points[3].x)
	var max_x = max(loop_points[0].x, loop_points[1].x, loop_points[2].x, loop_points[3].x)
	if max_x >= size.x:
		max_x = size.x - 1
	var min_y = min(loop_points[0].y, loop_points[1].y, loop_points[2].y, loop_points[3].y)
	var max_y = max(loop_points[0].y, loop_points[1].y, loop_points[2].y, loop_points[3].y)
	if max_y >= size.y:
		max_y = size.y - 1
	for x in range(min_x+1, max_x):
		for y in range(min_y+1, max_y):
			if array[x][y] != 1 and array[x][y] != 3:
				array[x][y] = 3
				image.set_pixel(x, y, fill_color)
				filled_area += 1
	update_board()

func hit_enemy(id):
	audio_player.set_stream(hit_path)
	audio_player.play()
	erase_path(id)

func erase_path(id):
	var enemies = $Enemies.get_children()
	for e in enemies:
		if e.id == id:
			for pt in e.pts:
				# Do not change empty, line and fill areas
				if array[pt.x][pt.y] > 3:
					array[pt.x][pt.y] = 0
			e.reset_enemy()
			break

## Should attack?
## Returns an array with: [num_options, up, right, down, left], the last four will be 1 if an option, -1 otherwise
func can_attack(pos, dir):
	var result = [0, -1, -1, -1, -1]
	var diff = pos - player.position
	if abs(diff.x) + abs(diff.y) >= safe_dist:
		if dir == Vector2(0, -1) or dir == Vector2(0, 1): # Up or down
			if pos.x+1 < size.x: # Right
				if array[pos.x+1][pos.y] == 0: # Empty
					result[0] += 1
					result[2] = 1
			if pos.x > 0: # Left
				if array[pos.x-1][pos.y] == 0: # Empty
					result[0] += 1
					result[4] = 1
		else: #if dir == Vector2(1, 0) or dir == Vector2(-1, 0): # Right or Left
			if pos.y > 0: # Up
				if array[pos.x][pos.y-1] == 0:
					result[0] += 1
					result[1] = 1
			if pos.y+1 < size.y: # Down
				if array[pos.x][pos.y+1] == 0:
					result[0] += 1
					result[3] = 1
	return result

## Should back off?
## Returns an array with: [bool, dir to closest line], the bool will be false if player is too close
func can_continue(pos, dir):
	var result = [true, -1]
	var diff = pos - player.position
	if abs(diff.x) + abs(diff.y) < safe_dist / 2:
		result[0] = false
		var new_dir
		var dist = -1
		if dir == Vector2(0, -1) or dir == Vector2(0, 1): # Up or down
			for x in range(pos.x+1, size.x): # Right
				if array[x][pos.y] == 1: # Line
					# Saves dir and 'best' dist until now
					new_dir = Vector2(1, 0)
					dist = x - pos.x
					break
				elif array[x][pos.y] != 0: # Invalid path
					break
			if dist == -1: # If not choose right, then auto-left
				new_dir = Vector2(-1, 0)
			else:
				for x in range(pos.x-1, -1, -1): # Left
					if array[x][pos.y] == 1: # Line
						# If best distance, then left. Else, mantain right (do nothing)
						if pos.x - x < dist:
							new_dir = Vector2(-1, 0)
						break
					elif array[x][pos.y] != 0: # Invalid path
						break
		else: #if dir == Vector2(1, 0) or dir == Vector2(-1, 0): # Right or Left
			for y in range(pos.y+1, size.y): # Down
				if array[pos.x][y] == 1: # Line
					# Saves dir and 'best' dist until now
					new_dir = Vector2(0, 1)
					dist = y - pos.y
					break
				elif array[pos.x][y] != 0: # Invalid path
					break
			if dist == -1: # If not choose down, then auto-up
				new_dir = Vector2(0, -1)
			else:
				for y in range(pos.y-1, -1, -1): # Up
					if array[pos.x][y] == 1: # Line
						# If best distance, then up. Else, mantain down (do nothing)
						if pos.y - y < dist:
							new_dir = Vector2(0, -1)
						break
					elif array[pos.x][y] != 0: # Invalid Path
						break
		result[1] = new_dir
	return result

func new_game():
	pause_menu.visible = false
	reset_game()
	$Starting/AnimationPlayer.play("Start")

func game_over():
	get_tree().paused = true
	
	if score > Global.best_score:
		highscore = true
		Global.set_best_score(score)
		go_highscore_label.set_text("New Record!")
	else:
		go_highscore_label.set_text("Record: " + str(round(Global.best_score)))
	go_score_label.set_text("Entertainment: " + str(round(score)))
	
	pause_menu.visible = true

func _on_retry_button_up():
	reset_game()
	get_tree().paused = false
	pause_menu.visible = false

func _on_back_button_up():
	reset_game()
	$"../Menu".back_to_menu()
