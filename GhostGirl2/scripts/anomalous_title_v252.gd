extends RefCounted
## v2.53: a coherent title palette per saved cosmetic identity. This is a
## derived display channel, not an item affix, rarity roll, or saved override.
const COLLECTOR = preload("res://scripts/collector_appearance_v177.gd")
const RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const FAMILIES: Array[Vector2] = [
	Vector2(0.58, 0.66), # midnight blue
	Vector2(0.70, 0.78), # amethyst
	Vector2(0.94, 1.02), # crimson / rose (wraps through red)
	Vector2(0.055, 0.12), # amber / bronze
	Vector2(0.30, 0.39), # jade
	Vector2(0.46, 0.53), # teal
	Vector2(0.80, 0.88) # dusty orchid
]
const DEFAULT_PALETTE: Array[Color] = [Color("647ca9"), Color("9096cc"), Color("c3d9fa")]
const CACHE_KEY: StringName = &"anomalous_palette_v253"

static func identity(uid: String, legacy_seed: int) -> String:
	return uid.to_lower() if RNG.is_valid_uid(uid) else "legacy-%d" % legacy_seed

static func palette_for(uid: String, legacy_seed: int) -> Array[Color]:
	var family_ticket: int = COLLECTOR.ticket(uid, legacy_seed, "v253-anomalous-title-family")
	var family: Vector2 = FAMILIES[mini(FAMILIES.size() - 1, int(floor(float(family_ticket) * FAMILIES.size() / 10000.0)))]
	var hue: float = lerpf(family.x, family.y, float(COLLECTOR.ticket(uid, legacy_seed, "v253-anomalous-title-hue")) / 9999.0)
	var tone: float = float(COLLECTOR.ticket(uid, legacy_seed, "v253-anomalous-title-tone")) / 9999.0
	# Muted but readable on the near-black tooltip; the glint is a lighter
	# shade of the same hue, not a rainbow or an unrelated accent.
	return [
		_readable(Color.from_hsv(fposmod(hue - 0.009, 1.0), 0.46 + tone * 0.07, 0.67)),
		_readable(Color.from_hsv(fposmod(hue + 0.009, 1.0), 0.34 + tone * 0.08, 0.81)),
		Color.from_hsv(fposmod(hue, 1.0), 0.22, 0.96)
	]

static func _readable(color: Color) -> Color:
	# Desaturate toward white only enough to avoid unreadably dark hues.
	var result: Color = color
	for step in range(8):
		if result.get_luminance() >= 0.23:
			break
		result = result.lerp(Color.WHITE, 0.08)
	return result

static func ink(seconds: float, palette: Array[Color] = []) -> Color:
	var colors: Array[Color] = palette if palette.size() == 3 else DEFAULT_PALETTE
	var drift: float = 0.5 + 0.5 * sin(seconds * 0.48)
	var crest: float = pow(0.5 + 0.5 * cos(seconds * TAU / 8.5), 14.0)
	return colors[0].lerp(colors[1], drift).lerp(colors[2], crest * 0.72)

static func apply(label: Label, seconds: float, item: Variant = null) -> void:
	var palette: Array[Color] = DEFAULT_PALETTE
	var phase: float = 0.0
	if item != null:
		var uid: String = str(item.cosmetic_uid)
		var legacy_seed: int = int(item.visual_seed())
		var key: String = identity(uid, legacy_seed)
		var cached: Dictionary = label.get_meta(CACHE_KEY, {})
		if str(cached.get("identity", "")) != key:
			cached = {
				"identity": key,
				"palette": palette_for(uid, legacy_seed),
				"phase": float(COLLECTOR.ticket(uid, legacy_seed, "v253-anomalous-title-phase")) * 8.5 / 10000.0
			}
			label.set_meta(CACHE_KEY, cached)
		palette.assign(cached["palette"])
		phase = float(cached["phase"])
	var tint: Color = ink(seconds + phase, palette)
	label.modulate = Color.WHITE
	label.add_theme_color_override("font_color", tint)
	var shadow: Color = tint.darkened(0.67)
	shadow.a = 0.78
	label.add_theme_color_override("font_shadow_color", shadow)
	label.add_theme_constant_override("shadow_outline_size", 2)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
