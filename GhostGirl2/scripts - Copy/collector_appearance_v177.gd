extends RefCounted
## Collecting-first appearance rolls. Stable v1 domains: never change these
## for an existing look. No item quality, combat seed RNG or stats involved.
const SURFACE = preload("res://scripts/living_metal_v187.gd")
const RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const LABELS: Array[String] = ["Standard", "Unusual", "Enchanted", "Animated", "Celestial", "Ethereal", "Anomaly"]
const COUNTS: Array[int] = [6000, 2500, 1000, 400, 90, 9, 1]

static func ticket(uid: String, legacy_seed: int, channel: String) -> int:
	var identity: String = uid.to_lower() if RNG.is_valid_uid(uid) else "legacy-%d" % legacy_seed
	var bytes: PackedByteArray = ("ghost-girl-collector-v1:" + channel + ":" + identity).sha256_buffer()
	return (int(bytes[0]) * 16777216 + int(bytes[1]) * 65536 + int(bytes[2]) * 256 + int(bytes[3])) % 10000

static func tier_for_ticket(value: int) -> int:
	var cursor: int = 0
	for i in range(COUNTS.size()):
		cursor += COUNTS[i]
		if clampi(value, 0, 9999) < cursor:
			return i
	return 6

static func roll(uid: String, legacy_seed: int) -> Dictionary:
	var material: int = tier_for_ticket(ticket(uid, legacy_seed, "material-rarity"))
	return {
		"material": material,
<<<<<<< Updated upstream
		"surface_mode": SURFACE.surface_for_ticket(ticket(uid, legacy_seed, "v187-surface-family"), material),
		"surface_phase": float(ticket(uid, legacy_seed, "v187-surface-phase")) / 10000.0,
		"surface_speed": 0.35 + float(ticket(uid, legacy_seed, "v187-surface-speed")) / 10000.0 * 0.65,
		"surface_colors": RNG.gradient_for_channel(uid, legacy_seed, "v187-surface-pigment"),
=======
>>>>>>> Stashed changes
		"color_mode": ticket(uid, legacy_seed, "v180-color-mode") % 7,
		"glow_motif": ticket(uid, legacy_seed, "v180-glow-motif") % 8,
		"shift_rate": 0.055 + float(ticket(uid, legacy_seed, "v180-shift-rate")) / 9999.0 * 0.24,
		"finish": ticket(uid, legacy_seed, "surface-finish") % 7,
		"pattern": ticket(uid, legacy_seed, "blade-pattern") % 11,
		"scythe_span": 0.82 + float(ticket(uid, legacy_seed, "v190-scythe-span")) / 9999.0 * 0.36,
		"scythe_curve": 0.45 + float(ticket(uid, legacy_seed, "v190-scythe-curve")) / 9999.0 * 0.45,
		"forge_width": 0.64 + float(ticket(uid, legacy_seed, "v189-width")) / 9999.0 * 0.59,
		"forge_shoulder": 0.82 + float(ticket(uid, legacy_seed, "v189-shoulder")) / 9999.0 * 0.18,
		"forge_taper": 0.55 + float(ticket(uid, legacy_seed, "v189-taper")) / 9999.0 * 0.45,
		"forge_guard": ticket(uid, legacy_seed, "v189-guard") % 8,
		"forge_guard_span": 0.85 + float(ticket(uid, legacy_seed, "v189-guard-span")) / 9999.0 * 0.52,
		"forge_grip": ticket(uid, legacy_seed, "v189-grip") % 6,
		"forge_grip_width": 0.78 + float(ticket(uid, legacy_seed, "v189-grip-width")) / 9999.0 * 0.40,
		"forge_wrap_count": 3 + ticket(uid, legacy_seed, "v189-wrap-count") % 7,
		"forge_inset": ticket(uid, legacy_seed, "v189-inset") % 7,
		"forge_inset_scale": 0.70 + float(ticket(uid, legacy_seed, "v189-inset-scale")) / 9999.0 * 0.50,
		"forge_etch": ticket(uid, legacy_seed, "v189-etch") % 5,
		"forge_etch_count": 2 + ticket(uid, legacy_seed, "v189-etch-count") % 6,
		"forge_ornament_colors": RNG.gradient_for_channel(uid, legacy_seed, "v189-ornament"),
		"ornament": ticket(uid, legacy_seed, "ornament") % 9,
		"particle": ticket(uid, legacy_seed, "particle") % 8,
		"particle_tier": tier_for_ticket(ticket(uid, legacy_seed, "particle-rarity")),
		"glow_strength": 0.72 + float(ticket(uid, legacy_seed, "glow-strength")) / 9999.0 * 0.56,
		"glow_speed": 0.35 + float(ticket(uid, legacy_seed, "glow-speed")) / 9999.0 * 0.95,
		"metal_colors": RNG.gradient_for_channel(uid, legacy_seed, "collector-v1-metal"),
		"accent_colors": RNG.gradient_for_channel(uid, legacy_seed, "collector-v1-accent"),
		"handle_colors": RNG.gradient_for_channel(uid, legacy_seed, "collector-v1-handle")
	}

static func rarity_label(look: Dictionary) -> String:
	return LABELS[clampi(int(look.get("material", 0)), 0, 6)]
