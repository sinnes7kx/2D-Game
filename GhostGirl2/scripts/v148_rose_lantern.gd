@tool
extends Node2D
## Editor-placeable hook target for the timed Rose Path.
const CHIME: AudioStream = preload("res://assets/audio/hook_chime.wav")
@export_range(1, 3, 1) var order: int = 1
var clock: float = 0.0
var flash: float = 0.0
var local_cooldown: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("hook_switch")

func hook_prompt() -> String:
    return "F  HOOK ROSE LANTERN " + str(order)

func on_hook_latched() -> void:
    if Engine.is_editor_hint() or local_cooldown > 0.0:
        return
    local_cooldown = 0.60
    flash = 0.60
    var sound: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
    sound.stream = CHIME
    sound.pitch_scale = 0.92 + float(order) * 0.13
    sound.volume_db = -10.0
    add_child(sound)
    sound.play()
    sound.finished.connect(sound.queue_free)
    var route: Node = get_parent().get_parent()
    if route != null and route.has_method("ring"):
        route.call("ring", order)
    queue_redraw()

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    clock += delta
    flash = maxf(0.0, flash - delta)
    local_cooldown = maxf(0.0, local_cooldown - delta)
    queue_redraw()

func _draw() -> void:
    var route: Node = get_parent().get_parent() if get_parent() != null and get_parent().get_parent() != null else null
    var illuminated: bool = route != null and (bool(route.get("completed")) or (bool(route.get("active")) and int(route.get("progress")) >= order))
    var tint: Color = Color("edc6e5") if illuminated else Color("947e93")
    var pulse: float = 0.12 + 0.05 * sin(clock * 3.0)
    draw_circle(Vector2(0, -10), 30.0, Color(0.83, 0.54, 0.83, pulse if illuminated else 0.05))
    draw_line(Vector2(0, -49), Vector2(0, -31), Color("a19398"), 3, true)
    draw_colored_polygon(PackedVector2Array([Vector2(-14, -27), Vector2(14, -27), Vector2(19, 3), Vector2(-19, 3)]), Color("29202e"))
    draw_line(Vector2(-14, -27), Vector2(14, -27), tint, 2.4, true)
    draw_line(Vector2(-19, 3), Vector2(19, 3), tint, 2.4, true)
    draw_circle(Vector2(0, -10), 8.0, tint)
    draw_arc(Vector2(0, -10), 25.0, 0.0, TAU, 34, Color(tint.r, tint.g, tint.b, 0.60), 2.4, true)
    for i in range(order):
        draw_circle(Vector2((float(i) - (float(order) - 1.0) * 0.5) * 11.0, 17), 3.0, tint)
    if flash > 0.0:
        draw_arc(Vector2(0, -10), 29.0 + (1.0 - flash / 0.6) * 75.0, 0.0, TAU, 40, Color(0.94, 0.74, 0.98, flash * 0.45), 3.0, true)
