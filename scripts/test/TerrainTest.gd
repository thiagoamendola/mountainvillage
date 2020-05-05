extends Spatial

const HTerrain = preload("res://addons/zylann.hterrain/hterrain.gd")
const HTerrainData = preload("res://addons/zylann.hterrain/hterrain_data.gd")

# You may want to change paths to your own textures
var grass_texture = load("res://addons/zylann.hterrain_demo/textures/ground/grass_albedo_bump.png")
var sand_texture = load("res://addons/zylann.hterrain_demo/textures/ground/sand_albedo_bump.png")
var leaves_texture = load("res://addons/zylann.hterrain_demo/textures/ground/leaves_albedo_bump.png")


func _ready():
	var data = HTerrainData.new()
	data.resize(65)
	
	var terrain = HTerrain.new()
	terrain.set_data(data)
	add_child(terrain)
	
	var noise = OpenSimplexNoise.new()
	var noise_multiplier = 530.0
	
	var heightmap: Image = data.get_image(HTerrainData.CHANNEL_HEIGHT)
	
	heightmap.lock()
	
	# ADD TEXTURE TO IMPROVE VISIBILITY

	for z in heightmap.get_height():
		for x in heightmap.get_width():
			# var h = noise_multiplier * noise.get_noise_2d(x, z)
			# var h = -1.0 + (z%4) + (x%4)
			var h = (z+x)/(2*heightmap.get_height())

			h *= noise_multiplier
			
			heightmap.set_pixel(x, z, Color(h, 0, 0))
	
	heightmap.unlock()
	
	var modified_region = Rect2(Vector2(), heightmap.get_size())
	data.notify_region_change(modified_region, HTerrainData.CHANNEL_HEIGHT)

	