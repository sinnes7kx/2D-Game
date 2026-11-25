extends RefCounted
## Original procedural, short transient layers. No external samples/licenses.
## Only presentation: never changes damage, stamina, animation timing or saves.
const RATE: int = 22050
const MAX_VOICES: int = 12
static var sound_level: float = 1.0
static var shake_level: float = 1.0
static var _cached: Dictionary = {}

static func set_sound_level(value: float) -> void:
    sound_level = clampf(value, 0.0, 1.5)

static func set_shake_level(value: float) -> void:
    shake_level = clampf(value, 0.0, 1.5)

static func play(parent: Node, where: Vector2, kind: String, volume_db: float = -15.0) -> void:
    if sound_level <= 0.0 or not is_instance_valid(parent) or not parent.is_inside_tree():
        return
    if parent.get_tree().get_nodes_in_group("ghost_impact_audio").size() >= MAX_VOICES:
        return
    if not _cached.has(kind):
        _cached[kind] = _render(kind)
    var voice: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
    voice.stream = _cached[kind] as AudioStream
    voice.volume_db = volume_db + linear_to_db(maxf(0.001, sound_level))
    voice.max_distance = 980.0
    voice.bus = "Master"
    voice.add_to_group("ghost_impact_audio")
    parent.add_child(voice)
    voice.global_position = where
    voice.finished.connect(voice.queue_free)
    voice.play()

# Sword sounds need the *motion of displaced air*, not a pitched buzz
# or an impact drum. Band-limited stochastic noise, an accelerating crest
# and a short descending harmonic form one original, airy sword whoosh.
# Original synthetic foley, not a prerecorded sample. A pair of filtered
# noise bands creates quiet fabric/air motion; the very small low harmonic
# supplies weight without the old high pitched sci-fi buzz.
static func _render_air_sweep(kind: String) -> AudioStreamWAV:
    var duration: float = 0.20
    var air_weight: float = 0.80
    var bass_weight: float = 0.020
    match kind:
        "heavy_swing":
            duration = 0.38
            air_weight = 1.05
            bass_weight = 0.050
        "jump_swing":
            duration = 0.43
            air_weight = 1.0
            bass_weight = 0.065
        "charged_swing":
            duration = 0.34
            air_weight = 0.96
            bass_weight = 0.042
    var count: int = roundi(duration * RATE)
    var pcm: PackedByteArray = PackedByteArray()
    pcm.resize(count * 2)
    var state: int = posmod(kind.hash() + 18523, 2147483646) + 1
    var mid: float = 0.0
    var low: float = 0.0
    var phase: float = 0.0
    for i in range(count):
        var t: float = float(i) / float(count)
        state = (state * 16807) % 2147483647
        var white: float = float(state % 65535) / 32767.5 - 1.0
        mid = lerpf(mid, white, 0.095)
        low = lerpf(low, white, 0.012)
        var feather: float = mid - low
        var pulse: float = pow(maxf(0.0, sin(PI * t)), 1.9)
        var acceleration: float = 0.64 + 0.36 * sin(PI * clampf(t * 1.13, 0.0, 1.0))
        phase += TAU * lerpf(110.0, 58.0, t) / RATE
        var sound: float = (feather * air_weight + sin(phase) * bass_weight) * pulse * acceleration
        var sample: int = clampi(roundi(sound * 12500.0), -32768, 32767)
        var packed: int = sample & 0xffff
        pcm[i * 2] = packed & 255
        pcm[i * 2 + 1] = (packed >> 8) & 255
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = pcm
    return stream

# Muted metallic/fabric contact: two short noise bands plus a tiny decaying
# steel resonance. Strong hits have weight, but no sharp synthetic beep.
static func _render_soft_contact(kind: String) -> AudioStreamWAV:
    var parry: bool = kind == "parry"
    var duration: float = 0.23 if parry else 0.16
    var count: int = roundi(duration * RATE)
    var pcm: PackedByteArray = PackedByteArray()
    pcm.resize(count * 2)
    var state: int = posmod(kind.hash() + 19431, 2147483646) + 1
    var mid: float = 0.0
    var low: float = 0.0
    var phase: float = 0.0
    for i in range(count):
        var t: float = float(i) / float(count)
        state = (state * 16807) % 2147483647
        var white: float = float(state % 65535) / 32767.5 - 1.0
        mid = lerpf(mid, white, 0.18)
        low = lerpf(low, white, 0.025)
        var body: float = low * exp(-7.0 * t)
        var scrape: float = (mid - low) * exp(-12.0 * t)
        phase += TAU * lerpf(830.0, 500.0, t) / RATE
        var resonance: float = sin(phase) * (0.13 if parry else 0.042) * exp(-13.0 * t)
        var attack: float = minf(1.0, t / 0.008)
        var sound: float = (body * 0.95 + scrape * (0.85 if parry else 0.62) + resonance) * attack
        var sample: int = clampi(roundi(sound * 13000.0), -32768, 32767)
        var packed: int = sample & 0xffff
        pcm[i * 2] = packed & 255
        pcm[i * 2 + 1] = (packed >> 8) & 255
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = pcm
    return stream

static func _render(kind: String) -> AudioStreamWAV:
    if kind in ["swing", "heavy_swing", "jump_swing", "charged_swing"]:
        return _render_air_sweep(kind)
    if kind in ["hit", "parry"]:
        return _render_soft_contact(kind)
    var duration: float = 0.19
    var start_hz: float = 350.0
    var end_hz: float = 100.0
    var noise_mix: float = 0.45
    match kind:
        "swing":
            duration = 0.12
            start_hz = 450.0
            end_hz = 120.0
            noise_mix = 0.80
        "hit":
            duration = 0.15
            start_hz = 165.0
            end_hz = 57.0
            noise_mix = 0.63
        "parry":
            duration = 0.27
            start_hz = 1280.0
            end_hz = 650.0
            noise_mix = 0.17
        "dodge":
            duration = 0.20
            start_hz = 620.0
            end_hz = 155.0
            noise_mix = 0.65
        "spell":
            duration = 0.28
            start_hz = 370.0
            end_hz = 880.0
            noise_mix = 0.12
        "debris":
            duration = 0.43
            start_hz = 130.0
            end_hz = 38.0
            noise_mix = 0.84
        "evade":
            duration = 0.16
            start_hz = 790.0
            end_hz = 420.0
            noise_mix = 0.16
    var count: int = roundi(duration * RATE)
    var pcm: PackedByteArray = PackedByteArray()
    pcm.resize(count * 2)
    var phase: float = 0.0
    var noise_state: int = 18637 + kind.hash() & 0x7fffffff
    for i in range(count):
        var t: float = float(i) / float(count)
        phase += TAU * lerpf(start_hz, end_hz, t) / RATE
        noise_state = (noise_state * 16807) % 2147483647
        var noise: float = float(noise_state % 65535) / 32767.5 - 1.0
        var attack: float = minf(1.0, t / 0.018)
        var envelope: float = attack * pow(1.0 - t, 2.6)
        var body: float = sin(phase) * (1.0 - noise_mix) + noise * noise_mix
        if kind == "parry":
            body += 0.3 * sin(phase * 1.505)
        elif kind == "spell":
            body += 0.2 * sin(phase * 2.01)
        var sample: int = clampi(roundi(body * envelope * 15000.0), -32768, 32767)
        var packed: int = sample & 0xffff
        pcm[i * 2] = packed & 255
        pcm[i * 2 + 1] = (packed >> 8) & 255
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = pcm
    return stream
