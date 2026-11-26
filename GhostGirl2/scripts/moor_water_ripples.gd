@tool
extends Node2D
const PERF_V230 = preload("res://scripts/performance_profiles_v230.gd")
var redraw_clock: float = 0.0
var last_profile_revision: int = -1
## Draws restrained glints on top of the existing painted pond, without
## replacing the user's background art or obscuring Ghost Girl.
@export_range(3, 24, 1) var glint_count: int = 11
@export_range(0.0, 1.0, 0.05) var glint_strength: float = 0.45
var phase: float = 0.0
var local_centers: Array[Vector3] = []

func _ready() -> void:
    _create_glints()

func _create_glints() -> void:
    local_centers.clear()
    var water: GhostWaterBody = get_parent() as GhostWaterBody
    if water == null or not water.has_node("WaterPolygon"):
        return
    var points: PackedVector2Array = (water.get_node("WaterPolygon") as CollisionPolygon2D).polygon
    if points.size() < 3:
        return
    # Use the polygon's actual bounding rectangle for candidate locations.
    var min_x: float = points[0].x
    var min_y: float = points[0].y
    var max_x: float = points[0].x
    var max_y: float = points[0].y
    for v in points:
        min_x = minf(min_x, v.x)
        max_x = maxf(max_x, v.x)
        min_y = minf(min_y, v.y)
        max_y = maxf(max_y, v.y)
    var rng := RandomNumberGenerator.new()
    rng.seed = 121202 + points.size() * 13
    for _i in range(glint_count * 8):
        var candidate: Vector2 = Vector2(rng.randf_range(min_x, max_x), rng.randf_range(min_y, max_y))
        if Geometry2D.is_point_in_polygon(candidate, points):
            local_centers.append(Vector3(candidate.x, candidate.y, rng.randf_range(0.0, TAU)))
            if local_centers.size() >= glint_count:
                break

func _process(delta: float) -> void:
    phase += delta
    redraw_clock += delta
    var hz: float = 0.0 if Engine.is_editor_hint() else PERF_V230.ambient_hz()
    if last_profile_revision != PERF_V230.revision or PERF_V230.due(redraw_clock, hz):
        last_profile_revision = PERF_V230.revision
        redraw_clock = PERF_V230.remainder(redraw_clock, hz)
        queue_redraw()

func _draw() -> void:
    if glint_strength <= 0.0:
        return
    for i in range(local_centers.size()):
        var spot: Vector3 = local_centers[i]
        var t: float = fposmod(phase * (0.6 + float(i % 3) * 0.10) + spot.z, TAU) / TAU
        var loc: Vector2 = Vector2(spot.x, spot.y)
        var radius: float = 9.0 + 21.0 * t
        var alpha: float = glint_strength * 0.20 * sin(t * PI)
        draw_arc(loc, radius, 0.12 * PI, 0.88 * PI, 15, Color(0.67, 0.75, 0.88, alpha), 1.2, true)
        if i % 3 == 0:
            draw_line(loc + Vector2(-6.0, 0.0), loc + Vector2(6.0, 0.0), Color(0.77, 0.81, 0.93, alpha * 0.7), 1.1, true)
