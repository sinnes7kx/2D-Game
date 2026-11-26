extends RefCounted
## Session-only display preference. Never part of an item seed or save.
const DEFAULT_INTENSITY: float = 2.0
static var intensity: float = DEFAULT_INTENSITY
static var revision: int = 0

static func set_intensity(value: float) -> void:
	var next: float = clampf(value, 0.0, 2.0)
	if not is_equal_approx(next, intensity):
		intensity = next
		revision += 1

static func alpha(value: float) -> float:
	return clampf(value * intensity, 0.0, 1.0)

static func edge_alpha(canvas: Node2D, value: float) -> float:
	# The prestige-only node already applies the setting via self_modulate.
	return clampf(value, 0.0, 1.0) if canvas.has_meta("v1924_fx_scaled") else alpha(value)
