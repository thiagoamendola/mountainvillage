tool
extends Control

var RUN_IN_EDITOR := false
var IMAGE_SIZE_PIXELS := 128
var PERSISTENCE := 1.0
var SLICE := 1.0

var R_POINTS_PER_AXIS := 5
var R_INTENSITY_MULTIPLIER := 1.1
var R_POINTS_COUNT
var R_SECTOR_SIZE
var R_SEAMLESS_POINTS_PER_AXIS

var G_POINTS_PER_AXIS := 6
var G_INTENSITY_MULTIPLIER := .7
var G_POINTS_COUNT
var G_SECTOR_SIZE
var G_SEAMLESS_POINTS_PER_AXIS

var B_POINTS_PER_AXIS := 8
var B_INTENSITY_MULTIPLIER := .7
var B_POINTS_COUNT
var B_SECTOR_SIZE
var B_SEAMLESS_POINTS_PER_AXIS

var rerender_param_cache
var regenerate_param_cache

var r_texture
var r_points
var g_texture
var b_texture

var noise_texture

func _ready():
	noise_texture = cloud_texture_creation()
	display_texture3d_slice(noise_texture)
	pass

func _process(delta):
	if (RUN_IN_EDITOR):
		var current_rerender_param_cache = [ \
			RUN_IN_EDITOR, \
			IMAGE_SIZE_PIXELS, \
			PERSISTENCE, \
			SLICE, \
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
				noise_texture = cloud_texture_creation()
			rerender_param_cache = current_rerender_param_cache
			display_texture3d_slice(noise_texture)

	pass

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_SPACE:
			noise_texture = cloud_texture_creation()
			display_texture3d_slice(noise_texture)
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
		name = "SLICE",
		type = TYPE_REAL,
		usage = PROPERTY_USAGE_DEFAULT,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "0.0,1.0"
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
	var texture = Texture3D.new()
	texture.create(IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, Image.FORMAT_RGBA8)
	for i in range(IMAGE_SIZE_PIXELS):
		var image = Image.new()
		image.create(IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, false, Image.FORMAT_RGBA8)
		image.lock()
		image.fill(Color(PERSISTENCE, PERSISTENCE, 0.0))
		image.unlock()
		texture.set_layer_data(image, i)
	return texture


# Creates a list of points based in sectors. Used as part of Worley Noise algorithm.
func create_discrete_sector_points(points_count, sector_size, points_per_axis):
	# Create 3D array, slightly bigger to cover mirrored edges
	var seamless_axis = points_per_axis+2
	var end = points_per_axis-1
	var ends = seamless_axis-1
	var points = []
	points.resize(seamless_axis)
	for x in range(seamless_axis):
		points[x] = []
		points[x].resize(seamless_axis)
		for y in range(seamless_axis):
			points[x][y] = []
			points[x][y].resize(seamless_axis)

	# Populate inner cube (NxNxN) of array with random points 
	for x in range(points_per_axis):
		for y in range(points_per_axis):
			for z in range(points_per_axis):
				points[x+1][y+1][z+1] = Vector3( \
					int(rand_range(sector_size*x, sector_size*x + sector_size)), \
					int(rand_range(sector_size*y, sector_size*y + sector_size)), \
					int(rand_range(sector_size*z, sector_size*z + sector_size)))

	# Populate mirrored edges
	# - Fill squares (NxNx1) with mirrored entries (x6)
	for x in range(points_per_axis):
		for y in range(points_per_axis):
			points[1+x][1+y][0] = points[x+1][y+1][end+1] + Vector3(0,0,-IMAGE_SIZE_PIXELS)
			points[1+x][1+y][ends] = points[x+1][y+1][1] + Vector3(0,0, IMAGE_SIZE_PIXELS)
	for x in range(points_per_axis):
		for z in range(points_per_axis):
			points[1+x][0][1+z] = points[x+1][end+1][z+1] + Vector3(0,-IMAGE_SIZE_PIXELS, 0)
			points[1+x][ends][1+z] = points[x+1][1][z+1] + Vector3(0, IMAGE_SIZE_PIXELS, 0)
	for y in range(points_per_axis):
		for z in range(points_per_axis):
			points[0][1+y][1+z] = points[end+1][y+1][z+1] + Vector3(-IMAGE_SIZE_PIXELS, 0, 0)
			points[ends][1+y][1+z] = points[1][y+1][z+1] + Vector3( IMAGE_SIZE_PIXELS, 0, 0)
	# - Fill corner lines (Nx1x1) with mirrored entries (x12)
	for x in range(points_per_axis):
		points[x+1][0][0] = points[x+1][end+1][end+1] + Vector3(0,-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
		points[x+1][ends][0] = points[x+1][1][end+1] + Vector3(0, IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
		points[x+1][0][ends] = points[x+1][end+1][1] + Vector3(0,-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
		points[x+1][ends][ends] = points[x+1][1][1] + Vector3(0, IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
	for y in range(points_per_axis):
		points[0][y+1][0] = points[end+1][y+1][end+1] + Vector3(-IMAGE_SIZE_PIXELS, 0,-IMAGE_SIZE_PIXELS)
		points[ends][y+1][0] = points[1][y+1][end+1] + Vector3( IMAGE_SIZE_PIXELS, 0,-IMAGE_SIZE_PIXELS)
		points[0][y+1][ends] = points[end+1][y+1][1] + Vector3(-IMAGE_SIZE_PIXELS, 0, IMAGE_SIZE_PIXELS)
		points[ends][y+1][ends] = points[1][y+1][1] + Vector3( IMAGE_SIZE_PIXELS, 0, IMAGE_SIZE_PIXELS)
	for z in range(points_per_axis):
		points[0][0][z+1] = points[end+1][end+1][z+1] + Vector3(-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS, 0)
		points[ends][0][z+1] = points[1][end+1][z+1] + Vector3( IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS, 0)
		points[0][ends][z+1] = points[end+1][1][z+1] + Vector3(-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, 0)
		points[ends][ends][z+1] = points[1][1][z+1] + Vector3( IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, 0)
	# - Fill corner elements (1x1x1) with mirrored entries (x8)
	points[0][0][0] = points[end+1][end+1][end+1] + Vector3(-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
	points[ends][0][0] = points[1][end+1][end+1] + Vector3( IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
	points[0][ends][0] = points[end+1][1][end+1] + Vector3(-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
	points[ends][ends][0] = points[1][1][end+1] + Vector3( IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS)
	points[0][0][ends] = points[end+1][end+1][1] + Vector3(-IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
	points[ends][0][ends] = points[1][end+1][1] + Vector3( IMAGE_SIZE_PIXELS,-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
	points[0][ends][ends] = points[end+1][1][1] + Vector3(-IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)
	points[ends][ends][ends] = points[1][1][1] + Vector3( IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS, IMAGE_SIZE_PIXELS)

	return points


# REMOVE
# Convert points_image into a sampler2D texture with xy in rg channel
func get_points_representation(points, points_per_axis, sector_size):
	var points_image: Image = Image.new()
	points_image.create(points_per_axis, points_per_axis, false, Image.FORMAT_RGB8)
	points_image.lock()
	var current_layer = int(SLICE * (points_per_axis-1))
	for y in range(points_per_axis):
		for x in range(points_per_axis):
			var coord_in_sector_raw = Vector2( \
				fposmod(points[x][y][current_layer].x, sector_size), \
				fposmod(points[x][y][current_layer].y, sector_size))
			var coord_in_sector_unit = coord_in_sector_raw / sector_size
			points_image.set_pixelv(Vector2(x,y), Color(coord_in_sector_unit.x, coord_in_sector_unit.y, 0, 1))
	points_image.unlock()
	return points_image


func cloud_texture_creation():
	var full_texture = setup_texture_creation();

	# Step 1: Create points for each channel

	r_points = create_discrete_sector_points( \
		R_POINTS_COUNT, \
		R_SECTOR_SIZE, \
		R_POINTS_PER_AXIS)	

	# Step 2: Render into 3D sampler

	# for each voxel

	# for each channel

	# Calculate min dist 

	# Write to sampler


	# Step 3: Display

	# Grab the first layer and throw in a screen texture 

	return full_texture


func display_texture3d_slice(texture):
	var display_texture = ImageTexture.new()
	var current_layer = int(SLICE * (IMAGE_SIZE_PIXELS-1))
	display_texture.create_from_image(texture.data['layers'][current_layer])

	r_texture = ImageTexture.new()
	var r_points_image = get_points_representation( \
		r_points, \
		R_SEAMLESS_POINTS_PER_AXIS, \
		R_SECTOR_SIZE)
	r_texture.create_from_image(r_points_image)

	$TextureVisualizer.texture = r_texture # display_texture

