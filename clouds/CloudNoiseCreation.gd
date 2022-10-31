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
	var start_time = OS.get_unix_time()
	cloud_texture_creation()
	render_texture()
	var end_time = OS.get_unix_time()
	print(end_time - start_time)
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
	R_POINTS_COUNT = R_POINTS_PER_AXIS*R_POINTS_PER_AXIS*R_POINTS_PER_AXIS
	R_SECTOR_SIZE = ceil(IMAGE_SIZE_PIXELS/R_POINTS_PER_AXIS)
	R_SEAMLESS_POINTS_PER_AXIS = R_POINTS_PER_AXIS+2

	G_POINTS_COUNT = G_POINTS_PER_AXIS*G_POINTS_PER_AXIS*G_POINTS_PER_AXIS
	G_SECTOR_SIZE = ceil(IMAGE_SIZE_PIXELS/G_POINTS_PER_AXIS)
	G_SEAMLESS_POINTS_PER_AXIS = G_POINTS_PER_AXIS+2

	B_POINTS_COUNT = B_POINTS_PER_AXIS*B_POINTS_PER_AXIS*B_POINTS_PER_AXIS
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
func create_discrete_sector_points(points_count, sector_size, points_per_axis):
	# Create 3D array
	var points = []
	points.resize(points_count)
	for x in range(points_count):
		points[x] = []
		points[x].resize(points_count)
		for y in range(points_count):
			points[x][y] = []
			points[x][y].resize(points_count)

	# Create random points
	for x in range(points_count):
		for y in range(points_count):
			for z in range(points_count):
				points[x][y][z] = Vector3( \
					int(rand_range(sector_size*x, sector_size*x + sector_size)), \
					int(rand_range(sector_size*y, sector_size*y + sector_size)), \
					int(rand_range(sector_size*z, sector_size*z + sector_size)))
	return points


# Creates an ordered list with the provided points along with repeated opposite 
# ones to allow a seamless texture creation 
func create_seamless_points(points, points_per_axis):
	# Create 3D array
	var seamless_axis = points_per_axis+2
	var end = points_per_axis-1
	var ends = seamless_axis-1
	var seamless_points = []
	seamless_points.resize(seamless_axis)
	for x in range(seamless_axis):
		seamless_points[x] = []
		seamless_points[x].resize(seamless_axis)
		for y in range(seamless_axis):
			seamless_points[x][y] = []
			seamless_points[x][y].resize(seamless_axis)
	# Build seamless matrix of points
	# Fill inner cube (NxNxN)
	for x in range(points_per_axis):
		for y in range(points_per_axis):
			for z in range(points_per_axis):
				seamless_points[x+1][y+1][z+1] = points[x][y][z]
	# Fill squares (NxNx1) with mirrored entries (x6)
	for x in range(points_per_axis):
		for y in range(points_per_axis):
			seamless_points[1+x][1+y][0] = points[x][y][end] + Vector3(0,0,-IMAGE_SIZE_PIXELS)
			seamless_points[1+x][1+y][ends] = points[x][y][0] + Vector3(0,0, IMAGE_SIZE_PIXELS)
	for x in range(points_per_axis):
		for z in range(points_per_axis):
			seamless_points[1+x][0][1+z] = points[x][end][z] + Vector3(0,-IMAGE_SIZE_PIXELS, 0)
			seamless_points[1+x][ends][1+z] = points[x][0][z] + Vector3(0, IMAGE_SIZE_PIXELS, 0)
	for y in range(points_per_axis):
		for z in range(points_per_axis):
			seamless_points[0][1+y][1+z] = points[end][y][z] + Vector3(-IMAGE_SIZE_PIXELS, 0, 0)
			seamless_points[ends][1+y][1+z] = points[0][y][z] + Vector3( IMAGE_SIZE_PIXELS, 0, 0)
	# Fill corner lines (Nx1x1) with mirrored entries (x12)
	for x in range(points_per_axis):
		seamless_points[x+1][0][0] = points[x][end][end] + Vector3(0,-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
		seamless_points[x+1][ends][0] = points[x][0][end] + Vector3(0, IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
		seamless_points[x+1][0][ends] = points[x][end][0] + Vector3(0,-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
		seamless_points[x+1][ends][ends] = points[x][0][0] + Vector3(0, IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
	for y in range(points_per_axis):
		seamless_points[0][y+1][0] = points[end][y][end] + Vector3(-IMAGE_SIZE_PIXELS, 0,-IMAGE_SIZE_PIXELS)
		seamless_points[ends][y+1][0] = points[0][y][end] + Vector3( IMAGE_SIZE_PIXELS, 0,-IMAGE_SIZE_PIXELS)
		seamless_points[0][y+1][ends] = points[end][y][0] + Vector3(-IMAGE_SIZE_PIXELS, 0, IMAGE_SIZE_PIXELS)
		seamless_points[ends][y+1][ends] = points[0][y][0] + Vector3( IMAGE_SIZE_PIXELS, 0, IMAGE_SIZE_PIXELS)
	for z in range(points_per_axis):
		seamless_points[0][0][z+1] = points[end][end][z] + Vector3(-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS, 0)
		seamless_points[ends][0][z+1] = points[0][end][z] + Vector3( IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS, 0)
		seamless_points[0][ends][z+1] = points[end][0][z] + Vector3(-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, 0)
		seamless_points[ends][ends][z+1] = points[0][0][z] + Vector3( IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, 0)
	# Fill corner elements (1x1x1) with mirrored entries (x8)
	seamless_points[0][0][0] = points[end][end][end] + Vector3(-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
	seamless_points[ends][0][0] = points[0][end][end] + Vector3( IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
	seamless_points[0][ends][0] = points[end][0][end] + Vector3(-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
	seamless_points[ends][ends][0] = points[0][0][end] + Vector3( IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
	seamless_points[0][0][ends] = points[end][end][0] + Vector3(-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
	seamless_points[ends][0][ends] = points[0][end][0] + Vector3( IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
	seamless_points[0][ends][ends] = points[end][0][0] + Vector3(-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
	seamless_points[ends][ends][ends] = points[0][0][0] + Vector3( IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)

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


# TODO: Convert to sampler3D
# Convert seamless_points_image into a sampler2D texture with xy in rg channel
func get_seamless_points_representation(seamless_points, seamless_points_per_axis, sector_size):
	var seamless_points_image: Image = Image.new()
	seamless_points_image.create(seamless_points_per_axis, seamless_points_per_axis, false, Image.FORMAT_RGB8)
	seamless_points_image.lock()
	for y in range(seamless_points_per_axis):
		for x in range(seamless_points_per_axis):
			var coord_in_sector_raw = Vector2( \
				fposmod(seamless_points[x][y][0].x, sector_size), \
				fposmod(seamless_points[x][y][0].y, sector_size))
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
	var r_points = create_discrete_sector_points( \
		R_POINTS_COUNT, \
		R_SECTOR_SIZE, \
		R_POINTS_PER_AXIS)
	var g_points = create_discrete_sector_points( \
		G_POINTS_COUNT, \
		G_SECTOR_SIZE, \
		G_POINTS_PER_AXIS)
	var b_points = create_discrete_sector_points( \
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
