extends Node2D
## v1.74: two long swords, separate hands and directional attack arcs.
## Uses unmodified approved Ghost Girl body frames; two sword layers are
## rendered separately and are never part of physics collision/damage logic.
const ITEM_ID: String = "gloamrose_dual_swords_v174"
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const SWORD_SCRIPT: Script = preload("res://scripts/v174_dual_sword_blade.gd")
var body: AnimatedSprite2D = null
var player: Node2D = null

static func install_animations(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = sprite.sprite_frames
	for face in ["front", "back", "left", "right"]:
		for mode in ["idle", "walk", "light_a", "light_b", "light_c", "heavy", "riposte"]:
			var source: String = ""
			var target: String = ""
			var fps: float = 12.0
			var looping: bool = false
			match mode:
				"idle":
					source = "idle_" + face
					target = "dual_sword_idle_" + face
					fps = 8.0
					looping = true
				"walk":
					source = "walk_" + face
					target = "dual_sword_walk_" + face
					fps = 11.0
					looping = true
				"heavy":
					source = "attack_heavy_" + face
					target = "attack_dual_sword_heavy_" + face
					fps = 11.0
				"riposte":
					var counter: String = "attack_counter_" + face
					source = counter if frames.has_animation(counter) else "attack_heavy_" + face
					target = "attack_dual_sword_riposte_" + face
					fps = 14.0
				_:
					source = "attack_light_" + face
					target = "attack_dual_sword_" + mode + "_" + face
					fps = 14.0
			if not frames.has_animation(source) or frames.get_frame_count(source) <= 0:
				push_warning("Dual swords missing clean Ghost Girl pose: " + source)
				continue
			if frames.has_animation(target):
				frames.remove_animation(target)
			frames.add_animation(target)
			frames.set_animation_speed(target, fps)
			frames.set_animation_loop(target, looping)
			var existing: int = frames.get_frame_count(source)
			for i in range(8):
				frames.add_frame(target, frames.get_frame_texture(source, i % existing))

func _ready() -> void:
	body = get_parent() as AnimatedSprite2D
	player = body.get_parent() as Node2D if body != null else null
	for i in range(2):
		var sword: Node2D = Node2D.new()
		sword.name = "LeftSword" if i == 0 else "RightSword"
		sword.set_script(SWORD_SCRIPT)
		sword.set("blade_index", i)
		add_child(sword)

func _equipped() -> bool:
	if player == null:
		return false
	var world: Node = player.get("world") as Node
	if world == null:
		return false
	var inventory: Node = world.get("inventory") as Node
	if inventory == null:
		return false
	var equipped: GhostItemInstance = inventory.get_equipped("sword")
	return equipped != null and equipped.definition != null and str(equipped.definition.item_id) == ITEM_ID

func is_active(animation_name: String) -> bool:
	return _equipped() and (animation_name.begins_with("dual_sword_") or animation_name.begins_with("attack_dual_sword_"))

func get_blade_spans(animation_name: String, frame_index: int) -> Array:
	# Both [grip, tip] spans in Ghost-local 256×220 pixel coordinates.
	# Frame-authored independent movements, no mirrored full-body art.
	if not is_active(animation_name):
		return []
	var face: String = "front"
	for direction in ["front", "back", "left", "right"]:
		if animation_name.ends_with(direction):
			face = direction
			break
	var action: String = "idle"
	if animation_name.begins_with("attack_dual_sword_light_a_"):
		action = "a"
	elif animation_name.begins_with("attack_dual_sword_light_b_"):
		action = "b"
	elif animation_name.begins_with("attack_dual_sword_light_c_"):
		action = "c"
	elif animation_name.begins_with("attack_dual_sword_heavy_"):
		action = "heavy"
	elif animation_name.begins_with("attack_dual_sword_riposte_"):
		action = "riposte"
	elif animation_name.begins_with("dual_sword_walk_"):
		action = "walk"
	var spans: Array = authored_blade_spans(face, action, 0 if action == "idle" else frame_index)
	if action == "idle":
		for hand in range(spans.size()):
			spans[hand] = GENTLE.smooth(body, animation_name, spans[hand], hand)
	return spans

# The actual approved body's screen-space wrist guides are the source of
# truth. Only covered/missing wrists use the pose's conservative fallback.
# This changes art geometry, never weapon reach, collision or item data.
static func hand_grip(face: String, hand: int, action: String = "idle", frame_index: int = 0) -> Vector2:
	var source_frame: int = clampi(frame_index, 0, 7) if action in ["a", "b", "c"] else 0
	var authored: Vector2 = HAND.hand_anchor(face, source_frame, hand)
	if authored != Vector2.INF:
		return authored
	match face:
		"back": return Vector2(-25, 13) if hand == 0 else Vector2(25, 13)
		"left": return Vector2(-34, 24) if hand == 0 else Vector2(-7, 25)
		"right": return Vector2(7, 25) if hand == 0 else Vector2(36, 24)
		_: return Vector2(-17, 31) if hand == 0 else Vector2(51, 27)

static func authored_blade_spans(face: String, action: String, frame_index: int) -> Array:
	# Pure per-frame geometry, also exercised in CI without granting inventory
	# items or touching persistent player saves.
	var forward: Vector2 = Vector2(0, 1)
	var across: Vector2 = Vector2(1, 0)
	var left_grip: Vector2 = hand_grip(face, 0, action, frame_index)
	var right_grip: Vector2 = hand_grip(face, 1, action, frame_index)
	match face:
		"back":
			forward = Vector2(0, -1)
		"left":
			forward = Vector2(-1, 0)
			across = Vector2(0, 1)
		"right":
			forward = Vector2(1, 0)
			across = Vector2(0, 1)
	var n: int = clampi(frame_index, 0, 7)
	var result: Array = []
	for hand_index in range(2):
		var side: float = -1.0 if hand_index == 0 else 1.0
		var grip: Vector2 = left_grip if hand_index == 0 else right_grip
		if action == "walk":
			grip += forward * (2.5 * sin(float(n) * PI * 0.5 + float(hand_index) * PI))
			grip += across * side * (1.7 * sin(float(n) * PI * 0.25))
		elif action == "idle":
			grip += Vector2(0, sin(float(n) * PI * 0.25) * 1.0)
		var lateral: float = side * 18.0
		var advance: float = 54.0
		if action in ["a", "b", "c", "heavy", "riposte"]:
			# A left-hand crescent, B right-hand rising cut, C two-blade
			# scissor, heavy wide X, riposte a synchronized forward lunge.
			var leading: bool = (action == "a" and hand_index == 0) or (action == "b" and hand_index == 1)
			var chop: Array[float] = [-36.0, -42.0, -27.0, 9.0, 40.0, 30.0, 2.0, -24.0]
			var thrust: Array[float] = [48.0, 37.0, 53.0, 71.0, 74.0, 60.0, 54.0, 48.0]
			if action in ["a", "b"]:
				if leading:
					lateral = chop[n] * (-side)
					advance = thrust[n]
				else:
					lateral = side * (19.0 + 4.0 * sin(float(n) * PI * 0.25))
					advance = 42.0
			elif action == "c":
				var scissor: Array[float] = [31.0, 40.0, 26.0, 2.0, -35.0, -18.0, 3.0, 29.0]
				lateral = side * scissor[n]
				var scissor_advances: Array[float] = [48.0, 39.0, 33.0, 56.0, 72.0, 64.0, 55.0, 48.0]
				advance = scissor_advances[n]
			elif action == "heavy":
				var crossing: Array[float] = [38.0, 47.0, 36.0, 6.0, -43.0, -34.0, -10.0, 34.0]
				lateral = side * crossing[n]
				var heavy_advances: Array[float] = [43.0, 32.0, 38.0, 61.0, 85.0, 81.0, 57.0, 46.0]
				advance = heavy_advances[n]
			else:
				# Riposte: two parallel moonsteel points, no spinning hilts.
				var riposte_lateral: Array[float] = [20.0, 18.0, 12.0, 8.0, 9.0, 13.0, 17.0, 20.0]
				var riposte_advances: Array[float] = [45.0, 40.0, 51.0, 81.0, 89.0, 70.0, 54.0, 45.0]
				lateral = side * riposte_lateral[n]
				advance = riposte_advances[n]
			# v1.74.1: the wrists now move with the cut instead of letting
			# both sword tips rotate around completely stationary hands.
			# Small offsets preserve the approved painted sleeves/body.
			var lead_reach: Array[float] = [0.0, 1.0, 3.0, 5.0, 5.0, 3.0, 1.0, 0.0]
			if action in ["a", "b"] and leading:
				grip += forward * (-0.85 * lead_reach[n])
				grip += across * (-side * lead_reach[n] * 0.48)
			elif action in ["c", "heavy"]:
				# Pull both hands toward the torso for the crossed finish.
				# Back-view grips move less to keep them behind the dress.
				var cross_amount: float = lead_reach[n] * (0.65 if face == "back" else 1.0)
				grip += across * (-side * cross_amount)
				grip += forward * (-lead_reach[n] * 0.48)
			elif action == "riposte":
				grip += forward * (-lead_reach[n] * 0.86)
				grip += across * (-side * lead_reach[n] * 0.18)
		var tip: Vector2 = grip + across * lateral + forward * advance
		result.append(PackedVector2Array([grip, tip]))
	return result
