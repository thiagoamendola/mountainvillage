tool
extends Spatial

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

var noise_texture

func _ready():
	noise_texture = cloud_texture_creation()
	display_texture3d(noise_texture)
	pass

func _process(delta):
	# display_texture3d(noise_texture)

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
			display_texture3d(noise_texture)

	pass

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_R:
			noise_texture = cloud_texture_creation()
			display_texture3d(noise_texture)
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
		image.fill(Color(0, 0, 0))
		image.unlock()
		texture.set_layer_data(image, i)
	return texture


# Creates a list of points based in sectors. Used as part of Worley Noise algorithm.
func create_discrete_sector_points(sector_size, points_per_axis):
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


# Get points for current and all neighbor sectors.
func get_adjacent_sector_points(seamless_points, current_voxel, sector_size, points_per_axis):
	var adjacent_points = []
	# Get current sector and apply offset to match seamless array
	var current_sector_vec = Vector3( \
		min(int(current_voxel.x/sector_size) + 1, points_per_axis-1), \
		min(int(current_voxel.y/sector_size) + 1, points_per_axis-1), \
		min(int(current_voxel.z/sector_size) + 1, points_per_axis-1))
	# Add all adjacent sector points
	for x in range(-1,2):
		for y in range(-1,2):
			for z in range(-1,2):
				adjacent_points.append(seamless_points[current_sector_vec.x+x] \
													  [current_sector_vec.y+y] \
													  [current_sector_vec.z+z])
	return adjacent_points


func get_color_for_channel(current_voxel, points, sector_size, points_per_axis, intensity_multiplier):
	# Calculate min dist 
	var min_dist = INF
	for adj_point in get_adjacent_sector_points(points, current_voxel, sector_size, points_per_axis):
		var cur_dist = adj_point.distance_to(current_voxel)
		if cur_dist < min_dist:
			min_dist = cur_dist
	# Get final value for channel
	return clamp(intensity_multiplier * min_dist / IMAGE_SIZE_PIXELS, 0.0, 1.0)


func cloud_texture_creation():
	print("START")
	var start_time = OS.get_unix_time()

	var full_texture = setup_texture_creation();

	# Step 1: Create points for each channel
	var r_points = create_discrete_sector_points( \
		R_SECTOR_SIZE, \
		R_POINTS_PER_AXIS)
	var g_points = create_discrete_sector_points( \
		G_SECTOR_SIZE, \
		G_POINTS_PER_AXIS)
	var b_points = create_discrete_sector_points( \
		B_SECTOR_SIZE, \
		B_POINTS_PER_AXIS)

	# Step 2: Render into 3D sampler

	var end_time = OS.get_unix_time()
	print(end_time - start_time)
	print("Start 3d sampler")

	for z in range(IMAGE_SIZE_PIXELS):
		var layer = full_texture.get_layer_data(z)
		layer.lock()

		#-> Multithread this? IDEA: create a shared pool of indexes and multiple threads. Each thread pops a value from the pool and processes it. Once done, it pops the next index until the list is over. Mutex is required for popping the pool
		for x in range(IMAGE_SIZE_PIXELS):
			for y in range(IMAGE_SIZE_PIXELS):
				var current_voxel = Vector3(x, y, z)
				
				var r_final_value = get_color_for_channel( \
					current_voxel, \
					r_points, \
					R_SECTOR_SIZE, \
					R_POINTS_PER_AXIS, \
					R_INTENSITY_MULTIPLIER)
				var g_final_value = get_color_for_channel( \
					current_voxel, \
					g_points, \
					G_SECTOR_SIZE, \
					G_POINTS_PER_AXIS, \
					G_INTENSITY_MULTIPLIER)
				var b_final_value = get_color_for_channel( \
					current_voxel, \
					b_points, \
					B_SECTOR_SIZE, \
					B_POINTS_PER_AXIS, \
					B_INTENSITY_MULTIPLIER)
				# Write to sampler
				layer.set_pixel(x, y, Color(1-r_final_value, 1-g_final_value, 1-b_final_value))

		layer.unlock()
		full_texture.set_layer_data(layer, z)

	# Step 3: Display

	end_time = OS.get_unix_time()
	print(end_time - start_time)
	print("3d sampler completed!")

	return full_texture


func display_texture3d(texture):
	var display_texture = ImageTexture.new()
	var current_layer = int(SLICE * (IMAGE_SIZE_PIXELS-1))
	display_texture.create_from_image(texture.data['layers'][current_layer])

	$TextureVisualizer.texture = display_texture

	var mat = get_node("ShaderQuad").get_active_material(0)
	var volume_aabb = $CloudVolume.get_aabb();
	var boundMin = Vector3($CloudVolume.global_translation) + \
		volume_aabb.position * volume_aabb.size * $CloudVolume.scale / 2
	var boundMax = Vector3($CloudVolume.global_translation) + \
		volume_aabb.end * volume_aabb.size * $CloudVolume.scale / 2
	mat.set_shader_param("boundMin", boundMin)
	mat.set_shader_param("boundMax", boundMax)


