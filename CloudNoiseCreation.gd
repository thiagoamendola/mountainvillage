extends Control

const IMAGE_SIZE_PIXELS = 500
var POINTS_PER_AXIS = 5
export var MAX_DIST_MULTIPLIER = 0.2

var POINTS_COUNT = POINTS_PER_AXIS*POINTS_PER_AXIS
var SECTOR_SIZE = IMAGE_SIZE_PIXELS/POINTS_PER_AXIS
var SEAMLESS_POINTS_PER_AXIS = POINTS_PER_AXIS+2

func _ready():
	var texture = cloud_texture_creation()
#	$TextureRect2.rect_position = Vector2(IMAGE_SIZE_PIXELS, 0)
#	$TextureRect3.rect_position = Vector2(0, IMAGE_SIZE_PIXELS)
#	$TextureRect4.rect_position = Vector2(IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
#	$TextureRect.texture = texture
#	$TextureRect2.texture = texture
#	$TextureRect3.texture = texture
#	$TextureRect4.texture = texture
	
func _process(delta):
	pass
	


# Creates a list of points based in sectors. Used as part of Worley Noise algorithm.
func create_discrete_sector_points_list():
	var points = []
	for i in range(POINTS_COUNT):
		var sector_interval_origin = Vector2(SECTOR_SIZE*(i%POINTS_PER_AXIS), SECTOR_SIZE*(i/POINTS_PER_AXIS))
		points.append(Vector2( \
			int(rand_range(sector_interval_origin.x, sector_interval_origin.x + SECTOR_SIZE)), \
#			int(sector_interval_origin.x), \
			int(rand_range(sector_interval_origin.y, sector_interval_origin.y + SECTOR_SIZE))))
#			int(sector_interval_origin.y)))
	return points


# Creates an ordered list with the provided points along with repeated opposite 
# ones to allow a seamless texture creation 
func create_seamless_points(points):
	var seamless_points = []
	# First line (only mirrored entries)
	seamless_points.append(points[(POINTS_PER_AXIS*POINTS_PER_AXIS)-1] + Vector2(-IMAGE_SIZE_PIXELS, -IMAGE_SIZE_PIXELS))
	for j in range(POINTS_PER_AXIS):
		seamless_points.append(points[POINTS_PER_AXIS*(POINTS_PER_AXIS-1)+j] + Vector2(0, -IMAGE_SIZE_PIXELS))
	seamless_points.append(points[POINTS_PER_AXIS*(POINTS_PER_AXIS-1)] + Vector2(IMAGE_SIZE_PIXELS, -IMAGE_SIZE_PIXELS))
	# Middle lines (mirrored entries at edges)
	for i in range(POINTS_PER_AXIS):
		seamless_points.append(points[(POINTS_PER_AXIS-1)+POINTS_PER_AXIS*i] + Vector2(-IMAGE_SIZE_PIXELS, 0))
		for j in range(POINTS_PER_AXIS*i, POINTS_PER_AXIS*i + POINTS_PER_AXIS):
			seamless_points.append(points[j])
		seamless_points.append(points[POINTS_PER_AXIS*i] + Vector2(IMAGE_SIZE_PIXELS, 0))
	# Final line (only mirrored entries)
	seamless_points.append(points[POINTS_PER_AXIS-1] + Vector2(-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS))
	for j in range(POINTS_PER_AXIS):
		seamless_points.append(points[j] + Vector2(0, IMAGE_SIZE_PIXELS))
	seamless_points.append(points[0] + Vector2(IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS))
	
	return seamless_points

# Get points for current and all neighbor sectors.
func get_adjacent_sector_points(seamless_points, current_pixel):
	var adjacent_points = []
	var current_sector_vec = Vector2( \
		int(current_pixel.x/SECTOR_SIZE), \
		int(current_pixel.y/SECTOR_SIZE))
	# Apply offset to match seamless array
	current_sector_vec += Vector2(1,1)
	# Get index value for sector
	var current_sector = current_sector_vec.y*(SEAMLESS_POINTS_PER_AXIS) + current_sector_vec.x
	# Add all adjacent sector points
	adjacent_points.append(seamless_points[current_sector])
	adjacent_points.append(seamless_points[current_sector-1])
	adjacent_points.append(seamless_points[current_sector+1])
	adjacent_points.append(seamless_points[current_sector-SEAMLESS_POINTS_PER_AXIS])
	adjacent_points.append(seamless_points[current_sector-SEAMLESS_POINTS_PER_AXIS-1])
	adjacent_points.append(seamless_points[current_sector-SEAMLESS_POINTS_PER_AXIS+1])
	adjacent_points.append(seamless_points[current_sector+SEAMLESS_POINTS_PER_AXIS])
	adjacent_points.append(seamless_points[current_sector+SEAMLESS_POINTS_PER_AXIS-1])
	adjacent_points.append(seamless_points[current_sector+SEAMLESS_POINTS_PER_AXIS+1])
	return adjacent_points


func create_image_cpu(image, seamless_points):
	image.lock()

	# Trace the distance between the closest point for each pixel by checking adjacent sectors
	var MAX_DIST = int(IMAGE_SIZE_PIXELS*MAX_DIST_MULTIPLIER)
	for i in range(IMAGE_SIZE_PIXELS):
		for j in range(IMAGE_SIZE_PIXELS):
			var min_dist = INF
			var current_pixel = Vector2(i,j)
			for p in get_adjacent_sector_points(seamless_points, current_pixel):
				var cur_dist = p.distance_to(current_pixel)
				if cur_dist < min_dist:
					min_dist = cur_dist
			image.set_pixelv(current_pixel, Color.white * clamp(min_dist / MAX_DIST, 0, 1))

	# Invert image
	for i in range(IMAGE_SIZE_PIXELS):
		for j in range(IMAGE_SIZE_PIXELS):
			image.set_pixelv(Vector2(i,j), image.get_pixelv(Vector2(i,j)).inverted())

	# Add visible points for reference
	for p in seamless_points:
		image.set_pixelv(p, Color.red)

	image.unlock()


# Uses Worley Noise algorithm to generate a cloud texture.
func cloud_texture_creation():
	var texture = ImageTexture.new()
	
	# Create list of aproximated random points by discrete sectors 
	var points = create_discrete_sector_points_list()
	
	# Create ordered list that includes repeated points from edge sections to make texture seamless.
	var seamless_points = create_seamless_points(points)
	
	# Create image in CPU
	# create_image_cpu(image, seamless_points)

	print(SECTOR_SIZE)
	# Convert seamless_points_image into a sampler2D texture with xy in rg channel
	var seamless_points_image: Image = Image.new()

	seamless_points_image.create(SEAMLESS_POINTS_PER_AXIS, SEAMLESS_POINTS_PER_AXIS, false, Image.FORMAT_RGB8)
	seamless_points_image.lock()
	for y in range(SEAMLESS_POINTS_PER_AXIS):
		for x in range(SEAMLESS_POINTS_PER_AXIS):
			var coord_in_sector_raw = Vector2( \
				fposmod(seamless_points[x + SEAMLESS_POINTS_PER_AXIS*y].x, SECTOR_SIZE), \
				fposmod(seamless_points[x + SEAMLESS_POINTS_PER_AXIS*y].y, SECTOR_SIZE))
			var coord_in_sector_unit = coord_in_sector_raw / SECTOR_SIZE
			seamless_points_image.set_pixelv(Vector2(x,y), Color(coord_in_sector_unit.x, coord_in_sector_unit.y, 0, 1))
	seamless_points_image.unlock()

	$TextureRect.material.set_shader_param("sector_size", SECTOR_SIZE)
	texture.create_from_image(seamless_points_image)
	$TextureRect.material.set_shader_param("seamless_points_tex", texture)

	return texture
