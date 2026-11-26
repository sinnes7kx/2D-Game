extends RefCounted
class_name GhostItemGenerator
## Deterministic quality, affixes, sockets, and palette streams.
## The same template + seed + forced quality always yields the same base item.
const AFFIX_POOL = [
    {"prefix": "Swift", "stat": "move_speed_pct", "low": 1.0, "high": 4.0},
    {"prefix": "Rosebound", "stat": "hook_range_pct", "low": 3.0, "high": 8.0},
    {"prefix": "Grasping", "stat": "hook_pull_pct", "low": 3.0, "high": 9.0},
    {"prefix": "Forceful", "stat": "throw_force_pct", "low": 3.0, "high": 9.0},
    {"prefix": "Moonlit", "stat": "spell_power_pct", "low": 5.0, "high": 13.0},
    {"prefix": "Blessed", "stat": "vitality_pct", "low": 4.0, "high": 10.0},
    {"prefix": "Fortunate", "stat": "find_bonus_pct", "low": 2.0, "high": 10.0}
]

# Only v0.7 bases (level 7+) roll these new combat affixes; older seeded
# item affixes and socket outcomes retain their original generation streams.
const HUNTER_AFFIXES = [
    {"prefix": "Merciless", "stat": "melee_power_pct", "low": 5.0, "high": 14.0},
    {"prefix": "Executioner's", "stat": "heavy_power_pct", "low": 8.0, "high": 18.0},
    {"prefix": "Fervent", "stat": "attack_speed_pct", "low": 4.0, "high": 11.0},
    {"prefix": "Relentless", "stat": "stamina_efficiency_pct", "low": 5.0, "high": 12.0},
    {"prefix": "Poised", "stat": "poise_power_pct", "low": 8.0, "high": 20.0},
    {"prefix": "Reprisal", "stat": "counter_damage_pct", "low": 10.0, "high": 24.0},
    {"prefix": "Sanguine", "stat": "rally_power_pct", "low": 9.0, "high": 22.0},
    {"prefix": "Arcane", "stat": "cast_speed_pct", "low": 7.0, "high": 17.0},
    {"prefix": "Censured", "stat": "charged_spell_pct", "low": 9.0, "high": 21.0},
    {"prefix": "Evasive", "stat": "backstep_efficiency_pct", "low": 8.0, "high": 19.0},
    {"prefix": "Restless", "stat": "stamina_recovery_pct", "low": 7.0, "high": 17.0}
]

static func create(template: GhostItemData, seed_value: int, forced_quality: String = "") -> GhostItemInstance:
    var item: GhostItemInstance = GhostItemInstance.new()
    item.definition = template
    item.item_seed = seed_value
    item.item_level = maxi(1, template.item_level)
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = absi(seed_value) + 378923
    if template.item_class != "equipment" or template.equip_slot == "none":
        item.quality = "normal"
    elif forced_quality in ["normal", "magic", "rare", "set", "unique"]:
        item.quality = forced_quality
    else:
        # 0.15% unique, 0.55% set, 3.3% rare, 15% magic. The
        # saved item's explicit quality takes precedence on reload.
        var chance: int = rng.randi_range(0, 9999)
        item.quality = "unique" if chance >= 9985 else ("set" if chance >= 9930 else ("rare" if chance >= 9600 else ("magic" if chance >= 8100 else "normal")))
    # Bow appearance is a distinct seed stream: no gameplay RNG is consumed.
    if template.weapon_style == "bow":
        var bow_look: Dictionary = GhostBowImprintsV138.roll(seed_value, item.quality)
        item.bow_element_index = int(bow_look["element"])
        item.bow_formation_index = int(bow_look["formation"])
        item.bow_glow_index = int(bow_look["glow"])
        item.bow_trail_index = int(bow_look["trail"])
        item.bow_detail_index = int(bow_look["detail"])
    var colors: RandomNumberGenerator = RandomNumberGenerator.new()
    colors.seed = absi(seed_value) + 11791
    item.palette_index = colors.randi_range(0, 5)
    var ornaments: RandomNumberGenerator = RandomNumberGenerator.new()
    ornaments.seed = absi(seed_value) + 73931
    item.decoration_index = ornaments.randi_range(0, 3)
    # Cosmetics use independent seed streams: changing these appearance rolls
    # never changes quality, affixes, sockets, weapon damage or legacy palette.
    item.weapon_base_index = item.palette_index
    var gradient_rng: RandomNumberGenerator = RandomNumberGenerator.new()
    gradient_rng.seed = absi(seed_value) + 711317
    item.weapon_gradient_index = gradient_rng.randi_range(0, 5)
    var surface_a_rng: RandomNumberGenerator = RandomNumberGenerator.new()
    surface_a_rng.seed = absi(seed_value) + 711319
    item.weapon_detail_a_index = surface_a_rng.randi_range(0, 3)
    var surface_b_rng: RandomNumberGenerator = RandomNumberGenerator.new()
    surface_b_rng.seed = absi(seed_value) + 711323
    item.weapon_detail_b_index = surface_b_rng.randi_range(0, 3)
    # One special visual affix with its own colour and optional wand shape.
    # Separate seeds preserve old stats, socket outcomes, and item appearance.
    var cosmetic: Dictionary = GhostWeaponFXLibrary.roll(seed_value, item.quality)
    item.weapon_fx_style_index = int(cosmetic["motif"])
    item.weapon_fx_color_index = int(cosmetic["color"])
    item.weapon_fx_accent_index = int(cosmetic["accent"])
    item.weapon_fx_trail_index = int(cosmetic["trail"])
    item.weapon_impact_style_index = int(cosmetic["impact"])
    item.wand_lance_index = int(cosmetic["lance"]) if template.equip_slot == "wand" else 0
    item.wand_cast_style_index = int(cosmetic["form"])
    var stats: RandomNumberGenerator = RandomNumberGenerator.new()
    stats.seed = absi(seed_value) + 178091
    item.stat_value = snappedf(stats.randf_range(template.min_stat, template.max_stat), 0.1)
    var count: int = 0
    match item.quality:
        "magic": count = rng.randi_range(1, 2)
        "rare": count = rng.randi_range(2, 4)
        "set": count = 2
        "unique": count = 3
    if template.equip_slot == "companion":
        count = 0 # Companions are collectible cosmetic equipment, not extra power.
    var available_affixes: Array = AFFIX_POOL.duplicate(true)
    if template.item_level >= 7:
        available_affixes.append_array(HUNTER_AFFIXES)
    var chosen: Dictionary = {}
    for n in range(count):
        var pool_index: int = rng.randi_range(0, available_affixes.size() - 1)
        var attempts: int = 0
        while chosen.has(pool_index) and attempts < 15:
            pool_index = rng.randi_range(0, available_affixes.size() - 1)
            attempts += 1
        chosen[pool_index] = true
        var affix: Dictionary = available_affixes[pool_index]
        item.affixes.append({"prefix": affix["prefix"], "stat": affix["stat"], "value": snappedf(rng.randf_range(affix["low"], affix["high"]), 0.1)})
    if template.max_sockets > 0:
        var socket_cap: int = template.max_sockets
        if item.quality == "unique" or item.quality == "set":
            socket_cap = mini(socket_cap, 2)
        var socket_chance: int = rng.randi_range(0, 99)
        if template.equip_slot == "wand" or socket_chance < 78 or item.quality in ["rare", "set", "unique"]:
            item.sockets = rng.randi_range(1, maxi(1, socket_cap))
    item.weapon_mod = preload("res://scripts/weapon_mods_v250.gd").roll(template.equip_slot, template.weapon_style, item.quality, seed_value)
    return item
