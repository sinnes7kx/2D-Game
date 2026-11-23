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
    var material: String = uid.to_lower() if is_valid_uid(uid) else "legacy-cosmetic-%d" % legacy_seed
    var ctx: HashingContext = HashingContext.new()
    ctx.start(HashingContext.HASH_SHA256)
    ctx.update(("ghost-girl-gradient-v153:" + material).to_utf8_buffer())
    var bytes: PackedByteArray = ctx.finish()
    # Hue has 65,536 possible levels per stop. The stops are separately
    # randomized and may be complementary, analogous or wildly different.
    var hue_a: float = float(int(bytes[0]) * 256 + int(bytes[1])) / 65536.0
    var hue_b: float = float(int(bytes[8]) * 256 + int(bytes[9])) / 65536.0
    var hue_c: float = float(int(bytes[16]) * 256 + int(bytes[17])) / 65536.0
    var sat_a: float = 0.67 + float(bytes[2]) / 255.0 * 0.31
    var sat_b: float = 0.65 + float(bytes[10]) / 255.0 * 0.33
    var sat_c: float = 0.69 + float(bytes[18]) / 255.0 * 0.29
    var val_a: float = 0.87 + float(bytes[3]) / 255.0 * 0.13
    var val_b: float = 0.85 + float(bytes[11]) / 255.0 * 0.15
    var val_c: float = 0.87 + float(bytes[19]) / 255.0 * 0.13
    return [Color.from_hsv(hue_a, sat_a, val_a),
            Color.from_hsv(hue_b, sat_b, val_b),
            Color.from_hsv(hue_c, sat_c, val_c)]


# v1.68: independent equipment appearance layers. Each channel has a distinct
# SHA-256 domain, all derived from the persisted 128-bit cosmetic UID. There
# are no named palettes, finite seeds, new stat rolls, or new save fields.
static func gradient_for_channel(uid: String, legacy_seed: int, channel: String) -> Array[Color]:
    var identity: String = uid.to_lower() if is_valid_uid(uid) else "legacy-%d" % legacy_seed
    var digest: PackedByteArray = ("ghost-girl-v168:" + channel + ":" + identity).sha256_buffer()
    var colors: Array[Color] = []
    for offset in [0, 9, 18]:
        var hue: float = float(int(digest[offset]) * 256 + int(digest[offset + 1])) / 65536.0
        var sat: float = 0.67 + float(digest[offset + 2]) / 255.0 * 0.29
        var brightness: float = 0.83 + float(digest[offset + 3]) / 255.0 * 0.17
        colors.append(Color.from_hsv(hue, sat, brightness))
    return colors
