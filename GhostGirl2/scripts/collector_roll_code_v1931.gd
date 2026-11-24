extends RefCounted
## V1 rarity fingerprint. Read-only; not an RNG seed or ownership ID.
## "-" is deliberately unranked, never a fabricated rare roll.
const LOOK = preload("res://scripts/collector_appearance_v177.gd")
const RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const SURFACE = preload("res://scripts/living_metal_v187.gd")
const REGION = preload("res://scripts/regional_treasures_v183.gd")
const LABELS: Array[String] = ["Material", "Signature", "Particles", "Surface", "Regional imprint", "Palette", "Motion", "Motif", "Shape/grip", "Ornament"]
const TIER_DIGITS: Array[int] = [9,7,5,3,2,1,0]
const SIG_DIGITS: Array[int] = [9,5,3,2,1,0]
const SURFACE_DIGITS: Array[int] = [9,9,7,5,3,2,0]
const REGION_DIGITS: Array[int] = [9,7,3,0]

static func supports_surface(item: Variant) -> bool:
	return item.get_slot() == "wand" or item.weapon_style() in ["bow","twinblade","dual_sword","dual_dagger","dagger","scythe","halberd","maul"] or str(item.definition.item_id) in ["nocturne_stiletto_v171","moonwarden_spear_v169","briarwake_trident_v171"]

static func current(item: Variant) -> String:
	if item == null or item.definition == null or item.get_slot() not in ["sword","wand"]:
		return ""
	# The material and particle domains are unchanged, including legacy fallback.
	var uid: String = item.cosmetic_uid
	var seed_value: int = item.visual_seed()
	var material: int = LOOK.tier_for_ticket(LOOK.ticket(uid, seed_value, "material-rarity"))
	var particles: int = LOOK.tier_for_ticket(LOOK.ticket(uid, seed_value, "particle-rarity"))
	var signature: String = str(SIG_DIGITS[clampi(item.genuine_visual_signature(),0,5)]) if RNG.is_valid_uid(uid) else "-"
	var surface: String = "-"
	if supports_surface(item):
		var mode: int = SURFACE.surface_for_ticket(LOOK.ticket(uid,seed_value,"v187-surface-family"),material)
		surface = str(SURFACE_DIGITS[mode])
	var regional: String = str(REGION_DIGITS[clampi(item.regional_rank,0,3)]) if REGION.REGIONS.has(item.origin_room) else "-"
	return str(TIER_DIGITS[material]) + signature + str(TIER_DIGITS[particles]) + surface + regional + "-----"

static func valid_code(value: String) -> bool:
	if value.length() != 10:
		return false
	for i in range(value.length()):
		if "0123456789-".find(value.substr(i,1)) < 0:
			return false
	return true

static func debug_active(item: Variant) -> bool:
	return OS.is_debug_build() and (item.debug_visual_override >= 0 or item.debug_mythic_variant >= 0 or item.debug_collector_tier >= 0 or item.debug_color_mode >= 0 or item.debug_glow_motif >= 0 or item.debug_surface_mode >= 0 or item.debug_forge_guard >= 0 or item.debug_forge_grip >= 0)

static func breakdown(code: String) -> String:
	if not valid_code(code):
		return "Unavailable"
	var parts: Array[String] = []
	for i in range(LABELS.size()):
		var digit: String = code.substr(i,1)
		if digit != "-":
			parts.append(LABELS[i] + " " + digit)
	return " · ".join(parts)

static func share(item: Variant) -> String:
	var code: String = current(item)
	if code.is_empty():
		return ""
	return "GGRC1:%s:%s:birth=%s" % [item.definition.item_id,code,item.birth_roll_code_v1 if valid_code(item.birth_roll_code_v1) else "unknown"]
