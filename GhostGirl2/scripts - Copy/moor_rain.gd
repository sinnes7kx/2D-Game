@tool
extends Node2D
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
    var girl: Node2D = get_tree().get_first_node_in_group("ghost_girl_player") as Node2D
    if girl == null:
        return
    global_position = girl.global_position
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    if intensity <= 0.01 or (Engine.is_editor_hint() and not editor_preview):
        return
    if drops.size() != streak_count:
        _populate_drops()
    var count: int = maxi(0, roundi(float(drops.size()) * intensity))
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
