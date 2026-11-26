extends SceneTree
const SILK = preload("res://scripts/silk_motion_v226.gd")
const STEADY = preload("res://scripts/steady_weapon_idles_v195.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var a: Image = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	var b: Image = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	a.fill(Color(0.9, 0.1, 0.3, 1.0))
	b.fill(Color(0.1, 0.8, 0.6, 1.0))
	var original: Texture2D = ImageTexture.create_from_image(a)
	var alternate: Texture2D = ImageTexture.create_from_image(b)
	var samples: Array[Texture2D] = STEADY._create_steps(original, alternate, 24)
	if samples.size() != 24 or samples[0] != original:
		_fail("Idle timing slots or original keyframe lost")
		return
	var refs: Dictionary = {}
	for texture in samples:
		refs[texture.get_instance_id()] = true
	if refs.size() != 13:
		_fail("24-sample cycle must allocate 13 unique references")
		return
	for i in range(1, 12):
		if samples[i] != samples[24 - i]:
			_fail("Cosine return not reused")
			return
		var mix: float = 0.18 * (0.5 - 0.5 * cos(TAU * float(i) / 24.0))
		if samples[i].get_image().get_data() != STEADY._mix_rgba(a.get_data(), b.get_data(), mix):
			_fail("Outgoing sample paint changed")
			return
	var target: Vector2 = Vector2(-0.6, 0.8)
	var hair: Vector2 = SILK.follow_vector(Vector2.ZERO, target, 0.1, 7.5)
	var hem: Vector2 = SILK.follow_vector(Vector2.ZERO, target, 0.1, 3.7)
	if hair.length() <= hem.length() or hair.length() >= 1.0 or hem.y <= 0.0:
		_fail("Independent two-axis inertia missing")
		return
	var stopped: Vector2 = SILK.follow_vector(hem, Vector2.ZERO, 0.2, 3.7)
	if stopped.length() >= hem.length():
		_fail("Fabric does not settle")
		return
	for face in ["front", "back", "left", "right"]:
		for family in ["wand_walk_", "dual_sword_walk_", "dual_dagger_walk_"]:
			if not SILK.supports(family + face):
				_fail("Clean modular walking pose unsupported")
				return
		if SILK.supports("attack_sword_light_" + face) or SILK.supports("wand_cast_" + face):
			_fail("Motion escaped approved scope")
			return
	print("v2.27 PASS: 24 slots / 13 idle references, unchanged outgoing paint, separate bounded silk response")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
