extends SceneTree
const DUAL_SWORD_POSES: Script = preload("res://scripts/v174_dual_swords.gd")
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
	# Verify geometry, not only animation names. This catches flipped side
	# facings, invisible tips, crossed blade failures and off-atlas drawings.
	var pose_count: int = 0
	for face in ["front", "back", "left", "right"]:
		for action in ["idle", "walk", "a", "b", "c", "heavy", "riposte"]:
			for n in range(8):
				var pair: Array = DUAL_SWORD_POSES.authored_blade_spans(face, action, n)
				if pair.size() != 2:
					push_error("v1.74.1: expected two hands: " + face + "/" + action + "/" + str(n))
					errors += 1
					continue
				for hand in range(2):
					var span: PackedVector2Array = pair[hand]
					if span.size() != 2:
						push_error("v1.74.1: missing hand span")
						errors += 1
						continue
					var grip: Vector2 = span[0]
					var tip: Vector2 = span[1]
					var length: float = grip.distance_to(tip)
					if length < 28.0 or length > 122.0:
						push_error("v1.74.1: sword blade length outside pose budget")
						errors += 1
					if absf(tip.x) > 123.0 or absf(tip.y) > 118.0:
						push_error("v1.74.1: sword tip outside 256x220 body frame")
						errors += 1
					pose_count += 1
	var heavy_open: Array = DUAL_SWORD_POSES.authored_blade_spans("front", "heavy", 0)
	var heavy_cross: Array = DUAL_SWORD_POSES.authored_blade_spans("front", "heavy", 4)
	if heavy_open[0][1].x >= heavy_open[1][1].x:
		push_error("v1.74.1: initial heavy windup swords are crossed too early")
		errors += 1
	if heavy_cross[0][1].x <= heavy_cross[1][1].x:
		push_error("v1.74.1: crossed heavy strike never crosses the blades")
		errors += 1
	var scissor_cross: Array = DUAL_SWORD_POSES.authored_blade_spans("front", "c", 4)
	if scissor_cross[0][1].x <= scissor_cross[1][1].x:
		push_error("v1.74.1: combo finisher does not cross blades")
		errors += 1
	var lunge_open: Array = DUAL_SWORD_POSES.authored_blade_spans("front", "riposte", 0)
	var lunge_hit: Array = DUAL_SWORD_POSES.authored_blade_spans("front", "riposte", 4)
	for hand in range(2):
		if lunge_hit[hand][1].y <= lunge_open[hand][1].y + 15.0:
			push_error("v1.74.1: both riposte swords should extend forward")
			errors += 1
	if errors == 0:
		print("v1.74.1 Godot runtime PASS: ", total, " clips, ", pose_count, " verified hand/pose spans, crossed heavy and riposte")
	else:
		push_error("v1.74 Godot runtime FAILED: " + str(errors) + " issues")
	actor.queue_free()
	quit(1 if errors > 0 else 0)
