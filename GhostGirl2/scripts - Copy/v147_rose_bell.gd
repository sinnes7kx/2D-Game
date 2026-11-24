@tool
extends Node2D
## One hook pull staggers nearby trial enemies; cooldown prevents spam.
## This remains optional and never gates room exits or quest completion.
const CHIME: AudioStream = preload("res://assets/audio/hook_chime.wav")
@export var interaction_name: String = "Ring the rose bell"
@export var pulse_radius: float = 270.0
@export var damage: float = 16.0
@export var cooldown_seconds: float = 8.0
var cooldown: float = 0.0
var bloom: float = 0.0
var clock: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("hook_switch")

func hook_prompt() -> String:
    if cooldown > 0.0:
        return ""
    return "F  RING ROSE BELL · STAGGER NEARBY FOES"

func on_hook_latched() -> void:
    if Engine.is_editor_hint() or cooldown > 0.0:
        return
    cooldown = cooldown_seconds
    bloom = 0.6
    remove_from_group("hook_switch")
    var chime: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
    chime.stream = CHIME
    chime.pitch_scale = 0.78
    chime.volume_db = -8.0
    chime.max_distance = 1000.0
    add_child(chime)
    chime.play()
    chime.finished.connect(chime.queue_free)
    var affected: int = 0
    var interrupted: int = 0
    for target in get_tree().get_nodes_in_group("v147_trial_enemy"):
        if not is_instance_valid(target) or not target is Node2D or target.is_queued_for_deletion():
            continue
        if global_position.distance_squared_to(target.global_position) > pulse_radius * pulse_radius:
            continue
        if target.has_method("hit"):
            # Hunter WARN/LUNGE and Wraith windups are real telegraphed attacks.
            var is_wraith: bool = target.has_method("_spawn_death_burst")
            var is_hunter: bool = target.has_method("_start_warning")
            var was_windup: bool = is_wraith and float(target.get("windup_left")) > 0.0
            var was_hunter_attack: bool = is_hunter and int(target.get("state")) in [2, 5]
            if was_windup or was_hunter_attack:
                interrupted += 1
            target.call("hit", damage, 1.7)
            affected += 1
    var game: Node = get_tree().current_scene
    if interrupted > 0 and game != null and game.has_node("GhostGirl"):
        var girl: Node = game.get_node("GhostGirl")
        girl.set("stamina", minf(100.0, float(girl.get("stamina")) + 9.0))
        game.get_node("HUD").call("set_stamina", girl.get("stamina"), 100.0)
    if game != null and game.has_node("HUD"):
        var feedback: String = "ROSE BELL · TIMED INTERRUPT · +9 STAMINA" if interrupted > 0 else ("ROSE BELL · %d ECHOES STAGGERED" % affected if affected > 0 else "ROSE BELL · A HOLLOW RING")
        game.get_node("HUD").call("show_pickup", feedback, Color("e3b7e1"))
    queue_redraw()

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    clock += delta
    if cooldown > 0.0:
        cooldown = maxf(0.0, cooldown - delta)
        if cooldown <= 0.0:
            add_to_group("hook_switch")
    bloom = maxf(0.0, bloom - delta)
    queue_redraw()

func _draw() -> void:
    draw_line(Vector2(0, -48), Vector2(0, -22), Color("8b7487"), 3.0, true)
    draw_arc(Vector2(0, -14), 25.0, 0.22, PI - 0.22, 22, Color("c28aa7"), 4.0, true)
    var shade: Color = Color("a77796") if cooldown <= 0.0 else Color("675666")
    draw_colored_polygon(PackedVector2Array([Vector2(-21,-17), Vector2(-18,7), Vector2(18,7), Vector2(21,-17)]), shade)
    draw_line(Vector2(-20, -16), Vector2(20, -16), Color("eed5dc"), 2.0, true)
    draw_circle(Vector2(0, 9), 4.0, Color("d8a5bc"))
    var glow: float = 0.4 + 0.2 * sin(clock * 2.1)
    draw_arc(Vector2(0,-5), 32.0, 0, TAU, 30, Color(0.94,0.62,0.83,glow if cooldown <= 0.0 else 0.12), 1.7, true)
    if bloom > 0.0:
        var t: float = 1.0 - bloom / 0.6
        for i in range(3):
            var radius: float = lerpf(25.0, pulse_radius * (0.75 + i * 0.12), t)
            draw_arc(Vector2.ZERO, radius, 0, TAU, 68, Color(0.96,0.68,0.87,0.34 * bloom / 0.6), 2.4, true)
