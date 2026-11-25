extends Resource
class_name GhostItemInstance
const RelicPaletteV139 = preload("res://scripts/procedural_relic_palette_v139.gd")
const COSMETIC_RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const COLLECTOR_LOOK = preload("res://scripts/collector_appearance_v177.gd")
## Each dropped instance stores its own deterministic rolls, independent of template.
var definition: GhostItemData
var item_seed: int = 0
# Cosmetic-only seed is intentionally separate from the original loot/stat seed.
# -1 keeps pre-v1.46.3 saves visually unchanged.
var cosmetic_seed: int = -1
# Opaque 128-bit appearance ID; intentionally never shown in tooltips.
var cosmetic_uid: String = ""
# V1 reproduces the exact historic ramp. Only new drops/re-rolled looks opt in.
var gradient_version: int = 1
# Recorded once for new finds; empty on legacy items with unknown birth appearance.
var birth_roll_code_v1: String = ""
var birth_roll_uid_v1: String = ""
# Independent, extremely rare VISUAL-only signature (0 none, 1..5 effects).
var rare_visual_mod: int = -1
# In-memory debug inspection only. Intentionally omitted from save dictionaries,
# cosmetic snapshots and normal RNG; never changes genuine rare rolls.
var debug_visual_override: int = -1
var debug_mythic_variant: int = -1
var collector_favorite: bool = false
var collector_locked: bool = false
const REGIONAL = preload("res://scripts/regional_treasures_v183.gd")
var origin_room: String = ""
var regional_rank: int = 0
# Physical Ethereal condition, not the cosmetic rarity tier.
var ethereal: bool = false
var durability: int = 0
var max_durability: int = 0
var exhibition_slot: int = -1 # Only assigned while in collection vault.
var debug_collector_tier: int = -1
var debug_color_mode: int = -1
var debug_glow_motif: int = -1
var debug_surface_mode: int = -1
var debug_forge_guard: int = -1
var debug_forge_grip: int = -1
# Favorite presets store exact appearance fields, including existing altar rolls.
var saved_cosmetic_looks: Array[Dictionary] = []
var palette_index: int = 0
var decoration_index: int = 0
# v1.11 separate weapon appearance channels. -1 falls back to legacy palette.
var weapon_base_index: int = -1
var weapon_gradient_index: int = 0
var weapon_detail_a_index: int = 0
var weapon_detail_b_index: int = 0
# Independent v1.13 visual affix rolls. -1 is compatible with older item saves.
var weapon_fx_style_index: int = -1
var weapon_fx_color_index: int = -1
var wand_cast_style_index: int = -1
# v1.14: independent secondary glow and motion pattern. Missing old-save keys
# fall back to deterministic per-item seed streams.
var weapon_fx_accent_index: int = -1
var weapon_fx_trail_index: int = -1
var weapon_impact_style_index: int = -1 # independently seeded, save-compatible cosmetic impact
var wand_lance_index: int = -1 # v1.17 separate rare beam skin; -1 = seed-derived fallback
# v1.38 independent bow-only appearance seeds (no weapon stats changed).
var bow_element_index: int = -1
var bow_formation_index: int = -1
var bow_glow_index: int = -1
var bow_trail_index: int = -1
var bow_detail_index: int = -1
var stat_value: float = 0.0
var quality: String = "normal"
var affixes: Array[Dictionary] = []
var sockets: int = 0
var socketed: Array[Dictionary] = []
var item_level: int = 1

const QUALITY_COLORS = {
	"normal": Color("cbc4d3"), "magic": Color("829ce9"),
	"rare": Color("ead38c"), "set": Color("71c5a0"),
	"unique": Color("cd9c75")
}

func quality_color() -> Color:
	return QUALITY_COLORS.get(quality, Color.WHITE)

func display_name() -> String:
	if definition == null:
		return "Unknown"
	var base: String = definition.display_name
	if ethereal:
		base = ("Broken Ethereal " if is_broken() else "Ethereal ") + base
	match quality:
		"magic":
			if affixes.size() > 0:
				return "%s %s" % [str(affixes[0].get("prefix", "Mystic")), base]
			return "Enchanted " + base
		"rare": return "Glimmering " + base
		"set": return "Vesper's " + base
		"unique": return "The Forgotten " + base
		_: return base

func get_slot() -> String:
	return definition.equip_slot if definition != null else "none"

# Independent deterministic blade roll: compatible with existing seeded saves.
func weapon_damage() -> float:
	if definition == null or get_slot() != "sword":
		return 0.0
	var damage_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	damage_rng.seed = absi(item_seed) + 612746
	return 0.0 if is_broken() else snappedf(damage_rng.randf_range(definition.min_weapon_damage, definition.max_weapon_damage) * (1.5 if ethereal else 1.0), 0.1)

func weapon_style() -> String:
	if definition != null and get_slot() == "sword":
		return definition.weapon_style
	return "unarmed"

# v2.03 mauls, maces, morningstars and flails are *blunt* weapons.
# This is presentation/impact classification, not a reroll or new item field.
func physical_damage_kind() -> String:
	match weapon_style():
		"maul": return "blunt"
		"bow": return "pierce"
		"dagger", "spear": return "pierce"
		_: return "slash"


	match weapon_style():
		"scythe": return 0.49
		"halberd": return 0.57
		"dagger": return 0.31
		"dual_dagger": return 0.32
		"dual_sword": return 0.47
		"spear": return 0.53
		"maul": return 0.67
		"twinblade": return 0.36
		"bow": return 0.38
		"blade": return 0.40
		_: return 0.40

func light_stamina_cost() -> float:
	match weapon_style():
		"scythe": return 18.9
		"halberd": return 20.34
		"dagger": return 14.22
		"dual_dagger": return 15.84
		"dual_sword": return 20.52
		"spear": return 19.62
		"maul": return 22.50
		"twinblade": return 16.20
		"bow": return 14.0
		_: return 18.0

func weapon_reach() -> float:
	match weapon_style():
		"scythe": return 184.0
		"halberd": return 206.0
		"dagger": return 112.0
		"dual_dagger": return 122.0
		"dual_sword": return 165.0
		"spear": return 213.0
		"maul": return 173.0
		"twinblade": return 168.0
		"bow": return 830.0
		"blade": return 144.0
		_: return 106.0

func weapon_base_color() -> Color:
	return COSMETIC_RNG.sample_palette(COSMETIC_RNG.gradient_for_channel(cosmetic_uid, visual_seed(), "physical-sword", gradient_version), 0.5)

func weapon_gradient_color() -> Color:
	return COSMETIC_RNG.sample_palette(COSMETIC_RNG.gradient_for_channel(cosmetic_uid, visual_seed(), "physical-sword-accent", gradient_version), 0.5)

func weapon_appearance_labels() -> Array[String]:
	return [GhostPaletteLibrary.palette_label("sword", weapon_base_index if weapon_base_index >= 0 else palette_index),
			GhostPaletteLibrary.weapon_gradient_label(weapon_gradient_index),
			GhostPaletteLibrary.weapon_detail_a_label(weapon_detail_a_index),
			GhostPaletteLibrary.weapon_detail_b_label(weapon_detail_b_index)]

func visual_seed() -> int:
	return cosmetic_seed if cosmetic_seed >= 0 else item_seed

func cosmetic_seed_number() -> int:
	return visual_seed()

func _cosmetic_fields() -> Array[String]:
	return ["gradient_version", "palette_index", "decoration_index", "weapon_base_index",
		"weapon_gradient_index", "weapon_detail_a_index", "weapon_detail_b_index",
		"weapon_fx_style_index", "weapon_fx_color_index", "weapon_fx_accent_index",
		"weapon_fx_trail_index", "weapon_impact_style_index", "wand_cast_style_index",
		"wand_lance_index", "bow_element_index", "bow_formation_index",
		"bow_glow_index", "bow_trail_index", "bow_detail_index"]

func cosmetic_snapshot() -> Dictionary:
	var look: Dictionary = {"seed": cosmetic_seed_number(), "cosmetic_seed": cosmetic_seed,
		"cosmetic_uid": cosmetic_uid, "rare_visual_mod": rare_visual_mod}
	for field in _cosmetic_fields():
		look[field] = get(field)
	return look

func save_cosmetic_look() -> bool:
	if get_slot() == "none":
		return false
	var snapshot: Dictionary = cosmetic_snapshot()
	for i in range(saved_cosmetic_looks.size()):
		if (not cosmetic_uid.is_empty() and str(saved_cosmetic_looks[i].get("cosmetic_uid", "")) == cosmetic_uid) or (cosmetic_uid.is_empty() and str(saved_cosmetic_looks[i].get("cosmetic_uid", "")).is_empty() and int(saved_cosmetic_looks[i].get("seed", -1)) == int(snapshot["seed"])):
			saved_cosmetic_looks[i] = snapshot
			return true
	if saved_cosmetic_looks.size() >= 16:
		return false
	saved_cosmetic_looks.append(snapshot)
	return true

func restore_cosmetic_look(index: int) -> bool:
	debug_visual_override = -1
	if index < 0 or index >= saved_cosmetic_looks.size():
		return false
	var snapshot: Dictionary = saved_cosmetic_looks[index]
	if snapshot.is_empty():
		return false
	cosmetic_seed = int(snapshot.get("cosmetic_seed", -1))
	cosmetic_uid = str(snapshot.get("cosmetic_uid", ""))
	gradient_version = clampi(int(snapshot.get("gradient_version", 1)), 1, 2)
	rare_visual_mod = int(snapshot.get("rare_visual_mod", -1))
	for field in _cosmetic_fields():
		if snapshot.has(field):
			set(field, int(snapshot[field]))
	return true

func reroll_cosmetic_seed() -> int:
	if get_slot() == "none":
		return cosmetic_seed_number()
	var old_uid: String = cosmetic_uid
	var old_color: int = weapon_fx_color_index if get_slot() in ["sword", "wand"] else palette_index
	# Godot requires a typed empty array here; the previous ternary returned
	# an untyped Array for dresses, making their cosmetic rerolls crash.
	var old_gradient: Array[Color] = []
	if get_slot() in ["sword", "wand"]:
		old_gradient = glow_gradient_colors()
	for attempt in range(32):
		var uid: String = COSMETIC_RNG.fresh_uid()
		if uid.is_empty() or uid == old_uid:
			continue
		apply_cosmetic_uid(uid)
		gradient_version = 2 # Deliberately requested reroll can discover onyx/black.
		var new_color: int = weapon_fx_color_index if get_slot() in ["sword", "wand"] else palette_index
		if get_slot() in ["sword", "wand"]:
			var new_gradient: Array[Color] = glow_gradient_colors()
			var hue_difference: float = absf(old_gradient[0].h - new_gradient[0].h)
			hue_difference = minf(hue_difference, 1.0 - hue_difference)
			if hue_difference > 0.075 or (absf(old_gradient[1].r - new_gradient[1].r) + absf(old_gradient[1].g - new_gradient[1].g) + absf(old_gradient[1].b - new_gradient[1].b)) > 0.45:
				break
		elif new_color != old_color:
			break
	return cosmetic_seed_number()

func apply_cosmetic_uid(uid: String) -> void:
	debug_visual_override = -1
	if get_slot() == "none" or not COSMETIC_RNG.is_valid_uid(uid):
		return
	apply_cosmetic_seed(COSMETIC_RNG.appearance_stream(uid))
	cosmetic_uid = uid
	rare_visual_mod = COSMETIC_RNG.signature(uid, get_slot())
	if _has_mythic_visual(uid):
		rare_visual_mod = 4
	if _has_moonfall_visual(uid):
		rare_visual_mod = 5

# V1.53: complete-spectrum, per-look gradients. Never change the combat seed.
func glow_gradient_colors() -> Array[Color]:
	return COSMETIC_RNG.gradient_for_channel(cosmetic_uid, visual_seed(), effect_palette_channel(), gradient_version)

# Bow limbs and bowstring have *different* independent three-stop gradients.
# Saving/restoring the cosmetic UID reproduces both without new schema fields.
func bow_limb_gradient_colors() -> Array[Color]:
	return COSMETIC_RNG.gradient_for_channel(cosmetic_uid, visual_seed(), "bow-limbs:" + effect_palette_channel(), gradient_version)

func bow_string_gradient_colors() -> Array[Color]:
	return COSMETIC_RNG.gradient_for_channel(cosmetic_uid, visual_seed(), "bow-string:" + effect_palette_channel(), gradient_version)

func mythic_layer_variant() -> int:
	if OS.is_debug_build() and debug_mythic_variant >= 0:
		return clampi(debug_mythic_variant, 0, 3)
	# Four reproducible, visual-only signature layers. No combat RNG draws.
	var material: String = cosmetic_uid if COSMETIC_RNG.is_valid_uid(cosmetic_uid) else "legacy-%d" % visual_seed()
	var digest: PackedByteArray = ("ghost-girl-v168-mythic-layer:" + material).sha256_buffer()
	return posmod(int(digest[0]), 4)

func visual_signature() -> int:
	if OS.is_debug_build() and debug_visual_override >= 0:
		return debug_visual_override
	return genuine_visual_signature()

func genuine_visual_signature() -> int:
	if rare_visual_mod >= 0:
		return rare_visual_mod
	var base_sig: int = COSMETIC_RNG.signature(cosmetic_uid, get_slot())
	if _has_moonfall_visual(cosmetic_uid):
		return 5
	if _has_mythic_visual(cosmetic_uid):
		return 4
	return base_sig

func _has_mythic_visual(uid: String) -> bool:
	# Hidden super-rare visual bless, independent of stats and ordinary signature.
	# Approximately 1/65536 valid UIDs become mythic. Empty/legacy looks never do.
	if uid.is_empty():
		return false
	var hash_value: int = 216613626
	for i in range(uid.length()):
		hash_value = int(((hash_value ^ uid.unicode_at(i)) * 16777619) & 0x7fffffff)
	return (hash_value & 0xffff) == 0x51a7

func _has_moonfall_visual(uid: String) -> bool:
	# Approx. 1/131072 independent UID looks; no global fixed seed table.
	if not COSMETIC_RNG.is_valid_uid(uid):
		return false
	var digest: PackedByteArray = ("moonfall-visual-v159:" + uid.to_lower()).sha256_buffer()
	var ticket: int = int(digest[0]) | (int(digest[1]) << 8) | (int(digest[2]) << 16)
	return (ticket & 0x1ffff) == 0x0cda3

func signature_of_saved_look(look: Dictionary) -> int:
	var stored: int = int(look.get("rare_visual_mod", -1))
	if stored >= 0:
		return stored
	var uid: String = str(look.get("cosmetic_uid", ""))
	if _has_moonfall_visual(uid):
		return 5
	if _has_mythic_visual(uid):
		return 4
	return COSMETIC_RNG.signature(uid, get_slot())

func apply_cosmetic_seed(number: int) -> void:
	if get_slot() == "none":
		return
	# Reroll only equipment appearance, NEVER item_seed/quality/affixes/stats.
	cosmetic_seed = maxi(0, number)
	# Legacy numeric applications deliberately clear the new UID; only the
	# 128-bit ID path grants a new ultra-rare signature.
	cosmetic_uid = ""
	rare_visual_mod = -1
	var colors: RandomNumberGenerator = RandomNumberGenerator.new()
	colors.seed = cosmetic_seed + 11791
	palette_index = colors.randi_range(0, 5)
	var ornament_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	ornament_rng.seed = cosmetic_seed + 73931
	decoration_index = ornament_rng.randi_range(0, 3)
	weapon_base_index = palette_index
	var gradient_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	gradient_rng.seed = cosmetic_seed + 711317
	weapon_gradient_index = gradient_rng.randi_range(0, 5)
	var detail_a_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	detail_a_rng.seed = cosmetic_seed + 711319
	weapon_detail_a_index = detail_a_rng.randi_range(0, 3)
	var detail_b_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	detail_b_rng.seed = cosmetic_seed + 711323
	weapon_detail_b_index = detail_b_rng.randi_range(0, 3)
	var cosmetic: Dictionary = GhostWeaponFXLibrary.roll(cosmetic_seed, quality)
	weapon_fx_style_index = int(cosmetic["motif"])
	weapon_fx_color_index = int(cosmetic["color"])
	weapon_fx_accent_index = int(cosmetic["accent"])
	weapon_fx_trail_index = int(cosmetic["trail"])
	weapon_impact_style_index = int(cosmetic["impact"])
	wand_cast_style_index = int(cosmetic["form"])
	wand_lance_index = int(cosmetic["lance"]) if get_slot() == "wand" else 0
	if weapon_style() == "bow":
		var bow_look: Dictionary = GhostBowImprintsV138.roll(cosmetic_seed, quality)
		bow_element_index = int(bow_look["element"])
		bow_formation_index = int(bow_look["formation"])
		bow_glow_index = int(bow_look["glow"])
		bow_trail_index = int(bow_look["trail"])
		bow_detail_index = int(bow_look["detail"])

func bow_rolls() -> Dictionary:
	var defaults: Dictionary = GhostBowImprintsV138.roll(visual_seed(), quality)
	var imprint: Dictionary = {
		"element": bow_element_index if bow_element_index >= 0 else int(defaults["element"]),
		"formation": bow_formation_index if bow_formation_index >= 0 else int(defaults["formation"]),
		"glow": bow_glow_index if bow_glow_index >= 0 else int(defaults["glow"]),
		"trail": bow_trail_index if bow_trail_index >= 0 else int(defaults["trail"]),
		"detail": bow_detail_index if bow_detail_index >= 0 else int(defaults["detail"])
	}
	imprint["procedural"] = RelicPaletteV139.build(visual_seed(), quality, int(imprint["element"]))
	return imprint

func bow_effect_description() -> String:
	var a: Dictionary = bow_rolls()
	return "%s · %s · %s · %s · %s" % [
		GhostBowImprintsV138.name_for_element(int(a["element"])),
		GhostBowImprintsV138.name_for_formation(int(a["formation"])),
		GhostWeaponFXLibrary.paint_name(int(a["glow"])),
		GhostBowImprintsV138.TRAIL_NAMES[int(a["trail"])],
		GhostBowImprintsV138.DETAIL_NAMES[int(a["detail"])]
	]

func procedural_visuals() -> Dictionary:
	return RelicPaletteV139.build(visual_seed(), quality, 0)

func effect_rolls() -> Dictionary:
	var fallback: Dictionary = GhostWeaponFXLibrary.roll(visual_seed(), quality)
	var lance: int = wand_lance_index if wand_lance_index >= 0 else int(fallback["lance"])
	var cast_form: int = wand_cast_style_index if wand_cast_style_index >= 0 else int(fallback["form"])
	if get_slot() == "wand" and GhostWeaponFXLibrary.tier(quality) >= 2 and lance > 0:
		cast_form = 7
	return {
		"lance": lance if get_slot() == "wand" else 0,
		"motif": weapon_fx_style_index if weapon_fx_style_index >= 0 else int(fallback["motif"]),
		"color": weapon_fx_color_index if weapon_fx_color_index >= 0 else int(fallback["color"]),
		"form": cast_form,
		"tier": GhostWeaponFXLibrary.tier(quality),
		"accent": weapon_fx_accent_index if weapon_fx_accent_index >= 0 else int(fallback["accent"]),
		"trail": weapon_fx_trail_index if weapon_fx_trail_index >= 0 else int(fallback["trail"]),
		"impact": weapon_impact_style_index if weapon_impact_style_index >= 0 else int(fallback["impact"])
	}

func effect_description() -> String:
	var v: Dictionary = effect_rolls()
	var name: String = GhostWeaponFXLibrary.motif_name(int(v["motif"]))
	var ink: String = GhostWeaponFXLibrary.paint_name(int(v["color"]))
	var style: String = GhostWeaponFXLibrary.trail_name(int(v["trail"]))
	var accent: String = GhostWeaponFXLibrary.paint_name(int(v["accent"]))
	var hit_style: String = GhostWeaponFXLibrary.impact_name(get_slot(), int(v["impact"]))
	if get_slot() == "wand":
		return "%s · %s / %s · %s · %s · %s" % [name, ink, accent, style, GhostWeaponFXLibrary.spell_form_name(int(v["form"])), hit_style]
	return "%s · %s / %s · %s · %s" % [name, ink, accent, style, hit_style]

# Collection identity is derived from existing saved looks, not persisted twice.
func collector_appearance() -> Dictionary:
	if get_slot() not in ["sword", "wand"]:
		return {}
	var look: Dictionary = REGIONAL.apply(COLLECTOR_LOOK.roll(cosmetic_uid, visual_seed(), gradient_version), origin_room, regional_rank)
	if OS.is_debug_build():
		if debug_collector_tier >= 0:
			look["material"] = debug_collector_tier
			look["particle_tier"] = debug_collector_tier
		if debug_color_mode >= 0:
			look["color_mode"] = debug_color_mode
		if debug_glow_motif >= 0:
			look["glow_motif"] = debug_glow_motif
		if debug_surface_mode >= 0:
			look["surface_mode"] = clampi(debug_surface_mode, 0, 6)
		if debug_forge_guard >= 0:
			look["forge_guard"] = clampi(debug_forge_guard, 0, 7)
		if debug_forge_grip >= 0:
			look["forge_grip"] = clampi(debug_forge_grip, 0, 5)
	look["signature"] = visual_signature()
	look["signature_variant"] = mythic_layer_variant()
	look.merge(COSMETIC_RNG.animation_profile(cosmetic_uid, visual_seed(), effect_palette_channel()), true)
	return look

# Only independently rolled collector-level cosmetics earn the tooltip star.
# Ignore debug overrides, item quality, and ordinary stat/affix rarity.
func has_rare_seeded_appearance() -> bool:
	if get_slot() not in ["sword", "wand"]:
		return false
	var natural: Dictionary = COLLECTOR_LOOK.roll(cosmetic_uid, visual_seed())
	return maxi(int(natural.get("material", 0)), int(natural.get("particle_tier", 0))) >= 4 or genuine_visual_signature() >= 4

func collector_material_label() -> String:
	var look: Dictionary = collector_appearance()
	return COLLECTOR_LOOK.rarity_label(look) if not look.is_empty() else ""

func palette_color() -> Color:
	return weapon_base_color() if get_slot() == "sword" else COSMETIC_RNG.sample_palette(COSMETIC_RNG.gradient_for_channel(cosmetic_uid, visual_seed(), "physical:" + get_slot(), gradient_version), 0.5)

func palette_name() -> String:
	return GhostPaletteLibrary.palette_label(get_slot(), weapon_base_index if get_slot() == "sword" and weapon_base_index >= 0 else palette_index)

func all_stats() -> Dictionary:
	var totals: Dictionary = {}
	if is_broken():
		return totals
	if definition != null and not definition.stat_id.is_empty():
		totals[definition.stat_id] = stat_value
	for affix in affixes:
		var stat: String = str(affix.get("stat", ""))
		if not stat.is_empty():
			totals[stat] = float(totals.get(stat, 0.0)) + float(affix.get("value", 0.0))
	if ethereal:
		for key in totals.keys():
			totals[key] = snappedf(float(totals[key]) * 1.25, 0.1)
	for jewel in socketed:
		var stat: String = str(jewel.get("stat", ""))
		if not stat.is_empty():
			totals[stat] = float(totals.get(stat, 0.0)) + float(jewel.get("value", 0.0))
	return totals

func stat_label() -> String:
	var lines: Array[String] = []
	for stat in all_stats().keys():
		lines.append("+%.1f%% %s" % [float(all_stats()[stat]), GhostPaletteLibrary.stat_label(str(stat))])
	return " · ".join(lines) if not lines.is_empty() else "A keepsake"

func details(advanced: bool = false) -> String:
	# Legacy plain-text callers also respect the compact default. Internal
	# loot and cosmetic seeds are deliberately not part of item tooltips.
	if definition == null:
		return ""
	var lines: Array[String] = ["%s · Level %d" % [get_slot().to_upper(), item_level]]
	if get_slot() == "sword":
		lines.append("%.1f damage · %.0f reach" % [weapon_damage(), weapon_reach()])
	var stats: Dictionary = all_stats()
	var ids: Array = stats.keys()
	ids.sort()
	for id in ids:
		lines.append("%+.1f%% %s" % [float(stats[id]), GhostPaletteLibrary.stat_label(str(id))])
	if sockets > 0:
		lines.append("Sockets %d/%d" % [socketed.size(), sockets])
	if advanced:
		lines.append(definition.description)
		if get_slot() in ["sword", "wand"]:
			lines.append("Material rarity: " + collector_material_label())
		if get_slot() == "sword":
			lines.append("Light attack %.2fs · %.1f stamina" % [light_swing_duration(), light_stamina_cost()])
		if get_slot() in ["sword", "wand"]:
			var fx: Dictionary = effect_rolls()
			lines.append("Aura: " + GhostWeaponFXLibrary.motif_name(int(fx["motif"])))
			lines.append("Trail: " + GhostWeaponFXLibrary.trail_name(int(fx["trail"])))
			lines.append("Impact: " + GhostWeaponFXLibrary.impact_name(get_slot(), int(fx["impact"])))
			if get_slot() == "wand":
				lines.append("Spell: " + GhostWeaponFXLibrary.spell_form_name(int(fx["form"])))
	return "\n".join(lines)

func stamp_origin(room_id: String) -> void:
	if not origin_room.is_empty() or room_id.is_empty() or get_slot() not in ["sword", "wand"]:
		return
	origin_room = room_id
	regional_rank = REGIONAL.roll_rank(room_id, cosmetic_uid, visual_seed())

func regional_imprint_label() -> String:
	return REGIONAL.imprint_label(origin_room, regional_rank)

func origin_label() -> String:
	return REGIONAL.origin_label(origin_room) if not origin_room.is_empty() else ""

# Only independently drawn weapon families are eligible in this release.
# Never make Ghost Girl's body transparent to imitate a spectral weapon.
func supports_ethereal() -> bool:
	return get_slot() == "wand" or (get_slot() == "sword" and weapon_style() in ["twinblade", "dual_dagger", "dual_sword", "scythe", "halberd", "maul"])

func roll_ethereal() -> void:
	if not supports_ethereal() or ethereal:
		return
	if COLLECTOR_LOOK.ticket(cosmetic_uid, visual_seed(), "v184-ethereal-condition") < 500:
		make_ethereal()

func make_ethereal() -> void:
	if not supports_ethereal() or ethereal:
		return
	ethereal = true
	max_durability = 80 + COLLECTOR_LOOK.ticket(cosmetic_uid, visual_seed(), "v184-durability") % 61
	durability = max_durability

func is_broken() -> bool:
	return ethereal and durability <= 0

func weapon_opacity() -> float:
	return 0.28 if is_broken() else (0.52 if ethereal else 1.0)

func wear_once() -> bool:
	if not ethereal or is_broken():
		return false
	durability = maxi(0, durability - 1)
	return is_broken()

# Discovery feedback is based exclusively on genuine persisted properties.
func discovery_label() -> String:
	if get_slot() not in ["sword", "wand"]:
		return ""
	var genuine: Dictionary = COLLECTOR_LOOK.roll(cosmetic_uid, visual_seed())
	var tier: int = maxi(int(genuine["material"]), int(genuine["particle_tier"]))
	if tier == 6:
		return "ANOMALY DISCOVERED"
	var signature: int = genuine_visual_signature()
	if signature == 5:
		return "MOONFALL DISCOVERED"
	if signature == 4:
		return "MYTHIC DISCOVERED"
	if tier == 5:
		return "ETHEREAL APPEARANCE DISCOVERED"
	if regional_rank == 3:
		return "RADIANT REGIONAL DISCOVERY"
	if ethereal:
		return "ETHEREAL WEAPON DISCOVERED"
	if tier == 4 or signature >= 2:
		return "EXTRAORDINARY DISCOVERY"
	return ""

# Each special effect gets an independent color domain. Debug tier/signature
# changes select the matching domain, not a fixed color set.
func effect_palette_channel() -> String:
	var signature: int = visual_signature()
	var tier: int = COLLECTOR_LOOK.tier_for_ticket(COLLECTOR_LOOK.ticket(cosmetic_uid, visual_seed(), "material-rarity"))
	var particles: int = COLLECTOR_LOOK.tier_for_ticket(COLLECTOR_LOOK.ticket(cosmetic_uid, visual_seed(), "particle-rarity"))
	if OS.is_debug_build() and debug_collector_tier >= 0:
		tier = debug_collector_tier
		particles = debug_collector_tier
	return "effect:%d:%d:%d:%d" % [signature, tier, particles, mythic_layer_variant() if signature == 4 else 0]

func effect_palette_motion() -> Dictionary:
	return COSMETIC_RNG.animation_profile(cosmetic_uid, visual_seed(), effect_palette_channel())
