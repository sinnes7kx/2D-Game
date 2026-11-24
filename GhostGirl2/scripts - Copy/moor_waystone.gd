@tool
extends Node2D
## A readable, hand-placed wilderness landmark. Not a teleporter:
## the player still explores the moor naturally and follows its paths.
@export var region_title: String = "Hollow Veil Moor"
@export_multiline var route_hint: String = "Southwest: Briar Hollow. Northeast: Moonthorn Woods."
@export var arrow_direction: Vector2 = Vector2.RIGHT
var elapsed: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("interactable")
        add_to_group("moor_waystone")

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var cold: Color = Color(0.64, 0.60, 0.70, 0.88)
    var warm: Color = Color(0.89, 0.70, 0.69, 0.90)
    var pulse: float = 0.65 + 0.2 * sin(elapsed * 1.5)
    draw_ellipse_ground()
    draw_colored_polygon(PackedVector2Array([Vector2(-15, 12), Vector2(-17, -27), Vector2(-8, -44), Vector2(9, -44), Vector2(17, -27), Vector2(15, 12)]), Color(0.15, 0.14, 0.18, 0.94))
    draw_line(Vector2(-15, 12), Vector2(-17, -27), cold, 2.3, true)
    draw_line(Vector2(-17, -27), Vector2(-8, -44), cold, 2.0, true)
    draw_line(Vector2(-8, -44), Vector2(9, -44), cold, 1.6, true)
    draw_line(Vector2(9, -44), Vector2(17, -27), cold, 2.0, true)
    draw_line(Vector2(17, -27), Vector2(15, 12), cold, 2.3, true)
    draw_line(Vector2(-11, -13), Vector2(11, -13), cold, 1.0, true)
    draw_circle(Vector2(0, -27), 8.5, Color(warm.r, warm.g, warm.b, 0.10 + 0.06 * pulse))
    var arrow: Vector2 = arrow_direction.normalized() if arrow_direction.length_squared() > 0.01 else Vector2.RIGHT
    var shaft_start: Vector2 = Vector2(0, -27) - arrow * 5.0
    var shaft_end: Vector2 = Vector2(0, -27) + arrow * 5.0
    draw_line(shaft_start, shaft_end, warm, 2.0, true)
    draw_line(shaft_end, shaft_end - arrow.rotated(0.65) * 5.0, warm, 1.7, true)
    draw_line(shaft_end, shaft_end - arrow.rotated(-0.65) * 5.0, warm, 1.7, true)
    draw_arc(Vector2(0, -27), 14.0, 0.0, TAU, 24, Color(warm.r, warm.g, warm.b, 0.12 + 0.10 * pulse), 1.0, true)

func draw_ellipse_ground() -> void:
    draw_circle(Vector2(0, 11), 21.0, Color(0.02, 0.02, 0.03, 0.22))
