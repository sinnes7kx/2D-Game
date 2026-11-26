extends Node2D
const DAGGER_THRUST = preload("res://scripts/dagger_thrust_v186.gd")
const ANOMALOUS = preload("res://scripts/anomalous_steel_fx_v180.gd")
var v180_elapsed: float = 0.0
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const STEADY = preload("res://scripts/steady_weapon_idles_v195.gd")
const MODULAR = preload("res://scripts/modular_weapon_art_v178.gd")
## v1.72.2 — authored four-facing weapon strike poses.
## Uses the approved unarmed attack BODY frames; renders physical weapon
## geometry at eight authored poses per action, not stretched inventory icons.
## Glow reads get_weapon_span(), so light and the painted weapon cannot drift.
const STILETTO: String = "nocturne_stiletto_v171"
const TRIDENT: String = "briarwake_trident_v171"
const TRIDENT_SHAFT_BACK: float = 26.0
var body: AnimatedSprite2D = null
var player: Node2D = null
var last_animation: String = ""
var last_frame: int = -1
var twin_axes: Dictionary = {}
const TWIN_AXES_PATH: String = "res://resources/new_weapon_axes_v170.json"

static func install_attack_frames(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = sprite.sprite_frames
	for weapon_art in ["nocturne_dagger", "briarwake_spear"]:
		for attack in ["light", "heavy"]:
			for face in ["front", "back", "left", "right"]:
				var base_name: String = "attack_" + attack + "_" + face
				var target: String = "attack_" + weapon_art + "_" + attack + "_" + face
				if not frames.has_animation(base_name):
					push_warning("Missing clean approved attack body: " + base_name)
					continue
				if frames.has_animation(target):
					frames.remove_animation(target)
				frames.add_animation(target)
				frames.set_animation_speed(target, 17.0 if weapon_art == "nocturne_dagger" else 12.0)
				frames.set_animation_loop(target, false)
				for i in range(frames.get_frame_count(base_name)):
					frames.add_frame(target, frames.get_frame_texture(base_name, i))

	install_single_swords(frames)

	# v1.76: dedicated eight-frame thrust clips for both polearms.
	# Source textures are the approved clean body, never the rose-hook art.
	for weapon_art in ["spear", "briarwake_spear"]:
		for action in ["pierce", "heavy_pierce"]:
			for face in ["front", "back", "left", "right"]:
				var source: String = "attack_unarmed_light_" + face
				var target: String = "attack_" + weapon_art + "_" + action + "_" + face
				if not frames.has_animation(source) or frames.get_frame_count(source) < 8:
					continue
				if frames.has_animation(target):
					frames.remove_animation(target)
				frames.add_animation(target)
				frames.set_animation_speed(target, 12.0)
				frames.set_animation_loop(target, false)
				var sequence: Array[int] = polearm_sequence()
				for index in sequence:
					frames.add_frame(target, frames.get_frame_texture(source, index))

	# Replace baked twinblades with the approved body and a separate physical
	# blade drawing. All old atlas files remain available, unchanged.
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(TWIN_AXES_PATH))
	if raw is Dictionary:
		for anim in frames.get_animation_names():
			var name: String = str(anim)
			if not name.contains("twinblade") or not raw.has(name):
				continue
			var face: String = name.get_slice("_", name.get_slice_count("_") - 1)
			var source: String = "attack_unarmed_light_" + face
			if not frames.has_animation(source) or frames.get_frame_count(source) < 8:
				continue
			var sequence: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
			if name.contains("_idle_"):
				sequence = [0, 0, 1, 0, 0, 1, 0, 0]
			elif name.contains("_walk_"):
				sequence = [0, 1, 2, 1, 0, 1, 2, 1]
			var speed: float = frames.get_animation_speed(name)
			var looping: bool = frames.get_animation_loop(name)
			frames.remove_animation(name)
			frames.add_animation(name)
			frames.set_animation_speed(name, speed)
			frames.set_animation_loop(name, looping)
			for index in sequence:
				frames.add_frame(name, frames.get_frame_texture(source, index))

# Use original clean unarmed body references, not additional sprite textures.
# The same source index drives the wrist in every new clip.
static func single_sword_sequence(name: String, face: String) -> Array[int]:
	if name.contains("_idle_"):
		var neutral: int = 1 if face == "back" else 0
		return [neutral, neutral, neutral, neutral, neutral, neutral, neutral, neutral]
	if name.contains("_walk_"):
		return [1, 1, 2, 1, 1, 1, 2, 1] if face == "back" else [0, 1, 2, 1, 0, 1, 2, 1]
	return [0, 1, 2, 3, 4, 5, 6, 7]

static func install_single_swords(frames: SpriteFrames) -> void:
	for face in ["front", "back", "left", "right"]:
		var source: String = "attack_unarmed_light_" + face
		if not frames.has_animation(source) or frames.get_frame_count(source) < 8:
			continue
		for name in ["sword_modular_idle_" + face, "sword_modular_walk_" + face, "attack_sword_modular_light_" + face, "attack_sword_modular_heavy_" + face, "attack_sword_modular_counter_" + face]:
			if frames.has_animation(name):
				continue
			var loop: bool = not name.begins_with("attack_")
			frames.add_animation(name)
			frames.set_animation_loop(name, loop)
			frames.set_animation_speed(name, 8.0 if loop else 16.0)
			for index in single_sword_sequence(name, face):
				frames.add_frame(name, frames.get_frame_texture(source, index))

static func single_sword_span(name: String, face: String, frame_index: int) -> PackedVector2Array:
	var index: int = clampi(frame_index, 0, 7)
	var grip: Vector2 = DAGGER_THRUST.hand_anchor(face, single_sword_sequence(name, face)[index], 0 if face == "left" else 1)
	if grip == Vector2.INF:
		return PackedVector2Array()
	var axis: Vector2 = DAGGER_THRUST.direction(face)
	var tilt: float = -0.92
	if name.begins_with("attack_"):
		var angles: Array[float] = [-1.15, -1.42, -0.84, -0.30, 0.32, 0.72, 0.12, -0.92]
		tilt = angles[index] * (1.14 if name.contains("_heavy_") else 1.0)
	var sign: float = -1.0 if face == "left" else 1.0
	return PackedVector2Array([grip, grip + axis.rotated(tilt * sign) * 60.0])

# This exact body sequence and the wrist lookup share one source.
static func polearm_sequence() -> Array[int]:
	return [0, 1, 2, 4, 4, 5, 2, 0]

static func polearm_span(face: String, source_index: int, phase_index: int, heavy: bool) -> PackedVector2Array:
	var hand: int = 0 if face == "left" else 1
	var grip: Vector2 = DAGGER_THRUST.hand_anchor(face, source_index, hand)
	# The back-facing wrist is hidden in some neutral frames. Do not invent
	# a detached hand or a glow where the physical weapon is not visible.
	if grip == Vector2.INF:
		return PackedVector2Array()
	var forward: Vector2 = DAGGER_THRUST.direction(face)
	var tilt: Array[float] = [-0.34, -0.52, -0.22, 0.0, 0.0, 0.10, -0.20, -0.34]
	var angle: float = tilt[clampi(phase_index, 0, 7)] * (1.18 if heavy else 1.0)
	var sign: float = -1.0 if face == "left" else 1.0
	return PackedVector2Array([grip, grip + forward.rotated(angle * sign) * 74.0])

static func pierce_span(face: String, frame_index: int, heavy: bool) -> PackedVector2Array:
	var index: int = clampi(frame_index, 0, 7)
	return polearm_span(face, polearm_sequence()[index], index, heavy)

func _ready() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(TWIN_AXES_PATH))
	if raw is Dictionary:
		twin_axes = raw
	body = get_parent() as AnimatedSprite2D
	player = body.get_parent() as Node2D if body != null else null
	z_as_relative = true
	z_index = 5
	set_process(true)

func _process(_delta: float) -> void:
	v180_elapsed += _delta
	if body == null:
		return
	MODULAR.apply_equipped_opacity(self, body)
	var animation_now: String = str(body.animation)
	if animation_now.contains("twinblade") or (_is_equipped(animation_now) and (animation_now.begins_with("attack_") or GENTLE.modular_idle(animation_now) or MODULAR.surface_is_animated(self, body))):
		queue_redraw()
	# Explicitly redraw when leaving an attack, or its last weapon image
	# would remain visible during walking/idle until the next attack.
	if animation_now != last_animation or body.frame != last_frame:
		last_animation = animation_now
		last_frame = body.frame
		z_index = -1 if animation_now.ends_with("back") else 5
		queue_redraw()

func _is_equipped(animation_name: String) -> bool:
	if player == null or player.get("world") == null:
		return false
	var world: Node = player.get("world") as Node
	if world == null:
		return false
	var inventory: Node = world.get("inventory") as Node
	if inventory == null:
		return false
	var equipped: GhostItemInstance = inventory.get_equipped("sword")
	if equipped == null or equipped.definition == null:
		return false
	var ident: String = str(equipped.definition.item_id)
	if equipped.uses_modular_single_sword():
		return animation_name.begins_with("sword_modular_") or animation_name.begins_with("attack_sword_modular_")
	if equipped.weapon_style() == "twinblade" and animation_name.contains("twinblade")  :
		return true
	if equipped.weapon_style() == "dagger" and animation_name.contains("_pierce_"):
		return true
	return (ident == STILETTO and animation_name.begins_with("attack_nocturne_dagger_")) or (ident == TRIDENT and animation_name.begins_with("attack_briarwake_spear_")) or (ident == "moonwarden_spear_v169" and animation_name.begins_with("attack_spear_") and animation_name.contains("_pierce_"))

func get_weapon_span(animation_name: String, frame_index: int) -> PackedVector2Array:
	var idle: bool = GENTLE.modular_idle(animation_name) or STEADY.is_smooth_blade_idle(animation_name)
	var span: PackedVector2Array = _authored_weapon_span(animation_name, 0 if idle else frame_index)
	if idle:
		return GENTLE.smooth(body, animation_name, span)
	var fraction: float = GENTLE.attack_fraction(body, animation_name, frame_index)
	if fraction > 0.0:
		return GENTLE.subframe_span(span, _authored_weapon_span(animation_name, frame_index + 1), fraction)
	return span

func _authored_weapon_span(animation_name: String, frame_index: int) -> PackedVector2Array:
	var empty: PackedVector2Array = PackedVector2Array()
	if not _is_equipped(animation_name):
		return empty
	if animation_name.contains("sword_modular_"):
		var face: String = animation_name.get_slice("_", animation_name.get_slice_count("_") - 1)
		return single_sword_span(animation_name, face, frame_index)
	if animation_name.contains("twinblade"):
		var guide_key: String = animation_name.replace("_air_", "_") if animation_name.contains("_air_") else animation_name
		var guides: Array = twin_axes.get(guide_key, [])
		if guides.is_empty():
			var facing: String = animation_name.get_slice("_", animation_name.get_slice_count("_") - 1)
			var anchor: Vector2 = Vector2(35, 25)
			match facing:
				"left": anchor = Vector2(-35, 25)
				"right": anchor = Vector2(35, 25)
				"back": anchor = Vector2(27, 15)
			var original_tip: Vector2 = anchor + Vector2(-40 if facing == "left" else 40, -55)
			# Match the longer double-ended blade scale, even without authored axes.
			return PackedVector2Array([anchor, anchor + (original_tip - anchor).normalized() * 76.0])
		var guide: Array = guides[clampi(frame_index, 0, guides.size() - 1)]
		var grip: Vector2 = Vector2(float(guide[0]), float(guide[1]))
		var tip: Vector2 = Vector2(float(guide[2]), float(guide[3]))
		# Drawing-only extension; all twinblade damage and collision remain fixed.
		return PackedVector2Array([grip, grip + (tip - grip).normalized() * 76.0])
	var spear: bool = animation_name.begins_with("attack_briarwake_spear_")
	var heavy: bool = animation_name.contains("_heavy_")
	var face: String = "front"
	for direction in ["front", "back", "left", "right"]:
		if animation_name.ends_with(direction):
			face = direction
			break
	if animation_name.contains("_pierce_"):
		if animation_name.begins_with("attack_dagger_") or animation_name.begins_with("attack_nocturne_dagger_"):
			return DAGGER_THRUST.single_span(face, frame_index, heavy)
		return pierce_span(face, frame_index, heavy)
	var n: int = clampi(frame_index, 0, 7)
	if spear:
		return polearm_span(face, n, n, heavy)
	var anchor: Vector2 = Vector2(29, 24)
	match face:
		"back": anchor = Vector2(25, 16)
		"left": anchor = Vector2(-23, 24)
		"right": anchor = Vector2(23, 24)
	var tips: Array[Vector2] = []
	if spear:
		match face:
			"front":
				tips = [Vector2(48, 86), Vector2(35, 83), Vector2(55, 58), Vector2(91, 23), Vector2(115, -17), Vector2(109, -32), Vector2(80, 37), Vector2(48, 86)]
			"back":
				tips = [Vector2(43, -49), Vector2(15, -73), Vector2(29, -94), Vector2(73, -104), Vector2(104, -83), Vector2(95, -55), Vector2(56, -60), Vector2(43, -49)]
			"left":
				tips = [Vector2(-29, 93), Vector2(-5, 77), Vector2(-38, 44), Vector2(-92, 21), Vector2(-115, 8), Vector2(-116, -7), Vector2(-77, 44), Vector2(-29, 93)]
			"right":
				tips = [Vector2(29, 93), Vector2(5, 77), Vector2(38, 44), Vector2(92, 21), Vector2(115, 8), Vector2(116, -7), Vector2(77, 44), Vector2(29, 93)]
	else:
		match face:
			"front":
				tips = [Vector2(42, 47), Vector2(18, 43), Vector2(43, 8), Vector2(72, 5), Vector2(83, 13), Vector2(70, 36), Vector2(51, 42), Vector2(42, 47)]
			"back":
				tips = [Vector2(32, -16), Vector2(15, -26), Vector2(37, -40), Vector2(65, -32), Vector2(78, -17), Vector2(57, -8), Vector2(36, -14), Vector2(32, -16)]
			"left":
				tips = [Vector2(-33, 44), Vector2(-8, 35), Vector2(-40, 6), Vector2(-67, 13), Vector2(-82, 16), Vector2(-70, 34), Vector2(-48, 39), Vector2(-33, 44)]
			"right":
				tips = [Vector2(33, 44), Vector2(8, 35), Vector2(40, 6), Vector2(67, 13), Vector2(82, 16), Vector2(70, 34), Vector2(48, 39), Vector2(33, 44)]
	# A slender dagger/stiletto gets a slightly longer visible blade. The
	# weapon remains anchored to the same hand; the attack collider is unchanged.
	if animation_name.begins_with("attack_nocturne_dagger_") or animation_name.begins_with("attack_dagger_"):
		tips[n] = anchor + (tips[n] - anchor) * 1.13
	# A heavy blow has a longer forearm extension, not a spinning flat weapon.
	var reach: Vector2 = tips[n] - anchor
	if heavy and n in [3, 4, 5]:
		tips[n] = anchor + reach * (1.13 if spear else 1.09)
	return PackedVector2Array([anchor, tips[n]])

func _draw() -> void:
	if body == null:
		return
	var animation_name: String = str(body.animation)
	var span: PackedVector2Array = get_weapon_span(animation_name, body.frame)
	if span.size() != 2:
		return
	var grip: Vector2 = span[0]
	var tip: Vector2 = span[1]
	var axis: Vector2 = tip - grip
	if axis.length_squared() < 36.0:
		return
	var tangent: Vector2 = axis.normalized()
	var normal: Vector2 = Vector2(-tangent.y, tangent.x)
	if animation_name.contains("sword_modular_"):
		var look: Dictionary = MODULAR.equipped_profile(self, body)
		if not look.is_empty():
			var root: Vector2 = grip + tangent * 10.0
			MODULAR.draw_grip(self, grip - tangent * 12.0, root, 3.0, look)
			MODULAR.draw_blade(self, root, tip, 4.2, look)
	elif animation_name.contains("twinblade"):
		_draw_v176_twinblade(grip, tip, animation_name.contains("rosemirror"))
	elif animation_name.begins_with("attack_nocturne_dagger_") or animation_name.begins_with("attack_dagger_"):
		_draw_nightglass_stiletto(grip, tip, tangent, normal)
	elif animation_name.begins_with("attack_spear_"):
		_draw_moonwarden_spear(grip, tip, tangent, normal)
	else:
		_draw_briarwake_trident(grip, tip, tangent, normal)

func _draw_nightglass_stiletto(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2) -> void:
	var guard: Vector2 = grip.lerp(tip, 0.22)
	var steel: Vector2 = grip.lerp(tip, 0.30)
	var look: Dictionary = MODULAR.equipped_profile(self, body)
	if not look.is_empty():
		MODULAR.draw_grip(self, grip - tangent * 5.0, steel, 3.2, look)
		MODULAR.draw_blade(self, steel, tip, 3.2, look)
		draw_circle(grip, 3.9, Color("d3c5d5"))
		return
	# Discrete fingers and dark hilt stay close to Ghost Girl's hand.
	draw_line(grip - tangent * 5.0, guard, Color("4b344e"), 5.4, true)
	draw_line(grip, guard, Color("aa829a"), 2.2, true)
	draw_line(guard - normal * 9.2 - tangent * 2.0, guard + normal * 9.2 - tangent * 2.0, Color("b6a2b5"), 2.7, true)
	draw_circle(guard, 3.4, Color("ab76d0"))
	# Slim original asymmetric darkglass blade and moon-silver cutting line.
	draw_colored_polygon(PackedVector2Array([steel + normal * 4.0, steel + tangent * 6.0 + normal * 1.5, tip, steel + tangent * 6.0 - normal * 2.1, steel - normal * 2.2]), Color("363046"))
	draw_line(steel + normal * 2.1, tip, Color("bcb1d7"), 1.4, true)
	draw_line(steel - normal * 1.0, tip - tangent * 3.2, Color("7677a6"), 0.9, true)
	draw_circle(grip, 3.9, Color("d3c5d5"))

func _draw_briarwake_trident(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2) -> void:
	var shaft_base: Vector2 = grip - tangent * TRIDENT_SHAFT_BACK
	var head: Vector2 = tip - tangent * 17.0
	var look: Dictionary = MODULAR.equipped_profile(self, body)
	if not look.is_empty():
		MODULAR.draw_grip(self, shaft_base, head, 4.5, look)
		for side in [-1.0, 1.0]:
			var fork: Vector2 = head + normal * side * 8.0
			var prong: Vector2 = tip - tangent * 2.0 + normal * side * 7.0
			var accent: Color = look["accent"]
			draw_line(head, fork, accent.darkened(0.25), 2.5, true)
			MODULAR.draw_blade(self, fork, prong, 1.8, look)
		MODULAR.draw_blade(self, head, tip, 2.6, look)
		return
	# Rosewood haft with a pale winding thread and a second grip.
	draw_line(shaft_base, head, Color("2d1a2c"), 7.7, true)
	draw_line(shaft_base, head, Color("86526a"), 5.2, true)
	draw_line(shaft_base + normal * 1.1, head + normal * 1.1, Color("d8ac9c"), 1.3, true)
	for knot in range(3):
		var at: Vector2 = grip + tangent * float(knot * 12 + 4)
		draw_line(at - normal * 3.7, at + normal * 3.7, Color("d0a3b0"), 1.0, true)
	# Three physically distinct garnet tines; the outer tines curve inward.
	for side in [-1.0, 1.0]:
		var offset: Vector2 = normal * side * 9.3
		var fork: Vector2 = head + offset
		var prong_tip: Vector2 = tip - tangent * 2.0 + offset * 0.81
		draw_line(head, fork, Color("b37b8e"), 3.6, true)
		draw_line(fork, prong_tip, Color("d9b4b2"), 2.8, true)
		draw_line(prong_tip, prong_tip + tangent * 2.1, Color("f6d8c5"), 1.2, true)
	draw_line(head, tip, Color("e2bab6"), 4.0, true)
	draw_line(head + normal * 0.8, tip, Color("f1d5c7"), 1.5, true)
	draw_circle(head, 4.5, Color("8f3457"))
	draw_circle(head, 2.0, Color("d7a0b3"))

func _draw_moonwarden_spear(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2) -> void:
	var root: Vector2 = tip - tangent * 24.0
	var butt: Vector2 = grip - tangent * 22.0
	var look: Dictionary = MODULAR.equipped_profile(self, body)
	if not look.is_empty():
		MODULAR.draw_grip(self, butt, root, 3.8, look)
		MODULAR.draw_blade(self, root, tip, 4.5, look)
		return
	draw_line(butt, root, Color("322638"), 6.5, true)
	draw_line(butt, root, Color("876f84"), 3.2, true)
	draw_line(butt + normal, root + normal, Color("b8a7c1"), 1.0, true)
	draw_colored_polygon(PackedVector2Array([root - normal * 5.0, tip, root + normal * 5.0, root - tangent * 3.0]), Color("b9b5d5"))
	draw_colored_polygon(PackedVector2Array([root, tip, root + normal * 5.0]), Color("625f8f"))
	draw_line(root - normal * 5.0, tip, Color("e6dcf4"), 1.1, true)

# Opaque metal, not additive glow. The rear blade has its own cutting
# direction; the wrapped central grip remains visibly separate.
func _draw_v176_twinblade(grip: Vector2, tip: Vector2, rose: bool) -> void:
	var spans: Array[PackedVector2Array] = MODULAR.twinblade_spans(grip, tip)
	var rear: Vector2 = spans[1][1]
	var front_root: Vector2 = spans[0][0]
	var rear_root: Vector2 = spans[1][0]
	var look: Dictionary = MODULAR.equipped_profile(self, body)
	if not look.is_empty():
		MODULAR.draw_grip(self, rear_root, front_root, 3.0, look)
		var width: float = MODULAR.twinblade_width(rose)
		MODULAR.draw_blade(self, front_root, tip, width, look)
		MODULAR.draw_blade(self, rear_root, rear, width, look)
		# Render light in the very same draw pass as both physical blades.
		# Independent of the separate prestige overlay's readiness/visibility.
		var world: Node = player.get("world") as Node if player != null else null
		var inventory: Node = world.get("inventory") as Node if world != null else null
		var equipped: GhostItemInstance = inventory.get_equipped("sword") if inventory != null else null
		if equipped != null:
			var key: String = "%s:%s:%s:%s:%s:%s:%s" % [equipped.get_instance_id(), equipped.cosmetic_uid, equipped.visual_seed(), equipped.debug_collector_tier, equipped.debug_color_mode * 10 + equipped.debug_glow_motif, equipped.visual_signature(), equipped.mythic_layer_variant()]
			if str(get_meta("v180_fx_key", "")) != key:
				set_meta("v180_fx_key", key)
				set_meta("v180_fx_look", equipped.collector_appearance())
				set_meta("v180_fx_colors", equipped.glow_gradient_colors())
			var fx_look: Dictionary = get_meta("v180_fx_look")
			var colors: Array[Color] = get_meta("v180_fx_colors")
			for side in [-1.0, 1.0]:
				ANOMALOUS.draw_edge(self, MODULAR.edge_points(front_root, tip, width, look, side), colors, fx_look, v180_elapsed, 0.78, side > 0.0)
				ANOMALOUS.draw_edge(self, MODULAR.edge_points(rear_root, rear, width, look, side), colors, fx_look, v180_elapsed, 0.78)
		return
	draw_line(rear_root, front_root, Color("271e30"), 5.0, true)
	draw_line(rear_root, front_root, Color("78596d"), 3.0, true)
	var axis: Vector2 = (tip - grip).normalized()
	var normal: Vector2 = Vector2(-axis.y, axis.x)
	for i in range(7):
		var p: Vector2 = rear_root.lerp(front_root, float(i + 1) / 8.0)
		draw_line(p - normal * 2.0, p + normal * 2.0, Color("b595a6"), 1.0, true)
	_draw_v176_razor(front_root, tip, rose)
	_draw_v176_razor(rear_root, rear, rose)
	draw_circle(grip, 3.7, Color("d8c7d6"))

func _draw_v176_razor(root: Vector2, tip: Vector2, rose: bool) -> void:
	var axis: Vector2 = (tip - root).normalized()
	var normal: Vector2 = Vector2(-axis.y, axis.x)
	var steel: Color = Color("c57a93") if rose else Color("a6b2dc")
	var shadow: Color = Color("67364e") if rose else Color("505775")
	var edge: Color = Color("ffe1e9") if rose else Color("edf3ff")
	# Straight sword cutting edges, long central bevel, acute point.
	# No swollen shoulder, club head or crescent bulb.
	var shoulder: Vector2 = root.lerp(tip, 0.08)
	var taper: Vector2 = root.lerp(tip, 0.76)
	var width: float = 3.8 if rose else 3.2
	draw_colored_polygon(PackedVector2Array([root - normal * width, shoulder - normal * width, taper - normal * width * 0.72, tip, taper + normal * width * 0.72, shoulder + normal * width, root + normal * width]), steel)
	draw_colored_polygon(PackedVector2Array([root, tip, taper + normal * width * 0.72, root + normal * width]), shadow)
	draw_line(root - normal * width, taper - normal * width * 0.72, edge, 0.85, true)
	draw_line(taper - normal * width * 0.72, tip, edge, 0.85, true)
	draw_line(root + normal * width, taper + normal * width * 0.72, Color("bfb0d5"), 0.65, true)
	draw_line(taper + normal * width * 0.72, tip, Color("bfb0d5"), 0.65, true)
	draw_line(root, tip, Color("e2d4ef"), 0.65, true)
	# Small crossguard separates the sword from the short leather grip.
	draw_line(root - normal * 6.0, root + normal * 6.0, Color("a993b5"), 1.7, true)
