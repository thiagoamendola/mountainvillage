tool
extends Spatial

var RUN_IN_EDITOR := false
var IMAGE_SIZE_PIXELS := 128
var PERSISTENCE := 1.0
var SLICE := 1.0

var R_POINTS_PER_AXIS := 5
var R_INTENSITY_MULTIPLIER := 1.1

var G_POINTS_PER_AXIS := 6
var G_INTENSITY_MULTIPLIER := .7

var B_POINTS_PER_AXIS := 8
var B_INTENSITY_MULTIPLIER := .7

var SLICE_MODE := false

var rerender_param_cache
var regenerate_param_cache

var noise_texture

var CubeTextureCreator = load("res://clouds/v2/CubeTextureCreator.gd")

var cube_texture_creator

"""
We need to aplit this into other files. here's a list:

- Current one: will be the Manager. Instantiates others, hangles Godot editor vars and calls stuff
- CubeTextureCreator
- TextureUIHelper
"""

func _ready():
	# Instantiation and grab ref to UI
	cube_texture_creator = CubeTextureCreator.new()

	# Generate cube texture and display
	noise_texture = generate_texture()
	display_texture3d(noise_texture)
	pass

func _process(delta):
	if (RUN_IN_EDITOR):
		# Not working????
		var current_rerender_param_cache = [ \
			RUN_IN_EDITOR, \
			IMAGE_SIZE_PIXELS, \
			PERSISTENCE, \
			SLICE, \
			SLICE_MODE, \
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
				noise_texture = generate_texture()
			rerender_param_cache = current_rerender_param_cache
			display_texture3d(noise_texture)

	pass

# Maybe move to UI?
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_R:
			noise_texture = generate_texture()
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

	props.append({
		name = "SLICE_MODE",
		type = TYPE_BOOL
	})

	return props


# Prepare parameters and call CubeTextureCreator
func generate_texture():
	var texture_creation_params = {
		"image_size_pixels": IMAGE_SIZE_PIXELS,
		"r_points_per_axis": R_POINTS_PER_AXIS,
		"g_points_per_axis": G_POINTS_PER_AXIS,
		"b_points_per_axis": B_POINTS_PER_AXIS,
		"r_intensity_multiplier": R_INTENSITY_MULTIPLIER,
		"g_intensity_multiplier": G_INTENSITY_MULTIPLIER,
		"b_intensity_multiplier": B_INTENSITY_MULTIPLIER
	}
	return cube_texture_creator.cloud_texture_creation(texture_creation_params)


# Move to UI
func display_texture3d(texture):
	var display_texture = ImageTexture.new()
	var current_layer = int(SLICE * (IMAGE_SIZE_PIXELS-1))
	display_texture.create_from_image(texture.data['layers'][current_layer])

	$DebugUI/TextureVisualizer.texture = display_texture
	var generation_time = cube_texture_creator.get_last_generation_time()
	var texture_details = "time = {generation_time}s"
	$DebugUI/TextureInfo.text = texture_details.format({
		"generation_time": generation_time
	})

	var mat = get_node("ShaderQuad").get_active_material(0)
	var volume_aabb = $CloudVolume.get_aabb();
	var bound_min = Vector3($CloudVolume.global_translation) + \
		volume_aabb.position * volume_aabb.size * $CloudVolume.scale / 2
	var bound_max = Vector3($CloudVolume.global_translation) + \
		volume_aabb.end * volume_aabb.size * $CloudVolume.scale / 2
	mat.set_shader_param("noise_texture", texture)
	mat.set_shader_param("bound_min", bound_min)
	mat.set_shader_param("bound_max", bound_max)
	mat.set_shader_param("slice_mode", SLICE_MODE)
	mat.set_shader_param("slice", SLICE)

