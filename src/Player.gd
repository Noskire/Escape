extends Sprite2D

@onready var qix = $".."

var size = Vector2(1920, 1080)
var mov_velocity = 600
var movement

func _process(delta):
	var hor_stick = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var ver_stick = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	var dir
	
	if hor_stick == 0 and ver_stick == 0:
		dir = Vector2(0, 0)
	elif abs(hor_stick) >= abs(ver_stick): # Left-Right has priority
		if hor_stick > 0:
			dir = Vector2(1, 0)
		else:
			dir = Vector2(-1, 0)
	else: # Up-Down
		if ver_stick > 0:
			dir = Vector2(0, 1)
		else:
			dir = Vector2(0, -1)
	movement = round(mov_velocity * delta)
	move(position, dir)
	var new_pos = position + dir * movement
	if new_pos.x < 0:
		new_pos.x = 0
	elif new_pos.x >= size.x:
		new_pos.x = size.x - 1
	if new_pos.y < 0:
		new_pos.y = 0
	elif new_pos.y >= size.y:
		new_pos.y = size.y - 1
	position = new_pos

func move(pos, dir):
	if dir == Vector2(0, -1): # Up
		for y in range(1, movement+1):
			if pos.y-y < 0:
				break
			if qix.array[pos.x][pos.y-y] == 2: # Intercepted the enemy
				qix.hit_enemy()
	elif dir == Vector2(1, 0): # Right
		for x in range(1, movement+1):
			if pos.x+x >= size.x:
				break
			if qix.array[pos.x+x][pos.y] == 2: # Intercepted the enemy
				qix.hit_enemy()
	elif dir == Vector2(0, 1): # Down
		for y in range(1, movement+1):
			if pos.y+y >= size.y:
				break
			if qix.array[pos.x][pos.y+y] == 2: # Intercepted the enemy
				qix.hit_enemy()
	else: #dir == Vector2(-1, 0): # Left
		for x in range(1, movement+1):
			if pos.x-x < 0:
				break
			if qix.array[pos.x-x][pos.y] == 2: # Intercepted the enemy
				qix.hit_enemy()
