extends RefCounted
## Original procedural, short transient layers. No external samples/licenses.
## Only presentation: never changes damage, stamina, animation timing or saves.
const RATE: int = 32000
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
    # Quiet, bounded variation prevents identical repeated farming cues.
    voice.pitch_scale = randf_range(0.965, 1.035)
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
        "dagger_swing":
            duration = 0.145
            air_weight = 0.72
            bass_weight = 0.008
        "blunt_swing":
            duration = 0.35
            air_weight = 0.88
            bass_weight = 0.12
        "polearm_swing":
            duration = 0.28
            air_weight = 1.02
            bass_weight = 0.055
        "dodge":
            duration = 0.22
            air_weight = 0.60
            bass_weight = 0.012
        "scythe_heavy":
            duration = 0.64
            air_weight = 1.22
            bass_weight = 0.11
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

# Original filtered-air and glass-resonance magic, not a rising beep.
static func _render_wand(kind: String) -> AudioStreamWAV:
    var heavy: bool = kind in ["spell_heavy", "spell_release_heavy"]
    var hit: bool = kind == "spell_hit"
    var release: bool = kind.begins_with("spell_release")
    var duration: float = 0.40 if heavy else (0.23 if hit else (0.25 if release else 0.32))
    var count: int = roundi(duration * RATE)
    var pcm: PackedByteArray = PackedByteArray()
    pcm.resize(count * 2)
    var state: int = posmod(kind.hash() + 92813, 2147483646) + 1
    var low: float = 0.0
    var mid: float = 0.0
    var phase: float = 0.0
    for i in range(count):
        var t: float = float(i) / float(count)
        state = (state * 16807) % 2147483647
        var white: float = float(state % 65535) / 32767.5 - 1.0
        mid = lerpf(mid, white, 0.13)
        low = lerpf(low, white, 0.018)
        var air: float = (mid - low) * pow(maxf(0.0, sin(PI * t)), 1.5)
        phase += TAU * lerpf(340.0 if heavy else 460.0, 260.0 if hit else 520.0, t) / RATE
        var attack: float = minf(1.0, t / 0.035)
        var decay: float = pow(1.0 - t, 2.2) * attack
        var glass: float = (sin(phase) * 0.16 + sin(phase * 2.37) * 0.055 + sin(phase * 3.11) * 0.022) * decay
        var sound: float = air * (1.20 if heavy or release else 0.85) + glass + low * decay * (0.5 if hit else 0.12)
        var sample: int = clampi(roundi(sound * 14500.0), -32768, 32767)
        var packed: int = sample & 0xffff
        pcm[i * 2] = packed & 255
        pcm[i * 2 + 1] = (packed >> 8) & 255
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.stereo = false
    stream.data = pcm
    return stream

# Six compact, original material-specific impact transients. These are
# synthesized once per cue by the existing capped positional audio cache.
static func _render_arrow(kind: String) -> AudioStreamWAV:
    var duration: float = 0.16
    var frequency: float = 260.0
    var resonance: float = 0.12
    var noise_weight: float = 0.55
    var decay: float = 9.0
    var filter_rate: float = 0.20
    match kind:
        "arrow_flesh":
            duration = 0.13
            frequency = 105.0
            resonance = 0.32
            noise_weight = 0.48
            filter_rate = 0.08
        "arrow_wood":
            duration = 0.17
            frequency = 315.0
            resonance = 0.30
            noise_weight = 0.68
            decay = 12.0
        "arrow_stone":
            duration = 0.19
            frequency = 720.0
            resonance = 0.20
            noise_weight = 0.85
            filter_rate = 0.48
        "arrow_metal":
            duration = 0.29
            frequency = 1260.0
            resonance = 0.47
            noise_weight = 0.30
            decay = 5.0
            filter_rate = 0.52
        "arrow_water":
            duration = 0.24
            frequency = 180.0
            resonance = 0.18
            noise_weight = 0.77
            decay = 6.0
            filter_rate = 0.11
        "arrow_magic":
            duration = 0.33
            frequency = 680.0
            resonance = 0.39
            noise_weight = 0.22
            decay = 5.0
    var count: int = roundi(duration * RATE)
    var pcm: PackedByteArray = PackedByteArray()
    pcm.resize(count * 2)
    var state: int = posmod(kind.hash() + 53177, 2147483646) + 1
    var low: float = 0.0
    var band: float = 0.0
    var phase: float = 0.0
    for i in range(count):
        var t: float = float(i) / float(count)
        state = (state * 16807) % 2147483647
        var white: float = float(state % 65535) / 32767.5 - 1.0
        band = lerpf(band, white, filter_rate)
        low = lerpf(low, white, 0.035)
        var transient: float = (band - low * 0.65) * noise_weight * exp(-13.0 * t)
        var pitch: float = frequency
        if kind == "arrow_water":
            pitch *= 1.0 + 0.36 * sin(t * TAU * 3.0)
            transient += band * 0.21 * sin(PI * t) * exp(-4.0 * t)
        elif kind == "arrow_flesh":
            pitch *= 1.0 - t * 0.48
        phase += TAU * pitch / RATE
        var ring: float = (sin(phase) + 0.30 * sin(phase * (1.48 if kind == "arrow_metal" else 2.01))) * resonance * exp(-decay * t)
        if kind == "arrow_magic":
            ring += sin(phase * 2.73) * 0.09 * exp(-4.0 * t)
        var envelope: float = minf(1.0, t / 0.012) * pow(1.0 - t, 1.3)
        var sample: int = clampi(roundi((transient + ring) * envelope * 19500.0), -32768, 32767)
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
    if kind in ["blunt_hit", "blade_hit", "crossbow_fire", "crossbow_reload", "bow_release", "ground_slam", "combo_finisher", "evade"]:
        return _render_foley(kind)
    if kind.begins_with("surface_"):
        return _render_arrow("arrow_" + kind.trim_prefix("surface_"))
    if kind in ["arrow_flesh", "arrow_wood", "arrow_stone", "arrow_metal", "arrow_water", "arrow_magic"]:
        return _render_arrow(kind)
    if kind in ["spell", "spell_heavy", "spell_release", "spell_release_heavy", "spell_hit"]:
        return _render_wand(kind)
    if kind in ["swing", "heavy_swing", "jump_swing", "charged_swing", "scythe_heavy", "dagger_swing", "blunt_swing", "polearm_swing", "dodge"]:
        return _render_air_sweep(kind)
    if kind in ["hit", "parry"]:
        return _render_soft_contact(kind)
    var duration: float = 0.19
    var start_hz: float = 350.0
    var end_hz: float = 100.0
    var noise_mix: float = 0.45
    match kind:
        "combo_finisher":
            duration = 0.31
            start_hz = 420.0
            end_hz = 72.0
            noise_mix = 0.42
        "ground_slam":
            duration = 0.36
            start_hz = 105.0
            end_hz = 34.0
            noise_mix = 0.68
        "crossbow_fire":
            duration = 0.10
            start_hz = 520.0
            end_hz = 130.0
            noise_mix = 0.76
        "crossbow_reload":
            duration = 0.18
            start_hz = 930.0
            end_hz = 390.0
            noise_mix = 0.56
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

# Original layered foley: filtered contact, a low body resonance and a
# small secondary mechanical transient. Cached once per cue, no audio assets.
static func _render_foley(kind: String) -> AudioStreamWAV:
    var duration: float = 0.24
    var fundamental: float = 135.0
    var mass: float = 0.36
    var grit: float = 0.45
    var clicks: float = 0.0
    var ring: float = 0.025
    match kind:
        "blunt_hit", "ground_slam":
            duration = 0.34
            fundamental = 74.0
            mass = 0.62
            grit = 0.42
        "blade_hit":
            duration = 0.17
            fundamental = 155.0
            mass = 0.26
            grit = 0.64
        "crossbow_fire", "bow_release":
            duration = 0.20
            fundamental = 215.0 if kind == "bow_release" else 140.0
            clicks = 0.30
            ring = 0.12
        "crossbow_reload":
            duration = 0.34
            fundamental = 250.0
            mass = 0.10
            grit = 0.23
            clicks = 0.60
        "combo_finisher":
            duration = 0.31
            fundamental = 105.0
            mass = 0.50
            ring = 0.08
        "evade":
            duration = 0.27
            fundamental = 395.0
            mass = 0.08
            grit = 0.18
            ring = 0.18
    var count: int = roundi(duration*RATE)
    var pcm: PackedByteArray = PackedByteArray()
    pcm.resize(count*2)
    var state: int = posmod(kind.hash()+77321,2147483646)+1
    var low: float = 0.0
    var mid: float = 0.0
    var phase: float = 0.0
    for i in range(count):
        var t: float = float(i)/float(count)
        state = (state*16807)%2147483647
        var white: float = float(state%65535)/32767.5-1.0
        low = lerpf(low,white,0.023)
        mid = lerpf(mid,white,0.21)
        phase += TAU*fundamental*(1.0-0.27*t)/RATE
        var contact: float = (mid-low)*grit*exp(-16.0*t)
        var body: float = (sin(phase)+low*0.7)*mass*exp(-11.0*t)
        var metal: float = (sin(phase*2.71)+0.22*sin(phase*4.13))*ring*exp(-7.0*t)
        var mechanical: float = (mid-low)*clicks*(exp(-absf(t-0.19)*48.0)+0.64*exp(-absf(t-0.53)*60.0))
        var env: float = minf(1.0,t/0.014)*pow(1.0-t,1.2)
        var value: int = clampi(roundi((contact+body+metal+mechanical)*env*19000.0),-32768,32767)&0xffff
        pcm[i*2] = value&255
        pcm[i*2+1] = (value>>8)&255
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = RATE
    stream.data = pcm
    return stream
