extends RefCounted
## v1.75: replace legacy rose-hook BODY frames only for weapon families that
## paint their held weapons separately. Keeps approved character pixels from
## the existing clean v14 unarmed animation, no destructive atlas edits.
static func install(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = sprite.sprite_frames
	for name in frames.get_animation_names():
		var anim: String = str(name)
		var dual: bool = anim.begins_with("dual_dagger_") or anim.begins_with("dual_sword_") or anim.begins_with("attack_dual_dagger_") or anim.begins_with("attack_dual_sword_")
		var newer_attack: bool = anim.begins_with("attack_nocturne_dagger_") or anim.begins_with("attack_briarwake_spear_")
		# The physical left bow is drawn separately and mirrored from the
		# RIGHT bow-only layer, so these left body frames must be bow-free.
		var left_bow: bool = anim.ends_with("_left") and (anim.begins_with("thornrose_idle_") or anim.begins_with("thornrose_walk_") or anim.begins_with("moonveil_idle_") or anim.begins_with("moonveil_walk_") or anim.begins_with("attack_thornrose_") or anim.begins_with("attack_moonveil_"))
		if not dual and not newer_attack and not left_bow:
			continue
		var face: String = ""
		for suffix in ["front", "back", "left", "right"]:
			if anim.ends_with(suffix):
				face = suffix
				break
		if face.is_empty():
			continue
		var source: String = "attack_unarmed_light_" + face
		if not frames.has_animation(source) or frames.get_frame_count(source) == 0:
			push_warning("v1.75 missing approved hook-free body: " + source)
			continue
		var original_count: int = frames.get_frame_count(anim)
		var speed: float = frames.get_animation_speed(anim)
		var looping: bool = frames.get_animation_loop(anim)
		var idle: bool = anim.contains("_idle_")
		var walk: bool = anim.contains("_walk_")
		var select_frames: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
		if idle:
			select_frames = [0, 0, 1, 0, 0, 1, 0, 0]
		elif walk:
			select_frames = [0, 1, 2, 1, 0, 1, 2, 1]
		var textures: Array[Texture2D] = []
		var source_count: int = frames.get_frame_count(source)
		for i in range(maxi(1, original_count)):
			var source_index: int = select_frames[i % 8] % source_count
			textures.append(frames.get_frame_texture(source, source_index))
		frames.remove_animation(anim)
		frames.add_animation(anim)
		frames.set_animation_speed(anim, speed)
		frames.set_animation_loop(anim, looping)
		for tile in textures:
			frames.add_frame(anim, tile)
