tool
extends Control

var RUN_IN_EDITOR := false
var IMAGE_SIZE_PIXELS := 300
var PERSISTENCE := 1.0

var R_POINTS_PER_AXIS := 5
var R_INTENSITY_MULTIPLIER := 1.1
var R_POINTS_COUNT
var R_SECTOR_SIZE
var R_SEAMLESS_POINTS_PER_AXIS

var G_POINTS_PER_AXIS := 12
var G_INTENSITY_MULTIPLIER := .7
var G_POINTS_COUNT
var G_SECTOR_SIZE
var G_SEAMLESS_POINTS_PER_AXIS

var B_POINTS_PER_AXIS := 12
var B_INTENSITY_MULTIPLIER := .7
var B_POINTS_COUNT
var B_SECTOR_SIZE
var B_SEAMLESS_POINTS_PER_AXIS

var rerender_param_cache
var regenerate_param_cache

var r_texture
var g_texture
var b_texture

func _ready():
	cloud_texture_creation()
	render_texture()
	pass

func _process(delta):
	if (RUN_IN_EDITOR):
		var current_rerender_param_cache = [ \
			RUN_IN_EDITOR, \
			IMAGE_SIZE_PIXELS, \
			PERSISTENCE, \
			R_POINTS_PER_AXIS, \
			R_INTENSITY_MULTIPLIER, \
			G_POINTS_PER_AXIS, \
			G_INTENSITY_MULTIPLIER, \
			B_POINTS_PER_AXIS, \
			B_INTENSITY_MULTIPLIER, \
		]
		var current_regenerate_param_cache = [ \
			RUN_IN_EDITOR, \
			IMAGE_SIZE_PIXELS, \
			R_POINTS_PER_AXIS, \
			G_POINTS_PER_AXIS, \
			B_POINTS_PER_AXIS, \
		]
		
		if (current_rerender_param_cache != rerender_param_cache):
			if (current_regenerate_param_cache != regenerate_param_cache):
				regenerate_param_cache = current_regenerate_param_cache
				cloud_texture_creation()
			rerender_param_cache = current_rerender_param_cache
			render_texture()
	pass


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_SPACE:
			cloud_texture_creation()
	pass

func _get_property_list():
	var props = []

	props.append({
		name = "Texture Config",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	
	props.append({
		name = "RUN_IN_EDITOR",
		type = TYPE_BOOL
	})
	props.append({
		name = "IMAGE_SIZE_PIXELS",
		type = TYPE_INT,
	})
	props.append({
		name = "PERSISTENCE",
		type = TYPE_REAL,
		usage = PROPERTY_USAGE_DEFAULT,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "0.0,1.0"
	})
	
	props.append({
		name = "Texture R",
		type = TYPE_NIL,
		hint_string = "R_",
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	props.append({
		name = "R_POINTS_PER_AXIS",
		type = TYPE_INT,
	})
	props.append({
		name = "R_INTENSITY_MULTIPLIER",
		type = TYPE_REAL,
		usage = PROPERTY_USAGE_DEFAULT,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "0.0,2.0"
	})

	props.append({
		name = "Texture G",
		type = TYPE_NIL,
		hint_string = "G_",
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	props.append({
		name = "G_POINTS_PER_AXIS",
		type = TYPE_INT,
	})
	props.append({
		name = "G_INTENSITY_MULTIPLIER",
		type = TYPE_REAL,
		usage = PROPERTY_USAGE_DEFAULT,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "0.0,2.0"
	})

	props.append({
		name = "Texture B",
		type = TYPE_NIL,
		hint_string = "B_",
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	props.append({
		name = "B_POINTS_PER_AXIS",
		type = TYPE_INT,
	})
	props.append({
		name = "B_INTENSITY_MULTIPLIER",
		type = TYPE_REAL,
		usage = PROPERTY_USAGE_DEFAULT,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "0.0,2.0"
	})

	return props


func setup_texture_creation():
	# Set main variables with latest values.
	R_POINTS_COUNT = R_POINTS_PER_AXIS*R_POINTS_PER_AXIS
	R_SECTOR_SIZE = ceil(IMAGE_SIZE_PIXELS/R_POINTS_PER_AXIS)
	R_SEAMLESS_POINTS_PER_AXIS = R_POINTS_PER_AXIS+2

	G_POINTS_COUNT = G_POINTS_PER_AXIS*G_POINTS_PER_AXIS
	G_SECTOR_SIZE = ceil(IMAGE_SIZE_PIXELS/G_POINTS_PER_AXIS)
	G_SEAMLESS_POINTS_PER_AXIS = G_POINTS_PER_AXIS+2

	B_POINTS_COUNT = B_POINTS_PER_AXIS*B_POINTS_PER_AXIS
	B_SECTOR_SIZE = ceil(IMAGE_SIZE_PIXELS/B_POINTS_PER_AXIS)
	B_SEAMLESS_POINTS_PER_AXIS = B_POINTS_PER_AXIS+2
	# Create default image for TextureRect to work.
	var texture = ImageTexture.new()
	var image = Image.new()
	image.create(IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, false, 4)
	image.fill(Color(0, 0, 0))
	texture.create_from_image(image)
	$CloudRect.texture = texture


# Creates a list of points based in sectors. Used as part of Worley Noise algorithm.
func create_discrete_sector_points_list(points_count, sector_size, points_per_axis):
	var points = []
	for i in range(points_count):
		var sector_interval_origin = Vector2(sector_size*(i%points_per_axis), sector_size*(i/points_per_axis))
		points.append(Vector2( \
			int(rand_range(sector_interval_origin.x, sector_interval_origin.x + sector_size)), \
#			int(sector_interval_origin.x), \
			int(rand_range(sector_interval_origin.y, sector_interval_origin.y + sector_size))))
#			int(sector_interval_origin.y)))
	return points


# Creates an ordered list with the provided points along with repeated opposite 
# ones to allow a seamless texture creation 
func create_seamless_points(points, points_per_axis):
	var seamless_points = []
	# First line (only mirrored entries)
	seamless_points.append(points[(points_per_axis*points_per_axis)-1] + Vector2(-IMAGE_SIZE_PIXELS, -IMAGE_SIZE_PIXELS))
	for j in range(points_per_axis):
		seamless_points.append(points[points_per_axis*(points_per_axis-1)+j] + Vector2(0, -IMAGE_SIZE_PIXELS))
	seamless_points.append(points[points_per_axis*(points_per_axis-1)] + Vector2(IMAGE_SIZE_PIXELS, -IMAGE_SIZE_PIXELS))
	# Middle lines (mirrored entries at edges)
	for i in range(points_per_axis):
		seamless_points.append(points[(points_per_axis-1)+points_per_axis*i] + Vector2(-IMAGE_SIZE_PIXELS, 0))
		for j in range(points_per_axis*i, points_per_axis*i + points_per_axis):
			seamless_points.append(points[j])
		seamless_points.append(points[points_per_axis*i] + Vector2(IMAGE_SIZE_PIXELS, 0))
	# Final line (only mirrored entries)
	seamless_points.append(points[points_per_axis-1] + Vector2(-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS))
	for j in range(points_per_axis):
		seamless_points.append(points[j] + Vector2(0, IMAGE_SIZE_PIXELS))
	seamless_points.append(points[0] + Vector2(IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS))
	
	return seamless_points

# Get points for current and all neighbor sectors.
func get_adjacent_sector_points(seamless_points, current_pixel):
	var adjacent_points = []
	var current_sector_vec = Vector2( \
		int(current_pixel.x/R_SECTOR_SIZE), \
		int(current_pixel.y/R_SECTOR_SIZE))
	# Apply offset to match seamless array
	current_sector_vec += Vector2(1,1)
	# Get index value for sector
	var current_sector = current_sector_vec.y*(R_SEAMLESS_POINTS_PER_AXIS) + current_sector_vec.x
	# Add all adjacent sector points
	adjacent_points.append(seamless_points[current_sector])
	adjacent_points.append(seamless_points[current_sector-1])
	adjacent_points.append(seamless_points[current_sector+1])
	adjacent_points.append(seamless_points[current_sector-R_SEAMLESS_POINTS_PER_AXIS])
	adjacent_points.append(seamless_points[current_sector-R_SEAMLESS_POINTS_PER_AXIS-1])
	adjacent_points.append(seamless_points[current_sector-R_SEAMLESS_POINTS_PER_AXIS+1])
	adjacent_points.append(seamless_points[current_sector+R_SEAMLESS_POINTS_PER_AXIS])
	adjacent_points.append(seamless_points[current_sector+R_SEAMLESS_POINTS_PER_AXIS-1])
	adjacent_points.append(seamless_points[current_sector+R_SEAMLESS_POINTS_PER_AXIS+1])
	return adjacent_points


func create_image_cpu(image, seamless_points):
	image.lock()

	# Trace the distance between the closest point for each pixel by checking adjacent sectors
	var MAX_DIST = int(IMAGE_SIZE_PIXELS)
	for i in range(IMAGE_SIZE_PIXELS):
		for j in range(IMAGE_SIZE_PIXELS):
			var min_dist = INF
			var current_pixel = Vector2(i,j)
			for p in get_adjacent_sector_points(seamless_points, current_pixel):
				var cur_dist = p.distance_to(current_pixel)
				if cur_dist < min_dist:
					min_dist = cur_dist
			image.set_pixelv(current_pixel, Color.white * clamp(R_INTENSITY_MULTIPLIER * min_dist / MAX_DIST, 0, 1))

	# Invert image
	for i in range(IMAGE_SIZE_PIXELS):
		for j in range(IMAGE_SIZE_PIXELS):
			image.set_pixelv(Vector2(i,j), image.get_pixelv(Vector2(i,j)).inverted())

	# Add visible points for reference
	for p in seamless_points:
		image.set_pixelv(p, Color.red)

	image.unlock()


# Convert seamless_points_image into a sampler2D texture with xy in rg channel
func get_seamless_points_representation(seamless_points, seamless_points_per_axis, sector_size):
	var seamless_points_image: Image = Image.new()
	seamless_points_image.create(seamless_points_per_axis, seamless_points_per_axis, false, Image.FORMAT_RGB8)
	seamless_points_image.lock()
	for y in range(seamless_points_per_axis):
		for x in range(seamless_points_per_axis):
			var coord_in_sector_raw = Vector2( \
				fposmod(seamless_points[x + seamless_points_per_axis*y].x, sector_size), \
				fposmod(seamless_points[x + seamless_points_per_axis*y].y, sector_size))
			var coord_in_sector_unit = coord_in_sector_raw / sector_size
			seamless_points_image.set_pixelv(Vector2(x,y), Color(coord_in_sector_unit.x, coord_in_sector_unit.y, 0, 1))
	seamless_points_image.unlock()
	return seamless_points_image


# Uses Worley Noise algorithm to generate a cloud texture.
func cloud_texture_creation():
	r_texture = ImageTexture.new()
	g_texture = ImageTexture.new()
	b_texture = ImageTexture.new()

	setup_texture_creation()
	
	# Create list of aproximated random points by discrete sectors 
	var r_points = create_discrete_sector_points_list( \
		R_POINTS_COUNT, \
		R_SECTOR_SIZE, \
		R_POINTS_PER_AXIS)
	var g_points = create_discrete_sector_points_list( \
		G_POINTS_COUNT, \
		G_SECTOR_SIZE, \
		G_POINTS_PER_AXIS)
	var b_points = create_discrete_sector_points_list( \
		B_POINTS_COUNT, \
		B_SECTOR_SIZE, \
		B_POINTS_PER_AXIS)
	
	# Create ordered list that includes repeated points from edge sections to make texture seamless.
	var r_seamless_points = create_seamless_points( \
		r_points, \
		R_POINTS_PER_AXIS)
	var g_seamless_points = create_seamless_points( \
		g_points, \
		G_POINTS_PER_AXIS)
	var b_seamless_points = create_seamless_points( \
		b_points, \
		B_POINTS_PER_AXIS)
	
	# Create image in CPU
	# create_image_cpu(image, r_seamless_points)

	# Convert seamless_points_image into a sampler2D texture with xy in rg channel
	var r_seamless_points_image = get_seamless_points_representation( \
		r_seamless_points, \
		R_SEAMLESS_POINTS_PER_AXIS, \
		R_SECTOR_SIZE)
	r_texture.create_from_image(r_seamless_points_image)
	var g_seamless_points_image = get_seamless_points_representation( \
		g_seamless_points, \
		G_SEAMLESS_POINTS_PER_AXIS, \
		G_SECTOR_SIZE)
	g_texture.create_from_image(g_seamless_points_image)
	var b_seamless_points_image = get_seamless_points_representation( \
		b_seamless_points, \
		B_SEAMLESS_POINTS_PER_AXIS, \
		B_SECTOR_SIZE)
	b_texture.create_from_image(b_seamless_points_image)

	return


func render_texture():
	# Pass variables to shader.
	$CloudRect.material.set_shader_param("texture_size", IMAGE_SIZE_PIXELS)
	$CloudRect.material.set_shader_param("persistence", PERSISTENCE)

	$CloudRect.material.set_shader_param("r_sector_size", R_SECTOR_SIZE)
	$CloudRect.material.set_shader_param("r_intensity_multiplier", R_INTENSITY_MULTIPLIER)
	$CloudRect.material.set_shader_param("r_seamless_points_tex", r_texture)

	$CloudRect.material.set_shader_param("g_sector_size", G_SECTOR_SIZE)
	$CloudRect.material.set_shader_param("g_intensity_multiplier", G_INTENSITY_MULTIPLIER)
	$CloudRect.material.set_shader_param("g_seamless_points_tex", g_texture)

	$CloudRect.material.set_shader_param("b_sector_size", B_SECTOR_SIZE)
	$CloudRect.material.set_shader_param("b_intensity_multiplier", B_INTENSITY_MULTIPLIER)
	$CloudRect.material.set_shader_param("b_seamless_points_tex", b_texture)

	return r_texture
