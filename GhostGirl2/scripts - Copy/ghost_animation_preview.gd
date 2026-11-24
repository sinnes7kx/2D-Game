extends Node2D
const EXTRA_ANIMATIONS = preload("res://scripts/ghost_animation_library.gd")
func _ready() -> void:
	var shared_frames: SpriteFrames = null
	for node in get_children():
		if node is AnimatedSprite2D:
			var sprite: AnimatedSprite2D = node as AnimatedSprite2D
			if shared_frames == null:
				EXTRA_ANIMATIONS.install(sprite)
				shared_frames = sprite.sprite_frames
			else:
				sprite.sprite_frames = shared_frames
			if sprite.sprite_frames.has_animation(sprite.animation):
				sprite.play(sprite.animation)
