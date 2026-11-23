@tool
extends Node2D
## Artist-authored floor breach. The existing support's one-time save flag
## controls when it opens; this script does NOT add new save fields.
@export var destination: String = "crypt_gallery"
@export var interaction_name: String = "Descend into the collapsed crypt floor"
@export var opened: bool = false
@export var hole_radius: Vector2 = Vector2(96.0, 58.0)
var reveal_clock: float = -1.0
var shimmer: float = 0.0

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    if opened:
        _open()

func reveal_from_collapse(restoring: bool = false) -> void:
    if opened:
        return
    if restoring:
        _open()
    else:
        # Masonry must actually land before the new passage becomes usable.
        reveal_clock = 0.84
    queue_redraw()

func _open() -> void:
    opened = true
    reveal_clock = -1.0
    if not Engine.is_editor_hint():
        add_to_group("room_portal")
        add_to_group("v1464_floor_breach")
        add_to_group("interactable")
    queue_redraw()

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    shimmer += delta
    if reveal_clock > 0.0:
        reveal_clock -= delta
        if reveal_clock <= 0.0:
            _open()
    queue_redraw()

func _draw() -> void:
    if not opened:
        # Faint seams hint at weakness without looking like an open passage.
        var seam: Color = Color(0.55, 0.44, 0.53, 0.35)
        for j in range(4):
            var x: float = -50.0 + float(j) * 31.0
            draw_polyline(PackedVector2Array([Vector2(x, -23), Vector2(x + 9.0, -6), Vector2(x - 7, 17), Vector2(x + 18, 33)]), seam, 1.7, true)
        return
    # Painted elliptical void; no mandatory new texture asset or opaque HUD.
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, hole_radius.y / hole_radius.x))
    draw_circle(Vector2.ZERO, hole_radius.x + 13.0, Color(0.34, 0.29, 0.38, 0.68))
    draw_circle(Vector2.ZERO, hole_radius.x + 6.0, Color(0.52, 0.43, 0.49, 0.8))
    draw_circle(Vector2.ZERO, hole_radius.x, Color(0.045, 0.035, 0.075, 0.95))
    draw_circle(Vector2(0, -11), hole_radius.x * 0.64, Color(0.085, 0.065, 0.14, 0.57))
    draw_arc(Vector2.ZERO, hole_radius.x + 3.0, PI * 0.03, PI * 0.97, 48, Color(0.81, 0.67, 0.7, 0.58), 4.0, true)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    for i in range(11):
        var a: float = float(i) * 2.39996
        var p: Vector2 = Vector2(cos(a) * (101.0 + float(i % 3) * 8.0), sin(a) * (61.0 + float(i % 3) * 5.0))
        draw_line(p, p + Vector2(8 + i % 4, -8 - i % 5), Color(0.55, 0.49, 0.55, 0.72), 3.0, true)
    var gleam: float = 0.35 + 0.2 * sin(shimmer * 1.7)
    draw_arc(Vector2(0, 7), 24.0, 0.1, PI * 1.9, 24, Color(0.72, 0.63, 0.9, gleam), 2.0, true)
    draw_circle(Vector2(0, 7), 3.0, Color(0.9, 0.83, 1.0, gleam))
