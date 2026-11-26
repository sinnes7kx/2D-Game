extends Node2D
const FX_LEVEL = preload("res://scripts/fx_intensity_v1924.gd")
var last_fx_revision: int = -1
const ANOMALOUS = preload("res://scripts/anomalous_steel_fx_v180.gd")
## A display-only weapon model; shares the equipped modular art routines.
const HEAVY = preload("res://scripts/heavy_weapon_art_v192.gd")
const SCYTHE = preload("res://scripts/scythe_art_v190.gd")
const SCYTHE_GLOW = preload("res://scripts/scythe_glow_layer_v211.gd")
const CHOICES_V216 = preload("res://scripts/visual_choices_v216.gd")
const PAINTED_SURFACE = preload("res://scripts/weapon_surface_v190.gd")
const BOW_POSE = preload("res://scripts/bow_palette_overlay_v139.gd")
var painted_preview: Sprite2D
var bow_painted_mask: Sprite2D
var bow_body_glow: Sprite2D
var scythe_glow: Node2D
var glow_preview_override: int = -1
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
var item: GhostItemInstance
var look: Dictionary = {}
var profiles: Array[Dictionary] = []
var gradients: Array[Color] = []
var glow_enabled: bool = true
var elapsed: float = 0.0
var segments: Array[PackedVector2Array] = []

func _ready() -> void:
	scythe_glow = SCYTHE_GLOW.new() as Node2D
	scythe_glow.name = "ScytheGlowLayerV211"
	scythe_glow.z_index = 2
	add_child(scythe_glow)

func set_glow_preview_override(level_index: int) -> void:
	glow_preview_override = level_index
	queue_redraw()

func set_item(value: GhostItemInstance) -> void:
	glow_preview_override = -1
	item = value
	self_modulate.a = item.weapon_opacity() if item != null else 1.0
	look = item.collector_appearance() if item != null else {}
	if item != null and look.is_empty():
		look = preload("res://scripts/collector_appearance_v177.gd").roll(item.cosmetic_uid, item.visual_seed())
		if OS.is_debug_build():
			if item.debug_collector_tier >= 0:
				look["material"] = item.debug_collector_tier
				look["particle_tier"] = item.debug_collector_tier
			if item.debug_color_mode >= 0:
				look["color_mode"] = item.debug_color_mode
			if item.debug_glow_motif >= 0:
				look["glow_motif"] = item.debug_glow_motif
	if item != null:
		look.merge(item.effect_palette_motion(), true)
	profiles.clear()
	for hand in range(2):
		profiles.append(ART.weapon_profile(look, str(item.definition.item_id), hand) if item != null and item.definition != null else {})
	gradients.clear()
	if item != null:
		gradients = item.glow_gradient_colors()
	_update_painted_preview()
	elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if last_fx_revision != FX_LEVEL.revision:
		last_fx_revision = FX_LEVEL.revision
		if is_instance_valid(painted_preview) and painted_preview.material is ShaderMaterial:
			(painted_preview.material as ShaderMaterial).set_shader_parameter("fx_intensity", FX_LEVEL.intensity)
		if is_instance_valid(bow_painted_mask) and bow_painted_mask.material is ShaderMaterial:
			(bow_painted_mask.material as ShaderMaterial).set_shader_parameter("fx_intensity", FX_LEVEL.intensity)
		queue_redraw()
	if is_instance_valid(bow_body_glow) and item != null:
		bow_body_glow.visible = item.weapon_style() == "bow" and glow_enabled and CHOICES_V216.bow_body_visible(item)
	if is_visible_in_tree() and item != null and (glow_enabled or (is_modular() and int(look.get("surface_mode", 0)) >= 2)):
		elapsed += delta
		queue_redraw()

func _grip(a: Vector2, b: Vector2, width: float, hand: int) -> void:
	ART.draw_grip(self, a, b, width, profiles[hand])

func _blade(a: Vector2, b: Vector2, width: float, hand: int) -> void:
	ART.draw_blade(self, a, b, width, profiles[hand], elapsed)
	for side in [-1.0, 1.0]:
		segments.append(ART.edge_points(a, b, width, profiles[hand], side))

func is_modular() -> bool:
	if item == null or item.definition == null:
		return false
	return item.weapon_style() in ["twinblade", "dual_sword", "dual_dagger", "dagger", "scythe", "halberd", "maul"] or str(item.definition.item_id) in ["nocturne_stiletto_v171", "moonwarden_spear_v169", "briarwake_trident_v171"]

func _draw() -> void:
	segments.clear()
	if item == null or item.definition == null:
		if is_instance_valid(scythe_glow):
			scythe_glow.call("clear_pose")
		return
	if item.weapon_style() != "scythe" and is_instance_valid(scythe_glow):
		scythe_glow.call("clear_pose")
	if not is_modular() or profiles.is_empty() or profiles[0].is_empty():
		if item.definition.icon != null and not has_painted_surface():
			var size: Vector2 = Vector2(item.definition.icon.get_size())
			var fit: Vector2 = size * (90.0 / maxf(1.0, maxf(size.x, size.y)))
			draw_texture_rect(item.definition.icon, Rect2(-fit * 0.5, fit), false)
		if glow_enabled and CHOICES_V216.effect_scale(item) > 0.0:
			_draw_artwork_effects()
		return
	var style: String = item.weapon_style()
	match style:
		"halberd", "maul":
			var p: Dictionary = profiles[0].duplicate()
			p["heavy_head_span"] = float(look.get("heavy_head_span", 1.0))
			p["heavy_head_flare"] = float(look.get("heavy_head_flare", 1.0))
			HEAVY.draw_heavy(self, Vector2(0, 27), Vector2(0, -55 if style == "halberd" else -27), p, look, gradients, elapsed, style, str(item.definition.item_id) == "ashglass_warmaul_v170", 1.0, glow_enabled and CHOICES_V216.effect_scale(item) > 0.0, str(item.definition.item_id))
		"scythe":
			var p: Dictionary = profiles[0].duplicate()
			p["scythe_span"] = float(look.get("scythe_span", 1.0))
			p["scythe_curve"] = float(look.get("scythe_curve", 0.7))
			SCYTHE.draw_scythe(self, Vector2(-12, 20), Vector2(-12, -56), p, look, gradients, elapsed, 1.0, glow_enabled and CHOICES_V216.effect_scale(item) > 0.0)
			if is_instance_valid(scythe_glow):
				if glow_enabled:
					scythe_glow.call("set_pose", item, Vector2(-12, 20), Vector2(-12, -56), p, 1.0, glow_preview_override)
				else:
					scythe_glow.call("clear_pose")
		"twinblade":
			var width: float = ART.twinblade_width(str(item.definition.item_id) == "rosemirror_twinblade_v170")
			var spans: Array[PackedVector2Array] = ART.twinblade_spans(Vector2.ZERO, Vector2(0, -68))
			_grip(spans[1][0], spans[0][0], 3.0, 0)
			for span in spans:
				_blade(span[0], span[1], width, 0)
		"dual_sword", "dual_dagger":
			var dagger: bool = style == "dual_dagger"
			for hand in range(2):
				var x: float = -17.0 if hand == 0 else 17.0
				var a: Vector2 = Vector2(x, 9)
				var tip: Vector2 = Vector2(x, -26 if dagger else -53)
				_grip(Vector2(x, 25), a, 3.5 if dagger else 5.1, hand)
				_blade(a, tip, 3.1 if dagger else (5.2 if hand == 0 else 4.8), hand)
		"spear":
			if str(item.definition.item_id) == "briarwake_trident_v171":
				_draw_trident()
			else:
				_grip(Vector2(0, 55), Vector2(0, -29), 3.8, 0)
				_blade(Vector2(0, -29), Vector2(0, -53), 4.5, 0)
		"trident":
			_draw_trident()
		_:
			if str(item.definition.item_id) == "briarwake_trident_v171":
				_draw_trident()
			else:
				_grip(Vector2(0, 20), Vector2(0, 5), 3.2, 0)
				_blade(Vector2(0, 5), Vector2(0, -35), 3.2, 0)
	if glow_enabled and CHOICES_V216.effect_scale(item) > 0.0:
		_draw_light()
		# Weapon signatures are drawn along the same edge as equipped art.

func _draw_trident() -> void:
	_grip(Vector2(0, 55), Vector2(0, -36), 4.5, 0)
	for side in [-1.0, 1.0]:
		var accent: Color = profiles[0]["accent"]
		draw_line(Vector2(0, -36), Vector2(side * 8, -36), accent.darkened(0.25), 2.5, true)
		_blade(Vector2(side * 8, -36), Vector2(side * 7, -51), 1.8, 0)
	_blade(Vector2(0, -36), Vector2(0, -53), 2.6, 0)

func _draw_light() -> void:
	for i in range(segments.size()):
		ANOMALOUS.draw_edge(self, segments[i], gradients, look, elapsed, float(look.get("glow_strength", 1.0)) * 0.80, i % 2 == 1)

# Existing icon artwork remains intact. These display-only effects use its
# saved colors and signatures; they do not pretend to be an equipped rig.
func _draw_artwork_effects() -> void:
	if gradients.size() < 3:
		return
	var tier: int = int(look.get("particle_tier", 0))
	var motif: int = int(look.get("glow_motif", 0))
	var radius: float = 39.0
	if item.get_slot() == "wand":
		radius = 32.0
	var strength: float = CHOICES_V216.effect_scale(item)
	var count: int = 4 + mini(tier, 5)
	for i in range(count):
		var u: float = float(i) / float(count)
		var phase: float = elapsed * (0.48 + 0.045 * float(motif)) + u * TAU
		var p: Vector2 = Vector2.from_angle(phase) * (radius + 5.0 * sin(phase * 2.0))
		var ink: Color = ANOMALOUS.color_at(gradients, look, u, elapsed)
		ink.a = FX_LEVEL.alpha((0.36 + 0.08 * sin(phase * 1.4)) * strength)
		match motif:
			0, 7: draw_circle(p, 1.6, ink)
			1, 6:
				draw_line(p - Vector2(3,0), p + Vector2(3,0), ink, 0.9, true)
				draw_line(p - Vector2(0,3), p + Vector2(0,3), ink, 0.9, true)
			2: draw_colored_polygon(PackedVector2Array([p, p + Vector2(2,-4), p + Vector2(4,1)]), ink)
			3: draw_polyline(PackedVector2Array([p - Vector2(3,3), p + Vector2(1,-1), p + Vector2(-1,1), p + Vector2(3,3)]), ink, 1.0, true)
			4: draw_arc(p, 3.0, phase, phase + PI, 12, ink, 1.0, true)
			5: draw_line(p, p - Vector2.from_angle(phase + PI / 2.0) * 7.0, ink, 1.2, true)
		ink.a = FX_LEVEL.alpha(0.045 * strength)
		draw_circle(p, 5.0, ink)
	_draw_signature(Vector2.ZERO, radius + 10.0)

func _draw_signature(center: Vector2, radius: float) -> void:
	var sig: int = item.visual_signature()
	var tier: int = maxi(int(look.get("material", 0)), int(look.get("particle_tier", 0)))
	if gradients.size() < 3 or (sig <= 0 and tier < 4):
		return
	var ink: Color = ANOMALOUS.color_at(gradients, look, 0.4, elapsed)
	ink.a = FX_LEVEL.alpha(0.32)
	var phase: float = elapsed * 0.65
	if sig == 2 or sig == 5 or tier >= 5:
		draw_arc(center, radius, phase, phase + PI * 1.35, 48, ink, 1.1, true)
	if sig == 5 or tier == 6:
		draw_arc(center, radius + 5.0, -phase, -phase + PI * 0.9, 36, ink, 0.9, true)
	var variant: int = item.mythic_layer_variant() if sig == 4 else sig % 4
	for j in range(5 if sig == 4 else 3):
		var a: float = phase + float(j) * TAU / 5.0
		var p: Vector2 = center + Vector2.from_angle(a) * radius
		match variant:
			0: draw_polyline(PackedVector2Array([p + Vector2(-3,-5),p,p + Vector2(3,-2),p + Vector2(0,5)]), ink, 1.0, true)
			1: draw_circle(p, 1.8, ink)
			2: draw_arc(p, 3.4, 0, TAU, 16, ink, 1.0, true)
			3: draw_colored_polygon(PackedVector2Array([p,p + Vector2(2,-4),p + Vector2(4,0)]), ink)

func has_painted_surface() -> bool:
	return item != null and item.definition != null and item.definition.icon != null and (item.get_slot() == "wand" or item.weapon_style() == "bow")

# The inspection bow is the actual carried bow-only atlas + its matching
# v139 mask, not a separate icon with an unrelated color shader.
func _actual_bow_preview() -> bool:
	var style: String = "moonveil" if str(item.definition.item_id) == "moonveil_bow" else "thornrose"
	var art_path: String = "res://assets/equipment/bows_v166/%s_carry_only_2048x1760.png" % style
	var mask_path: String = "res://assets/ghost/bows_v139/%s_locomotion_mask_2048x1760.png" % style
	if not ResourceLoader.exists(art_path) or not ResourceLoader.exists(mask_path):
		return false
	if not is_instance_valid(bow_painted_mask):
		bow_painted_mask = Sprite2D.new()
		bow_painted_mask.name = "ActualBowPaletteMaskV215"
		add_child(bow_painted_mask)
	var pose: Dictionary = BOW_POSE.idle_hold_pose("front")
	var angle: float = float(pose["rotation_deg"])
	# Center the same hand-grip pivot in Inspect rather than shifting the item
	# based on a different icon's opaque bounds.
	var source: Vector2 = pose["source_handle"]
	var scale_factor: float = 0.82
	var center_offset: Vector2 = -source.rotated(deg_to_rad(angle)) * scale_factor
	for entry in [
		{"node": painted_preview, "path": art_path},
		{"node": bow_painted_mask, "path": mask_path}
	]:
		var sprite: Sprite2D = entry["node"] as Sprite2D
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = load(str(entry["path"])) as Texture2D
		frame.filter_clip = true
		frame.region = Rect2(0.0, 0.0, 256.0, 220.0)
		sprite.texture = frame
		sprite.position = center_offset
		sprite.scale = Vector2.ONE * scale_factor
		sprite.rotation_degrees = angle
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.show_behind_parent = true
		sprite.self_modulate.a = item.weapon_opacity()
		sprite.show()
	painted_preview.material = null
	painted_preview.z_index = -2
	bow_painted_mask.z_index = -1
	# The same bow-only mask also provides a precise additive glow outline.
	# It remains separate from both the opaque physical sprite and tint mask.
	if not is_instance_valid(bow_body_glow):
		bow_body_glow = Sprite2D.new()
		bow_body_glow.name = "BowGlowLayerV216"
		add_child(bow_body_glow)
		var additive: CanvasItemMaterial = CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		bow_body_glow.material = additive
	bow_body_glow.texture = bow_painted_mask.texture
	bow_body_glow.position = bow_painted_mask.position
	bow_body_glow.rotation = bow_painted_mask.rotation
	bow_body_glow.scale = bow_painted_mask.scale
	bow_body_glow.z_index = 0
	bow_body_glow.show_behind_parent = false
	var limb_ink: Array[Color] = item.bow_limb_gradient_colors()
	bow_body_glow.modulate = limb_ink[1]
	var mode: int = CHOICES_V216.bow_mode(item)
	bow_body_glow.modulate.a = CHOICES_V216.opacity(item, 0.14) * (1.5 if mode == 3 else 0.8)
	bow_body_glow.visible = CHOICES_V216.bow_body_visible(item) and glow_enabled
	var mat: ShaderMaterial = ShaderMaterial.new()
	PAINTED_SURFACE.configure(mat, look, Vector2(256, 220), true, PAINTED_SURFACE.bow_pigment(item, look))
	bow_painted_mask.material = mat
	return true

func _update_painted_preview() -> void:
	if is_instance_valid(bow_painted_mask):
		bow_painted_mask.hide()
	if is_instance_valid(bow_body_glow):
		bow_body_glow.hide()
	if not has_painted_surface():
		if is_instance_valid(painted_preview):
			painted_preview.hide()
		return
	if not is_instance_valid(painted_preview):
		painted_preview = Sprite2D.new()
		painted_preview.name = "PaintedMaterialPreviewV190"
		painted_preview.show_behind_parent = true
		add_child(painted_preview)
	if item.weapon_style() == "bow" and _actual_bow_preview():
		return
	# Legacy icon remains an explicit fallback for missing optional artwork,
	# and for wands, whose full directional artwork is a separate workflow.
	painted_preview.texture = item.definition.icon
	painted_preview.rotation = 0.0
	painted_preview.position = Vector2.ZERO
	var size: Vector2 = Vector2(painted_preview.texture.get_size())
	painted_preview.scale = Vector2.ONE * (90.0 / maxf(1.0, maxf(size.x, size.y)))
	var mat: ShaderMaterial = ShaderMaterial.new()
	PAINTED_SURFACE.configure(mat, look, size, false, look.get("surface_colors", []))
	painted_preview.material = mat
	painted_preview.self_modulate.a = item.weapon_opacity()
	painted_preview.show()
