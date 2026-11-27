extends SceneTree
const TITLE = preload("res://scripts/anomalous_title_v252.gd")
const PATHS = preload("res://scripts/weapon_particle_paths_v244.gd")
func _initialize() -> void:
	var quiet: Color = TITLE.ink(4.25)
	var peak: Color = TITLE.ink(0.0)
	assert(quiet.b > quiet.r and peak.b > peak.r)
	assert(peak.get_luminance() > quiet.get_luminance())
	for pattern in range(8):
		var p: Vector2 = PATHS.offset(pattern, 0.35, 0.5, Vector2(12, 12))
		assert(p.is_finite())
		assert(p.length() < 24.0)
	print("v252 title palette and wisp paths")
	quit()
