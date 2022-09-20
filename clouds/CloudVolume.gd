extends MeshInstance



# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var mat = get_surface_material(0)
	mat.set_shader_param("boundMin", get_aabb().position)
	mat.set_shader_param("boundMax", get_aabb().end)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
