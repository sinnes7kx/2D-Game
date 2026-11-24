extends Node2D
const ANOMALOUS = preload("res://scripts/anomalous_steel_fx_v180.gd")
## A display-only weapon model; shares the equipped modular art routines.
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
var item: GhostItemInstance
var look: Dictionary = {}
var profiles: Array[Dictionary] = []
var gradients: Array[Color] = []
var glow_enabled: bool = true
var elapsed: float = 0.0
var segments: Array[PackedVector2Array] = []

func set_item(value: GhostItemInstance) -> void:
	item = value
	look = item.collector_appearance() if item != null else {}
	profiles.clear()
	for hand in range(2):
		profiles.append(ART.weapon_profile(look, str(item.definition.item_id), hand) if item != null and item.definition != null else {})
	gradients.clear()
	if item != null:
		gradients = item.glow_gradient_colors()
	elapsed = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if is_visible_in_tree() and glow_enabled:
		elapsed += delta
		queue_redraw()

func _grip(a: Vector2, b: Vector2, width: float, hand: int) -> void:
	ART.draw_grip(self, a, b, width, profiles[hand])

func _blade(a: Vector2, b: Vector2, width: float, hand: int) -> void:
	ART.draw_blade(self, a, b, width, profiles[hand])
	for side in [-1.0, 1.0]:
		segments.append(ART.edge_points(a, b, width, profiles[hand], side))

func is_modular() -> bool:
	if item == null or item.definition == null:
		return false
	return item.weapon_style() in ["twinblade", "dual_sword", "dual_dagger"] or str(item.definition.item_id) in ["nocturne_stiletto_v171", "moonwarden_spear_v169", "briarwake_trident_v171"]

func _draw() -> void:
	segments.clear()
	if item == null or item.definition == null:
		return
	if not is_modular() or profiles.is_empty() or profiles[0].is_empty():
		if item.definition.icon != null:
			draw_texture_rect(item.definition.icon, Rect2(-45, -45, 90, 90), false)
		return
	var style: String = item.weapon_style()
	match style:
		"twinblade":
			var width: float = 3.8 if str(item.definition.item_id) == "rosemirror_twinblade_v170" else 3.2
			_grip(Vector2(0, 11.88), Vector2(0, -12), 3.0, 0)
			_blade(Vector2(0, -12), Vector2(0, -60), width, 0)
			_blade(Vector2(0, 11.88), Vector2(0, 54), width, 0)
		"dual_sword", "dual_dagger":
			var dagger: bool = style == "dual_dagger"
			for hand in range(2):
				var x: float = -17.0 if hand == 0 else 17.0
				var a: Vector2 = Vector2(x, 9)
				var tip: Vector2 = Vector2(x, -26 if dagger else -53)
				_grip(Vector2(x, 25), a, 3.5 if dagger else 5.1, hand)
				_blade(a, tip, 3.1 if dagger else (5.2 if hand == 0 else 4.8), hand)
		"spear":
			if str(item.definition.item_id) == "briarwake_trident_v171":
				_draw_trident()
			else:
				_grip(Vector2(0, 55), Vector2(0, -29), 3.8, 0)
				_blade(Vector2(0, -29), Vector2(0, -53), 4.5, 0)
		"trident":
			_draw_trident()
		_:
			if str(item.definition.item_id) == "briarwake_trident_v171":
				_draw_trident()
			else:
				_grip(Vector2(0, 20), Vector2(0, 5), 3.2, 0)
				_blade(Vector2(0, 5), Vector2(0, -35), 3.2, 0)
	if glow_enabled:
		_draw_light()

func _draw_trident() -> void:
	_grip(Vector2(0, 55), Vector2(0, -36), 4.5, 0)
	for side in [-1.0, 1.0]:
		var accent: Color = profiles[0]["accent"]
		draw_line(Vector2(0, -36), Vector2(side * 8, -36), accent.darkened(0.25), 2.5, true)
		_blade(Vector2(side * 8, -36), Vector2(side * 7, -51), 1.8, 0)
	_blade(Vector2(0, -36), Vector2(0, -53), 2.6, 0)

func _draw_light() -> void:
	for path in segments:
		ANOMALOUS.draw_edge(self, path, gradients, look, elapsed, float(look.get("glow_strength", 1.0)))
