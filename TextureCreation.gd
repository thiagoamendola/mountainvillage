extends Control

const IMAGE_SIZE_PIXELS = 500

const POINTS_COUNT = 20

func _ready():
	dumb_texture_creation()


# Worley Noise
func dumb_texture_creation():
	var texture = ImageTexture.new()
	var image: Image = Image.new()
	
	image.load("res://icon.png")
	image.create(IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, false, Image.FORMAT_RGB8)
	image.lock()
	
	# Create list of random points
	var points = []
	for i in range(POINTS_COUNT):
		points.append(Vector2(int(rand_range(0,IMAGE_SIZE_PIXELS)), int(rand_range(0,IMAGE_SIZE_PIXELS))))
		image.set_pixelv(points[i], Color.red)
	
	# Add 2D mirroring of points to make texture seamless
	var initial_points = points.duplicate()
	for point in initial_points:
		points.append(point + Vector2(IMAGE_SIZE_PIXELS, 0))
		points.append(point + Vector2(IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS))
		points.append(point + Vector2(0, IMAGE_SIZE_PIXELS))
		points.append(point + Vector2(-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS))
		points.append(point + Vector2(-IMAGE_SIZE_PIXELS, 0))
		points.append(point + Vector2(-IMAGE_SIZE_PIXELS, -IMAGE_SIZE_PIXELS))
		points.append(point + Vector2(0, -IMAGE_SIZE_PIXELS))
		points.append(point + Vector2(IMAGE_SIZE_PIXELS, -IMAGE_SIZE_PIXELS))
	
	# Trace the distance between the closest point for each pixel
	# Brute force version
	var MAX_DIST = int(IMAGE_SIZE_PIXELS*.25)
	for i in range(IMAGE_SIZE_PIXELS):
		for j in range(IMAGE_SIZE_PIXELS):
			var min_dist = INF
			for p in points:
				var cur_dist = p.distance_to(Vector2(i,j))
				if cur_dist < min_dist:
					min_dist = cur_dist
			image.set_pixelv(Vector2(i,j), Color.white * clamp(min_dist / MAX_DIST, 0, 1))

	# Invert image
	for i in range(IMAGE_SIZE_PIXELS):
		for j in range(IMAGE_SIZE_PIXELS):
			image.set_pixelv(Vector2(i,j), image.get_pixelv(Vector2(i,j)).inverted())

	for i in range(POINTS_COUNT):
		image.set_pixelv(points[i], Color.red)

	image.unlock()

	texture.create_from_image(image)
	$TextureRect.texture = texture
	$TextureRect2.rect_position = Vector2(IMAGE_SIZE_PIXELS, 0)
	$TextureRect2.texture = texture

