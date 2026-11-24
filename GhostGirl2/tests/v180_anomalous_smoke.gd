extends SceneTree
const FX = preload("res://scripts/anomalous_steel_fx_v180.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const DAGGERS = preload("res://scripts/v173_dual_daggers.gd")
const LOOK = preload("res://scripts/collector_appearance_v177.gd")

func _initialize() -> void:
	var uid: String = "0123456789abcdef0123456789abcdef"
	var look: Dictionary = LOOK.roll(uid, 123)
	var colors: Array[Color] = [Color.RED, Color.BLUE, Color.GREEN]
	for mode in range(7):
		look["color_mode"] = mode
		var first: Color = FX.color_at(colors, look, 0.31, 0.0)
		var later: Color = FX.color_at(colors, look, 0.31, 2.4)
		if mode >= 2 and first.is_equal_approx(later):
			push_error("Animated chromatic mode did not change: " + str(mode))
			quit(1)
			return
	var eclipse: Dictionary = ART.weapon_profile(look, "eclipse_twinblade_v170")
	var rose: Dictionary = ART.weapon_profile(look, "rosemirror_twinblade_v170")
	if eclipse["shape"] == rose["shape"] or float(eclipse["width_scale"]) >= float(rose["width_scale"]):
		push_error("Twinblade silhouettes are not distinct")
		quit(1)
		return
	if DAGGERS.hand_anchor("front", 3, 1) != Vector2(77, -3) or DAGGERS.hand_anchor("left", 3, 1) != Vector2.INF:
		push_error("Dagger visible hand anchors or occlusion changed")
		quit(1)
		return
	var item: GhostItemInstance = GhostItemInstance.new()
	item.definition = load("res://items/eclipse_twinblade_v170.tres") as GhostItemData
	item.cosmetic_uid = uid
	var before: Dictionary = item.cosmetic_snapshot()
	var damage: float = item.weapon_damage()
	item.debug_collector_tier = 6
	item.debug_color_mode = 6
	item.debug_glow_motif = 7
	if OS.is_debug_build() and (item.collector_appearance()["material"] != 6 or item.collector_appearance()["glow_motif"] != 7):
		push_error("Debug preview not active")
		quit(1)
		return
	if before != item.cosmetic_snapshot() or damage != item.weapon_damage():
		push_error("Preview changed persistent look or gameplay stats")
		quit(1)
		return
	print("v1.80 PASS: color motion, distinct twinblade silhouettes, measured anchor samples, unsaved debug overrides")
	quit(0)
