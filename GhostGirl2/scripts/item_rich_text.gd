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
	var ability: String = preload("res://scripts/unique_specials_v261.gd").label(item)
	if not ability.is_empty():
		out.append("[font_size=14][color=%s]%s[/color][/font_size]" % [GOLD,escape(ability)])
		out.append("[font_size=12][color=#9cb9de]SHIFT + MOUSE2 · SPECIAL ATTACK[/color][/font_size]")
	if not item.weapon_mod.is_empty():
		var special: String = str(preload("res://scripts/weapon_mods_v250.gd").LABELS.get(item.weapon_mod, ""))
		if not special.is_empty():
			out.append("[font_size=15][color=%s]%s[/color][/font_size]" % [GOLD, escape(special)])
	if OS.is_debug_build() and not item.debug_weapon_mod.is_empty():
		var preview: String = str(preload("res://scripts/weapon_mods_v250.gd").LABELS.get(item.debug_weapon_mod, ""))
		out.append("[font_size=12][color=#9cb9de]TEST ONLY · %s (Lanternhaven)[/color][/font_size]" % escape(preview))
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
	if slot == "dress" and item.is_ethereal_dress():
		out.append("[color=#c1d8e4]Ethereal[/color]")
	if advanced and slot != "none":
		var dots: String = _cosmetic_dots(item)
		if not dots.is_empty():
			out.append(dots)
		if slot in ["sword", "wand"]:
			var code: String = ROLL_CODE.current(item)
			var birth: String = item.birth_roll_code_v1 if ROLL_CODE.valid_code(item.birth_roll_code_v1) else "unknown"
			out.append("[font_size=14][color=#dfc38e]ROLL · %s[/color][/font_size]" % code)
			out.append(_label("Original · " + birth))
			if ROLL_CODE.debug_active(item):
				out.append(_label("Test preview · genuine roll unchanged"))
		if LOOK_CHOICES_V219.has_personalization(item):
			out.append(_label("Personalized appearance · not a new roll"))
	var flavor: String = str(item.definition.description).strip_edges()
	if not flavor.is_empty():
		out.append("[font_size=13][color=%s][i]%s[/i][/color][/font_size]" % [FLAVOUR, escape(flavor)])
	if not advanced:
		if slot in ["sword", "wand"]:
			out.append("[font_size=11][color=%s]P · Inspect[/color][/font_size]" % MUTED)
		out.append("[font_size=11][color=%s]HOLD ALT · Colors & roll[/color][/font_size]" % MUTED)
	return "\n".join(out)

static func impact_text(item: Variant) -> String:
	if item == null or item.get_slot() not in ["sword", "wand"]:
		return ""
	if item.get_slot() == "sword" and item.physical_damage_kind() == "blunt":
		return "Heavy impact"
	return GhostWeaponFXLibrary.impact_name(item.get_slot(), int(item.effect_rolls().get("impact", 0)))

static func impact_color(item: Variant) -> Color:
	if item.get_slot() == "wand":
		return GhostWeaponFXLibrary.color(int(item.effect_rolls().get("color", 0))).lightened(0.25)
	if item.physical_damage_kind() == "blunt":
		return Color("d9b795")
	return Color("df829c").lerp(GhostWeaponFXLibrary.color(int(item.effect_rolls().get("color", 0))), 0.19)

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
