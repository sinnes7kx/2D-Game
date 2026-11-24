extends RefCounted
class_name GhostCosmeticRNGV152
## v1.52: 128-bit CSPRNG IDs for *appearances*. No multiplayer registry or
## absolute uniqueness guarantee; collision probability is negligible.
## Item loot/stat seeds remain unchanged so old saves and damage persist.
const SIGNATURE_NAMES: Array[String] = ["", "Aether Thorns", "Void Eclipse", "Astral Seraph"]

static func fresh_uid() -> String:
    var random_bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
    # Crypto supplies the full 128 bits, unlike the old 9-digit random seed.
    if random_bytes.size() != 16:
        push_error("Cosmetic RNG could not obtain 128-bit entropy")
        return ""
    return random_bytes.hex_encode()

static func is_valid_uid(uid: String) -> bool:
    if uid.length() != 32:
        return false
    for i in range(uid.length()):
        if "0123456789abcdef".find(uid.substr(i, 1).to_lower()) < 0:
            return false
    return true

static func appearance_stream(uid: String) -> int:
    if not is_valid_uid(uid):
        return 0
    # 48 bits keep every existing seed-based visual arithmetic in int64 range.
    # The complete, independent 128-bit ID is persisted in the save file.
    return uid.substr(0, 12).hex_to_int()

static func signature(uid: String, slot: String) -> int:
    if not is_valid_uid(uid) or slot not in ["sword", "wand"]:
        return 0
    # Completely independent bits from the palette/appearance stream.
    var ticket: int = uid.substr(16, 8).hex_to_int()
    if ticket % 32768 == 0:
        return 3  # approx 1:32768 — luminous wings, constellations, ribbons
    if ticket % 4096 == 1:
        return 2  # approx 1:4096 — eclipsed orbit trails
    if ticket % 512 == 2:
        return 1  # approx 1:512 — spectral thorn wake
    return 0

static func signature_name(level: int) -> String:
    return SIGNATURE_NAMES[clampi(level, 0, SIGNATURE_NAMES.size()-1)]


# v1.53 — continuous hue, saturation and value; NEVER a named/discrete palette.
# SHA-256 of the cryptographically generated 128-bit UID makes this fully
# deterministic for saved looks while keeping the draw unrelated to item stats.
# Old items with no UID use their existing cosmetic seed as a stable fallback.
static func gradient_colors(uid: String, legacy_seed: int) -> Array[Color]:
    return gradient_for_channel(uid, legacy_seed, "glow")

# Each channel derives a variable number of stops from the complete UID.
# No named color sets or forced rainbow. A continuous hue span can be almost
# monochrome, complementary, muted, jewel-bright, pastel, dark or broad.
static func gradient_for_channel(uid: String, legacy_seed: int, channel: String) -> Array[Color]:
    var identity: String = uid.to_lower() if is_valid_uid(uid) else "legacy-%d" % legacy_seed
    var domain: String = "ghost-girl-v188:" + channel + ":" + identity
    var header: PackedByteArray = domain.sha256_buffer()
    var count: int = 3 + int(header[0]) % 7
    var center: float = _unit16(header, 1)
    var span: float = 0.012 + pow(_unit16(header, 3), 1.65) * 0.94
    var sat: float = 0.10 + 0.87 * _unit16(header, 5)
    var value: float = 0.30 + 0.68 * _unit16(header, 7)
    var drift: float = _unit16(header, 9) * 2.0 - 1.0
    var colors: Array[Color] = []
    for i in range(count):
        var bytes: PackedByteArray = (domain + ":stop:" + str(i)).sha256_buffer()
        var u: float = float(i) / float(count - 1)
        var hue: float = fposmod(center + span * ((_unit16(bytes, 0) - 0.5) * 0.78 + (u - 0.5) * drift * 0.42), 1.0)
        var saturation: float = clampf(sat + (_unit16(bytes, 2) - 0.5) * 0.42, 0.025, 0.99)
        var brightness: float = clampf(value + (_unit16(bytes, 4) - 0.5) * 0.48, 0.16, 1.0)
        colors.append(Color.from_hsv(hue, saturation, brightness))
    return colors

static func _unit16(bytes: PackedByteArray, offset: int) -> float:
    return float(int(bytes[offset]) * 256 + int(bytes[offset + 1])) / 65535.0

# Open ramps for metal and string, closed ramps for moving effects. At the
# loop boundary interpolate last→first, never jump or leave the rolled palette.
static func sample_palette(colors: Array, u: float, cyclic: bool = false, smooth: bool = true) -> Color:
    if colors.is_empty():
        return Color.WHITE
    if colors.size() == 1:
        return colors[0]
    var count: int = colors.size()
    var at: float = fposmod(u, 1.0) * float(count) if cyclic else clampf(u, 0.0, 1.0) * float(count - 1)
    var first: int = mini(floori(at), count - 1)
    var second: int = (first + 1) % count if cyclic else mini(first + 1, count - 1)
    var weight: float = at - float(first)
    if smooth:
        weight = weight * weight * (3.0 - 2.0 * weight)
    var a: Color = colors[first]
    var b: Color = colors[second]
    return a.lerp(b, weight)

static func animation_profile(uid: String, legacy_seed: int, channel: String) -> Dictionary:
    var identity: String = uid.to_lower() if is_valid_uid(uid) else "legacy-%d" % legacy_seed
    var bytes: PackedByteArray = ("ghost-girl-v188-motion:" + channel + ":" + identity).sha256_buffer()
    return {
        "palette_offset": _unit16(bytes, 0),
        "palette_speed": 0.035 + _unit16(bytes, 2) * 0.22,
        "palette_span": 0.24 + _unit16(bytes, 4) * 1.5,
        "palette_direction": -1.0 if int(bytes[6]) % 2 == 0 else 1.0,
        "palette_curve": int(bytes[7]) % 4,
        "palette_pulse": 0.06 + _unit16(bytes, 8) * 0.24
    }
