tool
extends Control

var RUN_IN_EDITOR := false
var IMAGE_SIZE_PIXELS := 128
var PERSISTENCE := 1.0

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
			PERSISTENCE, \
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









func cloud_texture_creation():
	var texture = setup_texture_creation();

	# Step 1: Create points for each channel

	# Create bigger array

	# Create points

	# Add mirrored points


	# Step 2: Render into 3D sampler

	# for each voxel

	# for each channel

	# Calculate min dist 

	# Write to sampler


	# Step 3: Display

	# Grab the first layer and throw in a screen texture 

	return texture


func display_texture3d_slice(texture):
	var visTexture = ImageTexture.new()
	visTexture.create_from_image(texture.data['layers'][0])
	$TextureVisualizer.texture = visTexture

