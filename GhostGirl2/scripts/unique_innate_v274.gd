extends RefCounted
## Fixed base-specific powers, not randomized affixes. No persisted fields.
## Existing active special weapons retain their active ability instead.
# [name, first stat, value, second stat, value]. Explicit authoring rather
# than hashing a generic bonus onto unrelated items.
const POWERS: Dictionary = {
	"nightglass_rapier_v286":["Nightglass Reversal","counter_damage_pct",18,"backstep_efficiency_pct",8],
	"moonneedle_rapier_v283":["Lunar Oath","attack_speed_pct",10,"counter_damage_pct",12],
	"briar_hatchet_v283":["Briar's Severance","attack_speed_pct",14,"stamina_efficiency_pct",7],
	"mourning_longsword":["Grief's Edge","rally_power_pct",19,"melee_power_pct",7],
	"moonlace_dual_daggers_v173":["Moon's Teeth","attack_speed_pct",15,"move_speed_pct",4],
	"mourninglace_dual_daggers_v231":["Weeping Sisters","stamina_recovery_pct",16,"stamina_efficiency_pct",8],
	"gloamrose_dual_swords_v174":["Bride and Widow","attack_speed_pct",12,"counter_damage_pct",10],
	"cathedral_dual_swords_v233":["Broken Vows","poise_power_pct",16,"heavy_power_pct",9],
	"vesperthorn_dual_swords_v231":["Sorrow and Solace","rally_power_pct",22,"vitality_pct",5],
	"widowglass_twinblade_v231":["Widow Embrace","backstep_efficiency_pct",10,"attack_speed_pct",12],
	"vesper_recurve_bow_v238":["Evenfall Aim","stamina_efficiency_pct",11,"attack_speed_pct",8],
	"mourning_girder_bow":["Girder's Resolve","poise_power_pct",17,"heavy_power_pct",8],
	"choral_moonbow":["Moon Choir","stamina_recovery_pct",14,"attack_speed_pct",9],
	"vesper_latch_crossbow_v237":["The Last Word","attack_speed_pct",12,"stamina_efficiency_pct",9],
	"v203_nightchain_flail":["Unbroken Chain","poise_power_pct",14,"stamina_efficiency_pct",10],
	"cinderveil_dirk_v238":["Ember's Promise","melee_power_pct",12,"rally_power_pct",10],
	"roseglass_dagger_v169":["Rose's Secret","counter_damage_pct",15,"attack_speed_pct",8],
	"silkglass_dirk_v276":["Winterglass","backstep_efficiency_pct",13,"move_speed_pct",3],
	"bellthorn_lance_v276":["Bellthorn Judgment","heavy_power_pct",13,"poise_power_pct",15],
	"ivory_misericorde_v233":["Ivory Absolution","rally_power_pct",21,"stamina_efficiency_pct",6],
	"reliquary_knife_v238":["Reliquary Seal","counter_damage_pct",11,"stamina_recovery_pct",14],
	"ashbound_wand":["Ashen Invocation","spell_power_pct",12,"cast_speed_pct",7],
	"briar_wand":["Thorn Communion","cast_speed_pct",10,"hook_range_pct",8],
	"hunter_censer_wand":["Incense of Mercy","rally_power_pct",14,"spell_power_pct",7],
	"bloodrose_falchion":["Blood Remembers","rally_power_pct",18,"melee_power_pct",5],
	"vesper_arming_sword_v235":["Vesper's Oath","melee_power_pct",9,"backstep_efficiency_pct",7],
	"ossuary_falchion_v235":["Grave Demand","poise_power_pct",13,"melee_power_pct",6],
	"thornveil_sabre_v235":["Thorn's Kiss","attack_speed_pct",12,"rally_power_pct",7],
	"thornwake_sabre":["Briar Reckoning","melee_power_pct",7,"stamina_efficiency_pct",9],
	"dusk_needle":["Night Needle","attack_speed_pct",14,"backstep_efficiency_pct",5],
	"vesper_athame_v233":["Blood Covenant","rally_power_pct",20,"attack_speed_pct",4],
	"moonwoven_dress":["Moon Bride","vitality_pct",9,"move_speed_pct",3],
	"thornlace_dress":["Thorned Veil","backstep_efficiency_pct",13,"rally_power_pct",7],
	"hunter_sable_dress":["Night Mourning","stamina_efficiency_pct",8,"vitality_pct",7],
	"moonwisp_companion_v239":["Last Lantern","stamina_recovery_pct",8,"move_speed_pct",2],
	"v202_crescent_halo":["Saint Eclipse","spell_power_pct",8,"stamina_recovery_pct",8],
	"v202_moonlit_tiara":["Pale Coronation","vitality_pct",8,"cast_speed_pct",6],
	"v202_starfall_diadem":["Heaven's Tears","spell_power_pct",13,"cast_speed_pct",5],
	"v202_rose_horns":["Briar Crown","poise_power_pct",10,"heavy_power_pct",6],
	"rosewing_mantle":["Fallen Choir","move_speed_pct",4,"backstep_efficiency_pct",9],
	"mourning_locket":["Mother's Grief","rally_power_pct",16,"vitality_pct",5],
	"gloamglass_locket":["Fading Heart","stamina_recovery_pct",12,"vitality_pct",4],
	"velvet_reliquary":["Velvet Prison","stamina_efficiency_pct",9,"hook_pull_pct",8],
	"blackbrick_reliquary":["Black Testament","poise_power_pct",12,"vitality_pct",5],
	"ash_vigil_charm":["Ashen Covenant","spell_power_pct",11,"heavy_power_pct",5],
	"silver_thread_charm":["Fate's Thread","hook_range_pct",13,"move_speed_pct",3],
	"sylvan_charm":["Woods Remember","hook_range_pct",8,"hook_pull_pct",11],
	"hunter_duelist_rosary":["Penitent Prayer","counter_damage_pct",16,"backstep_efficiency_pct",6],
	"hunter_thorn_sigil":["Thorned Pact","melee_power_pct",6,"poise_power_pct",11],
	"v202_bandit_mask":["Nameless Face","move_speed_pct",4,"backstep_efficiency_pct",6],
	"v202_luminous_eyes":["Unseeing","spell_power_pct",9,"cast_speed_pct",4],
	"censer_of_the_fourth_bell":["Fourth Chime","spell_power_pct",14,"stamina_recovery_pct",7],
	"veilkeeper_reaper":["Veilkeeper's Vigil","counter_damage_pct",17,"rally_power_pct",9],
	"bellglass_reliquary":["Bellglass Echo","stamina_recovery_pct",15,"hook_range_pct",5],
	"vesperglass_wand":["Vesperglass Light","spell_power_pct",10,"cast_speed_pct",9],
	"widows_knot":["Widow's Knot","hook_pull_pct",15,"backstep_efficiency_pct",7],
	"chainwake_amulet":["Chainwake","hook_range_pct",15,"stamina_efficiency_pct",6],
	"chimekeeper_rosary":["Chimekeeper","stamina_recovery_pct",13,"cast_speed_pct",7],
	"emberfrost_stave":["Emberfrost","charged_spell_pct",9,"stamina_recovery_pct",9],
}

static func profile(item: Variant) -> Array:
	if item==null or item.definition==null or item.is_broken() or item.get_slot()=="none":
		return []
	if item.quality!="unique" and not item.definition.unique:
		return []
	return POWERS.get(item.definition.resource_path.get_file().get_basename(),[])

static func bonuses(item: Variant) -> Dictionary:
	var p: Array = profile(item)
	return {p[1]:float(p[2]),p[3]:float(p[4])} if p.size()==5 else {}

static func label(item: Variant) -> String:
	var p: Array = profile(item)
	return str(p[0]) if p.size()==5 else ""
