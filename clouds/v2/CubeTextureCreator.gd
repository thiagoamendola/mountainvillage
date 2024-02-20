extends Spatial

var r_points_count
var r_sector_size
var r_seamless_points_per_axis

var g_points_count
var g_sector_size
var g_seamless_points_per_axis

var b_points_count
var b_sector_size
var b_seamless_points_per_axis

var generation_time := 0.0

func _init():
	print("TIMTIM")
	pass

# Creates 3D texture
func cloud_texture_creation(params):
	print("START")
	var start_time = float(OS.get_system_time_msecs())

	var full_texture = setup_texture_creation(params);

	# Step 1: Create points for each channel
	var r_points = create_discrete_sector_points( \
		params, \
		r_sector_size, \
		params.r_points_per_axis)
	var g_points = create_discrete_sector_points( \
		params, \
		g_sector_size, \
		params.g_points_per_axis)
	var b_points = create_discrete_sector_points( \
		params, \
		b_sector_size, \
		params.b_points_per_axis)

	# Step 2: Render into 3D sampler

	var end_time = float(OS.get_system_time_msecs())
	print((end_time - start_time)/1000)
	print("Start 3d sampler")

	for z in range(params.image_size_pixels):
		var layer = full_texture.get_layer_data(z)
		layer.lock()

		#-> Multithread this? IDEA: create a shared pool of indexes and multiple threads. Each thread pops a value from the pool and processes it. Once done, it pops the next index until the list is over. Mutex is required for popping the pool
		for x in range(params.image_size_pixels):
			for y in range(params.image_size_pixels):
				var current_voxel = Vector3(x, y, z)
				
				var r_final_value = get_color_for_channel( \
					current_voxel, \
					r_points, \
					r_sector_size, \
					params.r_points_per_axis, \
					params.r_intensity_multiplier, \
					params.image_size_pixels)
				var g_final_value = get_color_for_channel( \
					current_voxel, \
					g_points, \
					g_sector_size, \
					params.g_points_per_axis, \
					params.g_intensity_multiplier, \
					params.image_size_pixels)
				var b_final_value = get_color_for_channel( \
					current_voxel, \
					b_points, \
					b_sector_size, \
					params.b_points_per_axis, \
					params.b_intensity_multiplier, \
					params.image_size_pixels)
				# Write to sampler
				layer.set_pixel(x, y, Color(1-r_final_value, 1-g_final_value, 1-b_final_value))

		layer.unlock()
		full_texture.set_layer_data(layer, z)

	# Step 3: Display

	end_time = float(OS.get_system_time_msecs())
	generation_time = (end_time - start_time) / 1000
	print(generation_time)
	print("3d sampler completed!")

	return full_texture


# Sets up necessary parameters and texture object.
func setup_texture_creation(params):
	# Set main variables with latest values.
	# <-- Do I need all of these???
	r_points_count = params.r_points_per_axis*params.r_points_per_axis*params.r_points_per_axis
	r_sector_size = ceil(params.image_size_pixels/params.r_points_per_axis)
	r_seamless_points_per_axis = params.r_points_per_axis+2

	g_points_count = params.g_points_per_axis*params.g_points_per_axis*params.g_points_per_axis
	g_sector_size = ceil(params.image_size_pixels/params.g_points_per_axis)
	g_seamless_points_per_axis = params.g_points_per_axis+2

	b_points_count = params.b_points_per_axis*params.b_points_per_axis*params.b_points_per_axis
	b_sector_size = ceil(params.image_size_pixels/params.b_points_per_axis)
	b_seamless_points_per_axis = params.b_points_per_axis+2

	# Create default image for TextureRect to work.
	var texture = Texture3D.new()
	texture.create(params.image_size_pixels, params.image_size_pixels, params.image_size_pixels, Image.FORMAT_RGBA8)
	for i in range(params.image_size_pixels):
		var image = Image.new()
		image.create(params.image_size_pixels, params.image_size_pixels, false, Image.FORMAT_RGBA8)
		image.lock()
		image.fill(Color(0, 0, 0))
		image.unlock()
		texture.set_layer_data(image, i)
	return texture


# Creates a list of points based in sectors. Used as part of Worley Noise algorithm.
func create_discrete_sector_points(params, sector_size, points_per_axis):
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
			points[1+x][1+y][0] = points[x+1][y+1][end+1] + Vector3(0,0,-params.image_size_pixels)
			points[1+x][1+y][ends] = points[x+1][y+1][1] + Vector3(0,0, params.image_size_pixels)
	for x in range(points_per_axis):
		for z in range(points_per_axis):
			points[1+x][0][1+z] = points[x+1][end+1][z+1] + Vector3(0,-params.image_size_pixels, 0)
			points[1+x][ends][1+z] = points[x+1][1][z+1] + Vector3(0, params.image_size_pixels, 0)
	for y in range(points_per_axis):
		for z in range(points_per_axis):
			points[0][1+y][1+z] = points[end+1][y+1][z+1] + Vector3(-params.image_size_pixels, 0, 0)
			points[ends][1+y][1+z] = points[1][y+1][z+1] + Vector3( params.image_size_pixels, 0, 0)
	# - Fill corner lines (Nx1x1) with mirrored entries (x12)
	for x in range(points_per_axis):
		points[x+1][0][0] = points[x+1][end+1][end+1] + Vector3(0,-params.image_size_pixels,-params.image_size_pixels)
		points[x+1][ends][0] = points[x+1][1][end+1] + Vector3(0, params.image_size_pixels,-params.image_size_pixels)
		points[x+1][0][ends] = points[x+1][end+1][1] + Vector3(0,-params.image_size_pixels, params.image_size_pixels)
		points[x+1][ends][ends] = points[x+1][1][1] + Vector3(0, params.image_size_pixels, params.image_size_pixels)
	for y in range(points_per_axis):
		points[0][y+1][0] = points[end+1][y+1][end+1] + Vector3(-params.image_size_pixels, 0,-params.image_size_pixels)
		points[ends][y+1][0] = points[1][y+1][end+1] + Vector3( params.image_size_pixels, 0,-params.image_size_pixels)
		points[0][y+1][ends] = points[end+1][y+1][1] + Vector3(-params.image_size_pixels, 0, params.image_size_pixels)
		points[ends][y+1][ends] = points[1][y+1][1] + Vector3( params.image_size_pixels, 0, params.image_size_pixels)
	for z in range(points_per_axis):
		points[0][0][z+1] = points[end+1][end+1][z+1] + Vector3(-params.image_size_pixels,-params.image_size_pixels, 0)
		points[ends][0][z+1] = points[1][end+1][z+1] + Vector3( params.image_size_pixels,-params.image_size_pixels, 0)
		points[0][ends][z+1] = points[end+1][1][z+1] + Vector3(-params.image_size_pixels, params.image_size_pixels, 0)
		points[ends][ends][z+1] = points[1][1][z+1] + Vector3( params.image_size_pixels, params.image_size_pixels, 0)
	# - Fill corner elements (1x1x1) with mirrored entries (x8)
	points[0][0][0] = points[end+1][end+1][end+1] + Vector3(-params.image_size_pixels,-params.image_size_pixels,-params.image_size_pixels)
	points[ends][0][0] = points[1][end+1][end+1] + Vector3( params.image_size_pixels,-params.image_size_pixels,-params.image_size_pixels)
	points[0][ends][0] = points[end+1][1][end+1] + Vector3(-params.image_size_pixels, params.image_size_pixels,-params.image_size_pixels)
	points[ends][ends][0] = points[1][1][end+1] + Vector3( params.image_size_pixels, params.image_size_pixels,-params.image_size_pixels)
	points[0][0][ends] = points[end+1][end+1][1] + Vector3(-params.image_size_pixels,-params.image_size_pixels, params.image_size_pixels)
	points[ends][0][ends] = points[1][end+1][1] + Vector3( params.image_size_pixels,-params.image_size_pixels, params.image_size_pixels)
	points[0][ends][ends] = points[end+1][1][1] + Vector3(-params.image_size_pixels, params.image_size_pixels, params.image_size_pixels)
	points[ends][ends][ends] = points[1][1][1] + Vector3( params.image_size_pixels, params.image_size_pixels, params.image_size_pixels)

	return points


# Gets value of the channel in a given voxel
func get_color_for_channel(current_voxel, points, sector_size, points_per_axis, intensity_multiplier, image_size_pixels):
	# Calculate min dist 
	var min_dist = INF
	for adj_point in get_adjacent_sector_points(points, current_voxel, sector_size, points_per_axis):
		var cur_dist = adj_point.distance_to(current_voxel)
		if cur_dist < min_dist:
			min_dist = cur_dist
	# Get final value for channel
	return clamp(intensity_multiplier * min_dist / image_size_pixels, 0.0, 1.0)


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


# Expose generation time.
func get_last_generation_time():
	return generation_time




