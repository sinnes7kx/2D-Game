extends Node2D
## v2.11 independent visual-only scythe silhouette aura.
## Zero is deliberately the common result. No save field or stat/RNG changes.
const SCYTHE = preload("res://scripts/scythe_art_v190.gd")
const RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const FX_LEVEL = preload("res://scripts/fx_intensity_v1924.gd")
const STOPS: Array[float] = [0.0, 0.10, 0.20, 0.30, 0.40, 0.50]

var grip: Vector2 = Vector2.ZERO
var head: Vector2 = Vector2.ZERO
var profile: Dictionary = {}
var side: float = 1.0
var palette: Array[Color] = []
var level: int = 0
var active: bool = false

func _ready() -> void:
	# Additive light is isolated from the opaque painted weapon and body.
	var light_material: CanvasItemMaterial = CanvasItemMaterial.new()
	light_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = light_material

static func rolled_level(item: GhostItemInstance) -> int:
	if item == null or item.definition == null or item.weapon_style() != "scythe":
		return 0
	# Domain-separated digest: distinct from stats, material, existing FX.
	var identity: String = item.cosmetic_uid.to_lower() if RNG.is_valid_uid(item.cosmetic_uid) else "legacy-%d" % item.visual_seed()
	var digest: PackedByteArray = ("ghost-girl-v211-scythe-aura:" + identity).sha256_buffer()
	# Most cosmetic appearances have no aura; other five bands are
	# equally represented within the remaining 30%. No fake rarity name.
	if int(digest[0]) < 179: # 179/256 ~= 69.9%
		return 0
	return 1 + int(digest[1]) % 5

static func opacity(level_index: int) -> float:
	return STOPS[clampi(level_index, 0, STOPS.size() - 1)]

func set_pose(item: GhostItemInstance, at_grip: Vector2, at_head: Vector2, shape: Dictionary, direction: float, override_level: int = -1) -> void:
	var next_level: int = clampi(override_level, 0, 5) if override_level >= 0 else rolled_level(item)
	var enabled: bool = item != null and item.weapon_style() == "scythe" and at_grip.distance_squared_to(at_head) > 16.0 and not shape.is_empty()
	var new_palette: Array[Color] = []
	if enabled:
		new_palette = item.glow_gradient_colors()
	if grip == at_grip and head == at_head and side == direction and level == next_level and active == enabled and profile == shape and palette == new_palette:
		return
	grip = at_grip
	head = at_head
	profile = shape.duplicate()
	side = direction
	level = next_level
	active = enabled
	palette = new_palette
	visible = active and level > 0
	queue_redraw()

func clear_pose() -> void:
	active = false
	hide()

func _draw() -> void:
	if not active or level <= 0 or FX_LEVEL.intensity <= 0.0 or palette.is_empty():
		return
	var alpha: float = opacity(level) * clampf(FX_LEVEL.intensity, 0.0, 1.0)
	if alpha <= 0.0:
		return
	var axis: Vector2 = (head - grip).normalized()
	var foot: Vector2 = grip - axis * 35.0
	var contours: Array[PackedVector2Array] = SCYTHE.contours(head, axis, profile, side)
	var outer: PackedVector2Array = contours[0]
	var inner: PackedVector2Array = contours[1]
	var base: Color = RNG.sample_palette(palette, 0.60).lerp(Color("ddd7fa"), 0.20)
	# Separate expanded aura drawn over the entire scythe silhouette:
	# long shaft, outside crescent and inside cutting edge. No damage.
	var widths: Array[float] = [16.0, 9.0, 4.0]
	var strengths: Array[float] = [0.11, 0.19, 0.27]
	for layer_index in range(3):
		var width: float = widths[layer_index]
		var strength: float = strengths[layer_index]
		var ink: Color = Color(base.r, base.g, base.b, alpha * strength)
		draw_line(foot, head, ink, width * 0.65, true)
		draw_polyline(outer, ink, width, true)
		draw_polyline(inner, ink, width * 0.80, true)
	# A small stronger rim follows the actual authored geometry, not a
	# screen-space rectangle or a straight line at the scythe head.
	var rim: Color = Color(base.r, base.g, base.b, alpha * 0.44)
	draw_line(foot, head, rim, 1.2, true)
	draw_polyline(outer, rim, 1.5, true)
	draw_polyline(inner, rim, 1.5, true)
