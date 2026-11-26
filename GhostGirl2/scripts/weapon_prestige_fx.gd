extends Node2D
const FX_LEVEL = preload("res://scripts/fx_intensity_v1924.gd")
const CHOICES_V216 = preload("res://scripts/visual_choices_v216.gd")
const WAND_ANCHORS_V216 = preload("res://scripts/wand_anchors_v216.gd")
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const STEADY_IDLE = preload("res://scripts/steady_weapon_idles_v195.gd")
const SWORD_V224 = preload("res://scripts/sword_attack_frames_v224.gd")
const ANOMALOUS = preload("res://scripts/anomalous_steel_fx_v180.gd")
const MODULAR = preload("res://scripts/modular_weapon_art_v178.gd")
## v1.72.3 — blade-only twinblade enchantments and high-visibility seeded Mythic shimmer.
## Axial glows track the weapon shaft/blade instead of orbiting a floating tip.
## Seeded colors and time-based shimmer are visual-only; no new damage paths.
const MANIFEST_PATH: String = "res://resources/weapon_layer_manifest.json"
const BOW_AXES_PATH: String = "res://resources/weapon_glow_axes_v142.json"
const LONG_AXES_PATH: String = "res://resources/long_weapon_glow_axes_v143.json"
const NEW_WEAPON_AXES_V169: String = "res://resources/new_weapon_axes_v169.json"
const NEW_WEAPON_AXES_V170: String = "res://resources/new_weapon_axes_v170.json"
const WAND_POSE_GUIDES_PATH: String = "res://resources/wand_pose_guides_v163.json"
var inventory: Node = null
var body: AnimatedSprite2D = null
var player: Node2D = null
var item: GhostItemInstance = null
var style_index: int = -1
var rarity_tier: int = 0
var visual_signature_level: int = 0
var effect_palette: Array[Color] = [Color("f0cced"), Color("b4d6f7"), Color("efbfe0")]
var paint_a: Color = Color("f0cced")
var paint_b: Color = Color("b4d6f7")
var elapsed: float = 0.0
var had_visible_fx: bool = false
var tip_by_name: Dictionary = {}
var bow_axes_by_animation: Dictionary = {}
var long_axes_by_animation: Dictionary = {}
var new_weapon_axes_by_animation: Dictionary = {}
var v170_axes_by_animation: Dictionary = {}
var wand_pose_by_animation: Dictionary = {}
@export_range(0.0, 1.5, 0.05) var effect_intensity: float = 1.0
var generated: Dictionary = {}
var collector_look: Dictionary = {}
var paint_c: Color = Color("efbfe0")
var bow_string_colors: Array[Color] = [Color("a9c4fb"), Color("f7c3ed"), Color("ddc9ff")]
var last_uid: String = ""
var last_seed: int = -9223372036854775807
var last_signature: int = -1
var last_fx_key: String = ""
# Inspector value also provides a useful live test; must never be zero by default.
@export_range(0.5, 3.0, 0.1) var visible_glow_strength: float = 1.95

func _ready() -> void:
	_read_wand_pose_guides()
	body = get_parent() as AnimatedSprite2D
	if body != null:
		player = body.get_parent() as Node2D
	z_index = 8
	z_as_relative = true
	# Transparent light is independent from Ghost Girl's fabric shader.
	# Alpha blending keeps layered colors legible instead of clipping to white.
	var glow_material: CanvasItemMaterial = CanvasItemMaterial.new()
	glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	material = glow_material
	set_meta("v1924_fx_scaled", true)
	self_modulate.a = FX_LEVEL.alpha(GENTLE.EFFECT_ALPHA) # Effects only; keep opaque metal readable.
	show()
	set_process(true)
	if FileAccess.file_exists(MANIFEST_PATH):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if data is Array:
			for entry in data:
				if entry is Dictionary:
					tip_by_name[str(entry.get("name", ""))] = entry.get("tip_positions", [])
	if FileAccess.file_exists(BOW_AXES_PATH):
		var axes_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(BOW_AXES_PATH))
		if axes_data is Dictionary:
			bow_axes_by_animation = axes_data
	if FileAccess.file_exists(LONG_AXES_PATH):
		var long_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(LONG_AXES_PATH))
		if long_data is Dictionary:
			long_axes_by_animation = long_data
	if FileAccess.file_exists(NEW_WEAPON_AXES_V169):
		var fresh_axes: Variant = JSON.parse_string(FileAccess.get_file_as_string(NEW_WEAPON_AXES_V169))
		if fresh_axes is Dictionary:
			new_weapon_axes_by_animation = fresh_axes
	if FileAccess.file_exists(NEW_WEAPON_AXES_V170):
		var v170_axes: Variant = JSON.parse_string(FileAccess.get_file_as_string(NEW_WEAPON_AXES_V170))
		if v170_axes is Dictionary:
			v170_axes_by_animation = v170_axes

func _read_wand_pose_guides() -> void:
	if not FileAccess.file_exists(WAND_POSE_GUIDES_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(WAND_POSE_GUIDES_PATH))
	if data is Dictionary:
		wand_pose_by_animation = data.get("animations", {}) as Dictionary

func bind_inventory(value: Node) -> void:
	inventory = value
	if inventory != null:
		if not inventory.equipment_changed.is_connected(refresh):
			inventory.equipment_changed.connect(refresh)
		if not inventory.contents_changed.is_connected(refresh):
			inventory.contents_changed.connect(refresh)
	show()
	refresh()

func refresh() -> void:
	item = null
	style_index = -1
	visual_signature_level = 0
	generated = {}
	collector_look = {}
	last_uid = ""
	last_seed = -9223372036854775807
	last_signature = -1
	if inventory == null:
		queue_redraw()
		return
	var sword: GhostItemInstance = inventory.get_equipped("sword")
	var wand: GhostItemInstance = inventory.get_equipped("wand")
	# Prefer the visible weapon. Casting temporarily activates wand cosmetics.
	var wand_pose: bool = body != null and WAND_ANCHORS_V216.is_wand_pose(str(body.animation))
	item = wand if wand_pose and wand != null else (sword if sword != null else wand)
	if item != null:
		last_uid = item.cosmetic_uid
		last_seed = item.visual_seed()
		last_signature = item.visual_signature()
		last_fx_key = _fx_key(item)
		collector_look = item.collector_appearance()
		# Every equipped weapon gets baseline illumination, regardless of
		# quality or whether it rolled a named prestige motif.
		style_index = GhostWeaponFXLibrary.prestige_variant(item.visual_seed(), item.quality)
		visual_signature_level = item.visual_signature()
		rarity_tier = GhostWeaponFXLibrary.tier(item.quality)
		generated = item.procedural_visuals() if style_index >= 0 else {}
		var rolls: Dictionary = item.effect_rolls()
		var gradient: Array[Color] = item.bow_limb_gradient_colors() if item.weapon_style() == "bow" else item.glow_gradient_colors()
		effect_palette = gradient
		paint_a = GhostCosmeticRNGV152.sample_palette(gradient, 0.0)
		paint_b = GhostCosmeticRNGV152.sample_palette(gradient, 0.5)
		paint_c = GhostCosmeticRNGV152.sample_palette(gradient, 1.0)
		if item.weapon_style() == "bow":
			bow_string_colors = item.bow_string_gradient_colors()
	queue_redraw()

# The bow glow, signature, ambient motes and drawn-charge light all share
# the *actual* colored bow layer's parent transform. This follows its carry
# angle, wrist motion and attack-frame changes without approximating a world
# offset. Non-bow effects stay Ghost-body-local exactly as before.
func _bow_mask_node() -> AnimatedSprite2D:
	if body == null:
		return null
	return body.get_node_or_null("BowPaletteV139") as AnimatedSprite2D

func _sync_transform_parent() -> void:
	if body == null:
		return
	var mask: AnimatedSprite2D = _bow_mask_node()
	var target: Node2D = body
	if item != null and item.weapon_style() == "bow":
		var carry: AnimatedSprite2D = body.get_node_or_null("BowCarryV166") as AnimatedSprite2D
		# Never parent weapon FX beneath an invisible color mask.
		if mask != null and mask.visible:
			target = mask
		elif carry != null and carry.visible:
			target = carry
	if get_parent() != target:
		reparent(target, false)
		position = Vector2.ZERO
		rotation = 0.0
		scale = Vector2.ONE
		queue_redraw()

func _bow_charge_progress() -> float:
	if player == null or item == null or item.weapon_style() != "bow" or not bool(player.get("bow_draw_active")):
		return 0.0
	# Match the 0.46 second hold used by player.gd without changing charge time.
	return clampf(float(player.get("bow_draw_time")) / 0.46, 0.0, 1.0)

func _draw_bow_charge_light(grip: Vector2, tip: Vector2, normal: Vector2, intensity: float) -> void:
	var progress: float = _bow_charge_progress()
	if progress <= 0.0:
		return
	var string_center: Vector2 = grip.lerp(tip, 0.54) + normal * 5.0
	var hue: Color = _bow_string_at(0.52)
	var strength: float = minf(intensity, 1.4) * progress
	# Small breath/halo attached to the drawn string; not an extra projectile.
	draw_circle(string_center, 6.0 + progress * 4.5, Color(hue.r, hue.g, hue.b, 0.030 * strength))
	draw_circle(string_center, 2.0 + progress * 2.2, Color(hue.r, hue.g, hue.b, 0.20 * strength))
	draw_arc(string_center, 9.0 + 2.0 * progress, -PI * 0.72, PI * 0.72, 20, Color(hue.r, hue.g, hue.b, 0.23 * strength), 1.3, true)

func _facing(name: String) -> String:
	for suffix in ["front", "back", "left", "right"]:
		if name.ends_with(suffix):
			return suffix
	if player != null:
		return str(player.get("facing_name"))
	return "front"

func _bow_style_name() -> String:
	return item.bow_art_style() if item != null else "thornrose"

func _resolved_bow_animation_name(animation_name: String) -> String:
	if bow_axes_by_animation.has(animation_name):
		return animation_name
	if animation_name.begins_with("idle_") or animation_name.begins_with("walk_"):
		var original_face: String = _facing(animation_name)
		var anim_face: String = "right" if original_face == "left" else original_face
		var motion: String = "walk_" if animation_name.begins_with("walk_") else "idle_"
		return _bow_style_name() + "_" + motion + anim_face
	return animation_name

func _bow_carry_offset(animation_name: String, frame_index: int) -> Vector2:
	var bob: float = 0.0
	if animation_name.begins_with("walk_"):
		var bob_cycle: Array[float] = [0.0, -0.4, -0.9, -0.5, 0.0, 0.5, 0.9, 0.4]
		bob = bob_cycle[posmod(frame_index, bob_cycle.size())]
	var face: String = _facing(animation_name)
	match face:
		"front": return Vector2(5.0, 4.0 + bob)
		"back": return Vector2(1.0, -3.0 + bob * 0.7)
		"left": return Vector2(-6.0, 1.5 + bob)
		"right": return Vector2(6.0, 1.5 + bob)
	return Vector2.ZERO

func _hand_anchor(face: String) -> Vector2:
	match face:
		"left": return Vector2(-17, 12)
		"right": return Vector2(17, 12)
		"back": return Vector2(13, 0)
		_: return Vector2(15, 14)

# Last-resort glow is deliberately always drawn for an equipped weapon.
# A missing baked-art frame/manifest MUST NOT silently hide all its effects.
func _axial_span() -> PackedVector2Array:
	var empty: PackedVector2Array = PackedVector2Array()
	if body == null or item == null:
		return empty
	var animation: String = str(body.animation)
	# Aerial clips change pose tempo, not physical weapon guide identity.
	if animation.contains("_air_"):
		animation = animation.replace("_air_", "_")
	if body.sprite_frames != null:
		var repaired: Dictionary = body.sprite_frames.get_meta("v186_heavy_fallbacks", {})
		animation = str(repaired.get(animation, animation))
	var face: String = _facing(animation)
	var grip: Vector2 = _hand_anchor(face)
	var end_point: Vector2 = _fallback_tip(grip, face, 46.0)
	var style: String = item.weapon_style()
	var pose_frame: int = 0 if STEADY_IDLE.matches(animation) else body.frame
	if item.get_slot() == "wand":
		# Shared with actual wand art and the spell release origin. Do not
		# approximate a separate hand offset for the prestige layer.
		var wand_span: PackedVector2Array = WAND_ANCHORS_V216.rendered_span(body, face)
		if wand_span.size() == 2:
			return wand_span
		return PackedVector2Array([grip, _fallback_tip(grip, face, 34.0)])
	if style == "dual_sword":
		var crossed: Node = player.get_node_or_null("Ghost/DualSwordsV174") if player != null else null
		if crossed != null and crossed.has_method("get_blade_spans"):
			var sword_spans: Array = crossed.call("get_blade_spans", animation, body.frame)
			if sword_spans.size() == 2:
				var first_sword: PackedVector2Array = sword_spans[0]
				if first_sword.size() == 2:
					return first_sword
		return PackedVector2Array([grip, _fallback_tip(grip, face, 67.0)])
	if style == "dual_dagger":
		var paired: Node = player.get_node_or_null("Ghost/DualDaggersV173") if player != null else null
		if paired != null and paired.has_method("get_blade_spans"):
			var spans: Array = paired.call("get_blade_spans", animation, body.frame)
			if spans.size() == 2:
				var first: PackedVector2Array = spans[0]
				if first.size() == 2:
					return first
				var second: PackedVector2Array = spans[1]
				if second.size() == 2:
					return second
		return PackedVector2Array([grip, _fallback_tip(grip, face, 35.0)])
	if style == "twinblade":
		var physical: Node = player.get_node_or_null("Ghost/WeaponPoseV172") if player != null else null
		if physical != null:
			var span: Variant = physical.call("get_weapon_span", animation, body.frame)
			if span is PackedVector2Array and span.size() == 2:
				return span
	if style in ["maul", "twinblade"]:
		# The four physical weapon variants have their own frame-authored
		# guides. No arbitrary white glowing rectangles or detached rings.
		var fresh_v170: Array = v170_axes_by_animation.get(animation, [])
		if not fresh_v170.is_empty():
			var segment: Variant = fresh_v170[clampi(body.frame, 0, fresh_v170.size() - 1)]
			if segment is Array and segment.size() == 4:
				return PackedVector2Array([Vector2(float(segment[0]), float(segment[1])), Vector2(float(segment[2]), float(segment[3]))])
		return PackedVector2Array([grip, _fallback_tip(grip, face, 66.0 if style == "maul" else 73.0)])
	if style in ["dagger", "spear"]:
		# v1.72.2: glow follows exactly the weapon geometry being rendered.
		var pose_node: Node = player.get_node_or_null("Ghost/WeaponPoseV172") if player != null else null
		if pose_node != null and pose_node.has_method("get_weapon_span"):
			var authored: Variant = pose_node.call("get_weapon_span", animation, pose_frame)
			if authored is PackedVector2Array and authored.size() == 2:
				return authored
			if item.uses_forge_dagger() or (style == "spear" and animation.begins_with("attack_")):
				return empty # Occluded physical grip: no detached fallback light.
		var fresh: Array = new_weapon_axes_by_animation.get(animation, [])
		if not fresh.is_empty():
			var pair: Variant = fresh[clampi(pose_frame, 0, fresh.size() - 1)]
			if pair is Array and pair.size() == 4:
				return PackedVector2Array([Vector2(float(pair[0]), float(pair[1])), Vector2(float(pair[2]), float(pair[3]))])
		return PackedVector2Array([grip, _fallback_tip(grip, face, 43.0 if style == "dagger" else 82.0)])
	if style == "blade":
		if item.uses_modular_single_sword():
			var rig: Node = player.get_node_or_null("Ghost/WeaponPoseV172") if player != null else null
			if rig != null:
				var shared: PackedVector2Array = rig.call("get_weapon_span", animation, body.frame)
				return shared
			return empty
		# Authored coordinates when available; safe idle blade otherwise.
		var blade: PackedVector2Array = _blade_span(animation, face, body.frame)
		var tracked: PackedVector2Array = PackedVector2Array()
		for point in blade:
			var local: Vector2 = point
			if body.flip_h:
				local.x = -local.x
			if body.flip_v:
				local.y = -local.y
			tracked.append(local + body.offset)
		return tracked
	if style in ["scythe", "halberd"]:
		var axes: Array = long_axes_by_animation.get(animation, [])
		if not axes.is_empty():
			var guide: Variant = axes[clampi(body.frame, 0, axes.size() - 1)]
			if guide is Array and guide.size() == 4:
				return PackedVector2Array([
					Vector2(float(guide[0]), float(guide[1])),
					Vector2(float(guide[2]), float(guide[3]))])
		# A generic weapon-axis fallback instead of invisible effects.
		return PackedVector2Array([grip, _fallback_tip(grip, face, 68.0)])
	if style == "bow":
		var bow_animation: String = _resolved_bow_animation_name(animation)
		var frame_index: int = pose_frame
		var mirrored: bool = false
		var offset: Vector2 = Vector2.ZERO
		var mask: AnimatedSprite2D = body.get_node_or_null("BowPaletteV139") as AnimatedSprite2D
		if mask != null and mask.visible and bow_axes_by_animation.has(str(mask.animation)):
			bow_animation = str(mask.animation)
			frame_index = 0 if STEADY_IDLE.matches(animation) else mask.frame
			mirrored = mask.flip_h
			# A child inherits mask position/rotation automatically. flip_h
			# flips pixels, not child nodes: mirror guide X explicitly below.
			offset = Vector2.ZERO if get_parent() == mask else mask.position
		var axes: Array = bow_axes_by_animation.get(bow_animation, [])
		if not axes.is_empty():
			var guide: Variant = axes[clampi(frame_index, 0, axes.size() - 1)]
			if guide is Array and guide.size() == 4:
				var start_pos: Vector2 = Vector2(float(guide[0]), float(guide[1]))
				var end_pos: Vector2 = Vector2(float(guide[2]), float(guide[3]))
				if mirrored:
					start_pos.x *= -1.0
					end_pos.x *= -1.0
				return PackedVector2Array([start_pos + offset, end_pos + offset])
		return PackedVector2Array([grip, _fallback_tip(grip, face, 46.0)])
	# Every equipment category that actually occupies the weapon slot
	# receives a visible fallback aura, not an empty array.
	return PackedVector2Array([grip, end_point])

# All points below refer to approved 256×220 baked sword sprites, in pixel
# coordinates. Converted to centered SpriteFrames coordinates before drawing.
# Frames follow the existing 8-pose authored ordering, not a fixed hand point.
func _blade_span(animation: String, face: String, frame_index: int) -> PackedVector2Array:
	var grip: Vector2 = Vector2(173, 139)
	var tip: Vector2 = Vector2(196, 188)
	var attacking: bool = animation.begins_with("attack_sword_")
	var poses: Array = []
	match face:
		"front":
			grip = Vector2(171, 138)
			tip = Vector2(198, 189)
			poses = [
				[173, 139, 198, 189], [171, 132, 205, 151],
				[151, 113, 193, 76], [174, 130, 207, 95],
				[186, 138, 218, 59], [190, 145, 235, 124],
				[176, 141, 219, 183], [173, 139, 198, 189]]
		"back":
			grip = Vector2(175, 138)
			tip = Vector2(204, 183)
			poses = [
				[173, 141, 204, 183], [180, 125, 208, 137],
				[171, 116, 191, 73], [175, 115, 190, 47],
				[177, 118, 200, 38], [170, 139, 219, 143],
				[173, 143, 205, 183], [173, 141, 204, 183]]
		"left":
			grip = Vector2(96, 140)
			tip = Vector2(63, 188)
			poses = [
				[95, 140, 63, 188], [98, 130, 52, 156],
				[101, 120, 53, 128], [92, 134, 66, 65],
				[92, 137, 62, 58], [91, 148, 48, 132],
				[95, 140, 61, 188], [95, 140, 63, 188]]
		"right":
			grip = Vector2(172, 140)
			tip = Vector2(206, 188)
			poses = [
				[172, 140, 206, 188], [170, 133, 214, 157],
				[166, 116, 211, 129], [178, 137, 218, 72],
				[182, 139, 228, 72], [180, 148, 241, 130],
				[172, 140, 210, 189], [172, 140, 206, 188]]
	if attacking and not poses.is_empty():
		var count: int = body.sprite_frames.get_frame_count(body.animation) if body != null and body.sprite_frames != null else 8
		var pose_index: int = roundi(float(frame_index) * 7.0 / float(maxi(1, count - 1)))
		if body != null and SWORD_V224.has_samples(body.sprite_frames, str(body.animation)):
			pose_index = SWORD_V224.source_pose_index(body.sprite_frames, str(body.animation), frame_index)
		var pose: Array = poses[clampi(pose_index, 0, poses.size() - 1)]
		grip = Vector2(float(pose[0]), float(pose[1]))
		tip = Vector2(float(pose[2]), float(pose[3]))
	# SpriteFrames textures are 256 x 220 and centered by AnimatedSprite2D.
	return PackedVector2Array([grip - Vector2(128, 110), tip - Vector2(128, 110)])

func _fallback_tip(grip: Vector2, face: String, distance: float) -> Vector2:
	match face:
		"left": return grip + Vector2(-distance * 0.8, -distance * 0.58)
		"right": return grip + Vector2(distance * 0.8, -distance * 0.58)
		"back": return grip + Vector2(10, -distance)
		_: return grip + Vector2(distance * 0.45, -distance * 0.9)

func _process(delta: float) -> void:
	# A little more edge presence on the small world-scale paired swords only.
	self_modulate.a = FX_LEVEL.alpha((0.80 if item != null and item.weapon_style() == "bow" else (0.72 if item != null and item.weapon_style() == "dual_sword" else GENTLE.EFFECT_ALPHA)) * CHOICES_V216.effect_scale(item))
	elapsed += delta
	if inventory == null and player != null:
		# Self-heal when an older game.gd forgot to call bind_inventory().
		# The inventory is a sibling of the player in scenes/main.tscn.
		var level: Node = player.get_parent()
		if level != null and level.has_node("Inventory"):
			bind_inventory(level.get_node("Inventory"))
	if inventory == null:
		return
	var wand_pose: bool = body != null and WAND_ANCHORS_V216.is_wand_pose(str(body.animation))
	var wand: GhostItemInstance = inventory.get_equipped("wand")
	var sword: GhostItemInstance = inventory.get_equipped("sword")
	var selected: GhostItemInstance = wand if wand_pose and wand != null else (sword if sword != null else wand)
	if selected != item:
		refresh()
	elif item != null and (last_uid != item.cosmetic_uid or last_seed != item.visual_seed() or last_signature != item.visual_signature() or last_fx_key != _fx_key(item)):
		refresh()
	_sync_transform_parent()
	# Redraw once when a visible effect disappears. Off must not keep
	# rebuilding an empty canvas, and restoring glow takes effect immediately.
	var visible_fx: bool = item != null and CHOICES_V216.effect_scale(item) > 0.0 and FX_LEVEL.intensity > 0.0
	if visible_fx or had_visible_fx:
		queue_redraw()
	had_visible_fx = visible_fx

func _fx_key(value: GhostItemInstance) -> String:
	return "%s:%s:%s:%s:%s:%s:%d:%d:%d" % [value.effect_palette_channel(), value.debug_color_mode, value.debug_glow_motif, value.debug_surface_mode, value.debug_forge_guard, value.debug_forge_grip, value.glow_level_override, value.bow_glow_mode_override, value.bow_projectile_style_override]

func _ink(progress: float, opacity: float) -> Color:
	var tint: Color = paint_a.lerp(paint_b, clampf(progress, 0.0, 1.0))
	tint.a = opacity
	return tint

func _gradient_at(t: float) -> Color:
	var u: float = clampf(t, 0.0, 1.0)
	var colors: Array[Color] = effect_palette
	return ANOMALOUS.color_at(colors, collector_look, u, elapsed)

# v1.54 -- soft bloom sampled around the approved weapon silhouette.
# Round, feathered light replaces the old large square-ended 26px line strips.
func _draw() -> void:
	if item == null or body == null or CHOICES_V216.effect_scale(item) <= 0.0 or FX_LEVEL.intensity <= 0.0:
		return
	# Crossbow geometry owns its restrained physical finish; bolt glow is independent.
	if item.weapon_style() == "crossbow" or item.uses_forge_bow():
		return
	var visible_clip: String = str(body.animation)
	if item.get_slot() == "wand" and not WAND_ANCHORS_V216.is_wand_pose(visible_clip):
		return
	if item.weapon_style() == "blade" and not (visible_clip.begins_with("sword_") or visible_clip.begins_with("attack_sword_")):
		return
	# Modular heavy weapons own their actual edge/rim glow; do not double it.
	if item.weapon_style() in ["halberd", "maul"] and player != null and player.has_node("Ghost/ScytheRigV190") and preload("res://scripts/heavy_weapon_art_v192.gd").matches(str(body.animation)):
		return
	# The new scythe rig owns the curved cutting-edge light, not the old baked shaft.
	if item.weapon_style() == "scythe" and player != null and player.has_node("Ghost/ScytheRigV190") and preload("res://scripts/scythe_art_v190.gd").matches(str(body.animation)):
		return
	var points: PackedVector2Array = _axial_span()
	if points.size() != 2:
		return
	var grip: Vector2 = points[0]
	var tip: Vector2 = points[1]
	var axis: Vector2 = tip - grip
	if axis.length_squared() < 64.0:
		return
	var tangent: Vector2 = axis.normalized()
	var normal: Vector2 = Vector2(-tangent.y, tangent.x)
	var animation: String = str(body.animation)
	var attacking: bool = animation.begins_with("attack_") or animation.contains("cast")
	var intensity: float = effect_intensity * visible_glow_strength * (0.88 + 0.12 * sin(elapsed * 3.1))
	intensity *= 1.18 if attacking else 0.83
	if visual_signature_level >= 4:
		intensity *= 1.22
	var style: String = item.weapon_style()
	# Bow body Off must silence every bow-owned light layer (including
	# seed-signature filaments), while leaving the physical bow and the
	# independent arrow-projectile appearance untouched.
	if style == "bow" and not CHOICES_V216.bow_body_visible(item):
		return
	# New independent intensity and rhythm rolls affect light only, never damage.
	if not collector_look.is_empty():
		intensity *= float(collector_look.get("glow_strength", 1.0))
		intensity *= 0.91 + 0.09 * sin(elapsed * float(collector_look.get("glow_speed", 0.8)) * TAU)
		if style not in ["dual_sword", "dual_dagger"]:
			_draw_v177_collector_finish(grip, tip, style, intensity)
	# Explicit owner-selected glow always produces a small visible metal/glass
	# highlight even if this weapon lacks an authored prestige animation.
	# Paired/twin blades and heavy rigs retain their own precise edge paths.
	var seeded_special: bool = GhostWeaponFXLibrary.tier(item.quality) >= 2 or item.visual_signature() > 0
	if (item.glow_level_override > 0 or (item.glow_level_override < 0 and seeded_special)) and style not in ["dual_sword", "dual_dagger", "twinblade"]:
		_draw_v216_visible_fallback(grip, tip, intensity)
	if style == "dual_sword":
		# Glow is applied to BOTH physical sword blades, never across the grips.
		var paired_swords: Node = player.get_node_or_null("Ghost/DualSwordsV174") if player != null else null
		if paired_swords != null and paired_swords.has_method("get_blade_spans"):
			var twin_swords: Array = paired_swords.call("get_blade_spans", animation, body.frame)
			_draw_v174_dual_sword_fx(twin_swords, intensity, attacking)
		return
	if style == "dual_dagger":
		var paired_rig: Node = player.get_node_or_null("Ghost/DualDaggersV173") if player != null else null
		if paired_rig != null and paired_rig.has_method("get_blade_spans"):
			var both: Array = paired_rig.call("get_blade_spans", animation, body.frame)
			_draw_v173_dual_dagger_fx(both, intensity, attacking)
		return
	var narrow: bool = style == "bow"
	var wand: bool = item.get_slot() == "wand"
	if narrow:
		if CHOICES_V216.bow_body_visible(item):
			ANOMALOUS.draw_edge(self, PackedVector2Array([grip, tip]), effect_palette, collector_look, elapsed, 1.1)
			_draw_bow_dual_glow(grip, tip, tangent, normal, minf(intensity, 1.15))
			if CHOICES_V216.bow_mode(item) == 3:
				_draw_full_bow_aura(grip, tip, normal, minf(intensity, 1.35))
		if CHOICES_V216.bow_string_visible(item):
			_draw_bow_charge_light(grip, tip, normal, intensity)
		_draw_ambient_fireflies(grip, tip, tangent, normal, minf(intensity, 1.35))
		_draw_socketed_jewel_echo(grip, tip, normal)
		if visual_signature_level > 0:
			_draw_signature(grip, tip, tangent, normal, attacking, minf(intensity, 1.55))
		_draw_v1723_mythic_sheen(grip, tip, tangent, normal, style, attacking)
		return
	# Twinblades have *two* cutting heads. Do not run the generic shaft
	# glow, center ring, socket orbit or mythic signature along their handle.
	if style == "twinblade":
		# The physical twinblade layer already draws its two cutting edges.
		# Preserve the independent signature, but never double up the glow.
		var physical: Node = player.get_node_or_null("Ghost/WeaponPoseV172") if player != null else null
		if physical == null or not bool(physical.call("_is_equipped", animation)):
			_draw_v1723_twinblade_edges(grip, tip, normal, intensity)
			_draw_v1723_mythic_sheen(grip, tip, tangent, normal, style, attacking)
		return
	ANOMALOUS.draw_edge(self, PackedVector2Array([grip.lerp(tip, 0.25), tip]), effect_palette, collector_look, elapsed, 1.0)
	# Bow string and body remain recognizable; its glow must not become a solid bar.
	var radius: float = (6.0 if narrow else (8.0 if wand else 10.5)) * 1.15
	var opaque_factor: float = 0.71 if narrow else 1.0
	for i in range(15):
		var t: float = 0.20 + 0.72 * float(i) / 14.0
		var p: Vector2 = grip.lerp(tip, t)
		var c: Color = _gradient_at(t)
		var taper: float = pow(sin((t - 0.15) / 0.85 * PI), 0.55)
		taper = maxf(0.20, taper)
		# Approximate a little Gaussian/lamp bloom: barely visible wide halo,
		# soft midlight and a small luminous core; no hard rectangle or fan.
		draw_circle(p, radius * 1.95 * taper, Color(c.r, c.g, c.b, 0.012 * intensity * opaque_factor))
		draw_circle(p, radius * 1.25 * taper, Color(c.r, c.g, c.b, 0.022 * intensity * opaque_factor))
		draw_circle(p, radius * 0.72 * taper, Color(c.r, c.g, c.b, 0.047 * intensity * opaque_factor))
		draw_circle(p, maxf(1.1, radius * 0.23) * taper, Color(c.r, c.g, c.b, 0.142 * intensity * opaque_factor))
	# Narrow streak holds together without washing over the weapon's texture.
	var streak_start: Vector2 = grip.lerp(tip, 0.24)
	var streak_end: Vector2 = grip.lerp(tip, 0.91)
	var filament: Color = _gradient_at(0.48)
	draw_line(streak_start, streak_end, Color(filament.r, filament.g, filament.b, 0.35 * minf(intensity, 1.65) * opaque_factor), 1.3 if narrow else 1.8, true)
	# v1.70.1: family-specific secondary illumination stays on the painted metal.
	# Every newer weapon family gets an unmistakable, but restrained, identity.
	if style == "twinblade":
		var back_tip: Vector2 = grip - axis * 0.68
		for j in range(9):
			var u: float = float(j) / 8.0
			var p: Vector2 = grip.lerp(back_tip, u)
			var c: Color = _gradient_at(1.0 - u)
			var falloff: float = maxf(0.12, sin(u * PI))
			draw_circle(p, 3.0 * falloff, Color(c.r, c.g, c.b, 0.045 * intensity))
			draw_circle(p, 1.15 * falloff, Color(c.r, c.g, c.b, 0.12 * intensity))
		var cross_mid: Vector2 = grip.lerp(tip, 0.50)
		draw_line(back_tip.lerp(grip, 0.18), grip.lerp(tip, 0.18), Color(filament.r, filament.g, filament.b, 0.14 * intensity), 1.0, true)
		_soft_orb(cross_mid, 2.4, _gradient_at(0.52), intensity * 0.38)
	elif style == "maul":
		# Small lantern glow within the actual hammer head, not a giant ring.
		var head_color: Color = _gradient_at(0.9)
		_soft_orb(tip, 4.6, head_color, minf(intensity, 1.5) * 0.72)
		for chip_i in range(3):
			var p: Vector2 = tip + normal * (-2.0 + 2.0 * chip_i) + tangent * (1.2 - 0.6 * chip_i)
			draw_circle(p, 0.95 + 0.15 * chip_i, Color(head_color.r, head_color.g, head_color.b, 0.14 * intensity))
	elif style == "dagger":
		var stab_color: Color = _gradient_at(0.78)
		draw_line(grip.lerp(tip, 0.46), tip, Color(stab_color.r, stab_color.g, stab_color.b, 0.18 * intensity), 1.1, true)
		draw_line(grip.lerp(tip, 0.60) + normal * 1.2, tip, Color(1.0, 1.0, 1.0, 0.10 * intensity), 0.8, true)
		_soft_orb(tip, 2.3, stab_color, intensity * 0.52)
	elif style == "spear":
		var spear_color: Color = _gradient_at(0.88)
		draw_line(grip.lerp(tip, 0.22), grip.lerp(tip, 0.96), Color(spear_color.r, spear_color.g, spear_color.b, 0.11 * intensity), 1.0, true)
		draw_line(grip.lerp(tip, 0.72), tip, Color(1.0, 1.0, 1.0, 0.09 * intensity), 0.75, true)
		_soft_orb(tip, 2.8, spear_color, intensity * 0.45)
	# Four slow lantern-like embers instead of angular rotating pattern geometry.
	for i in range(3 if visual_signature_level > 0 else 2):
		var orbit: float = fposmod(elapsed * (0.13 + 0.04 * float(i)) + float(i) * 0.36 + float(item.visual_seed() % 101) / 101.0, 1.0)
		var p: Vector2 = grip.lerp(tip, 0.25 + orbit * 0.66) + normal * sin(elapsed * 1.6 + float(i) * 2.5) * (2.1 if narrow else 3.0)
		var c: Color = _gradient_at(orbit)
		draw_circle(p, 1.6 if narrow else 2.0, Color(c.r, c.g, c.b, 0.43 * minf(intensity, 1.6)))
	_draw_ambient_fireflies(grip, tip, tangent, normal, minf(intensity, 1.5))
	_draw_socketed_jewel_echo(grip, tip, normal)
	if item.get_slot() == "wand":
		_draw_wand_hold_cosmetics(grip, tip, tangent, normal, attacking, minf(intensity, 1.7))
	if visual_signature_level > 0:
		_draw_signature(grip, tip, tangent, normal, attacking, minf(intensity, 1.6))
	_draw_v172_named_weapon_fx(grip, tip, tangent, normal, attacking, minf(intensity, 1.55))
	_draw_v1723_mythic_sheen(grip, tip, tangent, normal, style, attacking)


# v1.72.3 - blade-region maps are normalized segments along the authored grip-to-tip
# axis. Never brighten a twinblade's central wrapped handle.


# v1.75: a clearly legible NORMAL-quality metal edge (not gated on
# a Mythic signature). Only called on metal segments, never the handle.
func _v175_visible_edge(a: Vector2, b: Vector2, power: float, phase: float) -> void:
	var vec: Vector2 = b - a
	if vec.length_squared() < 24.0:
		return
	var direction: Vector2 = vec.normalized()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	var pulse: float = 0.86 + 0.14 * sin(elapsed * 1.7 + phase * TAU)
	var strong: float = clampf(power * pulse, 0.7, 3.2)
	for i in range(11):
		var u: float = float(i) / 10.0
		var p: Vector2 = a.lerp(b, u)
		var taper: float = maxf(0.12, sin((u * 0.80 + 0.16) * PI))
		var tint: Color = _gradient_at(fposmod(u * 0.45 + elapsed * 0.052 + phase, 1.0)).lerp(Color.WHITE, 0.19)
		draw_circle(p, 5.4 * taper, Color(tint.r, tint.g, tint.b, 0.085 * strong * taper))
		draw_circle(p, 2.8 * taper, Color(tint.r, tint.g, tint.b, 0.18 * strong * taper))
		draw_circle(p, 1.2 * taper, Color(1.0, 0.98, 1.0, 0.27 * strong * taper))
	var edge: Color = _gradient_at(fposmod(0.60 + phase + elapsed * 0.06, 1.0)).lerp(Color.WHITE, 0.33)
	draw_line(a.lerp(b, 0.06) - normal * 0.55, b, Color(edge.r, edge.g, edge.b, 0.52 * strong), 2.15, true)
	draw_line(a.lerp(b, 0.18) + normal * 0.42, b, Color(1.0, 0.99, 1.0, 0.26 * strong), 0.88, true)


# Additional Mythic families unlike the wand's projectile effects:
# twinblade: razor shards; paired daggers: spectral split strikes;
# paired swords: eclipse threads; bows: moon moths; polearms: falling petals.
# Cosmetic UID seed alone controls variant and phase; no damage/save RNG.
func _v175_mythic_signature(a: Vector2, b: Vector2, style: String, index: int, attacking: bool) -> void:
	if item == null or visual_signature_level not in [4, 5]:
		return
	var delta: Vector2 = b - a
	if delta.length_squared() < 24.0:
		return
	var tangent: Vector2 = delta.normalized()
	var normal: Vector2 = Vector2(-tangent.y, tangent.x)
	var seed: float = float(posmod(item.visual_seed(), 1543)) / 1543.0
	var variant: int = item.mythic_layer_variant()
	var phase: float = elapsed * (1.3 + 0.15 * float(variant)) + seed * TAU + float(index) * 1.53
	var pulse: float = 0.77 + 0.23 * sin(phase * 1.9)
	var power: float = clampf(visible_glow_strength * effect_intensity * pulse * (1.18 if attacking else 0.88), 0.7, 3.0)
	var bright: Color = _gradient_at(fposmod(elapsed * 0.10 + seed + float(index) * 0.25, 1.0)).lerp(Color.WHITE, 0.20)
	if style == "twinblade":
		# Razor shards extend beyond each sharpened tip, not along the grip.
		for i in range(3):
			var travel: float = fposmod(0.2 * float(i) + elapsed * 0.14 + seed, 0.96)
			var p: Vector2 = a.lerp(b, travel)
			var shard: Vector2 = p + normal * (3.3 + float(i) * 1.6) * (1.0 if index == 0 else -1.0)
			draw_colored_polygon(PackedVector2Array([p, shard + tangent * 3.5, shard - tangent * 2.0]), Color(bright.r, bright.g, bright.b, 0.29 * power))
		_soft_orb(b + tangent * 4.0, 4.3, bright, power * 0.96)
	elif style == "dual_dagger":
		# Two narrow staggered shadows follow the cutting edge.
		for side in [-1.0, 1.0]:
			var drift: Vector2 = normal * side * (2.6 + 1.8 * sin(phase))
			draw_line(a.lerp(b, 0.35) + drift, b + drift * 0.42, Color(bright.r, bright.g, bright.b, 0.27 * power), 0.95, true)
		_soft_orb(b, 3.5, bright, power * 0.90)
	elif style == "dual_sword" or style == "blade":
		# The blade crosses an ethereal eclipse filament (no wand beams).
		var crescent_center: Vector2 = b - tangent * 5.0
		draw_arc(crescent_center, 7.5, phase * 0.30, phase * 0.30 + PI * 0.86, 24, Color(bright.r, bright.g, bright.b, 0.29 * power), 1.2, true)
		draw_line(a.lerp(b, 0.53) + normal * 2.0, b + normal * 1.0, Color(bright.r, bright.g, bright.b, 0.21 * power), 1.0, true)
	elif style == "bow":
		# Three tiny moon-moths flutter around the bow, never the string grip.
		for i in range(3):
			var u: float = 0.22 + float(i) * 0.27
			var p: Vector2 = a.lerp(b, u) + normal * sin(phase + float(i) * 2.1) * 5.5
			draw_line(p, p + Vector2(-3.0, -2.0), Color(bright.r, bright.g, bright.b, 0.32 * power), 1.0, true)
			draw_line(p, p + Vector2(3.0, -2.0), Color(1.0, 0.95, 1.0, 0.33 * power), 1.0, true)
	else:
		# Spear/halberd/scythe/maul: short rising thorns and falling petals.
		for i in range(4):
			var u: float = fposmod(0.17 + float(i) * 0.19 + elapsed * 0.045 + seed, 0.94)
			var p: Vector2 = a.lerp(b, u)
			var offset: Vector2 = normal * sin(phase + float(i) * 1.6) * 5.0
			draw_colored_polygon(PackedVector2Array([p, p + offset + tangent * 2.0, p + offset - tangent * 1.9]), Color(bright.r, bright.g, bright.b, 0.24 * power))
	# A seeded point-star occasionally flares, distinct from old tiny motes.
	var sparkle_time: float = maxf(0.0, sin(phase * 2.1 + float(variant)))
	if sparkle_time > 0.32:
		var star: Vector2 = a.lerp(b, fposmod(elapsed * 0.17 + seed + float(index) * 0.33, 0.97))
		var extent: float = 2.2 + sparkle_time * 3.0
		draw_line(star - normal * extent, star + normal * extent, Color(1.0, 0.99, 1.0, 0.42 * power * sparkle_time), 1.1, true)
		draw_line(star - tangent * extent * 0.70, star + tangent * extent * 0.70, Color(bright.r, bright.g, bright.b, 0.34 * power * sparkle_time), 1.05, true)

func _draw_v174_dual_sword_fx(blades: Array, intensity: float, attacking: bool) -> void:
	# Two independent moving metal edge masks, each tied to its own authored
	# grip-to-point span. The original handle/guard is never treated as emissive.
	if item == null or blades.size() != 2:
		return
	var mythic: bool = visual_signature_level in [4, 5]
	var seed_phase: float = float(posmod(item.visual_seed(), 1009)) / 1009.0
	var variant: int = item.mythic_layer_variant()
	var pulse: float = 1.0 + 0.31 * sin(elapsed * 2.17 + seed_phase * TAU)
	var power: float = clampf(intensity * (1.47 if mythic else 0.61) * (1.12 if attacking else 1.0), 0.15, 3.6)
	for hand_index in range(2):
		var span: PackedVector2Array = blades[hand_index]
		if span.size() != 2:
			continue
		var grip: Vector2 = span[0]
		var tip: Vector2 = span[1]
		# Start on the lower steel, past the dark hilt and crossguard.
		var blade_root: Vector2 = grip.lerp(tip, 0.25)
		var blade_axis: Vector2 = tip - blade_root
		if blade_axis.length_squared() < 64.0:
			continue
		var blade_dir: Vector2 = blade_axis.normalized()
		var blade_normal: Vector2 = Vector2(-blade_dir.y, blade_dir.x)
		var hand_phase: float = float(hand_index) * 0.38
		# More luminous in Mythic but still following the cutting edge.
		for section_i in range(16):
			var u: float = float(section_i) / 15.0
			var at: Vector2 = blade_root.lerp(tip, u)
			var taper: float = maxf(0.14, sin((0.11 + u * 0.87) * PI))
			var chroma: float = fposmod(u * 0.59 + elapsed * (0.095 if mythic else 0.014) + seed_phase + hand_phase, 1.0)
			var ink: Color = _gradient_at(chroma)
			var brightness: float = (0.115 if mythic else 0.065) * power * pulse * taper
			draw_circle(at, (7.4 if mythic else 3.6) * taper, Color(ink.r, ink.g, ink.b, brightness))
			draw_circle(at, 2.5 * taper, Color(ink.r, ink.g, ink.b, brightness * 1.85))
		var shine: Color = _gradient_at(fposmod(0.67 + seed_phase + elapsed * 0.11 + hand_phase, 1.0))
		var edge_offset: float = -1.3 if hand_index == 0 else 1.3
		draw_line(blade_root + blade_normal * edge_offset, tip, Color(shine.r, shine.g, shine.b, (0.49 if mythic else 0.25) * power * pulse), 1.45, true)
		_v175_visible_edge(blade_root, tip, intensity, float(hand_index) * 0.32)
		var colors: Array[Color] = effect_palette
		ANOMALOUS.draw_edge(self, PackedVector2Array([blade_root, tip]), colors, collector_look, elapsed, intensity)
		if not mythic:
			continue
		_v175_mythic_signature(blade_root, tip, "dual_sword", hand_index, attacking)
		# Seven four-point glitters per blade; always reproducible from cosmetic
		# seed and time, with no non-cosmetic RandomNumberGenerator calls.
		for glitter_i in range(7):
			var n: float = float(glitter_i)
			var u: float = fposmod(0.10 + n * 0.13 + seed_phase * 0.13 + elapsed * 0.052 + hand_phase, 0.96)
			var flash: float = pow(maxf(0.0, sin(elapsed * (2.4 + n * 0.10) + seed_phase * TAU + n * 1.89 + hand_phase)), 2.0)
			if flash < 0.12:
				continue
			var sparkle: Vector2 = blade_root.lerp(tip, u) + blade_normal * (2.0 * sin(elapsed * 1.5 + n))
			var color: Color = _gradient_at(fposmod(u + elapsed * 0.13 + seed_phase + hand_phase, 1.0)).lerp(Color.WHITE, 0.45)
			var alpha: float = 0.55 * power * flash
			var width: float = 1.5 + flash * (1.4 + float(variant % 2))
			draw_line(sparkle - blade_normal * width, sparkle + blade_normal * width, Color(color.r, color.g, color.b, alpha), 1.1, true)
			draw_line(sparkle - blade_dir * width * 0.72, sparkle + blade_dir * width * 0.72, Color(1.0, 1.0, 1.0, alpha * 0.78), 1.0, true)
			draw_circle(sparkle, 1.1, Color(1.0, 1.0, 1.0, alpha * 0.78))
		match variant:
			0:
				var comet: Vector2 = blade_root.lerp(tip, fposmod(elapsed * 0.25 + seed_phase + hand_phase, 1.0))
				draw_circle(comet, 2.3, Color(shine.r, shine.g, shine.b, 0.28 * power))
			1:
				draw_circle(tip + blade_normal * sin(elapsed * 2.0 + hand_phase) * 2.5, 1.85, Color(1.0, 0.94, 1.0, 0.36 * power))
			2:
				draw_line(blade_root.lerp(tip, 0.27) + blade_normal * 2.1, tip + blade_normal * 0.5, Color(shine.r, shine.g, shine.b, 0.32 * power), 0.9, true)
			_:
				draw_line(tip - blade_normal * 3.1, tip + blade_normal * 3.1, Color(shine.r, shine.g, shine.b, 0.39 * power), 1.0, true)

func _draw_v173_dual_dagger_fx(blades: Array, intensity: float, attacking: bool) -> void:
	# Two separate blade-only gradients, one per hand, taken from the SAME
	# frame-authored geometry as the visible swords. No handle bloom, no new hits.
	if item == null or blades.size() != 2:
		return
	var mythic: bool = visual_signature_level in [4, 5]
	var seed_phase: float = float(posmod(item.visual_seed(), 1009)) / 1009.0
	var variant: int = item.mythic_layer_variant()
	var pulse: float = 1.0 + 0.34 * sin(elapsed * 2.55 + seed_phase * TAU)
	var power: float = clampf(intensity * (1.55 if mythic else 0.73), 0.2, 3.6)
	for hand_index in range(2):
		var span: PackedVector2Array = blades[hand_index]
		if span.size() != 2:
			continue
		var grip: Vector2 = span[0]
		var tip: Vector2 = span[1]
		var a: Vector2 = grip.lerp(tip, 0.39)
		var axis: Vector2 = tip - a
		if axis.length_squared() < 24.0:
			continue
		var blade_normal: Vector2 = Vector2(-axis.y, axis.x).normalized()
		var hand_phase: float = float(hand_index) * 0.27
		for stripe_i in range(10):
			var u: float = float(stripe_i) / 9.0
			var at: Vector2 = a.lerp(tip, u)
			var hue: float = fposmod(u * 0.48 + elapsed * (0.085 if mythic else 0.023) + seed_phase + hand_phase, 1.0)
			var color: Color = _gradient_at(hue)
			var taper: float = maxf(0.18, sin((0.10 + u * 0.87) * PI))
			var alpha: float = (0.13 if mythic else 0.055) * power * taper * pulse
			draw_circle(at, (5.4 if mythic else 2.7) * taper, Color(color.r, color.g, color.b, alpha))
			draw_circle(at, 1.6 * taper, Color(color.r, color.g, color.b, alpha * 2.2))
		var shine: Color = _gradient_at(fposmod(0.73 + seed_phase + elapsed * 0.09 + hand_phase, 1.0))
		draw_line(a - blade_normal * 1.1, tip, Color(shine.r, shine.g, shine.b, (0.45 if mythic else 0.14) * power * pulse), 1.35, true)
		_v175_visible_edge(a, tip, intensity, float(hand_index) * 0.31)
		var colors: Array[Color] = effect_palette
		ANOMALOUS.draw_edge(self, PackedVector2Array([a, tip]), colors, collector_look, elapsed, intensity)
		if not mythic:
			continue
		_v175_mythic_signature(a, tip, "dual_dagger", hand_index, attacking)
		for glitter_i in range(5):
			var n: float = float(glitter_i)
			var u: float = fposmod(0.13 + n * 0.17 + seed_phase * 0.13 + elapsed * 0.07 + hand_phase, 0.94)
			var glitter_pulse: float = pow(maxf(0.0, sin(elapsed * (2.8 + n * 0.09) + seed_phase * TAU + n * 2.1 + hand_phase)), 2.0)
			if glitter_pulse < 0.12:
				continue
			var spark: Vector2 = a.lerp(tip, u) + blade_normal * (1.7 * sin(elapsed * 1.9 + n))
			var glint: Color = _gradient_at(fposmod(u + seed_phase + elapsed * 0.15 + hand_phase, 1.0)).lerp(Color.WHITE, 0.42)
			var alpha: float = 0.55 * power * glitter_pulse
			var wings: float = 1.4 + glitter_pulse * (1.2 + float(variant % 2))
			draw_line(spark - blade_normal * wings, spark + blade_normal * wings, Color(glint.r, glint.g, glint.b, alpha), 1.0, true)
			draw_line(spark - axis.normalized() * wings * 0.8, spark + axis.normalized() * wings * 0.8, Color.WHITE * Color(1.0, 1.0, 1.0, alpha * 0.68), 0.95, true)
			draw_circle(spark, 1.05, Color(1.0, 1.0, 1.0, alpha * 0.88))
		match variant:
			0:
				var comet: Vector2 = a.lerp(tip, fposmod(elapsed * 0.37 + seed_phase + hand_phase, 1.0))
				draw_circle(comet, 2.3, Color(shine.r, shine.g, shine.b, 0.32 * power))
			1:
				draw_circle(tip + blade_normal * sin(elapsed * 2.0 + hand_phase) * 2.6, 1.7, Color(1.0, 0.95, 1.0, 0.37 * power))
			2:
				draw_line(a.lerp(tip, 0.3) + blade_normal * 2.0, tip + blade_normal * 0.5, Color(shine.r, shine.g, shine.b, 0.31 * power), 0.9, true)
			_:
				draw_line(tip - blade_normal * 3.0, tip + blade_normal * 3.0, Color(shine.r, shine.g, shine.b, 0.34 * power), 1.0, true)

func _v1723_blade_segments(grip: Vector2, tip: Vector2, style: String) -> Array:
	var result: Array = []
	if style == "twinblade":
		var spans: Array[PackedVector2Array] = MODULAR.twinblade_spans(grip, tip)
		for span in spans:
			result.append([span[0], span[1]])
	elif style == "maul":
		result.append([grip.lerp(tip, 0.79), tip])
	elif style == "spear" or style == "halberd":
		result.append([grip.lerp(tip, 0.72), tip])
	elif style == "scythe":
		result.append([grip.lerp(tip, 0.66), tip])
	elif style == "dagger":
		result.append([grip.lerp(tip, 0.43), tip])
	else:
		result.append([grip.lerp(tip, 0.26), tip])
	return result


func _draw_v1723_twinblade_edges(grip: Vector2, tip: Vector2, _normal: Vector2, intensity: float) -> void:
	# Narrow bevel highlights, not broad luminous heads. Keep metal visible.
	var width: float = MODULAR.twinblade_width(item != null and item.definition != null and str(item.definition.item_id) == "rosemirror_twinblade_v170")
	for segment in _v1723_blade_segments(grip, tip, "twinblade"):
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		var direction: Vector2 = (b - a).normalized()
		var normal: Vector2 = Vector2(-direction.y, direction.x)
		var physical_profile: Dictionary = MODULAR.equipped_profile(self, body)
		if not physical_profile.is_empty():
			var chroma: Color = _gradient_at(fposmod(elapsed * 0.052 + (0.41 if direction.x < 0.0 else 0.06), 1.0))
			for side in [-1.0, 1.0]:
				var edge_path: PackedVector2Array = MODULAR.edge_points(a, b, width, physical_profile, side)
				var colors: Array[Color] = effect_palette
				ANOMALOUS.draw_edge(self, edge_path, colors, collector_look, elapsed, intensity)
				draw_polyline(edge_path, Color(chroma.r, chroma.g, chroma.b, 0.16 * minf(intensity, 2.0)), 2.2, true)
				draw_polyline(edge_path, Color(chroma.r, chroma.g, chroma.b, 0.55 * minf(intensity, 1.5)), 0.85, true)
			continue
		var taper: Vector2 = a.lerp(b, 0.76)
		var edge: Color = _gradient_at(fposmod(elapsed * 0.052 + (0.41 if direction.x < 0.0 else 0.06), 1.0)).lerp(Color.WHITE, 0.18)
		for side in [-1.0, 1.0]:
			var root_edge: Vector2 = a + normal * width * side
			var mid_edge: Vector2 = taper + normal * width * 0.72 * side
			draw_line(root_edge, mid_edge, Color(edge.r, edge.g, edge.b, 0.17 * minf(intensity, 2.0)), 2.5, true)
			draw_line(mid_edge, b, Color(edge.r, edge.g, edge.b, 0.17 * minf(intensity, 2.0)), 2.0, true)
			draw_line(root_edge, mid_edge, Color(edge.r, edge.g, edge.b, 0.58 * minf(intensity, 1.5)), 0.85, true)
			draw_line(mid_edge, b, Color(edge.r, edge.g, edge.b, 0.58 * minf(intensity, 1.5)), 0.85, true)

# Additional persistent, colorful MYTHIC-only halo. The loop is reproducible
# from cosmetic UID's existing visual_seed(); it never draws or modifies damage.
func _draw_v1723_mythic_sheen(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2, style: String, attacking: bool) -> void:
	if item == null or visual_signature_level not in [4, 5]:
		return
	var seed: int = item.visual_seed()
	var seed_shift: float = float(posmod(seed, 1009)) / 1009.0
	var variant: int = item.mythic_layer_variant()
	var pulse: float = 1.15 + 0.30 * sin(elapsed * 2.3 + seed_shift * TAU)
	var strength: float = clampf(visible_glow_strength * effect_intensity * pulse * (1.14 if attacking else 1.0), 0.8, 3.4)
	var segments: Array = []
	if item.get_slot() == "wand":
		# A luminous gemstone crown, not a white streak along the wand handle.
		segments.append([grip.lerp(tip, 0.84), tip])
	elif style == "bow":
		# When the user wants limb-only light, attach the rare filament to
		# the limbs instead of secretly illuminating a disabled string.
		var offset: Vector2 = normal * 5.0 if CHOICES_V216.bow_string_visible(item) else Vector2.ZERO
		segments.append([grip.lerp(tip, 0.14) + offset, grip.lerp(tip, 0.91) + offset])
	else:
		segments = _v1723_blade_segments(grip, tip, style)
	for segment_i in range(segments.size()):
		var blade_a: Vector2 = segments[segment_i][0]
		var blade_b: Vector2 = segments[segment_i][1]
		if item.get_slot() != "wand":
			_v175_mythic_signature(blade_a, blade_b, style, segment_i, attacking)
		var blade_dir: Vector2 = (blade_b - blade_a).normalized()
		var blade_normal: Vector2 = Vector2(-blade_dir.y, blade_dir.x)
		# Always-visible, breathing color sweep on the sharp portion only.
		for stripe_i in range(13):
			var u: float = float(stripe_i) / 12.0
			var at: Vector2 = blade_a.lerp(blade_b, u)
			var taper: float = maxf(0.14, sin((0.12 + u * 0.86) * PI))
			var travel: float = fposmod(u * 0.64 + elapsed * 0.105 + seed_shift + float(segment_i) * 0.29, 1.0)
			var color: Color = _gradient_at(travel).lerp(Color.WHITE, 0.14)
			draw_circle(at, (5.9 if style == "twinblade" else 7.0) * taper, Color(color.r, color.g, color.b, 0.055 * strength * taper))
			draw_circle(at, 2.6 * taper, Color(color.r, color.g, color.b, 0.10 * strength * taper))
			if stripe_i < 12:
				var next_at: Vector2 = blade_a.lerp(blade_b, float(stripe_i + 1) / 12.0)
				draw_line(at - blade_normal * 0.7, next_at - blade_normal * 0.7, Color(color.r, color.g, color.b, 0.39 * strength * taper), 1.45, true)
		# Glitter sparkles follow blade segments; no jittering in the hilt.
		for sparkle_i in range(6):
			var slot: float = float(sparkle_i)
			var u: float = fposmod(0.13 + slot * 0.17 + seed_shift * 0.13 + elapsed * (0.06 + slot * 0.002), 0.92)
			var brightness: float = pow(maxf(0.0, sin(elapsed * (2.5 + slot * 0.11) + seed_shift * TAU + slot * 2.37)), 2.0)
			if brightness < 0.14:
				continue
			var pos: Vector2 = blade_a.lerp(blade_b, u) + blade_normal * (sin(elapsed * 1.7 + slot) * 2.6)
			var gleam: Color = _gradient_at(fposmod(u + elapsed * 0.15 + seed_shift, 1.0)).lerp(Color.WHITE, 0.38)
			var alpha: float = 0.67 * strength * brightness
			var wing: float = 1.4 + brightness * (1.5 + float(variant % 2))
			draw_line(pos - blade_normal * wing, pos + blade_normal * wing, Color(gleam.r, gleam.g, gleam.b, alpha), 1.15, true)
			draw_line(pos - blade_dir * wing * 0.76, pos + blade_dir * wing * 0.76, Color(1.0, 0.99, 1.0, alpha * 0.82), 1.0, true)
			draw_circle(pos, 1.20, Color(1.0, 1.0, 1.0, 0.70 * strength * brightness))
		# Four cosmetic-UID variants add an occasional family-consistent flourish.
		var head_color: Color = _gradient_at(fposmod(0.85 + elapsed * 0.08 + seed_shift, 1.0))
		match variant:
			0: # Glass shiver: a narrow comet bead.
				var chase: Vector2 = blade_a.lerp(blade_b, fposmod(elapsed * 0.32 + seed_shift, 1.0))
				draw_circle(chase, 2.1, Color(head_color.r, head_color.g, head_color.b, 0.26 * strength))
			1: # Star dust: a tiny detached moon pearl at the point.
				draw_circle(blade_b + blade_normal * sin(elapsed * 2.1) * 2.5, 1.8, Color(1.0, 0.94, 1.0, 0.42 * strength))
			2: # Prism sheen: a second traveling filament on the cutting edge.
				draw_line(blade_a.lerp(blade_b, 0.28) + blade_normal * 1.4, blade_b + blade_normal * 0.4, Color(head_color.r, head_color.g, head_color.b, 0.30 * strength), 0.9, true)
			_: # Moonburn: delicate point flare, not an oversized aura ring.
				draw_line(blade_b - blade_normal * 3.1, blade_b + blade_normal * 3.1, Color(head_color.r, head_color.g, head_color.b, 0.35 * strength), 1.0, true)

func _draw_v172_named_weapon_fx(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2, attacking: bool, power: float) -> void:
	# Item-specific cosmetic additions. This routine draws no hitboxes and does
	# not alter rolls or the saved UID; all motion derives from existing seeds.
	if item == null or item.definition == null:
		return
	var weapon_id: String = str(item.definition.item_id)
	if weapon_id not in ["nocturne_stiletto_v171", "briarwake_trident_v171"]:
		return
	var mythic: bool = visual_signature_level in [4, 5]
	var seed_phase: float = float(posmod(item.visual_seed(), 997)) / 997.0 * TAU
	var shimmer: float = 0.70 + 0.30 * sin(elapsed * 1.65 + seed_phase)
	if weapon_id == "nocturne_stiletto_v171":
		# Nightglass: a thin cold edge, kept close to the SHORT dagger blade.
		var ink: Color = _gradient_at(0.8)
		var a: Vector2 = grip.lerp(tip, 0.58)
		draw_line(a, tip, Color(ink.r, ink.g, ink.b, 0.18 * power * shimmer), 1.15, true)
		_soft_orb(tip, 2.1, ink, power * 0.40)
		if mythic:
			var phase: float = fposmod(elapsed + seed_phase, 3.1)
			if phase < (0.56 if attacking else 0.26):
				var shift: float = 2.0 + float(item.mythic_layer_variant()) * 0.6
				var ghost_edge: Vector2 = normal * shift
				draw_line(a + ghost_edge, tip + ghost_edge, Color(ink.r, ink.g, ink.b, 0.29 * power), 1.1, true)
				draw_line(tip - tangent * 4.0, tip + normal * (2.0 + shift), Color(0.92, 0.92, 1.0, 0.25 * power), 0.9, true)
	else:
		# Briarwake: light runs up the haft toward its garnet three-pronged head.
		var garnet: Color = _gradient_at(0.86)
		var run: float = fposmod(elapsed * 0.23 + seed_phase / TAU, 1.0)
		var shaft_point: Vector2 = grip.lerp(tip, 0.36 + 0.54 * run)
		draw_line(grip.lerp(tip, 0.42), tip, Color(garnet.r, garnet.g, garnet.b, 0.10 * power), 1.1, true)
		draw_circle(shaft_point, 1.3, Color(garnet.r, garnet.g, garnet.b, 0.22 * power))
		_soft_orb(tip, 3.1, garnet, power * 0.53)
		if mythic:
			for prong in [-1.0, 0.0, 1.0]:
				var head_a: Vector2 = tip - tangent * 5.0 + normal * prong * 2.2
				var head_b: Vector2 = tip + normal * prong * (3.5 + float(item.mythic_layer_variant()) * 0.28)
				draw_line(head_a, head_b, Color(garnet.r, garnet.g, garnet.b, 0.22 * power * shimmer), 0.9, true)
			if attacking:
				var petal_at: Vector2 = tip - tangent * 1.5 + normal * sin(elapsed * 2.3 + seed_phase) * 3.5
				draw_circle(petal_at, 1.5, Color(1.0, 0.87, 0.94, 0.42 * power))

func _bow_string_at(t: float) -> Color:
	var u: float = clampf(t, 0.0, 1.0)
	return GhostCosmeticRNGV152.sample_palette(bow_string_colors, u)

# Expanded light is a separate decoration riding the same carried-bow
# coordinates. No collision, attack or extra magic-projectile behavior.
func _draw_full_bow_aura(grip: Vector2, tip: Vector2, normal: Vector2, power: float) -> void:
	for i in range(19):
		var u: float = 0.08 + 0.86 * float(i) / 18.0
		var point: Vector2 = grip.lerp(tip, u) + normal * sin(u * TAU) * 4.1
		var ink: Color = _gradient_at(u)
		var taper: float = maxf(0.18, sin(u * PI))
		draw_circle(point, 7.2 * taper, Color(ink.r, ink.g, ink.b, 0.060 * power * taper))
		draw_circle(point, 3.1 * taper, Color(ink.r, ink.g, ink.b, 0.105 * power * taper))

func _draw_v216_visible_fallback(grip: Vector2, tip: Vector2, intensity: float) -> void:
	var color: Color = _gradient_at(0.72)
	var power: float = clampf(intensity, 0.0, 1.6)
	var root: Vector2 = grip.lerp(tip, 0.35)
	draw_line(root, tip, Color(color.r, color.g, color.b, 0.20 * power), 5.6, true)
	draw_line(root, tip, Color(color.r, color.g, color.b, 0.48 * power), 1.5, true)
	draw_circle(tip, 2.0, Color(color.r, color.g, color.b, 0.31 * power))

func _draw_bow_dual_glow(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2, intensity: float) -> void:
	# Two independent RNG gradients: preserved painted limbs + luminous string.
	# Limbs use soft S-shaped enamel highlights; avoid a thick one-line shard.
	var power: float = minf(intensity, 1.65)
	var string_visible: bool = CHOICES_V216.bow_string_visible(item)
	for i in range(18):
		var u: float = 0.12 + 0.82 * float(i) / 17.0
		var taper: float = maxf(0.16, sin(u * PI))
		var center: Vector2 = grip.lerp(tip, u)
		var limb_curve: float = sin(u * TAU) * 4.1
		var colored: Color = _gradient_at(u)
		var limb: Vector2 = center + normal * limb_curve
		draw_circle(limb, (3.2 + 1.5 * taper), Color(colored.r, colored.g, colored.b, 0.038 * power))
		draw_circle(limb, (1.35 + 0.6 * taper), Color(colored.r, colored.g, colored.b, 0.11 * power))
		if not string_visible:
			continue
		var filament_color: Color = _bow_string_at(u)
		# Move the string light behind the limbs, following the real string.
		var string_at: Vector2 = center + normal * 5.0
		draw_circle(string_at, 2.3 * taper, Color(filament_color.r, filament_color.g, filament_color.b, 0.025 * power))
		draw_circle(string_at, maxf(0.65, 1.05 * taper), Color(filament_color.r, filament_color.g, filament_color.b, 0.13 * power))
	if not string_visible:
		return
	# Fine uninterrupted string filament; no thick colored shard.
	var string_a: Vector2 = grip.lerp(tip, 0.13) + normal * 5.0
	var string_b: Vector2 = grip.lerp(tip, 0.91) + normal * 5.0
	var string_middle: Color = _bow_string_at(0.52)
	draw_line(string_a, string_b, Color(string_middle.r, string_middle.g, string_middle.b, 0.18 * power), 1.1, true)
	var end_color: Color = _gradient_at(0.95)
	_soft_orb(tip, 3.0, end_color, power * 0.8)

# Rare cosmetics remain independently rolled but no longer produce the hard,
# geometric fans that were hovering behind Ghost Girl's hair in v1.53.
func _draw_signature(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2, attacking: bool, power: float) -> void:
	var sig: int = visual_signature_level
	var center: Vector2 = grip.lerp(tip, 0.78)
	var strength: float = power * (1.20 if attacking else 0.77)
	if sig == 4:
		strength *= 1.35
	var c1: Color = paint_a.lerp(Color.WHITE, 0.20)
	var c2: Color = paint_c.lerp(Color.WHITE, 0.30)
	var length: float = tip.distance_to(grip)
	if sig == 5:
		# Moonfall Halo: two fine, color-shifting rails and living glints.
		# Unlike the older hard fan shapes, every bloom is rounded/tapered.
		for j in range(18):
			var u: float = 0.19 + 0.78 * float(j) / 17.0
			var at: Vector2 = grip.lerp(tip, u)
			var taper: float = maxf(0.16, sin(u * PI))
			var oscillation: float = sin(elapsed * 3.3 + u * 12.0) * 1.6
			var light: Color = _gradient_at(fposmod(u + elapsed * 0.055, 1.0))
			for side in [-1.0, 1.0]:
				var pos: Vector2 = at + normal * (2.5 * side + oscillation)
				draw_circle(pos, 4.8 * taper, Color(light.r, light.g, light.b, 0.024 * strength))
				draw_circle(pos, 1.8 * taper, Color(light.r, light.g, light.b, 0.16 * strength))
			if j % 6 == 0:
				_soft_orb(at + normal * oscillation, 3.2, light, strength * 0.95)
		var filament: Color = _gradient_at(fposmod(0.38 + elapsed * 0.06, 1.0))
		draw_line(grip.lerp(tip, 0.21), grip.lerp(tip, 0.96), Color(filament.r, filament.g, filament.b, 0.23 * strength), 1.6, true)
	elif sig == 4:
		_draw_mythic_signature(grip, tip, tangent, normal, strength, attacking)
	elif sig == 1:
		# Aether Thorns: narrow spectral wind, close to the silhouette.
		for k in range(9):
			var u: float = 0.26 + 0.67 * float(k) / 8.0
			var base: Vector2 = grip.lerp(tip, u)
			var drift: Vector2 = normal * sin(elapsed * 2.4 + u * 12.0) * 2.7
			draw_circle(base + drift, 1.2 + 0.7 * sin(u * PI), Color(c1.r, c1.g, c1.b, 0.16 * strength))
	elif sig == 2:
		# Void Eclipse: two restrained, slow arcs hugging the weapon tip.
		draw_arc(center, 6.2, elapsed * 0.7, elapsed * 0.7 + PI * 1.15, 22, Color(c2.r, c2.g, c2.b, 0.24 * strength), 1.15, true)
		draw_arc(center, 8.0, -elapsed * 0.45, -elapsed * 0.45 + PI * 0.84, 22, Color(c1.r, c1.g, c1.b, 0.15 * strength), 1.0, true)
	else:
		# Astral Seraph: pearls and tiny starlight at the edge, no wing polygon.
		for k in range(7):
			var u: float = 0.35 + 0.55 * float(k) / 6.0
			var at: Vector2 = grip.lerp(tip, u) + normal * sin(elapsed * 1.9 + float(k) * 1.7) * 3.8
			var star: Color = _gradient_at(u)
			draw_circle(at, 2.1, Color(star.r, star.g, star.b, 0.20 * strength))
			if k % 3 == 0:
				draw_line(at - tangent * 3.5, at + tangent * 3.5, Color(star.r, star.g, star.b, 0.24 * strength), 0.9, true)
		draw_circle(tip, 3.0, Color(1.0, 0.95, 1.0, 0.37 * strength))


# v1.64.2: distinctive mythic geometry for *each* weapon family.
# This is intentionally not just a stronger copy of the ordinary axial glow.
func _draw_mythic_signature(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2, strength: float, attacking: bool) -> void:
	var bright: Color = paint_b.lerp(Color.WHITE, 0.56)
	var rim: Color = paint_a.lerp(paint_c, 0.50).lightened(0.22)
	var phase: float = elapsed * 1.55
	var focus: Vector2 = grip.lerp(tip, 0.96)
	var style: String = item.weapon_style()
	if item.get_slot() == "wand":
		# Wand: an identifiable floating crystal crown, not a sword beam.
		var radius: float = (11.8 + 0.8 * sin(phase * 0.5)) * 1.20
		_soft_orb(focus, 11.0, rim, strength * 1.5)
		draw_arc(focus, radius, phase * 0.34, phase * 0.34 + PI * 1.47, 36, Color(rim.r, rim.g, rim.b, 0.66 * strength), 2.25, true)
		draw_arc(focus, radius - 3.0, -phase * 0.25, -phase * 0.25 + PI * 1.11, 32, Color(bright.r, bright.g, bright.b, 0.36 * strength), 1.4, true)
		for k in range(3):
			var angle: float = phase * 0.65 + float(k) * TAU / 3.0
			var star: Vector2 = focus + Vector2(cos(angle), sin(angle)) * radius
			draw_circle(star, 2.1, Color(1.0, 1.0, 1.0, 0.65 * strength))
			draw_circle(star, 4.3, Color(rim.r, rim.g, rim.b, 0.10 * strength))
		draw_line(grip.lerp(tip, 0.45), tip, Color(bright.r, bright.g, bright.b, 0.60 * strength), 1.65, true)
		draw_circle(focus, 2.3, Color(1.0, 0.98, 1.0, 0.78 * strength))
	elif style == "bow":
		# Bow mythic: unmistakably brighter than the regular prestige look,
		# but still attached to the bow silhouette rather than floating away.
		var start: Vector2 = grip.lerp(tip, 0.10) + normal * 5.0
		var endp: Vector2 = grip.lerp(tip, 0.98) + normal * 5.0
		var center: Vector2 = grip.lerp(tip, 0.56)
		var string_middle: Color = _bow_string_at(0.52)
		draw_line(start, endp, Color(string_middle.r, string_middle.g, string_middle.b, 0.41 * strength), 1.55, true)
		draw_line(start, endp, Color(1.0, 1.0, 1.0, 0.12 * strength), 0.65, true)
		for side in [-1.0, 1.0]:
			var rail_a: Vector2 = grip.lerp(tip, 0.21) + normal * side * 4.2
			var rail_b: Vector2 = grip.lerp(tip, 0.90) + normal * side * 2.1
			draw_line(rail_a, rail_b, Color(rim.r, rim.g, rim.b, 0.42 * strength), 3.7, true)
			draw_line(rail_a, rail_b, Color(bright.r, bright.g, bright.b, 0.22 * strength), 1.35, true)
		var nock: Vector2 = grip.lerp(tip, 0.19)
		_soft_orb(nock, 6.2, rim, strength * 1.65)
		_soft_orb(endp, 4.7, bright, strength * 1.40)
		var pulse: Vector2 = center + tangent * sin(phase * 1.2) * 2.0
		draw_circle(pulse, 5.2, Color(rim.r, rim.g, rim.b, 0.08 * strength))
		draw_circle(pulse, 1.8, Color(1.0, 1.0, 1.0, 0.88 * strength))
		for spark_i in range(4):
			var u: float = 0.29 + 0.17 * float(spark_i)
			var spark: Vector2 = grip.lerp(tip, u) + normal * sin(phase * 1.9 + float(spark_i) * 0.9) * 1.9
			draw_circle(spark, 1.35, Color(bright.r, bright.g, bright.b, 0.44 * strength))
		for comet_i in range(2):
			var v: float = fposmod(phase * 0.14 + float(comet_i) * 0.47, 1.0)
			var comet: Vector2 = grip.lerp(tip, 0.26 + v * 0.54)
			draw_line(comet - tangent * 3.0, comet + tangent * 3.0, Color(rim.r, rim.g, rim.b, 0.20 * strength), 1.0, true)
			draw_circle(comet, 1.7, Color(1.0, 1.0, 1.0, 0.56 * strength))
	elif style == "twinblade":
		# Mythic twinblades energize both heads and the center grip.
		var axis: Vector2 = tip - grip
		var fore_start: Vector2 = grip.lerp(tip, 0.10)
		var fore_end: Vector2 = grip.lerp(tip, 0.98)
		var aft_tip: Vector2 = grip - axis * 0.70
		var aft_start: Vector2 = grip.lerp(aft_tip, 0.16)
		var joint: Vector2 = grip.lerp(tip, 0.34)
		for seg in [[fore_start, fore_end], [aft_start, aft_tip]]:
			var a: Vector2 = seg[0]
			var b: Vector2 = seg[1]
			for beam_i in range(8):
				var u: float = float(beam_i) / 7.0
				var at: Vector2 = a.lerp(b, u)
				var taper: float = maxf(0.18, sin((u * 0.86 + 0.14) * PI))
				draw_circle(at, 4.8 * taper, Color(rim.r, rim.g, rim.b, 0.036 * strength))
				draw_circle(at, 2.2 * taper, Color(bright.r, bright.g, bright.b, 0.12 * strength))
			draw_line(a, b, Color(bright.r, bright.g, bright.b, 0.42 * strength), 1.4, true)
		draw_arc(joint, 5.0, phase * 0.7, phase * 0.7 + PI * 1.4, 26, Color(rim.r, rim.g, rim.b, 0.18 * strength), 1.0, true)
		_soft_orb(fore_end, 4.8, bright, strength * 1.35)
		_soft_orb(aft_tip, 4.8, bright, strength * 1.25)
	elif style == "maul":
		# Mythic mauls: the head gets an inner furnace glow and falling sparks.
		var haft_top: Vector2 = grip.lerp(tip, 0.72)
		_soft_orb(tip, 8.0, rim, strength * 1.95)
		_soft_orb(tip, 4.1, bright, strength * 1.45)
		draw_line(haft_top, tip, Color(bright.r, bright.g, bright.b, 0.20 * strength), 2.0, true)
		for crack_i in range(3):
			var off: float = -3.0 + float(crack_i) * 3.0
			var a: Vector2 = tip + normal * off - tangent * 4.0
			var b: Vector2 = tip + normal * off * 0.6 + tangent * 2.0
			draw_line(a, b, Color(1.0, 0.98, 1.0, 0.32 * strength), 0.9, true)
		for ember_i in range(3):
			var e: Vector2 = tip + normal * (-4.0 + 4.0 * ember_i) + Vector2(0.0, 1.5 + 1.1 * ember_i)
			draw_circle(e, 1.2, Color(bright.r, bright.g, bright.b, 0.34 * strength))
	elif style == "dagger":
		# Mythic daggers: tight assassin edge with brief afterimage stabs.
		var start: Vector2 = grip.lerp(tip, 0.45)
		var endp: Vector2 = tip
		draw_line(start, endp, Color(rim.r, rim.g, rim.b, 0.24 * strength), 3.0, true)
		draw_line(start, endp, Color(bright.r, bright.g, bright.b, 0.60 * strength), 1.2, true)
		draw_line(start - tangent * 2.2, endp - tangent * 2.2, Color(rim.r, rim.g, rim.b, 0.10 * strength), 0.9, true)
		_soft_orb(endp, 3.6, bright, strength * 1.18)
	elif style == "spear":
		# Mythic spears: a longer comet-like point and shaft thread.
		var shaft_a: Vector2 = grip.lerp(tip, 0.18)
		var shaft_b: Vector2 = grip.lerp(tip, 0.97)
		draw_line(shaft_a, shaft_b, Color(rim.r, rim.g, rim.b, 0.15 * strength), 1.2, true)
		draw_line(grip.lerp(tip, 0.72), shaft_b, Color(bright.r, bright.g, bright.b, 0.56 * strength), 1.6, true)
		var head_mid: Vector2 = grip.lerp(tip, 0.90)
		draw_arc(head_mid, 4.6, phase * 0.52, phase * 0.52 + PI * 0.92, 20, Color(rim.r, rim.g, rim.b, 0.16 * strength), 0.95, true)
		_soft_orb(tip, 4.2, bright, strength * 1.28)
	else:
		# Swords and long weapons: keep the laser-sword fantasy, but taper it
		# into a softer enchanted edge instead of a blocky square-ended bar.
		var start: Vector2 = grip.lerp(tip, 0.20)
		var endp: Vector2 = grip.lerp(tip, 0.99)
		for beam_i in range(12):
			var u: float = float(beam_i) / 11.0
			var at: Vector2 = start.lerp(endp, u)
			var taper: float = 0.28 + 0.72 * sin((u * 0.85 + 0.15) * PI * 0.5)
			draw_circle(at, 8.2 * taper, Color(rim.r, rim.g, rim.b, 0.032 * strength))
			draw_circle(at, 4.9 * taper, Color(rim.r, rim.g, rim.b, 0.058 * strength))
			draw_circle(at, 2.2 * taper, Color(bright.r, bright.g, bright.b, 0.122 * strength))
		for rail_i in range(14):
			var u: float = float(rail_i) / 14.0
			var v: float = float(rail_i + 1) / 14.0
			var taper: float = maxf(0.10, sin((u * 0.82 + 0.08) * PI))
			var ink: Color = _gradient_at(u)
			draw_line(start.lerp(endp, u), start.lerp(endp, v), Color(ink.r, ink.g, ink.b, 0.20 * strength * taper), 3.0 * taper, true)
			draw_line(start.lerp(endp, u), start.lerp(endp, v), Color(1.0, 0.99, 1.0, 0.47 * strength * taper), 1.15 * taper, true)
		var chase: float = fposmod(elapsed * (0.43 if attacking else 0.22), 0.72) + 0.23
		var comet: Vector2 = grip.lerp(tip, chase)
		_soft_orb(comet, 4.3, bright, strength * 1.55)
		_soft_orb(endp, 7.2, rim, strength * 2.05)
		for side in [-1.0, 1.0]:
			var sparkle: Vector2 = endp + normal * side * 6.2
			draw_line(endp, sparkle, Color(bright.r, bright.g, bright.b, 0.33 * strength), 0.9, true)
		draw_circle(endp, 2.5, Color(1.0, 1.0, 1.0, 0.86 * strength))

	_draw_mythic_seed_variant(grip, tip, tangent, normal, strength, attacking, style)

func _draw_mythic_seed_variant(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2, strength: float, attacking: bool, style: String) -> void:
	if item == null:
		return
	var variant: int = item.mythic_layer_variant()
	var cadence: float = 3.1 + float(variant) * 0.47
	var offset: float = float(posmod(item.visual_seed(), 431)) / 431.0 * cadence
	# Brief reproducible sparks, rather than permanently busy particles.
	if fposmod(elapsed + offset, cadence) > (0.54 if attacking else 0.34):
		return
	var phase: float = elapsed * (1.9 if attacking else 1.45) + float(posmod(item.visual_seed(), 251)) / 251.0 * TAU
	var c_hot: Color = paint_b.lerp(Color.WHITE, 0.48)
	var c_rim: Color = paint_a.lerp(paint_c, 0.50).lightened(0.16)
	match variant:
		0:
			# Lightning sparks
			for branch in range(2 if attacking else 1):
				var u: float = 0.34 + 0.24 * float(branch) + 0.06 * sin(phase + float(branch))
				var root: Vector2 = grip.lerp(tip, clampf(u, 0.26, 0.88))
				var dir: Vector2 = normal.rotated(0.18 * sin(phase * 0.8 + float(branch)))
				var prev: Vector2 = root
				for step in range(3):
					var jitter: float = 1.0 if step % 2 == 0 else -1.0
					var nxt: Vector2 = prev + tangent * (1.8 + float(step) * 0.6) + dir * jitter * (2.4 - float(step) * 0.45)
					draw_line(prev, nxt, Color(0.86, 0.96, 1.0, 0.36 * strength), 1.0, true)
					prev = nxt
				draw_circle(prev, 1.5, Color(1.0, 1.0, 1.0, 0.56 * strength))
		1:
			# Ember motes / cinders
			for mote_i in range(3):
				var u: float = 0.28 + 0.20 * float(mote_i)
				var drift: Vector2 = normal * sin(phase * 1.1 + float(mote_i) * 1.7) * (3.0 + float(mote_i))
				var p: Vector2 = grip.lerp(tip, u + 0.05 * sin(phase + float(mote_i))) + drift
				var ink: Color = _gradient_at(fposmod(0.22 * float(mote_i) + elapsed * 0.05, 1.0))
				draw_circle(p, 2.0, Color(ink.r, ink.g, ink.b, 0.16 * strength))
				draw_line(p - tangent * 2.4, p + tangent * 1.2, Color(ink.r, ink.g, ink.b, 0.12 * strength), 0.9, true)
		2:
			# Star pulse / moonlets
			var center: Vector2 = grip.lerp(tip, 0.74)
			draw_arc(center, 5.2 + 0.7 * sin(phase), phase * 0.24, phase * 0.24 + PI * 0.88, 20, Color(c_rim.r, c_rim.g, c_rim.b, 0.16 * strength), 1.0, true)
			for star_i in range(2):
				var ang: float = phase * 0.9 + float(star_i) * PI
				var p: Vector2 = center + Vector2(cos(ang), sin(ang)) * 4.6
				draw_circle(p, 1.2, Color(1.0, 1.0, 1.0, 0.52 * strength))
				draw_circle(p, 2.8, Color(c_hot.r, c_hot.g, c_hot.b, 0.07 * strength))
		_:
			# Wisps / petal drift
			for petal_i in range(3):
				var u: float = 0.31 + 0.18 * float(petal_i)
				var p: Vector2 = grip.lerp(tip, u) + normal * sin(phase * 0.8 + float(petal_i) * 1.6) * 4.2
				var petal: Color = _gradient_at(fposmod(0.15 + float(petal_i) * 0.21 + elapsed * 0.04, 1.0))
				draw_circle(p + tangent * 0.6, 1.4, Color(petal.r, petal.g, petal.b, 0.15 * strength))
				draw_circle(p - tangent * 0.6, 1.0, Color(petal.r, petal.g, petal.b, 0.18 * strength))
				draw_line(p - tangent * 1.8, p + tangent * 0.5, Color(petal.r, petal.g, petal.b, 0.10 * strength), 0.8, true)

func _soft_orb(center: Vector2, radius: float, color: Color, alpha_scale: float) -> void:
	draw_circle(center, radius * 2.0, Color(color.r, color.g, color.b, 0.012 * alpha_scale))
	draw_circle(center, radius * 1.35, Color(color.r, color.g, color.b, 0.024 * alpha_scale))
	draw_circle(center, radius * 0.72, Color(color.r, color.g, color.b, 0.070 * alpha_scale))
	draw_circle(center, maxf(1.0, radius * 0.22), Color(color.r, color.g, color.b, 0.145 * alpha_scale))

func _draw_socketed_jewel_echo(grip: Vector2, tip: Vector2, normal: Vector2) -> void:
	# Visual only. No attacks, stats, or additional damage are generated here.
	if item == null or item.socketed.is_empty():
		return
	var offset: int = 0
	for entry in item.socketed:
		if not (entry is Dictionary):
			continue
		var jewel_id: String = str(entry.get("id", ""))
		var tint: Color = Color.TRANSPARENT
		match jewel_id:
			"malady_jewel": tint = Color("e38a9f")
			"delirium_jewel": tint = Color("98c5f4")
			"exile_jewel": tint = Color("efd5a1")
			_: continue
		var u: float = 0.32 + 0.18 * float(offset % 3)
		var center: Vector2 = grip.lerp(tip, u)
		var drift: Vector2 = normal * sin(elapsed * (0.77 + 0.12 * offset)) * 2.7
		var at: Vector2 = center + drift
		draw_circle(at, 4.8, Color(tint.r, tint.g, tint.b, 0.025))
		draw_circle(at, 1.6, Color(tint.r, tint.g, tint.b, 0.24))
		draw_circle(at, 0.8, Color(1.0, 1.0, 1.0, 0.26))
		if jewel_id == "malady_jewel":
			draw_line(at - normal * 2.0, at + normal * 2.0, Color(tint.r, tint.g, tint.b, 0.31), 0.85, true)
		elif jewel_id == "delirium_jewel":
			var spark: Vector2 = at + Vector2(cos(elapsed * 0.85), sin(elapsed * 0.85)) * 3.6
			draw_circle(spark, 0.8, Color(tint.r, tint.g, tint.b, 0.23))
		else:
			draw_line(at + Vector2(-1.6, 0), at + Vector2(1.6, 0), Color(tint.r, tint.g, tint.b, 0.27), 0.75, true)
		offset += 1

func _draw_ambient_fireflies(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2, power: float) -> void:
	# v1.64 subtle rarity ambience: tiny firefly-like motes, inspired by the
	# environment particles, for rarer/cosmetic-seeded gear.
	if rarity_tier < 2 and visual_signature_level <= 0:
		return
	for i in range(3 + (1 if visual_signature_level > 0 else 0)):
		var phase: float = elapsed * (0.34 + float(i) * 0.05) + float(i) * 1.9 + float(item.visual_seed() % 137) / 137.0 * TAU
		var span_u: float = 0.18 + 0.18 * float(i)
		var base: Vector2 = grip.lerp(tip, minf(0.92, span_u))
		var p: Vector2 = base + normal * sin(phase) * (4.0 + float(i) * 1.1) + tangent * cos(phase * 0.73) * (2.0 + float(i) * 0.4)
		var c: Color = _gradient_at(fposmod(0.21 * float(i) + elapsed * 0.03, 1.0))
		var glow: float = 0.45 + 0.55 * (0.5 + 0.5 * sin(phase * 2.4))
		draw_circle(p, 3.5, Color(c.r, c.g, c.b, 0.007 * power * glow))
		draw_circle(p, 1.7, Color(c.r, c.g, c.b, 0.018 * power * glow))
		draw_circle(p, 0.9 + 0.25 * float(i % 2), Color(c.r, c.g, c.b, 0.11 * power * glow))

func _draw_wand_hold_cosmetics(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2, attacking: bool, power: float) -> void:
	# v1.55 — held-wand cosmetics stay close to the silhouette: crystal head,
	# lantern-soft bloom, suspended motes and a compact magical accent that
	# varies by the wand's cosmetic roll. This is visible while held, not only
	# while casting.
	var fx: Dictionary = item.effect_rolls()
	var form: int = int(fx.get("form", 0))
	var motif: int = int(fx.get("motif", 0))
	var seed_phase: float = float(posmod(item.visual_seed(), 2048)) / 2048.0
	var mid: Vector2 = grip.lerp(tip, 0.58)
	var head: Vector2 = grip.lerp(tip, 0.94)
	var base_alpha: float = power * (1.22 if attacking else 0.94)
	# Crystal / wand head emphasis.
	_soft_orb(head, 6.2, _gradient_at(0.16 + seed_phase * 0.18), base_alpha)
	_soft_orb(head + normal * 1.8, 3.2, _gradient_at(0.72), base_alpha * 0.9)
	if attacking:
		# Spell preparation tightens the light into the gemstone; the actual
		# release flash remains owned by wand_release_fx_v156.gd.
		var focus: float = 0.66 + 0.34 * sin(elapsed * 11.0)
		var glow: Color = _gradient_at(fposmod(seed_phase + elapsed * 0.09, 1.0))
		_soft_orb(head, 7.6, glow, 1.2 * power * focus)
		draw_arc(head, 5.0 + 0.8 * focus, elapsed * 0.5, elapsed * 0.5 + PI * 1.4, 24, Color(glow.r, glow.g, glow.b, 0.17 * focus), 1.1, true)
	# A tiny handle charm near the grip keeps the wand looking intentionally adorned.
	var charm: Vector2 = grip.lerp(tip, 0.22) - tangent * 1.2 + normal * 1.7
	var charm_color: Color = _gradient_at(0.44)
	draw_circle(charm, 1.8, Color(charm_color.r, charm_color.g, charm_color.b, 0.18 * base_alpha))
	draw_line(charm, charm + Vector2(0, 4.0), Color(charm_color.r, charm_color.g, charm_color.b, 0.12 * base_alpha), 0.8, true)
	# Restore the luminous gemstone core alongside the new motion path.
	var shine: Color = _gradient_at(fposmod(seed_phase + elapsed * 0.06, 1.0))
	_soft_orb(head, 8.4, shine, base_alpha * 0.8)
	draw_arc(head, 4.8, elapsed * 0.36, elapsed * 0.36 + PI * 1.3, 24, Color(shine.r, shine.g, shine.b, 0.24 * base_alpha), 1.0, true)
	# The existing cosmetic particle ticket now chooses distinct motion paths.
	preload("res://scripts/weapon_particle_paths_v244.gd").draw_pattern(self, head, tangent, Vector2(8.0, 10.0), effect_palette, collector_look, elapsed, minf(base_alpha, 1.35))
	if rarity_tier >= 2:
		# Always-visible runic dust for rarer wands.
		for i in range(4):
			var t: float = elapsed * (0.42 + float(i) * 0.05) + float(i) * 1.7 + seed_phase * TAU
			var offset: Vector2 = normal * sin(t) * (3.0 + float(i) * 0.35) + tangent * cos(t * 0.7) * 1.5
			var at: Vector2 = head - tangent * (2.0 + float(i)) + offset
			var c: Color = _gradient_at(fposmod(seed_phase + float(i) * 0.19, 1.0))
			draw_circle(at, 0.95 + 0.22 * float(i % 2), Color(c.r, c.g, c.b, 0.18 * base_alpha))

# Small independent material accents, visible on the cutting region only.
# The physical shape/material replacement for all weapon families follows in v1.78.
func _draw_v177_collector_finish(grip: Vector2, tip: Vector2, style: String, intensity: float) -> void:
	var tier: int = int(collector_look.get("material", 0))
	var particle_tier: int = int(collector_look.get("particle_tier", 0))
	var finish: int = int(collector_look.get("finish", 0))
	var pattern: int = int(collector_look.get("pattern", 0))
	var particle: int = int(collector_look.get("particle", 0))
	var colors: Array = collector_look.get("accent_colors", [])
	if colors.size() < 3:
		return
	var segments: Array = _v1723_blade_segments(grip, tip, style)
	if style in ["bow", "wand"]:
		# Restrict the new accents to the tip/gem; existing bowstring is separate.
		segments = [[grip.lerp(tip, 0.86), tip]]
	for segment in segments:
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		if style != "twinblade":
			var shift_colors: Array[Color] = effect_palette
			ANOMALOUS.draw_edge(self, PackedVector2Array([a, b]), shift_colors, collector_look, elapsed, intensity)
		var axis: Vector2 = (b - a).normalized()
		var normal: Vector2 = Vector2(-axis.y, axis.x)
		var tone: Color = colors[finish % colors.size()]
		if tier >= 1:
			var count: int = 2 + mini(tier, 4)
			for j in range(count):
				var u: float = (float(j) + 0.5) / float(count)
				if tier >= 3:
					u = fposmod(u + elapsed * 0.045 * float(1 + pattern % 3), 1.0)
				var at: Vector2 = a.lerp(b, u)
				var half: float = 1.0 + float(finish % 3) * 0.45
				draw_line(at - normal * half, at + normal * half, Color(tone.r, tone.g, tone.b, 0.16 * minf(intensity, 1.8)), 0.8, true)
		if particle_tier >= 2:
			for j in range(1 + mini(particle_tier, 4)):
				var u: float = fposmod(float(j) * 0.31 + elapsed * 0.12 + float(pattern) * 0.07, 1.0)
				var at: Vector2 = a.lerp(b, u) + normal * sin(u * TAU + float(particle)) * (1.5 + float(particle_tier) * 0.6)
				var alpha: float = sin(u * PI) * 0.55
				var ink: Color = colors[(j + particle) % colors.size()]
				if particle % 2 == 0:
					draw_circle(at, 0.8 + float(particle_tier) * 0.16, Color(ink.r, ink.g, ink.b, alpha))
				else:
					draw_line(at - axis * 1.8, at + axis * 1.8, Color(ink.r, ink.g, ink.b, alpha), 0.8, true)
