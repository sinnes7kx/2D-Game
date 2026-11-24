@tool
extends Node2D
## Hookable, ordered rose-bell. Painted numeral / glow are discoverable in-world.
const CHIME: AudioStream = preload("res://assets/audio/hook_chime.wav")
@export_range(1, 3, 1) var sequence_number: int = 1
var clock: float = 0.0
var ring_flash: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("hook_switch")

func hook_prompt() -> String:
    return "F  TOLL ROSE CHIME " + str(sequence_number)

func on_hook_latched() -> void:
    ring_flash = 0.55
    var chime: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
    chime.stream = CHIME
    chime.pitch_scale = 0.85 + float(sequence_number) * 0.16
    chime.volume_db = -9.0
    add_child(chime)
    chime.play()
    chime.finished.connect(chime.queue_free)
    var relay: Node = get_parent().get_parent()
    if relay != null and relay.has_method("ring"):
        relay.call("ring", sequence_number)

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    clock += delta
    ring_flash = maxf(0.0, ring_flash - delta)
    queue_redraw()

func _draw() -> void:
    var relay: Node = get_parent().get_parent() if get_parent() != null and get_parent().get_parent() != null else null
    var lit: bool = relay != null and (bool(relay.get("completed")) or int(relay.get("progress")) >= sequence_number)
    var tint: Color = Color("e1b4dd") if lit else Color("886a88")
    draw_circle(Vector2(0, -15), 32.0, Color(0.62,0.40,0.64,0.10 if not lit else 0.20))
    draw_line(Vector2(0, -43), Vector2(0, -31), tint, 3, true)
    draw_arc(Vector2(0,-10), 23.0, 0.0, TAU, 32, tint, 2.8, true)
    draw_line(Vector2(-15,-17), Vector2(0,-30), tint, 3.0, true)
    draw_line(Vector2(0,-30), Vector2(15,-17), tint, 3.0, true)
    draw_circle(Vector2.ZERO, 8.0, tint)
    for i in range(sequence_number):
        draw_circle(Vector2((float(i) - float(sequence_number - 1) * 0.5) * 12, 32), 3.0, Color("f5daeb") if lit else Color("cba6bc"))
    if ring_flash > 0.0:
        var expansion: float = 34.0 + (1.0 - ring_flash / 0.55) * 65.0
        draw_arc(Vector2(0,-10), expansion, 0.0, TAU, 38, Color(0.93,0.72,0.92,ring_flash * 0.65), 2.0, true)
    if lit:
        draw_arc(Vector2(0,-8), 35.0, clock * 0.3, clock * 0.3 + PI, 30, Color(0.94,0.78,0.98,0.30), 1.7, true)
