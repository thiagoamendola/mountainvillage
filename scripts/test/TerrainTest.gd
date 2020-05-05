extends Spatial

# Import classes
const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
const HTerrainData = preload("res://addons/zylann.hterrain/hterrain_data.gd")

const cell_per_axis = 16
const height_mountain_base = 30
const height_mountain_multiplier = 40
const height_plateau_base = 0
const height_plateau_multiplier = 10
const height_abyss_base = -60
const height_abyss_multiplier = 0

func _ready():

	# Create terrain resource and give it a size.
	# It must be either 513, 1025, 2049 or 4097.
	var terrain_data = HTerrainData.new()
	terrain_data.resize(1025)
	
	var noise = OpenSimplexNoise.new()
	var rng = RandomNumberGenerator.new()

	# Get access to terrain maps you want to modify
	var heightmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_HEIGHT)
	var normalmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_NORMAL)
	
	heightmap.lock()
	normalmap.lock()

	# Generate terrain maps
	# Note: this is an example with some arbitrary formulas,
	# you may want to come up with your own
	for z in heightmap.get_height():
		for x in heightmap.get_width():
			var z_cell = z / (heightmap.get_height()/cell_per_axis)
			var x_cell = x / (heightmap.get_width()/cell_per_axis)
			var h
			var normal

			rng.seed = z_cell + 10000*x_cell
			#if (z_cell + x_cell) % 2 == 0:
			var rand_val = rng.randi_range(0,3)
			if rand_val == 0:
				# MOUNTAIN CELL
				h = height_mountain_base + height_mountain_multiplier * noise.get_noise_2d(x, z)
				var h_right = height_mountain_base + height_mountain_multiplier * noise.get_noise_2d(x + 0.1, z)
				var h_forward = height_mountain_base + height_mountain_multiplier * noise.get_noise_2d(x, z + 0.1)
				normal = Vector3(h - h_right, 0.1, h_forward - h).normalized()
			elif rand_val == 1:
				h = height_plateau_base + height_plateau_multiplier * noise.get_noise_2d(x, z)
				var h_right = height_plateau_base + height_plateau_multiplier * noise.get_noise_2d(x + 0.1, z)
				var h_forward = height_plateau_base + height_plateau_multiplier * noise.get_noise_2d(x, z + 0.1)
				normal = Vector3(h - h_right, 0.1, h_forward - h).normalized()
			else:
				h = height_abyss_base + height_abyss_multiplier * noise.get_noise_2d(x, z)
				var h_right = height_abyss_base + height_abyss_multiplier * noise.get_noise_2d(x + 0.1, z)
				var h_forward = height_abyss_base + height_abyss_multiplier * noise.get_noise_2d(x, z + 0.1)
				normal = Vector3(h - h_right, 0.1, h_forward - h).normalized()
			
			heightmap.set_pixel(x, z, Color(h, 0, 0))
			normalmap.set_pixel(x, z, HTerrainData.encode_normal(normal))

	heightmap.unlock()
	normalmap.unlock()
	
	# Commit modifications so they get uploaded to the graphics card
	var modified_region = Rect2(Vector2(), heightmap.get_size())
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_HEIGHT)
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_NORMAL)

	# Create terrain node
	var terrain = HTerrain.new()
	#terrain.set_shader_type(HTerrain.SHADER_CLASSIC4_LITE)
	terrain.set_data(terrain_data)
	add_child(terrain)
			
	# No need to call this, but you may need to if you edit the terrain later on
	#terrain.update_collider()