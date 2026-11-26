extends SceneTree
const SILK = preload("res://scripts/silk_motion_v226.gd")
const PAINT = preload("res://scripts/steady_weapon_idles_v195.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var a: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	var b: Image = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
	a.fill(Color.TRANSPARENT)
	b.fill(Color.TRANSPARENT)
	a.fill_rect(Rect2i(3, 4, 7, 6), Color(0.9, 0.2, 0.5, 1.0))
	b.fill_rect(Rect2i(6, 2, 7, 6), Color(0.2, 0.8, 0.3, 1.0))
	var overlap: Rect2i = a.get_used_rect().intersection(b.get_used_rect())
	for mix in [0.0, 0.08, 0.18, 0.2]:
		var full: PackedByteArray = PAINT._mix_rgba(a.get_data(), b.get_data(), mix)
		var fast: PackedByteArray = PAINT._mix_rgba(a.get_data(), b.get_data(), mix, 16, overlap)
		if full != fast:
			_fail("Bounded blend changed pixels")
			return
	if PAINT._mix_rgba(a.get_data(), b.get_data(), 0.18, 16, Rect2i()) != a.get_data():
		_fail("Empty overlap did not retain base")
		return
	if not SILK.supports("walk_front") or not SILK.supports("wand_idle_left") or SILK.supports("attack_sword_light_front") or SILK.supports("wand_cast_front"):
		_fail("Secondary motion escaped supported poses")
		return
	var one: float = SILK.follow(0.0, 1.0, 0.1, 5.0)
	var two: float = SILK.follow(SILK.follow(0.0, 1.0, 0.05, 5.0), 1.0, 0.05, 5.0)
	if not is_equal_approx(one, two) or one <= 0.0 or one >= 1.0:
		_fail("Lag is frame-rate dependent")
		return
	var source: String = FileAccess.get_file_as_string("res://assets/equipment/dress_palette.gdshader")
	if not source.contains("silk_enabled > 0.5") or not source.contains("TEXTURE_PIXEL_SIZE"):
		_fail("Missing bounded shader branch")
		return
	print("v2.26 PASS: byte-identical bounded paint blend, scoped motion and frame-rate-independent lag")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
