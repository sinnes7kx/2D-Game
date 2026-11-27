extends SceneTree
const TITLE = preload("res://scripts/anomalous_title_v252.gd")
const PATHS = preload("res://scripts/weapon_particle_paths_v244.gd")
func _initialize() -> void:
	var quiet: Color = TITLE.ink(4.25)
	var peak: Color = TITLE.ink(0.0)
	assert(quiet.b > quiet.r and peak.b > peak.r)
	assert(peak.get_luminance() > quiet.get_luminance())
	var uid: String = "0123456789abcdef0123456789abcdef"
	assert(TITLE.palette_for(uid, 12) == TITLE.palette_for(uid.to_upper(), 99))
	assert(TITLE.palette_for("", 42) == TITLE.palette_for("", 42))
	var hues: Dictionary = {}
	for seed_value in range(64):
		var palette: Array[Color] = TITLE.palette_for("", seed_value)
		assert(palette.size() == 3)
		hues[roundi(palette[1].h * 24.0)] = true
		assert(palette[0].get_luminance() >= 0.229)
		assert(palette[1].get_luminance() >= 0.229)
		for sample in range(32):
			var ink: Color = TITLE.ink(float(sample) * 0.27, palette)
			assert(absf(wrapf(ink.h - palette[1].h, -0.5, 0.5)) < 0.05)
	assert(hues.size() >= 5)
	var label: Label = Label.new()
	var item: GhostItemInstance = GhostItemInstance.new()
	item.cosmetic_uid = uid
	TITLE.apply(label, 1.0, item)
	var first: Color = label.get_theme_color("font_color")
	item.item_seed = 9999
	TITLE.apply(label, 1.0, item)
	assert(label.get_theme_color("font_color") == first)
	item.cosmetic_uid = "fedcba9876543210fedcba9876543210"
	TITLE.apply(label, 1.0, item)
	assert(str(label.get_meta(TITLE.CACHE_KEY)["identity"]) == item.cosmetic_uid)
	label.free()
	for pattern in range(8):
		var p: Vector2 = PATHS.offset(pattern, 0.35, 0.5, Vector2(12, 12))
		assert(p.is_finite())
		assert(p.length() < 24.0)
	print("v252 title palette and wisp paths")
	quit()
