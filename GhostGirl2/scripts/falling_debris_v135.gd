extends Node2D
const IMPACT_SOUND: AudioStream = preload("res://assets/audio/v135_debris_impact.wav")
const PHYSICAL_FEEL: Script = preload("res://scripts/impact_spawner_v149.gd")
const COMBAT_JUICE: Script = preload("res://scripts/combat_juice_v194.gd")
## One telegraphed fall. One hit per victim; the remaining pile temporarily
## blocks projectiles and creates improvised cover. No repeating damage ticks.
var warning_seconds: float = 0.76
var pile_seconds: float = 11.0
var radius: float = 112.0
var damage: float = 48.0
var color: Color = Color("bca6b5")
var hit_player: bool = true
var source_site_id: String = ""
var age: float = 0.0
var struck: bool = false
var temporary_cover: StaticBody2D = null

func _ready() -> void:
    z_index = 13

func _process(delta: float) -> void:
    age += delta
    if not struck and age >= warning_seconds:
        struck = true
        _impact()
    if age >= warning_seconds + pile_seconds:
        queue_free()
        return
    queue_redraw()

func _impact() -> void:
    PHYSICAL_FEEL.burst(get_parent(), global_position, "stone", clampf(radius / 75.0, 1.0, 2.25), Vector2.DOWN, source_site_id.hash())
    PHYSICAL_FEEL.rumble(global_position, clampf(radius / 10.0, 6.0, 12.0))
    COMBAT_JUICE.play(get_tree().current_scene, global_position, "debris", -12.0)
    var crack: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
    crack.stream = IMPACT_SOUND
    crack.volume_db = -8.0
    crack.max_distance = 900.0
    add_child(crack)
    crack.play()
    crack.finished.connect(crack.queue_free)
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not candidate is Node2D or candidate.is_queued_for_deletion():
            continue
        var enemy: Node2D = candidate as Node2D
        if enemy.global_position.distance_squared_to(global_position) <= radius * radius:
            if enemy.has_method("hit"):
                enemy.call("hit", damage, 1.7)
            if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.has_method("on_hook_yank"):
                enemy.call("on_hook_yank", global_position, 100.0)
    var player: Node2D = get_tree().get_first_node_in_group("ghost_girl_player") as Node2D
    if hit_player and player != null and player.global_position.distance_squared_to(global_position) <= pow(radius * 0.78, 2.0):
        if float(player.get("jump_time_left")) <= 0.0 and player.has_method("receive_damage"):
            player.call("receive_damage", 5.0, global_position)
    # Propagate only from the actual impact event. Receivers apply a short
    # delay before collapsing, so the chain is visible and readable.
    get_tree().call_group("v136_chain_receivers", "on_falling_debris_impact", global_position, radius, source_site_id)
    # Small temporary obstruction; keep the wider landing circle navigable.
    temporary_cover = StaticBody2D.new()
    temporary_cover.collision_layer = 2
    temporary_cover.collision_mask = 0
    add_child(temporary_cover)
    var shape: CircleShape2D = CircleShape2D.new()
    shape.radius = minf(radius * 0.30, 39.0)
    var collision: CollisionShape2D = CollisionShape2D.new()
    collision.shape = shape
    temporary_cover.add_child(collision)

func _draw() -> void:
    if not struck:
        var fade: float = clampf(age / warning_seconds, 0.0, 1.0)
        draw_circle(Vector2.ZERO, radius, Color(0.75, 0.35, 0.46, 0.035 + 0.14 * fade))
        draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color(0.99, 0.62, 0.65, 0.25 + 0.60 * fade), 3.0, true)
        for i in range(12):
            var angle: float = float(i) * TAU / 12.0
            var p: Vector2 = Vector2.from_angle(angle) * radius * (1.0 - fade * 0.55)
            draw_circle(p, 3.1, Color(0.98, 0.82, 0.82, fade * 0.62))
    else:
        var fade: float = clampf(1.0 - (age - warning_seconds) / pile_seconds, 0.0, 1.0)
        draw_circle(Vector2.ZERO, radius * 0.38, Color(0.15, 0.13, 0.16, 0.22 * fade))
        for i in range(13):
            var a: float = float(i) * 2.39996
            var d: float = sqrt(float(i) / 13.0) * radius * 0.53
            var p: Vector2 = Vector2.from_angle(a) * d
            var points: PackedVector2Array = PackedVector2Array([p + Vector2(-12, 8), p + Vector2(-7, -11), p + Vector2(10, -8), p + Vector2(16, 7)])
            draw_colored_polygon(points, Color(0.26 + float(i % 3) * 0.035, 0.24, 0.28, 0.75 * fade))
            draw_line(p + Vector2(-7, -11), p + Vector2(10, -8), Color(color.r, color.g, color.b, fade * 0.42), 1.2, true)
        if age - warning_seconds < 0.48:
            var t: float = 1.0 - (age - warning_seconds) / 0.48
            draw_arc(Vector2.ZERO, radius * (1.0 - t * 0.28), 0.0, TAU, 52, Color(0.95, 0.82, 0.83, t * 0.72), 2.6, true)
