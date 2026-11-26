extends RefCounted
## v1.51 — Diablo II-inspired compact information, with ALT for advanced/cosmetics.
## Do not print stat/loot/cosmetic seed numbers or cosmetic palette names by default.
const ROLL_CODE = preload("res://scripts/collector_roll_code_v1931.gd")
const GOLD = "#dfc38e"
const MUTED = "#a19aa4"
const GREEN = "#9bcfb4"
const RED = "#e6a2a2"
const BLUE = "#a8bcff"
const PALE = "#d9ccd7"
const FLAVOUR = "#c99fd4"
const WEAPON_SURFACE = preload("res://scripts/weapon_surface_v190.gd")

static func escape(raw: String) -> String:
	return raw.replace("[", "[lb]")

static func color_to_tag(ink: Color) -> String:
	return "#" + ink.to_html(false)

static func _label(text_value: String) -> String:
	return "[font_size=12][color=%s]%s[/color][/font_size]" % [MUTED, escape(text_value)]

# These are explicitly named visual channels, NOT a promise that a whole
# weapon will appear in the swatch color. Painted art and layered shaders mix.
static func visual_colors(item: Variant, channel: String) -> Array[Color]:
	var result: Array[Color] = []
	if item == null:
		return result
	match channel:
		"glow":
			return item.glow_gradient_colors()
		"string":
			return item.bow_string_gradient_colors() if item.weapon_style() == "bow" else result
		"surface":
			if item.get_slot() not in ["sword", "wand"]:
				return result
			var look: Dictionary = item.collector_appearance()
			var raw: Array = WEAPON_SURFACE.bow_pigment(item, look) if item.weapon_style() == "bow" else look.get("surface_colors", [])
			for entry in raw:
				if entry is Color:
					result.append(entry)
	return result

static func _visual_row(item: Variant, channel: String, caption: String) -> String:
	var tones: Array[Color] = visual_colors(item, channel)
	if tones.is_empty():
		return ""
	var dots: Array[String] = []
	for ink in tones:
		dots.append("[font_size=20][color=%s]●[/color][/font_size]" % color_to_tag(ink))
	# One wide hover target covers both the caption and the entire color row.
	# The player no longer has to aim at a specific tiny dot.
	return "[url=visual:%s][font_size=13][color=%s]%s[/color][/font_size]   %s[/url]" % [channel, MUTED, caption, "  ".join(dots)]

static func _cosmetic_dots(item: Variant) -> String:
	var rows: Array[String] = []
	if item.weapon_style() == "bow":
		rows.append(_visual_row(item, "surface", "BOW TINT"))
		rows.append(_visual_row(item, "string", "STRING LIGHT"))
	elif item.get_slot() in ["sword", "wand"]:
		rows.append(_visual_row(item, "surface", "SURFACE TINT"))
	rows.append(_visual_row(item, "glow", "FX LIGHT"))
	var present: Array[String] = []
	for line in rows:
		if not line.is_empty():
			present.append(line)
	return "\n".join(present)

# One swatch's visible meaning is explained here, when hovered. Kept out
# of the ordinary item body: Alt only pins the panel for interactive reading.
static func visual_dot_details(item: Variant, meta: String) -> String:
	var tokens: PackedStringArray = meta.split(":")
	if item == null or tokens.size() < 2 or tokens[0] != "visual":
		return ""
	var channel: String = tokens[1]
	var tones: Array[Color] = visual_colors(item, channel)
	if tones.is_empty():
		return ""
	# Legacy per-dot meta still works, but the new UI uses one large target.
	if tokens.size() == 3:
		var legacy_index: int = int(tokens[2])
		if legacy_index < 0 or legacy_index >= tones.size():
			return ""
	match channel:
		"surface":
			return "Bow colors · whole bow palette" if item.weapon_style() == "bow" else "Weapon colors · material gradient"
		"string":
			return "Bowstring glow · separate from the bow colors"
		"glow":
			return "Special glow · effects around the item"
	return ""

static func _swatch_colors(colors: Array[Color]) -> String:
	var pieces: Array[String] = []
	for color in colors:
		pieces.append("[color=%s]●[/color]" % color_to_tag(color))
	return "  ".join(pieces)

const LOOK_CHOICES_V219 = preload("res://scripts/visual_choices_v216.gd")

static func item_info(item: Variant, advanced: bool = false) -> String:
	if item == null or item.definition == null:
		return ""
	var out: Array[String] = []
	var slot: String = str(item.get_slot())
	var item_class: String = str(item.definition.item_class)
	var category: String = ("HEAD ACCESSORY" if slot == "wings" else ("TIARA / DIADEM" if slot == "helm" else slot)) if slot != "none" else item_class
	if slot == "sword" and item.physical_damage_kind() == "blunt":
		category = "BLUNT WEAPON"
	var unique_socketable: bool = item.definition.unique and item_class in ["gem", "rune"]
	out.append("[font_size=12][color=%s]%s[/color][/font_size]" % [GOLD if unique_socketable else MUTED, "UNIQUE JEWEL" if unique_socketable else (escape(category.to_upper()) + "  ·  LEVEL %d" % item.item_level)])
	if slot == "sword":
		out.append("[font_size=15][color=%s]%.1f Damage[/color][color=%s]   ·   %.0f Reach[/color][/font_size]" % [GOLD, item.weapon_damage(), MUTED, item.weapon_reach()])
	if item.ethereal:
		out.append("[font_size=13][color=#c1d8e4]ETHEREAL · %s[/color][/font_size]" % ("BROKEN" if item.is_broken() else "%d/%d durability" % [item.durability, item.max_durability]))
		out.append(_label("Cannot be repaired · " + ("Display only" if item.is_broken() else "Enhanced power")))
	var stats: Dictionary = item.all_stats()
	if not stats.is_empty():
		var ids: Array = stats.keys()
		ids.sort()
		for id in ids:
			var value: float = float(stats[id])
			var ink: String = BLUE if value >= 0.0 else RED
			out.append("[font_size=15][color=%s]%+.1f%% %s[/color][/font_size]" % [ink, value, escape(GhostPaletteLibrary.stat_label(str(id)))])
	if int(item.sockets) > 0:
		out.append("[font_size=13][color=%s]◈  SOCKETS (%d/%d)[/color][/font_size]" % [GOLD, item.socketed.size(), item.sockets])
		for jewel in item.socketed:
			var name: String = str(jewel.get("name", "Gem"))
			var special: bool = str(jewel.get("id", "")) in ["malady_jewel", "delirium_jewel", "exile_jewel"]
			if special:
				out.append("[font_size=12][color=%s]◆ %s[/color][/font_size]" % [GOLD, escape(name)])
			elif advanced:
				out.append(_label("◇ " + name))
	if item_class in ["gem", "rune"]:
		out.append("[font_size=14][color=%s]+%.1f%% %s[/color][/font_size]" % [GOLD if unique_socketable else BLUE, item.definition.socket_bonus_value, escape(GhostPaletteLibrary.stat_label(item.definition.socket_bonus_id))])
	if slot != "none":
		out.append(_cosmetic_dots(item))
	if slot in ["sword", "wand"] and not item.regional_imprint_label().is_empty():
		out.append("[font_size=13][color=%s]✦ %s[/color][/font_size]" % [GOLD, escape(item.regional_imprint_label())])
	if slot in ["sword", "wand"] and advanced:
		var code: String = ROLL_CODE.current(item)
		var birth: String = item.birth_roll_code_v1 if ROLL_CODE.valid_code(item.birth_roll_code_v1) else "unknown (legacy)"
		out.append("[font_size=14][color=#dfc38e]ROLL · %s[/color][/font_size]" % code)
		out.append(_label("Original · " + birth))
		if ROLL_CODE.debug_active(item):
			out.append(_label("TEST FX active · genuine rolls unchanged"))
		if advanced:
			out.append(_label("V1 · - means not ranked / not applicable"))
			out.append(_label(ROLL_CODE.breakdown(code)))
			if birth != "unknown (legacy)":
				out.append(_label("Original seed" if item.cosmetic_uid == item.birth_roll_uid_v1 else "Current seed differs from original"))
	if advanced:
		if LOOK_CHOICES_V219.has_personalization(item):
			out.append(_label("Personalized appearance · not a new rarity roll"))
		for detail in LOOK_CHOICES_V219.appearance_details(item):
			out.append(_label(detail))
	var flavor: String = str(item.definition.description).strip_edges()
	if not flavor.is_empty():
		out.append("[font_size=13][color=%s][i]%s[/i][/color][/font_size]" % [FLAVOUR, escape(flavor)])
	# Keep special seeded visuals visible in the ordinary hover tooltip,
	# even when ALT is not held. Detailed roll codes stay in Inspect.
	var preview_only: bool = ROLL_CODE.debug_active(item)
	if item.has_rare_seeded_appearance():
		var appearance_label: String = "TEST material" if preview_only else "Rare appearance"
		out.append("[font_size=13][color=%s]✦ %s: %s[/color][/font_size]" % [GOLD, appearance_label, escape(item.collector_material_label())])
	if item.visual_signature() > 0:
		var level: int = item.visual_signature()
		var signature_label: String = "Mythic Radiance" if level == 4 else ("Moonfall Halo" if level == 5 else GhostCosmeticRNGV152.signature_name(level))
		out.append("[font_size=13][color=%s]✦ %s: %s[/color][/font_size]" % [GOLD, "TEST effect" if preview_only else "Special look", escape(signature_label)])
	if slot in ["sword", "wand"]:
		var visible_fx: Dictionary = item.effect_rolls()
		out.append(_label("Glow: " + GhostWeaponFXLibrary.motif_name(int(visible_fx.get("motif", 0))) + "  ·  Trail: " + GhostWeaponFXLibrary.trail_name(int(visible_fx.get("trail", 0)))))
		if item.weapon_style() == "bow":
			var arrow_style: Dictionary = item.bow_rolls()
			out.append(_label("Arrow: " + GhostBowImprintsV138.name_for_element(int(arrow_style.get("element", 0)))))
	if not advanced:
		if slot in ["sword", "wand"]:
			out.append("[font_size=11][color=%s]P  ·  Inspect weapon[/color][/font_size]" % MUTED)
		out.append("[font_size=11][color=%s]HOLD ALT  ·  Pin for color details[/color][/font_size]" % MUTED)
		return "\n".join(out)
	
	if slot == "sword":
		out.append(_label("Light strike %.2fs  ·  %.1f stamina" % [item.light_swing_duration(), item.light_stamina_cost()]))
	if slot in ["dress", "wings", "helm", "trinket", "charm"] and item.visual_signature() in [4, 5]:
		out.append("[font_size=13][color=%s]✦ %s[/color][/font_size]" % [GOLD, "Moonfall Halo" if item.visual_signature() == 5 else "Mythic Radiance"])
		out.append(_label("Luminous dress aura" if slot == "dress" else "Spectral accessory glimmer"))
	if slot in ["sword", "wand"]:
		if not item.origin_label().is_empty():
			out.append(_label("Found in " + item.origin_label()))
		var fx: Dictionary = item.effect_rolls()
		# ALT reveals what the item *does visually*, not its internal RNG identifiers.
		if item.visual_signature() > 0:
			var signature_level: int = item.visual_signature()
			var signature_title: String = "Mythic Radiance" if signature_level == 4 else ("Moonfall Halo" if signature_level == 5 else GhostCosmeticRNGV152.signature_name(signature_level))
			out.append("[font_size=13][color=%s]✦ %s · %s[/color][/font_size]" % [GOLD, "TEST EFFECT" if ROLL_CODE.debug_active(item) else "EXTREMELY RARE", escape(signature_title)])
			if signature_level == 4:
				var layers: Array[String] = ["Lightning arcs", "Cinder motes", "Astral pulses", "Spectral petals"]
				out.append(_label("Mythic animation · " + layers[item.mythic_layer_variant()]))
		out.append("[font_size=12][color=%s]✧  VISUAL EFFECTS[/color][/font_size]" % GOLD)
		out.append(_label("Aura  ·  " + GhostWeaponFXLibrary.motif_name(int(fx["motif"]))))
		out.append(_label("Trail  ·  " + GhostWeaponFXLibrary.trail_name(int(fx["trail"]))))
		out.append(_label("On hit  ·  " + GhostWeaponFXLibrary.impact_name(slot, int(fx["impact"]))))
		if slot == "wand":
			out.append(_label("Spell  ·  " + GhostWeaponFXLibrary.spell_form_name(int(fx["form"]))))
			if int(fx["lance"]) > 0:
				out.append(_label("Rare beam appearance"))
		elif item.weapon_style() == "bow":
			var bow: Dictionary = item.bow_rolls()
			var limb: Array[Color] = item.bow_limb_gradient_colors()
			var string_colors: Array[Color] = item.bow_string_gradient_colors()
			out.append("[font_size=12][color=%s]Bow limbs[/color]  %s[/font_size]" % [MUTED, _swatch_colors(limb)])
			out.append("[font_size=12][color=%s]Bowstring[/color]  %s[/font_size]" % [MUTED, _swatch_colors(string_colors)])
			out.append(_label("Arrow  ·  " + GhostBowImprintsV138.name_for_element(int(bow["element"]))))
		if int(item.saved_cosmetic_looks.size()) > 0:
			out.append(_label("★ %d saved appearances" % item.saved_cosmetic_looks.size()))
	return "\n".join(out)

static func changes(candidate: Variant, worn: Variant) -> String:
	if candidate == null or worn == null:
		return ""
	var a: Dictionary = candidate.all_stats()
	var b: Dictionary = worn.all_stats()
	var ids: Array = a.keys()
	for key in b.keys():
		if not ids.has(key):
			ids.append(key)
	ids.sort()
	var lines: Array[String] = ["[font_size=12][color=%s]IF EQUIPPED INSTEAD[/color][/font_size]" % GOLD]
	var count: int = 0
	if candidate.get_slot() == "sword" and worn.get_slot() == "sword":
		var delta: float = candidate.weapon_damage() - worn.weapon_damage()
		if absf(delta) >= 0.05:
			lines.append("[font_size=15][color=%s]%+.1f Blade Damage[/color][/font_size]" % [GREEN if delta > 0.0 else RED, delta])
			count += 1
		var duration: float = worn.light_swing_duration() - candidate.light_swing_duration()
		if absf(duration) >= 0.005:
			lines.append("[font_size=13][color=%s]%+.2fs Quicker Light Strike[/color][/font_size]" % [GREEN if duration > 0.0 else RED, duration])
			count += 1
		var reach: float = candidate.weapon_reach() - worn.weapon_reach()
		if absf(reach) >= 1.0:
			lines.append("[font_size=13][color=%s]%+.0f Reach[/color][/font_size]" % [GREEN if reach > 0.0 else RED, reach])
			count += 1
	for id in ids:
		var delta: float = float(a.get(id, 0.0)) - float(b.get(id, 0.0))
		if absf(delta) < 0.05:
			continue
		lines.append("[font_size=15][color=%s]%+.1f%% %s[/color][/font_size]" % [GREEN if delta > 0.0 else RED, delta, escape(GhostPaletteLibrary.stat_label(str(id)))])
		count += 1
	if count == 0:
		lines.append(_label("No stat difference"))
	return "\n".join(lines)
