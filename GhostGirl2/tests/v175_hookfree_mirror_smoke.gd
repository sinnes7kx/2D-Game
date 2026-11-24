extends SceneTree
const IDLE_SEQUENCE: Array[int] = [0, 0, 1, 0, 0, 1, 0, 0]
const WALK_SEQUENCE: Array[int] = [0, 1, 2, 1, 0, 1, 2, 1]
## v1.75: compare runtime frame TEXTURES to approved clean original sprites,
## not just the animation names. Check left-bow mirror structure exists.
func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var packed: PackedScene = load("res://scenes/player.tscn") as PackedScene
	if packed == null:
		push_error("v1.75 player scene missing")
		quit(1)
		return
	var player: Node = packed.instantiate()
	root.add_child(player)
	var ghost: AnimatedSprite2D = player.get_node_or_null("Ghost") as AnimatedSprite2D
	if ghost == null or ghost.sprite_frames == null:
		push_error("v1.75 approved body missing")
		quit(1)
		return
	var frames: SpriteFrames = ghost.sprite_frames
	var failures: int = 0
	var examined: int = 0
	for face in ["front", "back", "left", "right"]:
		var clean: String = "attack_unarmed_light_" + face
		if not frames.has_animation(clean):
			push_error("v1.75 missing clean base: " + clean)
			failures += 1
			continue
		var targets: Array[String] = []
		for family in ["dual_dagger", "dual_sword"]:
			targets.append(family + "_idle_" + face)
			targets.append(family + "_walk_" + face)
			for action in ["light_a", "light_b", "light_c", "heavy"]:
				targets.append("attack_" + family + "_" + action + "_" + face)
		for weapon in ["nocturne_dagger", "briarwake_spear"]:
			for action in ["light", "heavy"]:
				targets.append("attack_" + weapon + "_" + action + "_" + face)
		if face == "left":
			for bow in ["thornrose", "moonveil"]:
				for locomotion in ["idle", "walk"]:
					targets.append(bow + "_" + locomotion + "_left")
				for action in ["light", "heavy"]:
					targets.append("attack_" + bow + "_" + action + "_left")
		for target in targets:
			if not frames.has_animation(target):
				push_error("v1.75 missing animation: " + target)
				failures += 1
				continue
			if frames.get_frame_count(target) != 8:
				push_error("v1.75 expected 8 frames: " + target)
				failures += 1
				continue
			var idle: bool = target.contains("_idle_")
			var walk: bool = target.contains("_walk_")
			for frame in range(8):
				var source_frame: int = frame
				if idle:
					source_frame = IDLE_SEQUENCE[frame]
				elif walk:
					source_frame = WALK_SEQUENCE[frame]
				var image: Texture2D = frames.get_frame_texture(target, frame)
				var approved: Texture2D = frames.get_frame_texture(clean, source_frame)
				if image != approved:
					push_error("v1.75 old hook-backed frame detected: " + target + " #" + str(frame))
					failures += 1
				examined += 1
	var palette: Node = ghost.get_node_or_null("BowPaletteV139")
	var carry: Node = ghost.get_node_or_null("BowCarryV166")
	if palette == null or carry == null:
		push_error("v1.75 missing bow-only mirror layer")
		failures += 1
	elif not bool(palette.call("_should_flip_for_animation", "thornrose_idle_left")):
		push_error("v1.75 left bow mirroring inactive")
		failures += 1
	elif bool(palette.call("_should_flip_for_animation", "thornrose_idle_right")):
		push_error("v1.75 right bow erroneously mirrored")
		failures += 1
	if failures == 0:
		print("v1.75 Godot PASS: ", examined, " hook-free weapon frames and left-bow orientation")
	else:
		push_error("v1.75 Godot FAILED: " + str(failures))
	player.queue_free()
	quit(1 if failures > 0 else 0)
