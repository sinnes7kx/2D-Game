extends RefCounted
## Fixed base-specific powers, not randomized affixes. No persisted fields.
## Existing active special weapons retain their active ability instead.
const SPECIALS = preload("res://scripts/unique_specials_v261.gd")
# [name, first stat, value, second stat, value]. Explicit authoring rather
# than hashing a generic bonus onto unrelated items.
const POWERS: Dictionary = {
	"ashbound_wand":["Ashen Invocation","spell_power_pct",12,"charged_spell_pct",7],
	"briar_wand":["Thorn Communion","cast_speed_pct",10,"hook_range_pct",8],
	"hunter_censer_wand":["Incense of Mercy","rally_power_pct",14,"spell_power_pct",7],
	"blackthorn_bow_v234":["Widow's Volley","attack_speed_pct",8,"heavy_power_pct",8],
	"blackthorn_crossbow_v236":["Requiem Bolt","poise_power_pct",14,"attack_speed_pct",5],
	"moonveil_bow":["Moonlit Aim","stamina_efficiency_pct",9,"counter_damage_pct",8],
	"thornrose_bow":["Briar's Flight","attack_speed_pct",7,"stamina_recovery_pct",11],
	"mourning_yew_bow_v238":["Grief Drawn","heavy_power_pct",12,"stamina_efficiency_pct",5],
	"reliquary_silver_bow_v234":["Silver Promise","poise_power_pct",11,"stamina_efficiency_pct",7],
	"v202_fletcher_moonflight_bow":["Falling Star","attack_speed_pct",10,"move_speed_pct",3],
	"vesper_recurve_bow_v238":["Evenfall Aim","backstep_efficiency_pct",12,"attack_speed_pct",6],
	"silver_reliquary_crossbow_v236":["Saint's Verdict","heavy_power_pct",14,"poise_power_pct",6],
	"vesper_latch_crossbow_v237":["Final Word","attack_speed_pct",11,"stamina_efficiency_pct",6],
	"ossuary_arbalest_v237":["Bone Covenant","poise_power_pct",19,"move_speed_pct",2],
	"bloodrose_falchion":["Blood Remembers","rally_power_pct",18,"melee_power_pct",5],
	"mourning_longsword":["Edge of Grief","counter_damage_pct",15,"attack_speed_pct",5],
	"moonveil_grandblade":["Hollow Moon","heavy_power_pct",15,"stamina_recovery_pct",6],
	"vesper_arming_sword_v235":["Vesper's Oath","melee_power_pct",9,"backstep_efficiency_pct",7],
	"ossuary_falchion_v235":["Grave Demand","poise_power_pct",13,"melee_power_pct",6],
	"thornveil_sabre_v235":["Thorn's Kiss","attack_speed_pct",12,"rally_power_pct",7],
	"thornwake_sabre":["Briar Reckoning","melee_power_pct",7,"stamina_efficiency_pct",9],
	"vesper_rapier":["Heart's Silence","counter_damage_pct",19,"attack_speed_pct",4],
	"dusk_needle":["Night Needle","attack_speed_pct",14,"backstep_efficiency_pct",5],
	"lunar_vigil_halberd":["Endless Vigil","poise_power_pct",16,"counter_damage_pct",9],
	"ashglass_warmaul_v170":["Cathedral Ruin","heavy_power_pct",17,"poise_power_pct",8],
	"v203_mournful_mace":["Mercy Denied","poise_power_pct",15,"rally_power_pct",8],
	"v203_nightchain_flail":["Unbroken Chain","stamina_efficiency_pct",10,"poise_power_pct",8],
	"v203_rosequartz_morningstar":["Dawn Sorrow","heavy_power_pct",11,"rally_power_pct",11],
	"vesper_athame_v233":["Blood Covenant","rally_power_pct",20,"attack_speed_pct",4],
	"ivory_misericorde_v233":["Ivory Mercy","counter_damage_pct",21,"stamina_efficiency_pct",4],
	"reliquary_knife_v238":["Saint's Wound","melee_power_pct",8,"rally_power_pct",13],
	"moonlace_dual_daggers_v173":["Moon's Teeth","attack_speed_pct",13,"stamina_recovery_pct",6],
	"mourninglace_dual_daggers_v231":["Weeping Sisters","rally_power_pct",12,"backstep_efficiency_pct",12],
	"gloamrose_dual_swords_v174":["Bride and Widow","melee_power_pct",8,"counter_damage_pct",13],
	"cathedral_dual_swords_v233":["Broken Vows","heavy_power_pct",13,"poise_power_pct",9],
	"vesperthorn_dual_swords_v231":["Sorrow and Solace","rally_power_pct",14,"stamina_efficiency_pct",8],
	"rosemirror_twinblade_v170":["Rose Reflection","counter_damage_pct",12,"attack_speed_pct",8],
	"cathedral_thorn_twinblade_v231":["Martyr Crown","heavy_power_pct",10,"poise_power_pct",13],
	"widowglass_twinblade_v231":["Widow Embrace","attack_speed_pct",9,"stamina_recovery_pct",10],
	"moonwoven_dress":["Moon Bride","vitality_pct",9,"move_speed_pct",3],
	"thornlace_dress":["Thorned Veil","backstep_efficiency_pct",13,"rally_power_pct",7],
	"hunter_sable_dress":["Night Mourning","stamina_efficiency_pct",8,"vitality_pct",7],
	"moonwisp_companion_v239":["Last Lantern","find_bonus_pct",8,"move_speed_pct",2],
	"v202_crescent_halo":["Saint Eclipse","spell_power_pct",8,"stamina_recovery_pct",8],
	"v202_moonlit_tiara":["Pale Coronation","vitality_pct",8,"cast_speed_pct",6],
	"v202_starfall_diadem":["Heaven's Tears","charged_spell_pct",13,"cast_speed_pct",5],
	"v202_rose_horns":["Briar Crown","poise_power_pct",10,"heavy_power_pct",6],
	"rosewing_mantle":["Fallen Choir","move_speed_pct",4,"backstep_efficiency_pct",9],
	"mourning_locket":["Mother's Grief","rally_power_pct",16,"vitality_pct",5],
	"gloamglass_locket":["Fading Heart","stamina_recovery_pct",12,"vitality_pct",4],
	"velvet_reliquary":["Velvet Prison","stamina_efficiency_pct",9,"hook_pull_pct",8],
	"blackbrick_reliquary":["Black Testament","poise_power_pct",12,"vitality_pct",5],
	"ash_vigil_charm":["Ashen Covenant","charged_spell_pct",11,"heavy_power_pct",5],
	"silver_thread_charm":["Fate's Thread","hook_range_pct",13,"find_bonus_pct",5],
	"sylvan_charm":["Woods Remember","find_bonus_pct",11,"hook_pull_pct",5],
	"hunter_duelist_rosary":["Penitent Prayer","counter_damage_pct",16,"backstep_efficiency_pct",6],
	"hunter_thorn_sigil":["Thorned Pact","melee_power_pct",6,"poise_power_pct",11],
	"v202_bandit_mask":["Nameless Face","move_speed_pct",4,"find_bonus_pct",6],
	"v202_luminous_eyes":["Unseeing","find_bonus_pct",9,"cast_speed_pct",4],
	"censer_of_the_fourth_bell":["Fourth Chime","charged_spell_pct",14,"stamina_recovery_pct",7],
	"lament_moonbow":["Four Laments","attack_speed_pct",9,"counter_damage_pct",11],
	"veilkeeper_reaper":["Veilkeeper's Vigil","counter_damage_pct",17,"rally_power_pct",9],
	"bellglass_reliquary":["Bellglass Echo","stamina_recovery_pct",15,"hook_range_pct",5],
	"vesperglass_wand":["Vesperglass Light","spell_power_pct",10,"cast_speed_pct",9],
	"rafterfall_moonbow":["Rafterfall","throw_force_pct",10,"attack_speed_pct",8],
	"widows_knot":["Widow's Knot","hook_pull_pct",15,"backstep_efficiency_pct",7],
	"chainwake_amulet":["Chainwake","hook_range_pct",15,"stamina_efficiency_pct",6],
	"mourning_girder_bow":["Girder's Resolve","stamina_recovery_pct",14,"heavy_power_pct",7],
	"chimekeeper_rosary":["Chimekeeper","stamina_recovery_pct",13,"cast_speed_pct",7],
	"choral_moonbow":["Moon Choir","attack_speed_pct",10,"stamina_efficiency_pct",8],
	"emberfrost_stave":["Emberfrost","heavy_power_pct",9,"stamina_recovery_pct",9],
	"sunlace_longbow":["Sunlace","attack_speed_pct",11,"find_bonus_pct",5]
}

static func profile(item: Variant) -> Array:
	if item==null or item.definition==null or item.is_broken() or item.get_slot()=="none":
		return []
	if item.quality!="unique" and not item.definition.unique:
		return []
	if not SPECIALS.kind(item).is_empty():
		return []
	return POWERS.get(item.definition.resource_path.get_file().get_basename(),[])

static func bonuses(item: Variant) -> Dictionary:
	var p: Array = profile(item)
	return {p[1]:float(p[2]),p[3]:float(p[4])} if p.size()==5 else {}

static func label(item: Variant) -> String:
	var p: Array = profile(item)
	return str(p[0]) if p.size()==5 else ""
