extends Spatial

# const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
# const HTerrainData = preload("res://addons/zylann.hterrain/hterrain_data.gd")

# # You may want to change paths to your own textures
# var grass_texture = load("res://addons/zylann.hterrain_demo/textures/ground/grass_albedo_bump.png")
# var sand_texture = load("res://addons/zylann.hterrain_demo/textures/ground/sand_albedo_bump.png")
# var leaves_texture = load("res://addons/zylann.hterrain_demo/textures/ground/leaves_albedo_bump.png")


# func _ready():
# 	var data = HTerrainData.new()
# 	data.resize(65)
	
# 	var terrain = HTerrain.new()
# 	terrain.set_data(data)
# 	add_child(terrain)
	
# 	var noise = OpenSimplexNoise.new()
# 	var noise_multiplier = 530.0
	
# 	var heightmap: Image = data.get_image(HTerrainData.CHANNEL_HEIGHT)
	
# 	heightmap.lock()
	
# 	# ADD TEXTURE TO IMPROVE VISIBILITY

# 	for z in heightmap.get_height():
# 		for x in heightmap.get_width():
# 			# var h = noise_multiplier * noise.get_noise_2d(x, z)
# 			# var h = -1.0 + (z%4) + (x%4)
# 			var h = (z+x)/(2*heightmap.get_height())

# 			h *= noise_multiplier
			
# 			heightmap.set_pixel(x, z, Color(h, 0, 0))
	
# 	heightmap.unlock()
	
# 	var modified_region = Rect2(Vector2(), heightmap.get_size())
#	data.notify_region_change(modified_region, HTerrainData.CHANNEL_HEIGHT)

# Import classes
const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
const HTerrainData = preload("res://addons/zylann.hterrain/hterrain_data.gd")

# You may want to change paths to your own textures
var grass_texture = load("res://addons/zylann.hterrain_demo/textures/ground/grass_albedo_bump.png")
var sand_texture = load("res://addons/zylann.hterrain_demo/textures/ground/sand_albedo_bump.png")
var leaves_texture = load("res://addons/zylann.hterrain_demo/textures/ground/leaves_albedo_bump.png")

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
	var splatmap: Image = terrain_data.get_image(HTerrainData.CHANNEL_SPLAT)
	
	heightmap.lock()
	normalmap.lock()
	splatmap.lock()
	
	# Generate terrain maps
	# Note: this is an example with some arbitrary formulas,
	# you may want to come up with your own
	for z in heightmap.get_height():
		for x in heightmap.get_width():
			
			# Generate height
			var h = noise_multiplier * noise.get_noise_2d(x, z)
			
			# Getting normal by generating extra heights directly from noise,
			# so map borders won't have seams in case you stitch them
			var h_right = noise_multiplier * noise.get_noise_2d(x + 0.1, z)
			var h_forward = noise_multiplier * noise.get_noise_2d(x, z + 0.1)
			var normal = Vector3(h - h_right, 0.1, h_forward - h).normalized()
			
			# Generate texture amounts
			# Note: the red channel is 1 by default
			var splat = splatmap.get_pixel(x, z)
			var slope = 4.0 * normal.dot(Vector3.UP) - 2.0
			# Sand on the slopes
			var sand_amount = clamp(1.0 - slope, 0.0, 1.0)
			# Leaves below sea level
			var leaves_amount = clamp(0.0 - h, 0.0, 1.0)
			splat = splat.linear_interpolate(Color(0,1,0,0), sand_amount)
			splat = splat.linear_interpolate(Color(0,0,1,0), leaves_amount)

			heightmap.set_pixel(x, z, Color(h, 0, 0))
			normalmap.set_pixel(x, z, HTerrainData.encode_normal(normal))
			splatmap.set_pixel(x, z, splat)
	
	heightmap.unlock()
	normalmap.unlock()
	splatmap.unlock()
	
	# Commit modifications so they get uploaded to the graphics card
	var modified_region = Rect2(Vector2(), heightmap.get_size())
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_HEIGHT)
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_NORMAL)
	terrain_data.notify_region_change(modified_region, HTerrainData.CHANNEL_SPLAT)

	# Create terrain node
	var terrain = HTerrain.new()
	#terrain.set_shader_type(HTerrain.SHADER_CLASSIC4_LITE)
	terrain.set_data(terrain_data)
	terrain.set_ground_texture(0, HTerrain.GROUND_ALBEDO_BUMP, grass_texture)
	terrain.set_ground_texture(1, HTerrain.GROUND_ALBEDO_BUMP, sand_texture)
	terrain.set_ground_texture(2, HTerrain.GROUND_ALBEDO_BUMP, leaves_texture)
	add_child(terrain)
	
	# No need to call this, but you may need to if you edit the terrain later on
	#terrain.update_collider()