@tool
extends Node2D
## Small, original gothic overworld wildlife: no loot, collisions or save writes.
## Editor-placed homes keep critters from spawning in walls or on the player.
@export_enum("moth", "hare", "crow", "fox") var species: String = "moth"
@export_range(12.0, 110.0, 2.0) var wander_radius: float = 46.0
@export_range(0.2, 1.8, 0.1) var wander_speed: float = 0.65
var time_alive: float = 0.0
var home: Vector2 = Vector2.ZERO
var offset: Vector2 = Vector2.ZERO
var facing: float = 1.0
var phase: float = 0.0
var flee: float = 0.0

func _ready() -> void:
    home = position
    phase = float(posmod(name.hash(), 997)) / 997.0 * TAU
    z_index = 6
    set_process(true)

func _process(delta: float) -> void:
    time_alive += delta
    if Engine.is_editor_hint():
        queue_redraw()
        return
    var player: Node2D = get_tree().get_first_node_in_group("ghost_girl_player") as Node2D
    var nearby: bool = player != null and player.global_position.distance_to(global_position) < 115.0
    flee = move_toward(flee, 1.0 if nearby else 0.0, delta * (1.8 if nearby else 0.65))
    var t: float = time_alive * wander_speed + phase
    var target: Vector2 = Vector2(sin(t * 0.84) * wander_radius, cos(t * 0.57) * wander_radius * 0.43)
    if nearby and player != null:
        target += (global_position - player.global_position).normalized() * flee * minf(35.0, wander_radius * 0.65)
    target = target.limit_length(wander_radius)
    offset = offset.lerp(target, minf(1.0, delta * 1.6))
    position = home + offset
    facing = signf(cos(t * 0.84)) if absf(cos(t * 0.84)) > 0.04 else facing
    queue_redraw()

func _draw() -> void:
    var drift: float = sin(time_alive * 2.0 + phase)
    var ink: Color = Color("483f4b")
    var highlight: Color = Color("bbacc0")
    match species:
        "moth":
            var flap: float = 1.0 + 0.25 * sin(time_alive * 11.0 + phase)
            draw_circle(Vector2(0, -17 + drift * 3.0), 4.0, Color("baa6be"))
            for side in [-1.0, 1.0]:
                draw_colored_polygon(PackedVector2Array([Vector2(0, -18), Vector2(side * 12.0 * flap, -26), Vector2(side * 9.0 * flap, -13)]), Color("82798c"))
            draw_circle(Vector2(0, -17 + drift * 3.0), 1.3, Color("f1d9d4"))
        "hare":
            _draw_critter_ellipse(Vector2(0, 3), Vector2(16, 9), ink)
            draw_circle(Vector2(10 * facing, -6), 8.0, Color("6c606e"))
            for j in [-1.0, 1.0]:
                draw_line(Vector2(10 * facing + j * 2.5, -10), Vector2(10 * facing + j * 4.0, -29), Color("6c606e"), 5.0, true)
            draw_circle(Vector2(13 * facing, -7), 1.6, highlight)
            draw_circle(Vector2(-13 * facing, 2), 4.6, Color("a698aa"))
        "crow":
            _draw_critter_ellipse(Vector2(0, 0), Vector2(16, 8), Color("36333f"))
            draw_circle(Vector2(12 * facing, -7), 7.0, Color("393543"))
            draw_colored_polygon(PackedVector2Array([Vector2(14 * facing, -8), Vector2(27 * facing, -5), Vector2(14 * facing, -3)]), Color("b59b84"))
            draw_line(Vector2(-10 * facing, -3), Vector2(-21 * facing, -12), Color("5b5364"), 3.0, true)
            draw_circle(Vector2(13 * facing, -8), 1.3, Color("d3c1d9"))
        "fox":
            _draw_critter_ellipse(Vector2(0, 0), Vector2(22, 8), Color("76545f"))
            draw_circle(Vector2(15 * facing, -10), 9.0, Color("8e6974"))
            for side in [-1.0, 1.0]:
                draw_colored_polygon(PackedVector2Array([Vector2(12 * facing + side * 5, -14), Vector2(16 * facing + side * 8, -30), Vector2(17 * facing + side * 10, -12)]), Color("5e4356"))
            draw_line(Vector2(-13 * facing, -3), Vector2(-30 * facing, -13 + drift * 2), Color("916b79"), 9.0, true)
            draw_circle(Vector2(19 * facing, -10), 1.3, highlight)

func _draw_critter_ellipse(center: Vector2, size: Vector2, ink: Color) -> void:
    draw_set_transform(center, 0.0, size / Vector2(10.0, 10.0))
    draw_circle(Vector2.ZERO, 10.0, ink)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
