extends Spatial

# Import classes
const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
const HTerrainData = preload("res://addons/zylann.hterrain/hterrain_data.gd")

const cell_size = 128

func _ready():

	# Create terrain resource and give it a size.
	# It must be either 513, 1025, 2049 or 4097.
	var terrain_data = HTerrainData.new()
	terrain_data.resize(513)
	
	var noise = OpenSimplexNoise.new()
	var noise_multiplier = 50.0

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
			var x_cell = x / cell_size
			var z_cell = z / cell_size
			var h
			var normal

			if (z_cell + x_cell) % 2 == 0: 
				# Generate height
				h = noise_multiplier * noise.get_noise_2d(x, z)
				# Getting normal by generating extra heights directly from noise,
				# so map borders won't have seams in case you stitch them
				var h_right = noise_multiplier * noise.get_noise_2d(x + 0.1, z)
				var h_forward = noise_multiplier * noise.get_noise_2d(x, z + 0.1)
				normal = Vector3(h - h_right, 0.1, h_forward - h).normalized()
			else:
				h = 0.0
				normal = Vector3.UP
				
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