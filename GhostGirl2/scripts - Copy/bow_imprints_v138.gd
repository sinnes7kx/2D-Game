extends RefCounted
class_name GhostBowImprintsV138
## Independent, item-seeded bow appearance layers. No damage or affix rolls here.
## A three-arrow 'formation' is ONE physical arrow with two ornamental echoes.
const ELEMENT_NAMES: Array[String] = ["Moonsteel", "Emberfire", "Frostglass", "Luminous"]
const FORMATION_NAMES: Array[String] = ["Single", "Triune Echo"]
const TRAIL_NAMES: Array[String] = ["Rose Drift", "Comet Silk", "Vesper Sparks", "Frost Lace", "Starglass", "Twin Helix"]
const DETAIL_NAMES: Array[String] = ["Plain", "Silver Etching", "Thorn Runes", "Moon Dots", "Glint Filigree"]
const ELEMENT_COLORS: Array[Color] = [Color("d5aedb"), Color("f8a66e"), Color("94def6"), Color("f8ecae")]

static func roll(seed_value: int, quality: String) -> Dictionary:
    var s: int = absi(seed_value)
    var element: int = posmod(s * 17 + 138041, ELEMENT_NAMES.size())
    var formation: int = 1 if posmod(s * 29 + 138053, 3) == 0 else 0
    # Common bows stay quiet; rarer arrows earn recognizable visual identities.
    if quality == "normal":
        element = 0
        formation = 0
    elif quality == "magic":
        element = element if element in [0, 1, 2] else 0
        formation = 0
    return {
        "element": element,
        "formation": formation,
        "glow": posmod(s * 31 + 138067, GhostWeaponFXLibrary.PAINT.size()),
        "trail": posmod(s * 37 + 138071, TRAIL_NAMES.size()),
        "detail": posmod(s * 41 + 138079, DETAIL_NAMES.size())
    }

static func name_for_element(index: int) -> String:
    return ELEMENT_NAMES[posmod(index, ELEMENT_NAMES.size())]

static func name_for_formation(index: int) -> String:
    return FORMATION_NAMES[posmod(index, FORMATION_NAMES.size())]

static func color_for_element(index: int) -> Color:
    return ELEMENT_COLORS[posmod(index, ELEMENT_COLORS.size())]
