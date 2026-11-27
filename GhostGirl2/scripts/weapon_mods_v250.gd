extends RefCounted
const EXTRA: String = "extra_projectiles"
const RETURN: String = "returning_projectiles"
const MELEE: Array[String] = ["crushing", "execution", "long_reach", "finisher", "riposte", "soul_siphon", "vigor", "frostbite", "cleaving"]
const LABELS: Dictionary = {
	EXTRA: "+2 Projectiles", RETURN: "Returning Projectiles",
	"crushing": "+35% Stagger Power", "execution": "+25% Heavy Attack Damage",
	"long_reach": "+20% Melee Reach", "finisher": "+25% Combo Finisher Damage",
	"riposte": "+35% Counter Damage",
	"soul_siphon": "+2 Life per Successful Attack",
	"vigor": "+5 Stamina per Successful Attack",
	"frostbite": "Hits Slow Enemies for 1.5 Seconds",
	"cleaving": "25% Wider Melee Attack Arc"
}
const NAMES: Dictionary = {
	"seraph_reaper_v292": "Seraph Reaper",
	"ivory_duelist_rapier_v286": "Ivory Riposte",
	"nightglass_rapier_v286": "Nightglass Reversal",
	"rosehook_bearded_axe_v286": "Briar Funeral",
	"ossuary_poleaxe_v286": "Ossuary Verdict",
	"cathedral_rapier_v283": "The Gilded Verdict",
	"moonneedle_rapier_v283": "Lunar Oath",
	"briar_hatchet_v283": "Briar's Severance",
	"gravecleaver_axe_v283": "Gravecleaver's Toll",
	"gallows_greataxe_v283": "Gallows Requiem",
	"frostveil_bow_v277": "Winter's Choir", "mourning_star_crossbow_v277": "Astral Sentence", "hollowbell_maul_v277": "Hollow Cathedral",
	"silkglass_dirk_v276": "Winterglass Tear", "bellthorn_lance_v276": "The Bell of Judgment",
	"ashbound_wand": "Ashes of Eternity", "briar_wand": "The Pale Thorn", "hunter_censer_wand": "Saint's Last Breath",
	"blackthorn_bow_v234": "Widow's Lament", "blackthorn_crossbow_v236": "The Twin Requiem", "moonveil_bow": "Moon's Betrayal",
	"thornrose_bow": "Briar's Mercy", "mourning_yew_bow_v238": "Sorrow's String", "reliquary_silver_bow_v234": "The Silent Vow",
	"v202_fletcher_moonflight_bow": "The Falling Star", "vesper_recurve_bow_v238": "Evenfall",
	"silver_reliquary_crossbow_v236": "Saint's Verdict", "vesper_latch_crossbow_v237": "The Last Word", "ossuary_arbalest_v237": "Bone Covenant",
	"bloodrose_falchion": "Blood's Remembrance", "mourning_longsword": "Grief's Edge", "moonveil_grandblade": "The Hollow Moon",
	"penitent_longsword": "Penitent’s Descent", "vesper_arming_sword_v235": "Vesper's Oath", "ossuary_falchion_v235": "Grave's Demand", "thornveil_sabre_v235": "Thorn's Kiss",
	"thornwake_sabre": "Briar's Reckoning", "vesper_rapier": "Heart's Silence", "dusk_needle": "Night's Needle",
	"rose_reaper_scythe": "Death's Reverie", "lunar_vigil_halberd": "The Endless Vigil", "moonwarden_spear_v169": "Heaven's Reach",
	"briarwake_trident_v171": "The Drowned Crown", "ashglass_warmaul_v170": "Cathedral's Ruin", "gravebell_maul_v170": "The Last Toll",
	"v203_mournful_mace": "Mercy Denied", "v203_nightchain_flail": "The Unbroken Chain", "v203_rosequartz_morningstar": "Dawn's Sorrow",
	"roseglass_dagger_v169": "Rose's Secret", "nocturne_stiletto_v171": "The Quiet Death", "vesper_athame_v233": "Blood of the Covenant",
	"ivory_misericorde_v233": "Ivory Mercy", "cinderveil_dirk_v238": "Ember's Promise", "reliquary_knife_v238": "The Saint's Wound",
	"moonlace_dual_daggers_v173": "Moon's Teeth", "mourninglace_dual_daggers_v231": "The Weeping Sisters",
	"gloamrose_dual_swords_v174": "Bride and Widow", "cathedral_dual_swords_v233": "The Broken Vows", "vesperthorn_dual_swords_v231": "Sorrow and Solace",
	"eclipse_twinblade_v170": "Eclipse's Hunger", "rosemirror_twinblade_v170": "The Rose's Reflection",
	"cathedral_thorn_twinblade_v231": "Martyr's Crown", "widowglass_twinblade_v231": "Widow's Embrace",
	"moonwoven_dress": "The Moon's Bride", "thornlace_dress": "The Thorned Veil", "hunter_sable_dress": "Night's Mourning",
	"moonwisp_companion_v239": "The Last Lantern", "v202_crescent_halo": "Saint's Eclipse", "v202_moonlit_tiara": "The Pale Coronation",
	"v202_starfall_diadem": "Heaven's Tears", "v202_rose_horns": "The Briar Crown", "rosewing_mantle": "The Fallen Choir",
	"mourning_locket": "A Mother's Grief", "gloamglass_locket": "The Fading Heart", "velvet_reliquary": "The Velvet Prison",
	"blackbrick_reliquary": "The Black Testament", "ash_vigil_charm": "Ashen Covenant", "silver_thread_charm": "Fate's Thread",
	"sylvan_charm": "The Woods Remember", "hunter_duelist_rosary": "The Penitent's Prayer", "hunter_thorn_sigil": "The Thorned Pact",
	"v202_bandit_mask": "The Nameless Face", "v202_luminous_eyes": "The Unseeing"
}
static func allowed(slot: String, style: String) -> Array[String]:
	if slot == "wand":
		return [EXTRA, RETURN]
	if slot != "sword":
		return []
	if style in ["bow", "crossbow"]:
		return [EXTRA, RETURN]
	return MELEE.duplicate()

static func roll(slot: String, style: String, quality: String, seed_value: int) -> String:
	var pool: Array[String] = allowed(slot, style)
	if pool.is_empty() or quality not in ["rare", "unique"]:
		return ""
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value ^ 250931
	if quality == "rare" and rng.randi_range(0, 999) >= 100:
		return ""
	return pool[rng.randi_range(0, pool.size() - 1)]

static func sanitize(value: String, slot: String, style: String, quality: String) -> String:
	return value if quality in ["rare", "unique"] and value in allowed(slot, style) else ""

static func unique_name(path: String, fallback: String) -> String:
	return str(NAMES.get(path.get_file().get_basename(), fallback))

static func projectile_count(mod: String, base_count: int) -> int:
	return base_count + (2 if mod == EXTRA else 0)

static func volley_multiplier(mod: String) -> float:
	return 1.5 if mod == EXTRA else (0.85 if mod == RETURN else 1.0)

static func angle(index: int, count: int) -> float:
	return deg_to_rad((float(index) - float(count - 1) * 0.5) * 8.0) if count > 1 else 0.0

static func copy_launch(source: Node, target: Node, fields: Array) -> void:
	for field in fields:
		target.set(field, source.get(field))
