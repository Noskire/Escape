extends Node2D

@onready var line = $Line2D

var points = [] #pos, up_id, right_id, down_id, left_id (-1 if invalid)
var at_point = 0 #-1 if moving
var moving = [] #from, to, current position
var invalid_dir = -1
var mov_velocity = 500
var rng = RandomNumberGenerator.new()

var attacking = false
var att_velocity = 300
var att_dir
var att_line_point

func _ready():
	points.append([Vector2(   0,    0), invalid_dir,           1,           2, invalid_dir])
	points.append([Vector2(1920,    0), invalid_dir, invalid_dir,           3,           0])
	points.append([Vector2(   0, 1080),           0,           3, invalid_dir, invalid_dir])
	points.append([Vector2(1920, 1080),           1, invalid_dir, invalid_dir,           2])
	line.clear_points()

func _process(delta):
	if attacking:
		var new_pos = $Enemy.position + (att_dir * att_velocity * delta)
		## TODO Check if get to destination
		$Enemy.position = new_pos
		line.set_point_position(att_line_point, new_pos)
	elif at_point == -1: # moving
		## Get direction
		var from = points[moving[0]][0]
		var to = points[moving[1]][0]
		
		var diff = from - to
		#up, right, down, left
		var dir
		if diff.y > 0:
			dir = Vector2(0, -1)
		elif diff.x > 0:
			dir = Vector2(-1, 0)
		elif diff.y < 0:
			dir = Vector2(0, 1)
		elif diff.x < 0:
			dir = Vector2(1, 0)
		#var dir = get_dir()
		var new_pos = moving[2] + (dir * mov_velocity * delta)
		## Check if get to destination
		if diff.y > 0:
			if new_pos.y < to.y:
				new_pos = to
				at_point = moving[1]
		elif diff.x > 0:
			if new_pos.x < to.x:
				new_pos = to
				at_point = moving[1]
		elif diff.y < 0:
			if new_pos.y > to.y:
				new_pos = to
				at_point = moving[1]
		elif diff.x < 0:
			if new_pos.x > to.x:
				new_pos = to
				at_point = moving[1]
		## Update position
		$Enemy.position = new_pos
		moving[2] = new_pos
		## Check if should get piece
		if check_dist():
			## TODO Choose dir to attack
			line.add_point(moving[2])
			line.add_point(moving[2])
			att_line_point = 1
			att_dir = Vector2(0, 1)
			attacking = true
	else: # choose dir
		var options = 0
		for r in range(1, 5):
			var p = points[at_point][r]
			if p != -1:
				options += 1
		var new_dir = randi_range(0, options-1)
		for r in range(1, 5):
			var p = points[at_point][r]
			if p != -1:
				if new_dir == 0:
					moving = [at_point, p, points[at_point][0]] #from, to, current position
					break
				else:
					new_dir -= 1
		at_point = -1

func get_dir():
	var from = points[moving[0]][0]
	var to = points[moving[1]][0]
	
	var diff = from - to
	#up, right, down, left
	if diff.y > 0:
		return Vector2(0, -1)
	if diff.x > 0:
		return Vector2(-1, 0)
	if diff.y < 0:
		return Vector2(0, 1)
	#if diff.x < 0:
	return Vector2(1, 0)

func check_dist():
	var player_pos = $Player.position
	var dist = position - player_pos
	var safe_dist = 500
	if (abs(dist.x) + abs(dist.y)) > safe_dist:
		return true
	return false
