extends SceneTree
const THRUST = preload("res://scripts/dagger_thrust_v186.gd")
const GUARD = preload("res://scripts/frame_guard_v186.gd")
const LIBRARY = preload("res://scripts/ghost_animation_library.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = (load("res://resources/ghost_girl_frames.tres") as SpriteFrames).duplicate(true)
	root.add_child(sprite)
	LIBRARY.install(sprite)
	THRUST.install(sprite)
	GUARD.install(sprite)
	var frames: SpriteFrames = sprite.sprite_frames
	var count: int = 0
	for face in ["front", "back", "left", "right"]:
		var source: String = "attack_unarmed_light_" + face
		for prefix in ["attack_heavy_", "attack_unarmed_heavy_", "attack_sword_heavy_"]:
			var name: String = prefix + face
			var clean: String = "attack_sword_light_" + face if prefix == "attack_sword_heavy_" else source
			if not frames.has_animation(name) or frames.get_frame_count(name) != 8:
				_fail("Missing repaired core heavy clip " + name)
				return
			for i in range(8):
				if frames.get_frame_texture(name, i).resource_path != frames.get_frame_texture(clean, i).resource_path:
					_fail("Damaged source still used by " + name)
					return
		for art in ["dagger", "nocturne_dagger", "dual_dagger"]:
			for action in ["pierce", "heavy_pierce"]:
				var name: String = "attack_" + art + "_" + action + "_" + face
				var heavy: bool = action == "heavy_pierce"
				if not frames.has_animation(name) or frames.get_frame_count(name) != 8 or frames.get_animation_loop(name):
					_fail("Invalid thrust clip " + name)
					return
				for i in range(8):
					var expected: int = THRUST.sequence(heavy)[i]
					if frames.get_frame_texture(name, i) != frames.get_frame_texture(source, expected):
						_fail("Thrust body source mismatch: " + name)
						return
				var stab: PackedVector2Array = THRUST.single_span(face, 3, heavy)
				if stab.size() != 2 or (stab[1] - stab[0]).normalized().dot(THRUST.direction(face)) < 0.99:
					_fail("Stab is not facing the attack direction")
					return
				for hand in range(2):
					var pair: PackedVector2Array = THRUST.span(face, 3, hand, heavy, true)
					var anchor: Vector2 = THRUST.hand_anchor(face, THRUST.sequence(heavy)[3], hand)
					if anchor == Vector2.INF:
						if not pair.is_empty():
							_fail("Occluded hand has floating blade")
							return
					elif pair.size() != 2 or pair[0] != anchor:
						_fail("Blade grip detached from body")
						return
				count += 1
	if count != 24:
		_fail("Incorrect thrust count")
		return
	# Synthetic raster fixtures: demonstrate both cut detection and detached
	# bottom-row contamination without modifying any original character pixels.
	var clean_image: Image = Image.create(256, 220, false, Image.FORMAT_RGBA8)
	clean_image.fill(Color.TRANSPARENT)
	clean_image.fill_rect(Rect2i(80, 25, 80, 160), Color.WHITE)
	var cut: Image = clean_image.duplicate()
	cut.fill_rect(Rect2i(100, 7, 45, 18), Color.WHITE)
	var fragment: Image = clean_image.duplicate()
	fragment.fill_rect(Rect2i(105, 210, 45, 6), Color.WHITE)
	if GUARD.has_cut_or_fragment(clean_image) or not GUARD.has_cut_or_fragment(cut) or not GUARD.has_cut_or_fragment(fragment):
		_fail("Frame guard failed raster regression")
		return
	for name in frames.get_animation_names():
		for i in range(frames.get_frame_count(name)):
			var texture: Texture2D = frames.get_frame_texture(name, i)
			if texture is AtlasTexture and not (texture as AtlasTexture).filter_clip:
				_fail("Unprotected atlas frame " + str(name))
				return
	sprite.free()
	print("v1.86 PASS: 24 directional dagger clips, 96 corrected core frames, hand anchors, raster cut/fragment checks and atlas isolation")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
