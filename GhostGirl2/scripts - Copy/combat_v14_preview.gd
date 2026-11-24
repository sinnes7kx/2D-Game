extends Node2D
const EXTRA_ANIMATIONS = preload("res://scripts/ghost_animation_library.gd")
## SpriteFrames workshop: all 16 production tracks restart independently.
func _ready() -> void:
    var shared_frames: SpriteFrames = null
    for node in get_children():
        if node is AnimatedSprite2D:
            if shared_frames == null:
                EXTRA_ANIMATIONS.install(node)
                shared_frames = node.sprite_frames
            else:
                node.sprite_frames = shared_frames
            if node.sprite_frames.has_animation(node.animation):
                node.play(node.animation)
            node.animation_finished.connect(_loop_track.bind(node))

func _loop_track(sprite: AnimatedSprite2D) -> void:
    if is_instance_valid(sprite):
        sprite.play()
