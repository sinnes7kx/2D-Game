extends RefCounted
class_name GhostPaletteLibrary
## Palette/ornament labels shared by item instances and generator.
const DRESS_COLORS = [
	Color("b7a7c5"), Color("829ab4"), Color("cfabc0"),
	Color("a19bac"), Color("b3bca8"), Color("b1a8d1")
]
const WING_COLORS = [
	Color("c0badb"), Color("9db7d2"), Color("d7a4c4"),
	Color("998aa7"), Color("b5c9c0"), Color("c7b9de")
]
const ACCENT_COLORS = [
	Color("b89abe"), Color("7d9bb8"), Color("d7a6b7"),
	Color("c5b0dd"), Color("9caeae"), Color("d3b7a0")
]
const WEAPON_COLORS = [
	Color("d9b3db"), Color("80b9e7"), Color("ed91b6"),
	Color("a39cf1"), Color("78cbbd"), Color("efbb83")
]
const WEAPON_LABELS = ["Roseglow", "Frostsilver", "Bloodrose", "Amethyst", "Sea-Moon", "Dawnbrass"]
const LABELS = ["Heather", "Frost", "Dusty Rose", "Twilight", "Sage", "Moonstone"]

static func color_for_slot(slot: String, index: int) -> Color:
	var palette = DRESS_COLORS if slot == "dress" else (WING_COLORS if slot == "wings" else (WEAPON_COLORS if slot in ["sword", "wand"] else ACCENT_COLORS))
	return palette[posmod(index, palette.size())]

static func palette_label(slot: String, index: int) -> String:
	return WEAPON_LABELS[posmod(index, WEAPON_LABELS.size())] if slot in ["sword", "wand"] else LABELS[posmod(index, LABELS.size())]

static func stat_label(stat: String) -> String:
	match stat:
		"move_speed_pct": return "walking speed"
		"hook_range_pct": return "hook reach"
		"hook_pull_pct": return "hook pulling power"
		"throw_force_pct": return "throwing force"
		"spell_power_pct": return "wand spell power"
		"vitality_pct": return "vitality"
		"melee_power_pct": return "melee attack damage"
		"heavy_power_pct": return "heavy attack damage"
		"attack_speed_pct": return "attack speed"
		"stamina_efficiency_pct": return "reduced stamina costs"
		"poise_power_pct": return "poise breaking"
		"counter_damage_pct": return "backstep counter damage"
		"rally_power_pct": return "rally healing"
		"cast_speed_pct": return "wand casting speed"
		"charged_spell_pct": return "charged wand damage"
		"backstep_efficiency_pct": return "backstep efficiency"
		"stamina_recovery_pct": return "stamina regeneration"
		"find_bonus_pct": return "item discovery"
		_: return stat.replace("_", " ")

# v1.11: Four independent weapon appearance channels, with stable legacy colors.
const WEAPON_GRADIENTS = [
	Color("9dc8ed"), Color("e6a6c9"), Color("b5acf4"),
	Color("9ed9cf"), Color("eed4a4"), Color("7677af")
]
const WEAPON_GRADIENT_LABELS = [
	"Moonfade", "Duskwash", "Amethyst Mist", "Sea-Fog", "Amberfall", "Midnight Haze"
]
const WEAPON_DETAIL_A_LABELS = ["Brushed Steel", "Moonstone Veins", "Rose Etching", "Frost Grain"]
const WEAPON_DETAIL_B_LABELS = ["Silver Scratches", "Star-Cracked", "Thorn Filigree", "Celestial Lace"]

static func weapon_gradient_color(index: int) -> Color:
	return WEAPON_GRADIENTS[posmod(index, WEAPON_GRADIENTS.size())]

static func weapon_gradient_label(index: int) -> String:
	return WEAPON_GRADIENT_LABELS[posmod(index, WEAPON_GRADIENT_LABELS.size())]

static func weapon_detail_a_label(index: int) -> String:
	return WEAPON_DETAIL_A_LABELS[posmod(index, WEAPON_DETAIL_A_LABELS.size())]

static func weapon_detail_b_label(index: int) -> String:
	return WEAPON_DETAIL_B_LABELS[posmod(index, WEAPON_DETAIL_B_LABELS.size())]
