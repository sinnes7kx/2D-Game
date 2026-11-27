extends AnimatedSprite2D
## Aligned *only-bow* texture masks colorized by an item-seeded shader.
## The baked bow underneath remains visible if this node cannot load.
const SHADE: Shader = preload("res://assets/equipment/weapon_surface_v190.gdshader")
const WEAPON_SURFACE = preload("res://scripts/weapon_surface_v190.gd")
const STEADY_IDLE = preload("res://scripts/steady_weapon_idles_v195.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const DIAGONAL_V270 = preload("res://scripts/ghost_diagonal_art_v247.gd")
var inventory: Node = null
var body: AnimatedSprite2D = null
var last_bow_cosmetic_key: String = ""
@onready var bow_carry_visual: AnimatedSprite2D = get_parent().get_node_or_null("BowCarryV166") as AnimatedSprite2D
const CARRY_ATLASES: Dictionary = {
	"thornrose": "res://assets/equipment/bows_v166/thornrose_carry_only_2048x1760.png",
	"moonveil": "res://assets/equipment/bows_v166/moonveil_carry_only_2048x1760.png"
}

func _bow_style_name(item: GhostItemInstance) -> String:
	return item.bow_art_style() if item != null else "thornrose"

func _resolved_animation_name(item: GhostItemInstance, animation_name: String) -> String:
	# Aerial strike clips preserve the exact same painted bow and recolor mask.
	# Normalize only lookup names, never the physical bow or child FX pivot.
	if animation_name.contains("_air_"):
		animation_name = animation_name.replace("_air_", "_")
	if sprite_frames != null and sprite_frames.has_animation(animation_name):
		return animation_name
	var style: String = _bow_style_name(item)
	if animation_name.begins_with("idle_") or animation_name.begins_with("walk_"):
		var motion: String = "walk" if animation_name.begins_with("walk_") else "idle"
		var face: String = "front"
		for suffix in ["front", "back", "left", "right"]:
			if animation_name.ends_with(suffix):
				face = suffix
				break
		# v1.69: use the actual directional art; never mirror the physical bow.
		return style + "_" + motion + "_" + face
	return animation_name

func _should_flip_for_animation(animation_name: String) -> bool:
	# Mirror the BOW-ONLY right-side graphic, never Ghost Girl herself.
	return animation_name.ends_with("_left")

func _carry_transform_for_animation(source_animation: String, frame_index: int) -> Dictionary:
	if source_animation.begins_with("attack_"):
		return {"position": Vector2.ZERO, "rotation_deg": 0.0, "scale": Vector2.ONE}
	var bob_cycle: Array[float] = [0.0, -0.35, -0.8, -0.4, 0.0, 0.45, 0.8, 0.35]
	var bob: float = 0.0
	if source_animation.begins_with("walk_"):
		bob = bob_cycle[posmod(frame_index, bob_cycle.size())]
	if source_animation.ends_with("_front"):
		return {"position": Vector2(3.0, -0.8 + bob * 0.45), "rotation_deg": -88.0, "scale": Vector2(1.0, 1.0)}
	if source_animation.ends_with("_back"):
		return {"position": Vector2(0.0, -7.0 + bob * 0.35), "rotation_deg": -82.0, "scale": Vector2(1.0, 1.0)}
	if source_animation.ends_with("_left"):
		return {"position": Vector2(-10.0, -0.5 + bob * 0.55), "rotation_deg": 18.0, "scale": Vector2(0.98, 0.98)}
	if source_animation.ends_with("_right"):
		return {"position": Vector2(10.0, -0.5 + bob * 0.55), "rotation_deg": -18.0, "scale": Vector2(0.98, 0.98)}
	return {"position": Vector2.ZERO, "rotation_deg": 0.0, "scale": Vector2.ONE}

# Idle reference: bow held gently across the torso, not upright alongside it.
# The image is a full 256x220 bow-only atlas tile; rotate about the *source
# handle*, then translate that pivot onto Ghost Girl's genuine hand.
# Use each authored view when possible; left mirrors the right source.
# Direction-specific orientation for the extracted bow-only artwork.
# This table uses the actual corrected final angle, not an extra runtime 180°,
# so the two bow layers and their child glow cannot accidentally double-flip.
const UPRIGHT_IDLE_ANGLES: Dictionary = {
	"front": 98.0,
	"back": 102.0,
	"left": -100.0,
	"right": 98.0
}

# v2.03: calibration from the approved idle bodies (atlas pixels, before
# Ghost.scale=0.52). The left hand needs a modest south-east shift; front
# bows were floating beyond the wrist and need to tuck left/down.
# This is PHYSICAL grip placement, never a field in the cosmetic seed:
# recoloring cannot move the bow, its mask or child FX.
const WRIST_CORRECTIONS_V203: Dictionary = {
	"front": Vector2(-20.0, 10.0),
	"back": Vector2(-4.0, 5.0),
	"left": Vector2(22.0, 13.0),
	"right": Vector2(-9.0, 5.0)
}

static func idle_hold_pose(face: String) -> Dictionary:
	var flip: bool = face == "left"
	# Front/back use the matching authored bow view. Only left uses the
	# mirrored right-bow source, preserving the approved right/left handedness.
	var source_face: String = "right" if flip else face
	var hand: Vector2 = HAND.hand_anchor(face, 0, 0 if flip else 1)
	if hand == Vector2.INF:
		# Back hair occludes the original hand at pose zero.
		hand = Vector2(34.0, 27.0)
	hand += WRIST_CORRECTIONS_V203.get(face, Vector2.ZERO)
	var source: Vector2 = HAND.hand_anchor(source_face, 0, 1)
	if source == Vector2.INF:
		source = Vector2(34.0, 27.0)
	if flip:
		source.x = -source.x
	# Rotate the source *once* and always recompute position around the
	# same grip. Never apply independent flip/rotation to the prestige FX.
	var angle: float = float(UPRIGHT_IDLE_ANGLES.get(face, 98.0))
	return {
		"source_face": source_face,
		"flip_h": flip,
		"rotation_deg": angle,
		"position": hand - source.rotated(deg_to_rad(angle)),
		"hand": hand,
		"source_handle": source,
		"wrist_correction": WRIST_CORRECTIONS_V203.get(face, Vector2.ZERO)
	}

func _show_idle_bow(item: GhostItemInstance, source_animation: String) -> bool:
	if bow_carry_visual == null or bow_carry_visual.sprite_frames == null or sprite_frames == null:
		return false
	var face: String = "front"
	for suffix in ["front", "back", "left", "right"]:
		if source_animation.ends_with(suffix):
			face = suffix
			break
	var pose: Dictionary = idle_hold_pose(face)
	var carry_name: String = _bow_style_name(item) + "_idle_" + str(pose["source_face"])
	if not bow_carry_visual.sprite_frames.has_animation(carry_name) or not sprite_frames.has_animation(carry_name):
		return false
	for layer in [bow_carry_visual, self]:
		layer.visible = true
		layer.flip_h = bool(pose["flip_h"])
		layer.show_behind_parent = false
		layer.z_index = 3 if layer == bow_carry_visual else 4
		layer.position = pose["position"]
		layer.rotation_degrees = float(pose["rotation_deg"])
		layer.scale = Vector2.ONE
		if str(layer.animation) != carry_name:
			layer.animation = StringName(carry_name)
		layer.set_frame_and_progress(0, 0.0)
	return true

func _ready() -> void:
	body = get_parent() as AnimatedSprite2D
	sprite_frames = SpriteFrames.new()
	var style_names: Array[String] = ["thornrose", "moonveil"]
	var faces: Array[String] = ["front", "back", "left", "right"]
	for style in style_names:
		for family in ["locomotion", "combat"]:
			var path: String = "res://assets/ghost/bows_v139/%s_%s_mask_2048x1760.png" % [style, family]
			if not ResourceLoader.exists(path):
				push_warning("Bow color mask not found: " + path)
				continue
			var atlas: Texture2D = load(path) as Texture2D
			for phase_index in range(2):
				var motion: String = "idle" if phase_index == 0 else "walk"
				if family == "combat":
					motion = "light" if phase_index == 0 else "heavy"
				for face_index in range(4):
					var key: String = (style + "_" + motion + "_" + faces[face_index]) if family == "locomotion" else ("attack_" + style + "_" + motion + "_" + faces[face_index])
					sprite_frames.add_animation(key)
					sprite_frames.set_animation_loop(key, motion in ["idle", "walk"])
					for col in range(8):
						var tile: AtlasTexture = AtlasTexture.new()
						tile.atlas = atlas
						tile.filter_clip = true
						tile.region = Rect2(col * 256, (phase_index * 4 + face_index) * 220, 256, 220)
						sprite_frames.add_frame(key, tile)
	var shader_material: ShaderMaterial = ShaderMaterial.new()
	shader_material.shader = SHADE
	material = shader_material
	show_behind_parent = false
	z_index = 2
	centered = true
	visible = false
	# v1.68.1: this detached carry layer is optional after switching to
	# dedicated hook-free bow body animations in v1.68. Older player scenes
	# may not contain BowCarryV166. Do not construct unused SpriteFrames.
	if bow_carry_visual != null:
		_create_bow_carry_art()

func _create_bow_carry_art() -> void:
	if bow_carry_visual == null:
		return
	# A full-color bow-only overlay in the exact character atlas frame space.
	# This is separate from the recolor mask and *never* replaces attack art.
	bow_carry_visual.sprite_frames = SpriteFrames.new()
	bow_carry_visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bow_carry_visual.visible = false
	bow_carry_visual.z_as_relative = true
	bow_carry_visual.z_index = 3
	for style in ["thornrose", "moonveil"]:
		var path: String = str(CARRY_ATLASES[style])
		if not ResourceLoader.exists(path):
			push_warning("Bow carry art missing: " + path)
			continue
		var atlas: Texture2D = load(path) as Texture2D
		for motion_index in range(2):
			var motion: String = "idle" if motion_index == 0 else "walk"
			for face_index in range(4):
				var face: String = ["front", "back", "left", "right"][face_index]
				var anim_name: String = "%s_%s_%s" % [style, motion, face]
				bow_carry_visual.sprite_frames.add_animation(anim_name)
				bow_carry_visual.sprite_frames.set_animation_loop(anim_name, true)
				for frame_idx in range(8):
					var tile: AtlasTexture = AtlasTexture.new()
					tile.atlas = atlas
					tile.filter_clip = true
					tile.region = Rect2(frame_idx * 256, (motion_index * 4 + face_index) * 220, 256, 220)
					bow_carry_visual.sprite_frames.add_frame(anim_name, tile)

func bind_inventory(value: Node) -> void:
	inventory = value
	if inventory != null and not inventory.equipment_changed.is_connected(refresh):
		inventory.equipment_changed.connect(refresh)
	if inventory != null and not inventory.contents_changed.is_connected(refresh):
		inventory.contents_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if inventory == null or material == null:
		visible = false
		return
	var item: GhostItemInstance = inventory.get_equipped("sword")
	if item == null or item.weapon_style() != "bow" or item.uses_forge_bow():
		visible = false
		return
	last_bow_cosmetic_key = WEAPON_SURFACE.key(item)
	var mat: ShaderMaterial = material as ShaderMaterial
	var look: Dictionary = item.collector_appearance()
	# The real bow limb palette is independent from the string. Blend its
	# full ramp with the separately rolled living surface pigment.
	WEAPON_SURFACE.configure(mat, look, Vector2(256, 220), true, WEAPON_SURFACE.bow_pigment(item, look))

func _process(_delta: float) -> void:
	if body == null or inventory == null:
		visible = false
		return
	var item: GhostItemInstance = inventory.get_equipped("sword")
	var source_animation: String = str(body.animation)
	# The new idle body is mostly the authored neutral pose; lock masks and
	# the left-facing detached bow to that same pose to prevent color jitter.
	var overlay_frame: int = 0 if STEADY_IDLE.is_bow_idle(source_animation) else body.frame
	if item != null and item.weapon_style() == "bow" and not item.uses_forge_bow():
		var key: String = WEAPON_SURFACE.key(item)
		if key != last_bow_cosmetic_key:
			refresh()
	if item == null or item.weapon_style() != "bow" or item.uses_forge_bow():
		visible = false
		if bow_carry_visual != null:
			bow_carry_visual.visible = false
		return
	if DIAGONAL_V270.is_painted_bow_carry(source_animation):
		_show_diagonal_bow_v270(item,source_animation)
		return
	var animation: String = _resolved_animation_name(item, source_animation)
	if STEADY_IDLE.is_bow_idle(source_animation):
		if _show_idle_bow(item, source_animation):
			return
		# Missing optional atlas: suppress any stale transformed color mask.
		if bow_carry_visual != null:
			bow_carry_visual.visible = false
		visible = false
		return
	# Restore neutral transforms for walking/shooting (the idle pose must
	# never leak into attack animations).
	rotation_degrees = 0.0
	scale = Vector2.ONE
	if bow_carry_visual != null:
		bow_carry_visual.rotation_degrees = 0.0
		bow_carry_visual.scale = Vector2.ONE
	# v1.75: the left-facing painted bow was not actually reversed. The BODY
	# is now the untouched left-facing unarmed Ghost Girl pose, so draw a
	# mirrored RIGHT-facing bow-only sprite at the left hand.
	if _should_flip_for_animation(source_animation) and bow_carry_visual != null and bow_carry_visual.sprite_frames != null:
		var bow_motion: String = "walk" if source_animation.contains("_walk_") else "idle"
		var mirrored_bow: String = _bow_style_name(item) + "_" + bow_motion + "_right"
		if bow_carry_visual.sprite_frames.has_animation(mirrored_bow):
			# The right-facing color-mask silhouette matches the extracted
			# bow-only right art (same 256x220 coordinates). Mirror BOTH so
			# saved gradients survive when Ghost Girl faces left.
			if sprite_frames != null and sprite_frames.has_animation(mirrored_bow):
				visible = true
				flip_h = true
				show_behind_parent = false
				z_index = 4
				position = Vector2(3.0, -1.0)
				if str(self.animation) != mirrored_bow:
					self.animation = StringName(mirrored_bow)
				set_frame_and_progress(clampi(overlay_frame, 0, sprite_frames.get_frame_count(mirrored_bow) - 1), body.frame_progress)
			else:
				visible = false
			bow_carry_visual.visible = true
			bow_carry_visual.flip_h = true
			bow_carry_visual.show_behind_parent = false
			bow_carry_visual.z_index = 3
			bow_carry_visual.position = Vector2(3.0, -1.0)
			bow_carry_visual.rotation_degrees = 0.0
			bow_carry_visual.scale = Vector2.ONE
			if str(bow_carry_visual.animation) != mirrored_bow:
				bow_carry_visual.animation = StringName(mirrored_bow)
			bow_carry_visual.set_frame_and_progress(clampi(overlay_frame, 0, bow_carry_visual.sprite_frames.get_frame_count(mirrored_bow) - 1), body.frame_progress)
			return
	# The ordinary idle/walk art has a baked rose hook. Dedicated bow artwork
	# contains the correct clean character and physical bow; the extracted
	# detached BowCarryV166 must never overlay that artwork.
	var carrying: bool = false
	if carrying:
		# These are the approved empty-hand body frames. Draw the extracted
		# full-color bow instead of the old palette-only transparency mask.
		visible = false
		if bow_carry_visual == null or not bow_carry_visual.sprite_frames.has_animation(animation):
			return
		bow_carry_visual.visible = true
		bow_carry_visual.flip_h = _should_flip_for_animation(source_animation)
		bow_carry_visual.show_behind_parent = source_animation.ends_with("_back")
		bow_carry_visual.z_index = -2 if bow_carry_visual.show_behind_parent else 3
		var carry: Dictionary = _carry_transform_for_animation(source_animation, body.frame)
		bow_carry_visual.position = carry.get("position", Vector2.ZERO)
		bow_carry_visual.rotation_degrees = float(carry.get("rotation_deg", 0.0))
		bow_carry_visual.scale = carry.get("scale", Vector2.ONE)
		if str(bow_carry_visual.animation) != animation:
			bow_carry_visual.animation = StringName(animation)
		bow_carry_visual.set_frame_and_progress(clampi(overlay_frame, 0, bow_carry_visual.sprite_frames.get_frame_count(animation) - 1), body.frame_progress)
		return
	if bow_carry_visual != null:
		bow_carry_visual.visible = false
		bow_carry_visual.rotation_degrees = 0.0
		bow_carry_visual.scale = Vector2.ONE
	# Combat frames retain their originally authored two-hand shooting artwork.
	if not sprite_frames.has_animation(animation):
		visible = false
		return
	flip_h = false
	show_behind_parent = source_animation.ends_with("_back")
	z_index = -2 if show_behind_parent else 2
	position = Vector2.ZERO
	if str(self.animation) != animation:
		self.animation = StringName(animation)
	set_frame_and_progress(clampi(overlay_frame, 0, sprite_frames.get_frame_count(animation) - 1), body.frame_progress)
	visible = true

# Actual bow-only neutral art and matching shader mask share one grip pivot.
func _show_diagonal_bow_v270(item: GhostItemInstance,clip: String) -> void:
	visible=false
	if bow_carry_visual==null or bow_carry_visual.sprite_frames==null or sprite_frames==null:
		return
	bow_carry_visual.visible=false
	var wrist: Vector2 = DIAGONAL_V270.wrist(clip,body.frame)
	if wrist==Vector2.INF:
		return
	var face: String = "left" if DIAGONAL_V270.diagonal_name(clip).ends_with("left") else "right"
	var pose: Dictionary = idle_hold_pose(face)
	var carry_name: String = _bow_style_name(item)+"_idle_"+str(pose["source_face"])
	if not bow_carry_visual.sprite_frames.has_animation(carry_name) or not sprite_frames.has_animation(carry_name):
		return
	var angle: float = float(pose["rotation_deg"])
	var source: Vector2 = pose["source_handle"]
	var position_at: Vector2 = wrist-source.rotated(deg_to_rad(angle))
	for layer in [bow_carry_visual,self]:
		layer.visible=true
		layer.flip_h=bool(pose["flip_h"])
		layer.show_behind_parent=false
		layer.z_index=3 if layer==bow_carry_visual else 4
		layer.position=position_at
		layer.rotation_degrees=angle
		layer.scale=Vector2.ONE
		if str(layer.animation)!=carry_name:
			layer.animation=StringName(carry_name)
		layer.set_frame_and_progress(0,0.0)
