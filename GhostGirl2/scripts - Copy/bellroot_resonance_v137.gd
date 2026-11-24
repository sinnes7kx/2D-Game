@tool
extends Node2D
## Multi-solution environmental bell. Every different activation style is
## recorded separately, so no creative-method reward can be missed forever.
## All sprites, collisions and locations remain editable scene nodes.
const CHIME: AudioStream = preload("res://assets/audio/v137_bellroot_chime.wav")
const METHODS: Array[String] = ["hook", "roses", "frost", "bow", "debris"]
@export var bell_id: String = "v137_bell"
@export var bell_title: String = "Bellroot Chime"
@export_range(30.0, 130.0, 2.0) var trigger_radius: float = 75.0
@export_range(35.0, 180.0, 5.0) var bloom_radius: float = 95.0
@export_range(90.0, 320.0, 5.0) var shockwave_radius: float = 205.0
@export_range(0.0, 16.0, 0.5) var pulse_damage: float = 8.0
@export var resonance_color: Color = Color("d7b4e9")
var inventory: Node = null
var recorded_methods: Dictionary = {}
var first_chime: bool = false
var age: float = 0.0
var flash_time: float = 0.0
var cooldown: float = 0.0
var flash_color: Color = Color("d7b4e9")

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    add_to_group("hook_switch")
    add_to_group("rose_bloom_relay")
    add_to_group("v135_frost_targets")
    add_to_group("moon_archery_targets")
    add_to_group("v136_chain_receivers")

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    recorded_methods.clear()
    first_chime = false
    if inventory != null:
        first_chime = bool(inventory.call("has_collected", bell_id))
        for style in METHODS:
            if inventory.call("has_collected", _method_key(style)):
                recorded_methods[style] = true
    queue_redraw()

func _method_key(style: String) -> String:
    return bell_id + "_method_" + style

func hook_prompt() -> String:
    return "F  RING " + bell_title.to_upper() + " (OTHER MAGIC ALSO WORKS)"

func on_hook_latched() -> void:
    _ring("hook")

func on_grasping_roses() -> bool:
    return _ring("roses")

func on_moonfall() -> bool:
    return _ring("frost")

func on_bow_hit(charged: bool, airborne: bool) -> bool:
    if not charged or not airborne:
        return false
    return _ring("bow")

func on_falling_debris_impact(point: Vector2, impact_radius: float, source_id: String) -> void:
    if source_id == bell_id:
        return
    if global_position.distance_squared_to(point) <= pow(shockwave_radius * 0.35 + impact_radius, 2.0):
        _ring("debris")

func _ring(style: String) -> bool:
    if Engine.is_editor_hint() or not METHODS.has(style):
        return false
    if cooldown > 0.0 or recorded_methods.has(style):
        return false
    if inventory == null:
        var root: Node = get_tree().current_scene
        if root != null:
            inventory = root.get_node_or_null("Inventory")
    if inventory == null:
        return false
    recorded_methods[style] = true
    first_chime = true
    # No combat stats or drops change; persist discovery through the existing
    # collected-pickups map and save format.
    var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
    flags[bell_id] = true
    flags[_method_key(style)] = true
    inventory.call("save_game")
    cooldown = 0.92
    flash_time = 1.25
    flash_color = _style_color(style)
    _ring_sound()
    _pulse_once()
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", bell_title.to_upper() + " · " + style.to_upper() + " RESONATES", flash_color)
    get_tree().call_group("v137_chorus_vault", "refresh")
    queue_redraw()
    return true

func _style_color(style: String) -> Color:
    match style:
        "frost": return Color("a8dff7")
        "roses": return Color("ee9fbc")
        "bow": return Color("f3d7a0")
        "debris": return Color("bdc0e1")
        _: return resonance_color

func _ring_sound() -> void:
    var bell: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
    bell.stream = CHIME
    bell.volume_db = -14.0
    bell.max_distance = 950.0
    add_child(bell)
    bell.play()
    bell.finished.connect(bell.queue_free)

func _pulse_once() -> void:
    # Exactly one hit per enemy for this newly discovered interaction. Every
    # later visual ring is cosmetic, with no recurring collision/damage timer.
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not candidate is Node2D or candidate.is_queued_for_deletion():
            continue
        var enemy: Node2D = candidate as Node2D
        if enemy.global_position.distance_squared_to(global_position) > shockwave_radius * shockwave_radius:
            continue
        if enemy.has_method("hit"):
            enemy.call("hit", pulse_damage, 0.7)
        if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.has_method("on_hook_yank"):
            enemy.call("on_hook_yank", global_position, 70.0)
    # Bell shockwaves break nearby weak cover, a visible environmental payoff.
    for cover in get_tree().get_nodes_in_group("breakable_cover"):
        if not is_instance_valid(cover) or not cover is Node2D or cover.is_queued_for_deletion():
            continue
        if cover.global_position.distance_squared_to(global_position) < pow(shockwave_radius * 0.62, 2.0):
            cover.call("receive_damage", 12.0)

func _process(delta: float) -> void:
    age += delta
    cooldown = maxf(0.0, cooldown - delta)
    flash_time = maxf(0.0, flash_time - delta)
    queue_redraw()

func _draw() -> void:
    var body: Color = Color("665466")
    var lilac: Color = Color("c5a6c7")
    var shimmer: float = 0.5 + 0.5 * sin(age * 1.45)
    draw_circle(Vector2(0.0, 18.0), 38.0, Color(0.03, 0.02, 0.045, 0.31))
    draw_line(Vector2(-25, -55), Vector2(25, -55), body, 6.0, true)
    draw_line(Vector2(0, -55), Vector2(0, -38), lilac, 2.5, true)
    draw_colored_polygon(PackedVector2Array([Vector2(-21,-34),Vector2(-17,10),Vector2(-30,22),Vector2(30,22),Vector2(17,10),Vector2(21,-34)]), body)
    draw_arc(Vector2(0,-8), 21.0, PI, TAU, 32, lilac, 2.5, true)
    draw_circle(Vector2(0, 18), 6.0, Color("dbb4bf"))
    draw_line(Vector2(-22, 22), Vector2(22, 22), lilac, 3.0, true)
    var ring: Color = Color("d8c5ed") if first_chime else resonance_color
    draw_arc(Vector2(0,-8), 36.0, age * 0.24, age * 0.24 + PI * 1.55, 36, Color(ring.r, ring.g, ring.b, 0.16 + 0.22 * shimmer), 2.0, true)
    for i in range(METHODS.size()):
        var angle: float = -PI * 0.5 + float(i) * TAU / float(METHODS.size())
        var dot: Vector2 = Vector2(0,-8) + Vector2.from_angle(angle) * 44.0
        var style: String = METHODS[i]
        draw_circle(dot, 3.6, _style_color(style) if recorded_methods.has(style) else Color("554b5f"))
    if flash_time > 0.0:
        var p: float = 1.0 - flash_time / 1.25
        var opacity: float = clampf(1.0 - p, 0.0, 1.0)
        draw_circle(Vector2(0,-10), 37.0 + p * 140.0, Color(flash_color.r, flash_color.g, flash_color.b, 0.055 * opacity))
        draw_arc(Vector2(0,-10), 34.0 + p * shockwave_radius, 0.0, TAU, 80, Color(flash_color.r, flash_color.g, flash_color.b, 0.72 * opacity), 3.6, true)
        for i in range(12):
            var theta: float = float(i) * TAU / 12.0 + p * 1.8
            var mote: Vector2 = Vector2(0,-10) + Vector2.from_angle(theta) * (27.0 + p * 130.0)
            draw_circle(mote, 2.5 * opacity, Color(flash_color.r, flash_color.g, flash_color.b, 0.9 * opacity))
