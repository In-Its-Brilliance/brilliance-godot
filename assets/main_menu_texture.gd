@tool
extends TextureRect

@export var textures: Array[Texture2D] = []
@export var randomize_texture: bool = false:
	set(value):
		if value and textures.size() > 0:
			texture = textures.pick_random()

func _ready():
	if textures.size() > 0:
		texture = textures.pick_random()
