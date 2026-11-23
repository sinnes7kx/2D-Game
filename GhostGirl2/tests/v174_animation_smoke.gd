extends SceneTree
## v1.74 actual Godot engine smoke check (not only regex source assertions).
## Instantiate approved Ghost Girl player and verify ALL directional clips.
func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var scene: PackedScene = load("res://scenes/player.tscn") as PackedScene
	if scene == null:
		push_error("v1.74: player.tscn not loadable")
		quit(1)
		return
	var actor: Node = scene.instantiate()
	root.add_child(actor)
	var art: AnimatedSprite2D = actor.get_node_or_null("Ghost") as AnimatedSprite2D
	if art == null or art.sprite_frames == null:
		push_error("v1.74: Ghost Girl sprite frames missing")
		quit(1)
		return
	var frames: SpriteFrames = art.sprite_frames
	var errors: int = 0
	var total: int = 0
	for face in ["front", "back", "left", "right"]:
		for mode in ["idle", "walk", "light_a", "light_b", "light_c", "heavy", "riposte"]:
			var name: String = ""
			if mode in ["idle", "walk"]:
				name = "dual_sword_" + mode + "_" + face
			elif mode == "heavy" or mode == "riposte":
				name = "attack_dual_sword_" + mode + "_" + face
			else:
				name = "attack_dual_sword_" + mode + "_" + face
			if not frames.has_animation(name):
				push_error("v1.74: missing animation: " + name)
				errors += 1
				continue
			if frames.get_frame_count(name) != 8:
				push_error("v1.74: expected 8 frames for " + name)
				errors += 1
			total += 1
	var rig: Node = art.get_node_or_null("DualSwordsV174")
	if rig == null or rig.get_child_count() != 2:
		push_error("v1.74: expected exactly two in-game sword layers")
		errors += 1
	# Sanity-check existing dual daggers were not replaced.
	if art.get_node_or_null("DualDaggersV173") == null:
		push_error("v1.74: previous dual-dagger rig missing")
		errors += 1
	if errors == 0:
		print("v1.74 Godot runtime PASS: ", total, " directional sword clips / 224 frames and both weapon hands")
	else:
		push_error("v1.74 Godot runtime FAILED: " + str(errors) + " issues")
	actor.queue_free()
	quit(1 if errors > 0 else 0)
