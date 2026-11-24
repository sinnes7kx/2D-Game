extends RefCounted
class_name GhostWeaponFXLibrary
## v1.13: independent, seed-stable COSMETIC visual affixes.
## Higher item qualities unlock rarer effect motifs and projectile forms.
## No visual roll changes damage, cast count, collision, or other stat streams.
const MOTIFS = [
    "Rose Dust", "Moon Sparks", "Frost Motes", "Vesper Cinders",
    "Lace Shimmer", "Thorn Halo", "Astral Petals", "Silver Runes",
    "Aurora Ghostfire", "Eclipse Shards"
]
const PAINT_NAMES = [
    "Rose Quartz", "Ice Blue", "Moon Pearl", "Violet Specter", "Sea Glass",
    "Old Gold", "Blood Rose", "Silver Smoke", "Amethyst Flame", "Drowned Teal"
]
const PAINT = [
    Color("eaa9c8"), Color("8ecaf5"), Color("f4eaff"), Color("ad91ee"), Color("80dfcd"),
    Color("f4cc85"), Color("e67c9d"), Color("bfc5d7"), Color("b583ef"), Color("60bbbc")
]
const TRAIL_STYLES = [
    "Velvet Smoke", "Orbiting Petals", "Frost Ribbons", "Stardust Wake",
    "Twin Helix", "Eclipse Embers"
]
const SPELL_FORMS = [
    "Moon Orb", "Comet", "Twin Wisps", "Orbiting Sigil", "Triune Stars",
    "Moonlight Beam", "Prismatic Lattice", "Luminous Lance"
]

const BLADE_IMPACTS = ["Crimson Flecks", "Rose Splash", "Scarlet Ribbons", "Thornburst", "Sanguine Cascade"]
const WAND_IMPACTS = ["Moon Ring", "Crystal Sparks", "Spectral Petals", "Astral Starburst", "Prismatic Shatter"]

static func impact_limit(quality: String) -> int:
    match quality:
        "magic": return 3
        "rare": return 5
        "set", "unique": return 5
        _: return 2

static func impact_name(slot: String, index: int) -> String:
    var names: Array = WAND_IMPACTS if slot == "wand" else BLADE_IMPACTS
    return str(names[posmod(index, names.size())])

static func tier(quality: String) -> int:
    match quality:
        "magic": return 1
        "rare": return 2
        "set": return 3
        "unique": return 4
        _: return 0

static func motif_limit(quality: String) -> int:
    match quality:
        "magic": return 5
        "rare": return 8
        "set": return 9
        "unique": return 10
        _: return 3

static func form_limit(quality: String) -> int:
    match quality:
        "magic": return 4
        "rare": return 6
        "set", "unique": return 7
        _: return 2

static func trail_limit(quality: String) -> int:
    match quality:
        "magic": return 3
        "rare": return 5
        "set", "unique": return 6
        _: return 2

# The Luminous Lance is an additional independent cosmetic roll, NOT a new
# damaging projectile. Keep the original seven form selection streams intact.
# Different drop seeds yield different prestigious appearances without
# changing existing item stats or ordinary spell form probabilities.
static func luminous_lance_roll(seed_value: int, quality: String) -> int:
    var denominator: int = 0
    match quality:
        "rare": denominator = 8
        "set": denominator = 6
        "unique": denominator = 4
        _: return 0
    return 1 if posmod(absi(seed_value) + 117117, denominator) == 0 else 0

static func trail_name(index: int) -> String:
    return TRAIL_STYLES[posmod(index, TRAIL_STYLES.size())]

static func roll(seed_value: int, quality: String) -> Dictionary:
    var rng_motif: RandomNumberGenerator = RandomNumberGenerator.new()
    var rng_color: RandomNumberGenerator = RandomNumberGenerator.new()
    var rng_form: RandomNumberGenerator = RandomNumberGenerator.new()
    rng_motif.seed = absi(seed_value) + 1131101
    rng_color.seed = absi(seed_value) + 1131103
    rng_form.seed = absi(seed_value) + 1131109
    var rng_accent: RandomNumberGenerator = RandomNumberGenerator.new()
    var rng_trail: RandomNumberGenerator = RandomNumberGenerator.new()
    var rng_impact: RandomNumberGenerator = RandomNumberGenerator.new()
    # Separate visual streams; no changes to the original three rolls.
    rng_accent.seed = absi(seed_value) + 1141201
    rng_trail.seed = absi(seed_value) + 1141207
    rng_impact.seed = absi(seed_value) + 1161931
    return {
        "motif": rng_motif.randi_range(0, motif_limit(quality) - 1),
        "color": rng_color.randi_range(0, PAINT.size() - 1),
        "form": rng_form.randi_range(0, form_limit(quality) - 1),
        "accent": rng_accent.randi_range(0, PAINT.size() - 1),
        "trail": rng_trail.randi_range(0, trail_limit(quality) - 1),
        "impact": rng_impact.randi_range(0, impact_limit(quality) - 1),
        "lance": luminous_lance_roll(seed_value, quality)
    }

static func color(index: int) -> Color:
    return PAINT[posmod(index, PAINT.size())]

static func motif_name(index: int) -> String:
    return MOTIFS[posmod(index, MOTIFS.size())]

static func paint_name(index: int) -> String:
    return PAINT_NAMES[posmod(index, PAINT_NAMES.size())]

static func spell_form_name(index: int) -> String:
    return SPELL_FORMS[posmod(index, SPELL_FORMS.size())]

# v1.23: extremely rare deterministic appearance-only affix. No new save field.
const PRESTIGE_NAMES: Array[String] = ["Crowned Moon", "Rose Comet", "Astral Filigree", "Eclipse Wings", "Frostfire Halo", "Thorn Constellation", "Prismatic Afterglow"]

static func prestige_variant(seed_value: int, quality: String) -> int:
    var tier_index: int = tier(quality)
    if tier_index < 2:
        return -1
    # Rare: one out of eleven. Set / Unique: prestige is part of the identity.
    if tier_index == 2 and posmod(seed_value + 230123, 11) != 0:
        return -1
    return posmod(seed_value * 17 + 230123, PRESTIGE_NAMES.size())

static func prestige_name(seed_value: int, quality: String) -> String:
    var index: int = prestige_variant(seed_value, quality)
    return PRESTIGE_NAMES[index] if index >= 0 else ""

# Frost-spell visual styles are seeded independently of damage and affixes.
# Ordinary items only access restrained ice styles; rare/set/unique unlock
# the elaborate ornamental patterns.
const MOONFALL_STYLES = ["Moon Snow", "Frostsilver Lace", "Bloodrose Hail", "Drowned Glass", "Eclipse Ice", "Celestial Flurry"]

static func moonfall_style(seed_value: int, quality: String) -> int:
    var tier_value: int = tier(quality)
    var range_size: int = 2 if tier_value <= 1 else MOONFALL_STYLES.size()
    return posmod(absi(seed_value) * 17 + 125251, range_size)

static func moonfall_style_name(seed_value: int, quality: String) -> String:
    return MOONFALL_STYLES[moonfall_style(seed_value, quality)]
