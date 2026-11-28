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
const SKILLS = preload("res://scripts/unique_specials_v261.gd")
static var _body_font: SystemFont
static var _title_font: SystemFont

static func body_font() -> Font:
	if _body_font == null:
		_body_font = SystemFont.new()
		_body_font.font_names = PackedStringArray(["Segoe UI", "Noto Sans", "DejaVu Sans"])
	return _body_font

static func title_font() -> Font:
	if _title_font == null:
		_title_font = SystemFont.new()
		_title_font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif"])
	return _title_font

static func style_body(label: RichTextLabel) -> void:
	label.add_theme_font_override("normal_font", body_font())
	label.add_theme_font_override("bold_font", title_font())
	label.add_theme_font_size_override("normal_font_size", 14)
	label.add_theme_constant_override("line_separation", 3)
	label.meta_underlined = false

static func special_title(item: Variant) -> String:
	if item == null or item.get_slot() not in ["sword","wand"]:
		return ""
	if item.rainbow_skin:
		return "Prism"
	return "Mythic" if item.visual_signature() == 4 else ""

static func special_title_markup(item: Variant) -> String:
	var title: String = special_title(item)
	if title == "Prism":
		var colors: Array[Color] = item.glow_gradient_colors()
		var glyphs: Array[String] = []
		for i in range(title.length()):
			glyphs.append("[color=%s]%s[/color]" % [color_to_tag(colors[i]), title.substr(i,1)])
		return "[font_size=18][b]" + "".join(glyphs) + "[/b][/font_size]"
	if title == "Mythic":
		return "[font_size=17][color=#e8c6ff][b]Mythic[/b][/font_size]"
	return ""

static func cosmetic_indicator(item: Variant) -> Array[Color]:
	var out: Array[Color] = []
	if item == null or item.get_slot() not in ["sword","wand"]:
		return out
	var colors: Array[Color] = item.glow_gradient_colors()
	return colors

static func skill_hover_details(item: Variant, meta: String) -> String:
	if item == null or meta != "skill:granted":
		return ""
	var ability: String = SKILLS.label(item)
	if ability.is_empty():
		return ""
	var parts: PackedStringArray = ability.split(" · ", true, 1)
	var lines: Array[String] = [parts[0]]
	if parts.size() > 1:
		lines.append(parts[1])
	lines.append("Shift + Mouse2")
	var kind: String = SKILLS.kind(item)
	var mechanics = preload("res://scripts/relic_mechanics_v288.gd")
	if mechanics.is_channel(kind):
		var channel: Dictionary = mechanics.CHANNELS[kind]
		lines.append("Hold Mouse2 · move with WASD")
		lines.append("5 stamina to start · %.0f/s · release or dodge to stop" % float(channel["drain"]))
	elif mechanics.cooldown(kind)>0.0:
		lines.append("%.1fs recharge" % mechanics.cooldown(kind))
	if preload("res://scripts/relic_arsenal_v277.gd").has_skill(kind):
		if item.weapon_style()=="bow":
			lines.append("Hold Shift + Mouse2 to full draw, then release")
		elif item.weapon_style()=="crossbow":
			lines.append("Heavy relic shot · normal reload")
	if SKILLS.is_throw(kind):
		lines.append("Hold to charge · release Mouse2 to throw")
		lines.append("Full charge increases power, speed and reach")
		lines.append("Weapon returns when the throw ends")
	if kind=="eclipse_dance":
		lines.append("Repeat during dance · retreat combo")
	return "\n".join(lines)


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
	var colors: Array[Color] = cosmetic_indicator(item)
	var dots: Array[String] = []
	for ink in colors:
		dots.append("[font_size=19][color=%s]●[/color][/font_size]" % color_to_tag(ink))
	return "  ".join(dots)

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
	var title: String = special_title_markup(item)
	if not title.is_empty():
		out.append(title)
	out.append("[font_size=12][color=%s]%s[/color][/font_size]" % [GOLD if unique_socketable else MUTED, "UNIQUE JEWEL" if unique_socketable else (escape(category.to_upper()) + "  ·  LEVEL %d" % item.item_level)])
	var ability: String = SKILLS.label(item)
	if slot == "sword":
		out.append("[font_size=15][color=%s]%.1f Damage[/color][color=%s]   ·   %.0f Reach[/color][/font_size]" % [GOLD, item.weapon_damage(), MUTED, item.weapon_reach()])
	if item.ethereal:
		out.append("[font_size=13][color=#c1d8e4]ETHEREAL · %s[/color][/font_size]" % ("BROKEN" if item.is_broken() else "%d/%d durability" % [item.durability, item.max_durability]))
		out.append(_label("Cannot be repaired · " + ("Display only" if item.is_broken() else "Enhanced power")))
	var innate = preload("res://scripts/unique_innate_v274.gd")
	var innate_stats: Dictionary = innate.bonuses(item)
	var innate_label: String = innate.label(item)
	var stats: Dictionary = item.all_stats()
	if not innate_label.is_empty():
		out.append("[font_size=14][color=#f0d2a0]Innate: %s[/color][/font_size]" % escape(innate_label))
		for key in innate_stats:
			out.append("[font_size=14][color=#a9d8d3]+%.0f%% %s[/color][/font_size]" % [innate_stats[key],escape(GhostPaletteLibrary.stat_label(str(key)))])
			stats[key]=float(stats.get(key,0.0))-float(innate_stats[key])
			if absf(float(stats[key]))<0.001:
				stats.erase(key)
	if not stats.is_empty():
		var ids: Array = stats.keys()
		ids.sort()
		for id in ids:
			var value: float = float(stats[id])
			var ink: String = BLUE if value >= 0.0 else RED
			out.append("[font_size=15][color=%s]%+.1f%% %s[/color][/font_size]" % [ink, value, escape(GhostPaletteLibrary.stat_label(str(id)))])
	if not ability.is_empty():
		var parts: PackedStringArray = ability.split(" · ", true, 1)
		out.append("[url=skill:granted][font_size=15][color=#f0d2a0]Grants %s[/color][/font_size][/url]" % escape(parts[0]))
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
	var flavor: String = str(item.definition.description).strip_edges()
	if advanced and not flavor.is_empty():
		out.append("[font_size=13][color=%s][i]%s[/i][/color][/font_size]" % [FLAVOUR, escape(flavor)])
	if not advanced:
		if slot in ["sword", "wand"]:
			out.append("[font_size=11][color=%s]P · Inspect[/color][/font_size]" % MUTED)
		if not ability.is_empty():
			out.append("[font_size=11][color=%s]Alt + hover skill for details[/color][/font_size]" % MUTED)
	var dots: String = _cosmetic_dots(item)
	if not dots.is_empty():
		out.append(dots)
	return "\n".join(out)

static func impact_text(_item: Variant) -> String:
	return "" # Compatibility for older callers; never display hit effect labels.

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
