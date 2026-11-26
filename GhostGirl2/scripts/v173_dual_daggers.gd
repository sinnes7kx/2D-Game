extends Node2D
## v1.73: two-hand dagger rig. Approved original body textures are reused:
## 8 frames x 4 directions for idle, walk, A/B/C light combo and heavy.
## Each hand gets an independently authored tip path, driven by frame index.
const ITEM_ID: String = "moonlace_dual_daggers_v173"
const BLADE_LENGTH: float = 35.0
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const THRUST = preload("res://scripts/dagger_thrust_v186.gd")
const BLADE_SCRIPT = preload("res://scripts/v173_dual_dagger_blade.gd")
var body: AnimatedSprite2D = null
var player: Node2D = null

static func install_animations(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = sprite.sprite_frames
	for face in ["front", "back", "left", "right"]:
		for mode in ["idle", "walk", "light_a", "light_b", "light_c", "heavy"]:
			var source: String = ""
			var target: String = ""
			var fps: float = 12.0
			var looping: bool = false
			match mode:
				"idle":
					source = "idle_" + face
					target = "dual_dagger_idle_" + face
					fps = 8.0
					looping = true
				"walk":
					source = "walk_" + face
					target = "dual_dagger_walk_" + face
					fps = 12.0
					looping = true
				"heavy":
					source = "attack_heavy_" + face
					target = "attack_dual_dagger_heavy_" + face
					fps = 12.0
				_:
					source = "attack_light_" + face
					target = "attack_dual_dagger_" + mode + "_" + face
					fps = 18.0
			if not frames.has_animation(source) or frames.get_frame_count(source) <= 0:
				push_warning("Dual daggers missing original Ghost Girl body frames: " + source)
				continue
			if frames.has_animation(target):
				frames.remove_animation(target)
			frames.add_animation(target)
			frames.set_animation_loop(target, looping)
			frames.set_animation_speed(target, fps)
			var existing: int = frames.get_frame_count(source)
			for i in range(8):
				frames.add_frame(target, frames.get_frame_texture(source, i % existing))

func _ready() -> void:
	body = get_parent() as AnimatedSprite2D
	player = body.get_parent() as Node2D if body != null else null
	for i in range(2):
		var blade: Node2D = Node2D.new()
		blade.name = "LeftDagger" if i == 0 else "RightDagger"
		blade.set_script(BLADE_SCRIPT)
		blade.set("blade_index", i)
		add_child(blade)

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
	return equipped != null and equipped.definition != null and equipped.weapon_style() == "dual_dagger"

func is_active(animation_name: String) -> bool:
	return _equipped() and (animation_name.begins_with("dual_dagger_") or animation_name.begins_with("attack_dual_dagger_"))

func get_blade_spans(animation_name: String, frame_index: int) -> Array:
	var idle: bool = GENTLE.modular_idle(animation_name)
	var spans: Array = _authored_blade_spans(animation_name, 0 if idle else frame_index)
	if idle:
		for hand in range(spans.size()):
			spans[hand] = GENTLE.smooth(body, animation_name, spans[hand], hand)
	else:
		var fraction: float = GENTLE.attack_fraction(body, animation_name, frame_index)
		if fraction > 0.0:
			var upcoming: Array = _authored_blade_spans(animation_name, frame_index + 1)
			for hand in range(mini(spans.size(), upcoming.size())):
				spans[hand] = GENTLE.subframe_span(spans[hand], upcoming[hand], fraction)
	return spans

func _authored_blade_spans(animation_name: String, frame_index: int) -> Array:
	# Array of two PackedVector2Array [grip, tip], in Ghost sprite-local space.
	if not is_active(animation_name):
		return []
	var face: String = "front"
	for candidate in ["front", "back", "left", "right"]:
		if animation_name.ends_with(candidate):
			face = candidate
			break
	var forward: Vector2 = Vector2(0, 1)
	var sweep: Vector2 = Vector2(1, 0)
	var left_grip: Vector2 = Vector2(-27, 23)
	var right_grip: Vector2 = Vector2(27, 23)
	match face:
		"back":
			forward = Vector2(0, -1)
			left_grip = Vector2(-25, 13)
			right_grip = Vector2(25, 13)
		"left":
			forward = Vector2(-1, 0)
			sweep = Vector2(0, 1)
			left_grip = Vector2(-24, 19)
			right_grip = Vector2(-7, 25)
		"right":
			forward = Vector2(1, 0)
			sweep = Vector2(0, 1)
			left_grip = Vector2(7, 25)
			right_grip = Vector2(24, 19)
	if animation_name.contains("_pierce_"):
		var heavy_pierce: bool = animation_name.contains("_heavy_pierce_")
		return [THRUST.span(face, frame_index, 0, heavy_pierce, true), THRUST.span(face, frame_index, 1, heavy_pierce, true)]
	var n: int = clampi(frame_index, 0, 7)
	var action: String = "idle"
	if animation_name.begins_with("attack_dual_dagger_light_a_"):
		action = "a"
	elif animation_name.begins_with("attack_dual_dagger_light_b_"):
		action = "b"
	elif animation_name.begins_with("attack_dual_dagger_light_c_"):
		action = "c"
	elif animation_name.begins_with("attack_dual_dagger_heavy_"):
		action = "heavy"
	elif animation_name.begins_with("dual_dagger_walk_"):
		action = "walk"
	var result: Array = []
	for hand_index in range(2):
		var side: float = -1.0 if hand_index == 0 else 1.0
		var grip: Vector2 = left_grip if hand_index == 0 else right_grip
		if action == "walk":
			grip += forward * (2.0 * sin(float(n) * PI * 0.5 + float(hand_index) * PI))
			grip += sweep * side * (1.6 * sin(float(n) * PI * 0.25))
		elif action == "idle":
			grip += Vector2(0, sin(float(n) * PI * 0.25) * 0.8)
		var lateral: float = side * 17.0
		var advance: float = 24.0
		if action in ["a", "b", "c", "heavy"]:
			# Three genuinely different paired strikes: left lead, right lead,
			# and an alternating crossing finisher. Heavy crosses BOTH knives.
			var lead_left: bool = action == "a"
			var lead_right: bool = action == "b"
			var is_lead: bool = (lead_left and hand_index == 0) or (lead_right and hand_index == 1)
			var crossing: bool = action == "c" or action == "heavy"
			var sweep_steps: Array[float] = [-18.0, -29.0, -30.0, -5.0, 23.0, 28.0, 1.0, -18.0]
			var advance_steps: Array[float] = [19.0, 10.0, -12.0, -23.0, -11.0, 8.0, 19.0, 21.0]
			if crossing:
				var cross_steps: Array[float] = [-22.0, -34.0, -24.0, 0.0, 30.0, 16.0, -4.0, -22.0]
				var push_steps: Array[float] = [21.0, 4.0, -16.0, -29.0, -15.0, 5.0, 18.0, 22.0]
				lateral = cross_steps[n] * (-side)
				advance = push_steps[n] * (1.12 if action == "heavy" else 1.0)
				if hand_index == 1:
					advance += 4.0 * sin(float(n) * PI * 0.25)
			elif is_lead:
				lateral = sweep_steps[n] * (-side)
				advance = advance_steps[n]
			else:
				lateral = side * 9.0
				advance = 13.0 + 4.0 * sin(float(n) * PI * 0.25)
			if n in [2, 3, 4]:
				grip += forward * (-2.0 if is_lead or crossing else 1.0)
		# v1.80: actual visible hand centers measured on the approved v14
		# 256x220 body images. The v175 installer remaps idle/walk frames.
		var source_frame: int = n
		if action == "idle":
			source_frame = [0, 0, 1, 0, 0, 1, 0, 0][n]
		elif action == "walk":
			source_frame = [0, 1, 2, 1, 0, 1, 2, 1][n]
		var anchor: Vector2 = hand_anchor(face, source_frame, hand_index)
		if anchor == Vector2.INF:
			# Hair/body occludes this hand. Do not float a second knife
			# outside the visible character silhouette.
			result.append(PackedVector2Array())
			continue
		grip = anchor
		var aim: Vector2 = (sweep * lateral + forward * advance).normalized()
		if aim.is_zero_approx():
			aim = forward
		var tip: Vector2 = grip + aim * BLADE_LENGTH
		result.append(PackedVector2Array([grip, tip]))
	return result

# Pixel centers in the original 256x220 artwork, converted to centered
# Ghost-local coordinates. Occluded hands are not rendered.
static func hand_anchor(face: String, frame: int, hand: int) -> Vector2:
	return THRUST.hand_anchor(face, frame, hand)
