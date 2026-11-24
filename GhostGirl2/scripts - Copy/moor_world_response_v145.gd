@tool
extends Node2D
## v1.45: a localized, non-combat-only reaction to physical changes.
## Does not invent enemies or hits. Live creatures hear a collapse and may
## investigate the opened passage; nearby memorials react separately.
@export_range(180.0, 900.0, 10.0) var hearing_radius: float = 580.0
@export_range(0.4, 5.0, 0.1) var investigation_seconds: float = 3.0
var echo_points: Array[Vector2] = []
var echo_age: Array[float] = []

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v145_world_response")

func report_world_change(world_point: Vector2, source: String = "collapse") -> void:
    if Engine.is_editor_hint():
        return
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not (candidate is Node2D) or candidate.is_queued_for_deletion():
            continue
        var enemy: Node2D = candidate as Node2D
        if enemy.global_position.distance_squared_to(world_point) <= hearing_radius * hearing_radius:
            if enemy.has_method("on_world_disturbance"):
                enemy.call("on_world_disturbance", world_point, investigation_seconds)
    for listener in get_tree().get_nodes_in_group("v145_aftershock_memory"):
        if is_instance_valid(listener) and listener.has_method("on_world_change"):
            listener.call("on_world_change", world_point, source)
    # Three fine threads fade along the ground: no giant magic circles.
    echo_points.append(to_local(world_point))
    echo_age.append(0.0)
    while echo_points.size() > 6:
        echo_points.pop_front()
        echo_age.pop_front()
    queue_redraw()

func report_fire_ignition(world_point: Vector2, alert_radius: float = 175.0) -> void:
    if Engine.is_editor_hint():
        return
    var max_distance_sq: float = alert_radius * alert_radius
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not (candidate is Node2D) or candidate.is_queued_for_deletion():
            continue
        if candidate.global_position.distance_squared_to(world_point) <= max_distance_sq:
            if candidate.has_method("on_environment_threat"):
                candidate.call("on_environment_threat", world_point, 2.0)
    # Fire does not issue a second collapse/damage event, trigger memory
    # rewards, or draw the oversized concentric VFX from earlier builds.

func _process(delta: float) -> void:
    for index in range(echo_age.size() - 1, -1, -1):
        echo_age[index] += delta
        if echo_age[index] >= 0.95:
            echo_age.remove_at(index)
            echo_points.remove_at(index)
    if not echo_age.is_empty():
        queue_redraw()

func _draw() -> void:
    if Engine.is_editor_hint():
        return
    for index in range(echo_points.size()):
        var fade: float = 1.0 - echo_age[index] / 0.95
        var p: Vector2 = echo_points[index]
        for line_index in range(3):
            var a: float = float(line_index) * TAU / 3.0
            var length: float = 25.0 + (1.0 - fade) * 70.0
            var direction: Vector2 = Vector2.from_angle(a)
            draw_line(p + direction * 9.0, p + direction * length, Color(0.80, 0.65, 0.77, 0.16 * fade), 1.2, true)
