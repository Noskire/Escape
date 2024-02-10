extends Node2D

@onready var text_rect = $Control/TextureRect

var array = []
	# 0 - empty
	# 1 - line
	# 2 - making line
	# 3 - fill
var size = Vector2(1920, 1080)
var image
var line_color = Color("#000000")

func _ready():
	image = text_rect.get_texture().get_image()
	
	for x in size.x:
		array.append([])
		for y in size.y:
			if x == 0 or x == 1919 or y == 0 or y == 1079:
				array[x].append(1) # line
				image.set_pixel(x, y, line_color)
			else:
				array[x].append(0) # empty
	var texture = ImageTexture.create_from_image(image)
	text_rect.set_texture(texture)

func _process(_delta):
	pass

func update_board():
	#if image.get_pixel(0, 0).is_equal_approx(Color("#FFFFFF")):
	pass

func can_move(pos, dir, movement):
	if dir == Vector2(1, 0):
		for x in range(movement+1):
			if pos.x+x >= size.x:
				return [false, Vector2(pos.x+x-1, pos.y)]
			if array[pos.x+x][pos.y] != 1: # Can't move beyond that point
				return [false, Vector2(pos.x+x-1, pos.y)]
		return [true, Vector2(pos.x+movement, pos.y)]
	elif dir == Vector2(0, 1):
		for y in range(movement+1):
			if pos.y+y >= size.y:
				return [false, Vector2(pos.x, pos.y+y-1)]
			if array[pos.x][pos.y+y] != 1: # Can't move beyond that point
				return [false, Vector2(pos.x, pos.y+y-1)]
		return [true, Vector2(pos.x, pos.y+movement)]
