extends SceneTree
const POSE = preload("res://scripts/v172_weapon_pose.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var packed: PackedScene = load("res://scenes/player.tscn") as PackedScene
	var player: Node = packed.instantiate()
	root.add_child(player)
	var ghost: AnimatedSprite2D = player.get_node("Ghost") as AnimatedSprite2D
	var frames: SpriteFrames = ghost.sprite_frames
	var failures: int = 0
	var clips: int = 0
	for face in ["front", "back", "left", "right"]:
		var heading: Vector2 = Vector2.DOWN
		match face:
			"back": heading = Vector2.UP
			"left": heading = Vector2.LEFT
			"right": heading = Vector2.RIGHT
		for family in ["spear", "briarwake_spear"]:
			for action in ["pierce", "heavy_pierce"]:
				var name: String = "attack_" + family + "_" + action + "_" + face
				if not frames.has_animation(name) or frames.get_frame_count(name) != 8:
					push_error("Missing eight-frame thrust: " + name)
					failures += 1
					continue
				clips += 1
				if frames.get_frame_texture(name, 3) != frames.get_frame_texture("attack_unarmed_light_" + face, 4):
					push_error("Thrust body timing overwritten: " + name)
					failures += 1
				var start: PackedVector2Array = POSE.pierce_span(face, 1, action == "heavy_pierce")
				var strike: PackedVector2Array = POSE.pierce_span(face, 3, action == "heavy_pierce")
				var recovered: PackedVector2Array = POSE.pierce_span(face, 7, action == "heavy_pierce")
				if (strike[1] - start[1]).dot(heading) < 35.0 or (strike[1] - recovered[1]).dot(heading) < 25.0:
					push_error("Thrust travel or recovery invalid: " + name)
					failures += 1
				if not is_equal_approx(strike[0].distance_to(strike[1]), start[0].distance_to(start[1])):
					push_error("Polearm changes physical length: " + name)
					failures += 1
		for family in ["twinblade", "rosemirror_twinblade"]:
			for motion in ["idle", "walk"]:
				var name: String = family + "_" + motion + "_" + face
				if not frames.has_animation(name) or frames.get_frame_count(name) != 8:
					failures += 1
					continue
				if frames.get_frame_texture(name, 0) != frames.get_frame_texture("attack_unarmed_light_" + face, 0):
					push_error("Baked twinblade body still present: " + name)
					failures += 1
	var sanctum: PackedScene = load("res://scenes/rooms/sanctum.tscn") as PackedScene
	var room: Node = sanctum.instantiate()
	var racks: Node = room.get_node_or_null("Gameplay/WeaponShowcases")
	if racks == null or racks.get_child_count() != 10:
		push_error("Sanctum test armory incomplete")
		failures += 1
	else:
		var ids: Dictionary = {}
		for rack in racks.get_children():
			var pickup: String = str(rack.get("pickup_id"))
			if pickup.is_empty() or ids.has(pickup) or rack.get("item_data") == null or not bool(rack.get("ground_display")):
				failures += 1
			ids[pickup] = true
	room.free()
	player.queue_free()
	print("v1.76 checked ", clips, " thrust clips, twinblade locomotion and Sanctum pickups; failures: ", failures)
	quit(1 if failures > 0 else 0)
