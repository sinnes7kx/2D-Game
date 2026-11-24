extends RefCounted
const FX_LEVEL = preload("res://scripts/fx_intensity_v1924.gd")
const FX = preload("res://scripts/anomalous_steel_fx_v180.gd")
const SHADER = preload("res://assets/equipment/weapon_surface_v190.gdshader")

static func ramp(colors: Array) -> GradientTexture1D:
	var gradient: Gradient = Gradient.new()
	var safe: Array = colors if colors.size() >= 2 else [Color.WHITE, Color.WHITE]
	var offsets: PackedFloat32Array = PackedFloat32Array()
	for i in range(safe.size()):
		offsets.append(float(i) / float(safe.size() - 1))
	gradient.offsets = offsets
	gradient.colors = PackedColorArray(safe)
	var tex: GradientTexture1D = GradientTexture1D.new()
	tex.gradient = gradient
	tex.width = 256
	return tex

static func configure(mat: ShaderMaterial, look: Dictionary, cell: Vector2, overlay: bool, colors: Array = []) -> void:
	mat.shader = SHADER
	mat.set_shader_parameter("pigment_ramp", ramp(colors if not colors.is_empty() else look.get("surface_colors", [])))
	mat.set_shader_parameter("signature_kind", FX.signature_kind(look))
	mat.set_shader_parameter("glow_motif", int(look.get("glow_motif", 0)))
	mat.set_shader_parameter("color_mode", int(look.get("color_mode", 0)))
	mat.set_shader_parameter("surface_mode", int(look.get("surface_mode", 0)))
	mat.set_shader_parameter("surface_phase", float(look.get("surface_phase", 0.0)))
	mat.set_shader_parameter("surface_speed", float(look.get("surface_speed", 0.5)))
	mat.set_shader_parameter("cell_size", cell)
	mat.set_shader_parameter("overlay_only", overlay)
	mat.set_shader_parameter("strength", 0.38 if overlay else 0.40)
	mat.set_shader_parameter("fx_intensity", FX_LEVEL.intensity)

static func key(item: GhostItemInstance) -> String:
	return "%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [item.get_instance_id(), item.cosmetic_uid, item.visual_seed(), item.gradient_version, item.debug_surface_mode, item.effect_palette_channel(), item.regional_rank, item.debug_glow_motif, item.debug_color_mode, FX_LEVEL.revision]

static func bow_pigment(item: GhostItemInstance, look: Dictionary) -> Array[Color]:
	var limbs: Array[Color] = item.bow_limb_gradient_colors()
	var pigment: Array = look.get("surface_colors", [])
	var blended: Array[Color] = []
	for i in range(limbs.size()):
		var u: float = float(i) / float(limbs.size() - 1)
		blended.append(limbs[i].lerp(GhostCosmeticRNGV152.sample_palette(pigment, u), 0.42))
	return blended
