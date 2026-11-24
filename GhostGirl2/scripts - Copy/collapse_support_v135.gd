@tool
extends Node2D
## A deliberately readable environmental hazard. It can collapse by hook,
## charged jump-shot, rose magic, frost, a frost+hook combo or thrown crates.
## Source/perch and landing areas each receive a single damage event.
const FALL_FX: Script = preload("res://scripts/falling_debris_v135.gd")
const PHYSICAL_FEEL: Script = preload("res://scripts/impact_spawner_v149.gd")
const CREAK: AudioStream = preload("res://assets/audio/v135_beam_creak.wav")
@export var site_id: String = "v135_support"
@export var aftermath_path: NodePath
@export var display_name: String = "Withered support"
@export_enum("hook", "airborne_bow", "roses", "frost", "frost_then_hook") var activation: String = "hook"
@export_enum("timber", "masonry", "bell", "thorn", "ice") var material_kind: String = "timber"
@export var landing_offset: Vector2 = Vector2(170.0, 65.0)
@export var collapse_radius: float = 105.0
@export var perch_radius: float = 78.0
@export var perched_enemy_path: NodePath
@export var damage: float = 44.0
@export var bloom_radius: float = 74.0
@export var trigger_radius: float = 42.0
@export var activated: bool = false
var prepared: bool = false
var time: float = 0.0
var pulse: float = 0.0
var inventory: Node = null

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    _update_groups()

func _update_groups() -> void:
    if activation in ["hook", "frost_then_hook"]:
        add_to_group("hook_switch")
    if activation == "airborne_bow":
        add_to_group("moon_archery_targets")
    if activation == "roses":
        add_to_group("rose_bloom_relay")
    if activation in ["frost", "frost_then_hook"]:
        add_to_group("v135_frost_targets")

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    if inventory == null:
        return
    activated = inventory.call("has_collected", site_id)
    prepared = activated or inventory.call("has_collected", site_id + "_frozen")
    var hitbox: StaticBody2D = get_node_or_null("HookBody") as StaticBody2D
    if hitbox != null:
        hitbox.collision_layer = 0 if activated else 2
    if activated:
        _reveal_aftermath(true)
        for group_name in ["hook_switch", "moon_archery_targets", "rose_bloom_relay", "v135_frost_targets"]:
            remove_from_group(group_name)
        # Respawned decorative perched enemies must not stand on a support
        # that was permanently broken in a previous visit.
        if not perched_enemy_path.is_empty():
            var perched: Node = get_node_or_null(perched_enemy_path)
            if perched != null:
                perched.queue_free()
    queue_redraw()

func hook_prompt() -> String:
    if activated:
        return ""
    if activation == "frost_then_hook" and not prepared:
        return "Z  FREEZE THE CRACKED SUPPORT  ·  F  PULL IT DOWN"
    return "F  PULL DOWN THE " + display_name.to_upper()

func on_hook_latched() -> void:
    if activated or activation not in ["hook", "frost_then_hook"]:
        return
    if activation == "frost_then_hook" and not prepared:
        _say("THE SUPPORT IS TOO STRONG · FREEZE IT FIRST", Color("bad8f3"))
        return
    _collapse()

func on_bow_hit(charged: bool, airborne: bool) -> bool:
    if activated or activation != "airborne_bow" or not charged or not airborne:
        return false
    _collapse()
    return true

func on_grasping_roses() -> bool:
    if activated or activation != "roses":
        return false
    _collapse()
    return true

func on_moonfall() -> bool:
    if activated or activation not in ["frost", "frost_then_hook"]:
        return false
    if activation == "frost_then_hook":
        if not prepared:
            prepared = true
            _save(site_id + "_frozen")
            _say("ICE FRACTURES THE ROTTEN JOINT · HOOK IT NOW", Color("b8e2f1"))
            queue_redraw()
        return true
    _collapse()
    return true

func receive_damage(amount: float) -> void:
    # Fast thrown crates can topple most rotten supports, irrespective of the
    # suggested hook/bow/spell solution. Ice-bound arches still need frost.
    if activated or amount < 8.0:
        return
    if activation == "frost_then_hook" and not prepared:
        return
    _collapse()

func _save(key: String) -> void:
    if inventory == null:
        var game: Node = get_tree().current_scene
        if game != null:
            inventory = game.get_node_or_null("Inventory")
    if inventory != null:
        var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
        flags[key] = true
        inventory.call("save_game")

func _collapse() -> void:
    if activated or Engine.is_editor_hint():
        return
    activated = true
    PHYSICAL_FEEL.burst(get_parent(), global_position, "wood", 1.45, Vector2.DOWN, site_id.hash())
    PHYSICAL_FEEL.rumble(global_position, 4.4)
    _save(site_id)
    _reveal_aftermath(false)
    get_tree().call_group("v145_world_response", "report_world_change", global_position, "falling support")
    for group_name in ["hook_switch", "moon_archery_targets", "rose_bloom_relay", "v135_frost_targets"]:
        remove_from_group(group_name)
    var hitbox: StaticBody2D = get_node_or_null("HookBody") as StaticBody2D
    if hitbox != null:
        hitbox.set_deferred("collision_layer", 0)
    _drop_perched_enemies()
    var creak: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
    creak.stream = CREAK
    creak.volume_db = -10.0
    creak.max_distance = 850.0
    add_child(creak)
    creak.play()
    creak.finished.connect(creak.queue_free)
    var root: Node = get_tree().current_scene
    if root != null:
        var falling: Node2D = Node2D.new()
        falling.set_script(FALL_FX)
        falling.set("radius", collapse_radius)
        falling.set("damage", damage)
        falling.set("source_site_id", site_id)
        root.add_child(falling)
        falling.global_position = global_position + landing_offset
    _say(display_name.to_upper() + " FALLS · WATCH THE MARKED GROUND", Color("e9c0bd"))
    get_tree().call_group("v135_hazard_seal", "refresh")
    queue_redraw()

func _reveal_aftermath(restoring: bool) -> void:
    if aftermath_path.is_empty():
        return
    var outcome: Node = get_node_or_null(aftermath_path)
    if outcome != null and outcome.has_method("reveal_from_collapse"):
        outcome.call("reveal_from_collapse", restoring)

func _drop_perched_enemies() -> void:
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not candidate is Node2D or candidate.is_queued_for_deletion():
            continue
        var enemy: Node2D = candidate as Node2D
        if enemy.global_position.distance_squared_to(global_position) > perch_radius * perch_radius:
            continue
        # A creature perched on the beam falls into the landing zone.
        enemy.global_position += landing_offset * 0.55
        if enemy.has_method("hit"):
            enemy.call("hit", damage * 0.7, 1.45)

func _say(message: String, color: Color) -> void:
    var game: Node = get_tree().current_scene
    if game != null and game.has_node("HUD"):
        game.get_node("HUD").call("show_pickup", message, color)

func _process(delta: float) -> void:
    time += delta
    pulse = 0.5 + sin(time * 2.3) * 0.5
    queue_redraw()

func _draw() -> void:
    var wood: Color = Color("61505a")
    var highlight: Color = Color("c2a0a8") if activation != "frost" else Color("b1d6e8")
    draw_circle(Vector2(0, 18), 41.0, Color(0.04, 0.03, 0.055, 0.24))
    if activated:
        draw_line(Vector2(-36, 12), Vector2(29, 22), wood, 9.0, true)
        draw_line(Vector2(-12, 9), Vector2(39, 13), highlight.darkened(0.6), 4.0, true)
        draw_circle(Vector2(12, 7), 4.0, Color("dbb8b9"))
        return
    if material_kind == "bell":
        draw_line(Vector2(-26, -30), Vector2(27, -30), wood, 9.0, true)
        draw_line(Vector2(-27, -31), Vector2(-27, 20), wood, 7.0, true)
        draw_line(Vector2(27, -31), Vector2(27, 20), wood, 7.0, true)
        draw_circle(Vector2(0, -8), 13, Color("7c677c"))
    elif material_kind in ["masonry", "ice"]:
        draw_colored_polygon(PackedVector2Array([Vector2(-44, 15), Vector2(-36, -40), Vector2(35, -37), Vector2(45, 15)]), Color("514956") if material_kind == "masonry" else Color("8aabba"))
        for n in range(3):
            draw_line(Vector2(-24+n*20, -29), Vector2(-11+n*17, 11), highlight, 1.8, true)
    else:
        draw_line(Vector2(-43, -18), Vector2(43, -18), wood, 13.0, true)
        draw_line(Vector2(-35, -18), Vector2(-35, 23), wood.darkened(0.2), 8.0, true)
        draw_line(Vector2(35, -18), Vector2(35, 23), wood.darkened(0.2), 8.0, true)
        if material_kind == "thorn":
            for j in range(6):
                var p: Vector2 = Vector2(-35 + j*14, -20)
                draw_line(p, p + Vector2(6, -11), Color("9e6b8b"), 2.0, true)
    draw_circle(Vector2.ZERO, 18.0 + 2.5 * pulse, Color(highlight.r, highlight.g, highlight.b, 0.04 + pulse * 0.06))
    draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 30, Color(highlight.r, highlight.g, highlight.b, 0.30 + pulse * 0.34), 1.8, true)
    if prepared and activation == "frost_then_hook":
        draw_arc(Vector2.ZERO, 26.0, time, time + PI * 1.35, 27, Color("caebff"), 2.2, true)
