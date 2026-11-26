extends RefCounted
## Cosmetic personalization only. Item rolls, stats, hitboxes and quality are
## never consulted or modified by these user-selected rendering preferences.
const RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const PROJECTILE_STYLES: Array[String] = [
	"Natural", "Moonthread", "Twin Helix", "Halo Burst", "Petal Drift",
	"Glass Motes", "Comet Tail", "Starlace", "Wisp Bloom"
]
const GLOW_LEVELS: Array[float] = [0.0, 0.10, 0.20, 0.30, 0.40, 0.50]
const BOW_GLOW_MODES: Array[String] = ["Natural", "Off", "Limbs", "Limbs + string", "Full bow"]

# A genuinely rare seed-only special can exist without an override. A visual
# choice changes only the decoration of ONE original physical projectile.
static func projectile_style(item: GhostItemInstance) -> int:
	if item == null or item.weapon_style() != "bow":
		return 0
	if item.bow_projectile_style_override >= 0:
		return clampi(item.bow_projectile_style_override, 0, 8)
	return seeded_projectile_style(item)

static func seeded_projectile_style(item: GhostItemInstance) -> int:
	if item == null or item.weapon_style() != "bow":
		return 0
	var identity: String = item.cosmetic_uid.to_lower() if RNG.is_valid_uid(item.cosmetic_uid) else "legacy-%d" % item.visual_seed()
	var digest: PackedByteArray = ("ghostgirl-v216-arrow-decoration:" + identity).sha256_buffer()
	# ~28% of bow identities choose one of eight extra visible motifs.
	return 0 if int(digest[0]) < 184 else 1 + int(digest[1]) % 8

static func chosen_glow_level(item: GhostItemInstance) -> int:
	return clampi(item.glow_level_override, -1, 5) if item != null else -1

# Natural keeps the existing generated light strength. Explicit Off is zero;
# manual 10–50% map to literal 0.10..0.50 alpha multipliers.
static func effect_scale(item: GhostItemInstance) -> float:
	var level: int = chosen_glow_level(item)
	return 1.0 if level < 0 else GLOW_LEVELS[level]

static func opacity(item: GhostItemInstance, natural_opacity: float = 0.20) -> float:
	var level: int = chosen_glow_level(item)
	return natural_opacity if level < 0 else GLOW_LEVELS[level]

static func bow_mode(item: GhostItemInstance) -> int:
	return clampi(item.bow_glow_mode_override, -1, 3) if item != null else -1

static func bow_body_visible(item: GhostItemInstance) -> bool:
	return effect_scale(item) > 0.0 and bow_mode(item) != 0

static func bow_string_visible(item: GhostItemInstance) -> bool:
	return effect_scale(item) > 0.0 and bow_mode(item) in [-1, 2, 3]

# These descriptions report current saved preferences, not a rarity claim.
static func projectile_label(index: int) -> String:
	return "Plain" if index <= 0 else PROJECTILE_STYLES[clampi(index, 1, 8)]

static func has_personalization(item: GhostItemInstance) -> bool:
	if item == null or item.definition == null:
		return false
	var slot: String = item.get_slot()
	if slot in ["sword", "wand"]:
		if item.glow_level_override >= 0:
			return true
		if item.weapon_style() == "bow":
			return item.bow_glow_mode_override >= 0 or item.bow_projectile_style_override >= 0
	if str(item.definition.item_id) == "v202_luminous_eyes":
		return item.eye_style_override >= 0 or item.eye_palette_override >= 0
	return false

static func appearance_details(item: GhostItemInstance) -> Array[String]:
	var lines: Array[String] = []
	if item == null or item.definition == null:
		return lines
	if item.get_slot() in ["sword", "wand"] and item.glow_level_override >= 0:
		var level: int = chosen_glow_level(item)
		lines.append("Custom glow: " + ("Off" if level == 0 else "%d%%" % (level * 10)))
	if item.weapon_style() == "bow":
		if item.bow_glow_mode_override >= 0:
			lines.append("Custom bow body: " + BOW_GLOW_MODES[bow_mode(item) + 1])
		var seeded: String = projectile_label(seeded_projectile_style(item))
		if item.bow_projectile_style_override >= 0:
			lines.append("Custom arrow ornament: " + projectile_label(projectile_style(item)))
			lines.append("Seeded arrow ornament: " + seeded)
		else:
			lines.append("Seeded arrow ornament: " + seeded)
	if str(item.definition.item_id) == "v202_luminous_eyes":
		if item.eye_style_override >= 0:
			var shapes: Array[String] = ["Moonveil", "Cathedral", "Starborn", "Hollow"]
			lines.append("Custom eye shape: " + shapes[clampi(item.eye_style_override, 0, 3)])
		if item.eye_palette_override >= 0:
			var palettes: Array[String] = ["Violet", "Rose", "Moonblue", "Jade", "Gold", "Ash"]
			lines.append("Custom eye color: " + palettes[clampi(item.eye_palette_override, 0, 5)])
	return lines
