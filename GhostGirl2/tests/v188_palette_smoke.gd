extends SceneTree
const RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const FX = preload("res://scripts/anomalous_steel_fx_v180.gd")
const INV = preload("res://scripts/inventory.gd")

func _initialize() -> void:
	var sizes: Dictionary = {}
	var unique: Dictionary = {}
	var muted: bool = false
	var bright: bool = false
	for i in range(256):
		var uid: String = "%032x" % i
		var colors: Array[Color] = RNG.gradient_for_channel(uid, 1, "effect:0:6:6:0")
		sizes[colors.size()] = true
		unique[colors[0].to_html()] = true
		if colors != RNG.gradient_for_channel(uid, 999, "effect:0:6:6:0") or colors == RNG.gradient_for_channel(uid, 1, "effect:4:6:6:0"):
			_fail("UID stability or signature isolation failed")
			return
		for ink in colors:
			muted = muted or ink.s < 0.25
			bright = bright or ink.v > 0.9
		if not RNG.sample_palette(colors, 0.0, true).is_equal_approx(RNG.sample_palette(colors, 1.0, true)):
			_fail("Closed palette loop seam")
			return
	if sizes.size() != 7 or unique.size() < 200 or not muted or not bright:
		_fail("Insufficient palette variation")
		return
	# A deliberately narrow red palette must never become green or blue,
	# even at Anomaly tier or in the old hue-cycle/Prism modes.
	var reds: Array[Color] = [Color(0.8,0.05,0.10), Color(0.55,0.09,0.15), Color(0.95,0.15,0.19), Color(0.7,0.20,0.22)]
	for mode in range(7):
		var look: Dictionary = {"material":6,"particle_tier":6,"color_mode":mode,"palette_speed":0.18}
		for i in range(120):
			var ink: Color = FX.color_at(reds,look,float(i%17)/16.0,float(i)*0.4)
			if ink.r < ink.g or ink.r < ink.b:
				_fail("Anomaly escaped its rolled palette")
				return
	var inv: Node = INV.new()
	var item: GhostItemInstance = GhostItemGenerator.create(load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData,188001,"rare")
	item.cosmetic_uid = "123456789abcdef0123456789abcdef0"
	var original: Array[Color] = item.glow_gradient_colors()
	var stats: Dictionary = item.all_stats()
	var snapshot: Dictionary = item.cosmetic_snapshot()
	item.debug_collector_tier = 6
	item.debug_visual_override = 4
	if OS.is_debug_build() and item.glow_gradient_colors() == original:
		_fail("Special effect did not get its own palette")
		return
	var restored: GhostItemInstance = inv._deserialize_item(inv._serialize_item(item,Vector2i.ZERO))
	if restored == null or restored.glow_gradient_colors() != original or restored.all_stats() != stats or item.cosmetic_snapshot() != snapshot:
		_fail("Palette preview changed persistent item or stats")
		return
	inv.free()
	print("v1.88 PASS: variable 3–9 stop palettes, unique colors, special-effect isolation, seamless loops, bounded Anomaly and save fidelity")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
