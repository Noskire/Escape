extends Sprite2D

@onready var qix = $"../.."
#@onready var line = $"../../LineTemp"

var mov_velocity = 500
var att_velocity = 300
var state = "Choosing" # "Choosing", "Moving", Attacking", "Retreating"
var dir = Vector2(1, 0)
var attack_delay = 3 # in seconds
var wait_delay = 0.5 # in seconds
var current_delay = 0
var starting_point = Vector2(0, 0)
var rng = RandomNumberGenerator.new()
var movement
var loop_points = []
var curr_pt

var line
var id
var pts = []

func _process(delta):
	current_delay += delta
	if state == "Moving":
		movement = round(mov_velocity * delta)
		var func_return = qix.move(position, dir, movement)
		position = func_return[1]
		if not func_return[0]: # In an intersection, can't attack
			state = "Choosing"
		elif current_delay > attack_delay:
			# Should attack?
			var options = qix.can_attack(position, dir)
			if options[0] > 0:
				var new_dir = randi_range(0, options[0]-1)
				for r in range(1, 5):
					if options[r] != -1:
						if new_dir > 0:
							new_dir -= 1
						else:
							if r == 1:
								dir = Vector2(0, -1)
							elif r == 2:
								dir = Vector2(1, 0)
							elif r == 3:
								dir = Vector2(0, 1)
							else:
								dir = Vector2(-1, 0)
							break
				## END FOR
				state = "Attacking"
				loop_points.append(position)
				line.add_point(position)
				line.add_point(position)
				curr_pt = 1
			current_delay -= wait_delay
	elif state == "Choosing":
		var dirs = qix.get_dirs(position)
		if id % 3 == 0: # Random
			var new_dir = randi_range(0, dirs[0]-1)
			for r in range(1, 5):
				if dirs[r] != -1:
					if new_dir > 0:
						new_dir -= 1
					else:
						if r == 1:
							dir = Vector2(0, -1)
						elif r == 2:
							dir = Vector2(1, 0)
						elif r == 3:
							dir = Vector2(0, 1)
						else:
							dir = Vector2(-1, 0)
						break
			## END FOR
		elif id % 3 == 1: # Clockwise
			if dir == Vector2(0, -1): # Up
				if dirs[2] == 1:
					dir = Vector2(1, 0) # Right
				elif dirs[1] == 1:
					dir = Vector2(0, -1) # Up
				elif dirs[4] == 1:
					dir = Vector2(-1, 0) # Left
				else: #elif dirs[3] == 1:
					dir = Vector2(0, 1) # Down
			elif dir == Vector2(1, 0): # Right
				if dirs[3] == 1:
					dir = Vector2(0, 1) # Down
				elif dirs[2] == 1:
					dir = Vector2(1, 0) # Right
				elif dirs[1] == 1:
					dir = Vector2(0, -1) # Up
				else: #elif dirs[4] == 1:
					dir = Vector2(-1, 0) # Left
			elif dir == Vector2(0, 1): # Down
				if dirs[4] == 1:
					dir = Vector2(-1, 0) # Left
				elif dirs[3] == 1:
					dir = Vector2(0, 1) # Down
				elif dirs[2] == 1:
					dir = Vector2(1, 0) # Right
				else: #elif dirs[1] == 1:
					dir = Vector2(0, -1) # Up
			elif dir == Vector2(-1, 0): # Left
				if dirs[1] == 1:
					dir = Vector2(0, -1) # Up
				elif dirs[4] == 1:
					dir = Vector2(-1, 0) # Left
				elif dirs[3] == 1:
					dir = Vector2(0, 1) # Down
				else: #elif dirs[2] == 1:
					dir = Vector2(1, 0) # Right
		else: #elif id % 3 == 1: # AntiClockwise
			if dir == Vector2(0, -1): # Up
				if dirs[4] == 1:
					dir = Vector2(-1, 0) # Left
				elif dirs[1] == 1:
					dir = Vector2(0, -1) # Up
				elif dirs[2] == 1:
					dir = Vector2(1, 0) # Right
				else: #elif dirs[3] == 1:
					dir = Vector2(0, 1) # Down
			elif dir == Vector2(1, 0): # Right
				if dirs[1] == 1:
					dir = Vector2(0, -1) # Up
				elif dirs[2] == 1:
					dir = Vector2(1, 0) # Right
				elif dirs[3] == 1:
					dir = Vector2(0, 1) # Down
				else: #elif dirs[4] == 1:
					dir = Vector2(-1, 0) # Left
			elif dir == Vector2(0, 1): # Down
				if dirs[2] == 1:
					dir = Vector2(1, 0) # Right
				elif dirs[3] == 1:
					dir = Vector2(0, 1) # Down
				elif dirs[4] == 1:
					dir = Vector2(-1, 0) # Left
				else: #elif dirs[1] == 1:
					dir = Vector2(0, -1) # Up
			elif dir == Vector2(-1, 0): # Left
				if dirs[3] == 1:
					dir = Vector2(0, 1) # Down
				elif dirs[4] == 1:
					dir = Vector2(-1, 0) # Left
				elif dirs[1] == 1:
					dir = Vector2(0, -1) # Up
				else: #elif dirs[2] == 1:
					dir = Vector2(1, 0) # Right
		## END IF id % 3 == ?
		state = "Moving"
	elif state == "Attacking":
		movement = round(att_velocity * delta)
		var func_return = qix.attack(self, position, dir, movement, id)
		position = func_return[1]
		line.set_point_position(curr_pt, position)
		if func_return[0] == 1: # Closed loop
			state = "Choosing"
			current_delay = 0
			loop_points.append(position)
			line.add_point(position)
			var new_line = Line2D.new()
			for p in line.get_point_count():
				new_line.add_point(line.get_point_position(p))
			line.clear_points()
			new_line.set_default_color(qix.line_color)
			qix.find_child("Lines").add_child(new_line)
			fill_area()
			loop_points.clear()
		elif func_return[0] == -1: # Invalid path
			qix.erase_path(id)
			reset_enemy()
		else: #func_return[0] == 0, continue moving
			if current_delay > attack_delay:
				# Should retreat?
				var options = qix.can_continue(position, dir)
				if options[0] == false:
					dir = options[1]
					state = "Retreating"
					loop_points.append(position)
					line.add_point(position)
					curr_pt += 1
				current_delay -= wait_delay
	elif state == "Retreating":
		movement = round(att_velocity * delta)
		var func_return = qix.attack(self, position, dir, movement, id)
		position = func_return[1]
		line.set_point_position(curr_pt, position)
		if func_return[0] == 1: # Closed loop
			state = "Choosing"
			current_delay = 0
			loop_points.append(position)
			line.add_point(position)
			var new_line = Line2D.new()
			for p in line.get_point_count():
				new_line.add_point(line.get_point_position(p))
			line.clear_points()
			new_line.set_default_color(qix.line_color)
			qix.find_child("Lines").add_child(new_line)
			fill_area()
			loop_points.clear()
		elif func_return[0] == -1: # Invalid path
			qix.erase_path(id)
			reset_enemy()
		#elif func_return[0] == 0, do nothing

func fill_area():
	qix.close_rect(loop_points)

func reset_enemy():
	state = "Choosing"
	position = starting_point
	current_delay = 0
	loop_points.clear()
	line.clear_points()
	pts.clear()
