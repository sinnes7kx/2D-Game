@tool
extends Node2D
## A post-Warden hold-the-circle ritual. Fighting, movement and dodging
## still use existing player systems. Enemy waves exist only during this visit;
## the one-time success flag and reward gate are the only saved changes.
const COMPLETE_ID: String = "v134_vesper_vigil_completed"
const WARDEN_FLAG: String = "v132_moor_warden_defeated"
const CREATURE: PackedScene = preload("res://scenes/moor_creature_v129.tscn")
const REQUIRED_TIME: float = 18.0
const HOLD_RADIUS: float = 190.0
@export var gate_path: NodePath
@export var wave_container_path: NodePath
@export var interaction_name: String = "Keep the Vesper Vigil"
var inventory: Node = null
var active: bool = false
var completed: bool = false
var progress: float = 0.0
var wave_count: int = 0
var elapsed: float = 0.0
var spawned: Array[Node] = []

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("interactable")
        add_to_group("v134_vesper_vigil")

func restore_from_inventory(save_data: Node) -> void:
    inventory = save_data
    completed = inventory != null and inventory.has_collected(COMPLETE_ID)
    active = false
    progress = 0.0
    wave_count = 0
    _clear_waves()
    _update_gate()
    queue_redraw()

func try_begin() -> String:
    if completed:
        return "THE VESPER VIGIL IS COMPLETE · CLAIM THE RELIC"
    if inventory == null:
        return "THE VIGIL CANNOT HEAR YOU"
    if not inventory.has_collected(WARDEN_FLAG):
        return "THE VIGIL WAITS UNTIL THE MOOR WARDEN FALLS"
    if active:
        return "HOLD THE MOON CIRCLE · %d / 18 SECONDS" % int(progress)
    active = true
    progress = 0.0
    wave_count = 0
    _clear_waves()
    queue_redraw()
    return "VESPER VIGIL · REMAIN INSIDE THE RING AND SURVIVE"

func _process(delta: float) -> void:
    elapsed += delta
    if Engine.is_editor_hint():
        queue_redraw()
        return
    if not active or completed:
        return
    var root: Node = get_tree().current_scene
    if root == null:
        return
    var hud: Node = root.get_node_or_null("HUD")
    if hud != null and hud.has_method("is_menu_open") and bool(hud.call("is_menu_open")):
        return
    var girl: Node2D = get_tree().get_first_node_in_group("ghost_girl_player") as Node2D
    if girl == null:
        return
    if girl.global_position.distance_to(global_position) <= HOLD_RADIUS:
        progress = minf(REQUIRED_TIME, progress + delta)
    else:
        progress = maxf(0.0, progress - delta * 1.3)
    var thresholds: Array[float] = [1.0, 7.0, 13.0]
    if wave_count < thresholds.size() and progress >= thresholds[wave_count]:
        _spawn_wave(wave_count)
        wave_count += 1
    if progress >= REQUIRED_TIME:
        _complete()
    queue_redraw()

func _spawn_wave(index: int) -> void:
    var container: Node2D = get_node_or_null(wave_container_path) as Node2D
    if container == null:
        return
    for n in range(2):
        var moth: CharacterBody2D = CREATURE.instantiate() as CharacterBody2D
        if moth == null:
            continue
        var lantern: bool = index == 1 and n == 1
        moth.set("creature_kind", "gloom_lantern" if lantern else "hush_moth")
        moth.set("max_health", 17.0 if lantern else 11.0)
        moth.set("attack_damage", 3.0 if lantern else 2.0)
        moth.set("loot_template", null)
        moth.set("loot_seed", 134000 + index * 2 + n)
        # Position BEFORE add_child so the creature's _ready() saves the
        # correct roost rather than the room origin.
        var theta: float = float(index * 2 + n) * TAU / 6.0 + 0.4
        var world_point: Vector2 = global_position + Vector2.from_angle(theta) * 295.0
        moth.position = container.to_local(world_point)
        container.add_child(moth)
        moth.add_to_group("v134_vigil_summons")
        spawned.append(moth)

func _complete() -> void:
    active = false
    completed = true
    if inventory != null:
        var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
        flags[COMPLETE_ID] = true
        inventory.call("save_game")
    _clear_waves()
    _update_gate()
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", "VESPER VIGIL COMPLETE · VESPERGLASS WAND UNSEALED", Color("e6d2fa"))

func _clear_waves() -> void:
    for creature in spawned:
        if is_instance_valid(creature):
            creature.queue_free()
    spawned.clear()

func _update_gate() -> void:
    var gate: Node = get_node_or_null(gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", completed)

func _exit_tree() -> void:
    if not Engine.is_editor_hint():
        _clear_waves()

func _draw() -> void:
    var pulse: float = 0.5 + 0.5 * sin(elapsed * 2.1)
    var ink: Color = Color("bde3da") if completed else (Color("efc6dd") if active else Color("baaccd"))
    draw_circle(Vector2.ZERO, HOLD_RADIUS, Color(ink.r, ink.g, ink.b, 0.018 if not active else 0.05))
    draw_arc(Vector2.ZERO, HOLD_RADIUS, 0.0, TAU, 96, Color(ink.r, ink.g, ink.b, 0.3 + 0.15 * pulse), 2.4, true)
    draw_arc(Vector2.ZERO, HOLD_RADIUS - 14.0, -PI * 0.5, -PI * 0.5 + TAU * progress / REQUIRED_TIME, 96, Color("f6dcf4"), 4.0, true)
    for n in range(8):
        var angle: float = float(n) * TAU / 8.0
        var p: Vector2 = Vector2.from_angle(angle) * HOLD_RADIUS
        draw_circle(p, 7.0 + pulse * 2.0, Color(ink.r, ink.g, ink.b, 0.75))
    draw_circle(Vector2(0, -18), 22.0 + pulse * 3.0, Color(ink.r, ink.g, ink.b, 0.15))
    draw_colored_polygon(PackedVector2Array([Vector2(-18, 11), Vector2(-12, -41), Vector2(0, -60), Vector2(12, -41), Vector2(18, 11)]), Color("43364f"))
    draw_arc(Vector2(0, -25), 13.0, 0.0, TAU, 30, ink, 2.2, true)
    if active:
        var font: Font = ThemeDB.fallback_font
        draw_string(font, Vector2(-91, -72), "VESPER VIGIL  %d / 18" % int(progress), HORIZONTAL_ALIGNMENT_CENTER, 182.0, 16, Color("e9d9eb"))
