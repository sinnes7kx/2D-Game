extends Node2D
## The Moonmoth: Ghost Girl's original, quiet traveling familiar.
## No hitboxes, autoplay chatter, player buffs, drops or item/save writes.
## An occasional brighter orbit hints that something nearby may be curious.
var time_alive: float = 0.0
var curiosity: float = 0.0
var target_hint: Vector2 = Vector2.ZERO
var check_time: float = 0.0
var actor: Node2D = null
var subdued: bool = false

func _ready() -> void:
    actor = get_parent() as Node2D
    z_index = 28
    position = Vector2(-47.0, -121.0)
    subdued = actor == null or bool(actor.get("equipment_preview_only"))
    visible = not subdued
    set_process(not subdued)

func _process(delta: float) -> void:
    if actor == null:
        return
    time_alive += delta
    var facing: String = str(actor.get("facing_name"))
    var side: float = 1.0 if facing == "left" else -1.0
    var normal: Vector2 = Vector2(side * 46.0, -116.0 + sin(time_alive * 1.7) * 8.0)
    check_time -= delta
    if check_time <= 0.0:
        check_time = 0.42
        _find_secret()
    var desired: Vector2 = normal + target_hint * curiosity
    position = position.lerp(desired, minf(1.0, delta * 4.4))
    queue_redraw()

func _find_secret() -> void:
    target_hint = Vector2.ZERO
    curiosity = move_toward(curiosity, 0.0, 0.14)
    if get_tree().current_scene == null:
        return
    for group in ["v201_cave_blocker", "v202_world_puzzle"]:
        for clue in get_tree().get_nodes_in_group(group):
            if not is_instance_valid(clue) or not clue is Node2D:
                continue
            var point: Vector2 = (clue as Node2D).global_position
            if actor.global_position.distance_squared_to(point) > 225.0 * 225.0:
                continue
            if clue.has_method("is_resolved") and clue.call("is_resolved"):
                continue
            if bool(clue.get("opened")):
                continue
            var delta: Vector2 = (point - actor.global_position).normalized()
            target_hint = delta * 23.0
            curiosity = minf(1.0, curiosity + 0.24)
            return

func _draw() -> void:
    var lift: float = sin(time_alive * 2.1) * 2.0
    var bright: float = 0.68 + 0.18 * sin(time_alive * 1.6) + curiosity * 0.14
    var aura: Color = Color("b6d1ef")
    var body: Vector2 = Vector2(0, lift)
    draw_circle(body, 13.0, Color(aura.r, aura.g, aura.b, 0.034 * bright))
    var wing: float = 0.66 + 0.25 * sin(time_alive * 8.0)
    for side in [-1.0, 1.0]:
        var outer: Vector2 = body + Vector2(side * (9.0 + 4.0 * wing), -8.0)
        var lower: Vector2 = body + Vector2(side * 8.0, 6.0)
        draw_colored_polygon(PackedVector2Array([body, outer, lower]), Color(0.83, 0.71, 0.89, 0.35 * bright))
        draw_line(body, outer, Color("c8b8e1"), 0.85, true)
    draw_circle(body, 3.4, Color("8aa5cd"))
    draw_circle(body + Vector2(0, -1), 1.65, Color(0.98, 0.95, 1.0, bright))
    for i in range(3):
        var t: float = time_alive * (0.8 + i * 0.12) + i * 2.1
        var mote: Vector2 = body + Vector2(sin(t) * (9.0 + i * 3.0), cos(t * 1.1) * (9.0 + i * 3.0))
        draw_circle(mote, 0.9, Color(0.79, 0.79, 1.0, 0.28 * bright))
