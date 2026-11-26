extends SceneTree
const PAINT = preload("res://scripts/steady_weapon_idles_v195.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var width: int = 17
    var height: int = 13
    var a: PackedByteArray = PackedByteArray()
    var b: PackedByteArray = PackedByteArray()
    var alpha_values: Array[int] = [0, 128, 231, 232, 254, 255]
    for i in range(width * height):
        a.append_array(PackedByteArray([i % 256, (i * 13) % 256, 64, alpha_values[i % 6]]))
        b.append_array(PackedByteArray([(255 - i) % 256, (i * 7) % 256, 64, alpha_values[(i + 1) % 6]]))
    for bounds in [Rect2i(0, 0, width, height), Rect2i(3, 2, 8, 7), Rect2i()]:
        var channels: PackedInt32Array = PAINT._changed_channels(a, b, width, bounds)
        for p in channels:
            if p % 4 == 3 or a[p] == b[p] or a[p - p % 4 + 3] < 232 or b[p - p % 4 + 3] < 232:
                _fail("Prepared channel includes alpha or protected paint")
                return
        for weight in [-0.1, 0.0, 0.024, 0.055, 0.095, 0.145, 0.18, 0.2, 0.8]:
            var expected: PackedByteArray = PAINT._mix_rgba(a, b, weight, width, bounds)
            var actual: PackedByteArray = PAINT._mix_prepared(a, b, weight, channels)
            if actual != expected:
                _fail("Prepared paint differs from prior exact blend")
                return
    if PAINT.ATLAS_CACHE_LIMIT != 4:
        _fail("Idle atlas retention limit changed")
        return
    var shader: String = FileAccess.get_file_as_string("res://assets/equipment/dress_palette.gdshader")
    if not shader.contains("hair > 0.001 || hem > 0.001") or not shader.contains("side_phase") or not shader.contains("vec2(-2.5), vec2(2.5)"):
        _fail("Bounded independent silk ripple wiring missing")
        return
    print("v2.29 PASS: byte-identical prepared blends, bounded atlas retention and silk ripple wiring")
    quit(0)

func _fail(reason: String) -> void:
    push_error(reason)
    quit(1)
