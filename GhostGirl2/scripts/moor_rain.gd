@tool
extends Node2D
const PERF_V230 = preload("res://scripts/performance_profiles_v230.gd")
var redraw_clock: float = 0.0
var last_profile_revision: int = -1
var followed_player: Node2D = null
## Local, camera-adjacent drizzle. Keeping only nearby streaks alive avoids
## expensive whole-map particles in the 10,368 x 6,912 wilderness.
@export_range(0.0, 1.0, 0.05) var intensity: float = 0.38
@export_range(-160.0, 160.0, 5.0) var wind: float = 42.0
@export_range(40, 260, 5) var streak_count: int = 140
@export var editor_preview: bool = false
var elapsed: float = 0.0
var drops: Array[Vector4] = []
const VIEW_SIZE := Vector2(2900.0, 1850.0)

func _ready() -> void:
    z_index = 42
    _populate_drops()

func _populate_drops() -> void:
    drops.clear()
    var rng := RandomNumberGenerator.new()
    rng.seed = 121601
    for i in range(streak_count):
        drops.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(430.0, 780.0), rng.randf_range(0.55, 1.2)))

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        if editor_preview:
            elapsed += delta
            queue_redraw()
        return
    if not is_instance_valid(followed_player) or not followed_player.is_inside_tree() or followed_player.is_queued_for_deletion():
        followed_player = get_tree().get_first_node_in_group("ghost_girl_player") as Node2D
    if not is_instance_valid(followed_player):
        return
    global_position = followed_player.global_position
    elapsed += delta
    redraw_clock += delta
    var hz: float = PERF_V230.rain_hz()
    if last_profile_revision != PERF_V230.revision or PERF_V230.due(redraw_clock, hz):
        last_profile_revision = PERF_V230.revision
        redraw_clock = PERF_V230.remainder(redraw_clock, hz)
        queue_redraw()

func _draw() -> void:
    if intensity <= 0.01 or (Engine.is_editor_hint() and not editor_preview):
        return
    if drops.size() != streak_count:
        _populate_drops()
    var density: float = 1.0 if Engine.is_editor_hint() else PERF_V230.rain_density()
    var count: int = clampi(roundi(float(drops.size()) * intensity * density), 0, drops.size())
    for i in range(count):
        var d: Vector4 = drops[i]
        var x: float = fposmod(d.x * VIEW_SIZE.x + elapsed * wind * d.w, VIEW_SIZE.x) - VIEW_SIZE.x * 0.5
        var y: float = fposmod(d.y * VIEW_SIZE.y + elapsed * d.z, VIEW_SIZE.y) - VIEW_SIZE.y * 0.5
        var p: Vector2 = Vector2(x, y)
        var streak: Vector2 = Vector2(-3.0 - wind * 0.045, 13.0 + d.w * 10.0)
        var alpha: float = (0.09 + 0.09 * d.w) * intensity
        draw_line(p, p + streak, Color(0.72, 0.78, 0.94, alpha), 1.0 if d.w < 0.9 else 1.4, true)
        if i % 16 == 0:
            draw_arc(p + streak * 1.5, 4.2, PI * 0.1, PI * 0.9, 9, Color(0.70, 0.77, 0.90, alpha * 0.65), 1.0, true)
