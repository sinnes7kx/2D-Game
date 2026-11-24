@tool
extends Node2D
const HITBOX_SCRIPT: Script = preload("res://scripts/moonroot_hitbox_v144.gd")
const PHYSICAL_FEEL: Script = preload("res://scripts/impact_spawner_v149.gd")
## Moonroot lattice: an editor-editable, persistent side-route obstruction.
## Different *existing* player actions may open it. A linked lattice can
## also respond to a neighboring collapse, making the world feel connected.
## The only damage is a single, capped impact when the physical gate falls.
@export var lattice_id: String = "v144_moonroot_lattice"
@export var display_name: String = "Moonroot lattice"
@export_enum("timber", "frost_joint") var lattice_kind: String = "timber"
@export_range(28.0, 120.0, 1.0) var trigger_radius: float = 103.0
@export_range(65.0, 185.0, 5.0) var bloom_radius: float = 75.0
@export_range(80.0, 240.0, 5.0) var barrier_width: float = 148.0
@export_range(18.0, 70.0, 2.0) var barrier_depth: float = 34.0
@export_range(120.0, 500.0, 10.0) var chain_radius: float = 225.0
@export var allow_chain_open: bool = true
@export_range(0.0, 22.0, 1.0) var impact_damage: float = 9.0
var inventory: Node = null
var opened: bool = false
var frost_ready: bool = false
var burning: bool = false
@export var fire_avoid_radius: float = 168.0
var burn_time: float = 0.0
var age: float = 0.0
var flash: float = 0.0
var blocker: StaticBody2D = null
var shape_node: CollisionShape2D = null

func _ready() -> void:
    _ensure_blocker()
    if Engine.is_editor_hint():
        return
    add_to_group("v144_moonroot_lattice")
    add_to_group("v139_elemental_world")
    add_to_group("v135_frost_targets")
    add_to_group("v140_flammable")
    if lattice_kind == "timber":
        add_to_group("rose_bloom_relay")
    add_to_group("hook_switch")
    _set_collision()

func _ensure_blocker() -> void:
    blocker = get_node_or_null("Barrier") as StaticBody2D
    if blocker == null:
        blocker = StaticBody2D.new()
        blocker.name = "Barrier"
        add_child(blocker)
    if blocker.get_script() != HITBOX_SCRIPT:
        blocker.set_script(HITBOX_SCRIPT)
    blocker.collision_layer = 2
    blocker.collision_mask = 0
    shape_node = blocker.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if shape_node == null:
        shape_node = CollisionShape2D.new()
        shape_node.name = "CollisionShape2D"
        blocker.add_child(shape_node)
    # Do not resize a shape shared with other instances.
    if shape_node.shape == null or not (shape_node.shape is RectangleShape2D):
        shape_node.shape = RectangleShape2D.new()
    var r: RectangleShape2D = shape_node.shape as RectangleShape2D
    r.size = Vector2(barrier_width, barrier_depth)

func _set_collision() -> void:
    if blocker == null:
        return
    if not Engine.is_editor_hint():
        blocker.set_deferred("collision_layer", 0 if opened else 2)
        if shape_node != null:
            shape_node.set_deferred("disabled", opened)

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    opened = inventory != null and inventory.has_collected(lattice_id)
    frost_ready = opened or (inventory != null and inventory.has_collected(lattice_id + "_frost"))
    burning = false
    remove_from_group("v146_live_fire")
    if opened:
        remove_from_group("hook_switch")
        remove_from_group("v140_flammable")
        remove_from_group("rose_bloom_relay")
    _set_collision()
    queue_redraw()

func hook_prompt() -> String:
    if opened:
        return ""
    if lattice_kind == "frost_joint" and not frost_ready:
        return "Z  FREEZE THE JOINT · F  PULL THE LATTICE"
    return "F  PULL THE " + display_name.to_upper()

func on_hook_latched() -> void:
    if opened:
        return
    if lattice_kind == "frost_joint" and not frost_ready:
        _show("FROST WILL WEAKEN THE IRON ROOTS", Color("b9d6ee"))
        return
    _open("rose-hook")

func on_elemental_arrow_hit(element: int, _formation: int, charged: bool, airborne: bool) -> bool:
    if opened:
        return false
    match element:
        1:
            if lattice_kind == "timber":
                ignite_from_environment()
                return true
        2:
            return on_moonfall()
        3:
            # Light can reveal nearby moonmarks, but isn't a skeleton key.
            _reveal_local_moonmarks()
            return true
    if lattice_kind == "timber" and charged and airborne:
        _open("charged jump-shot")
        return true
    return false

func on_bow_hit(charged: bool, airborne: bool) -> bool:
    if opened or lattice_kind != "timber" or not charged or not airborne:
        return false
    _open("charged jump-shot")
    return true

func on_grasping_roses() -> bool:
    if opened or lattice_kind != "timber":
        return false
    _open("grasping roses")
    return true

func on_moonfall() -> bool:
    if opened:
        return false
    if lattice_kind == "frost_joint":
        frost_ready = true
        _save(lattice_id + "_frost")
        flash = 1.0
        _show("IRON ROOTS BRITTLE · THE HOOK CAN PULL THEM", Color("c7e7f9"))
        queue_redraw()
        return true
    return false

func ignite_from_environment() -> void:
    if opened or burning or lattice_kind != "timber" or Engine.is_editor_hint():
        return
    burning = true
    burn_time = 0.0
    flash = 1.0
    add_to_group("v146_live_fire")
    get_tree().call_group("v145_world_response", "report_fire_ignition", global_position, fire_avoid_radius * 1.5)

func receive_damage(amount: float, _attacker: Vector2 = Vector2.ZERO) -> void:
    if opened or amount < 12.0 or lattice_kind != "timber":
        return
    _open("physical impact")

func on_neighbor_opened(world_point: Vector2) -> void:
    if opened or not allow_chain_open or lattice_kind != "timber":
        return
    if global_position.distance_squared_to(world_point) <= chain_radius * chain_radius:
        _open("chain collapse")

func _save(key: String) -> void:
    if inventory == null:
        var root: Node = get_tree().current_scene
        inventory = root.get_node_or_null("Inventory") if root != null else null
    if inventory != null:
        var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
        flags[key] = true
        inventory.call("save_game")

func _reveal_local_moonmarks() -> void:
    for mark in get_tree().get_nodes_in_group("v140_light_reveal"):
        if not is_instance_valid(mark) or not (mark is Node2D):
            continue
        if global_position.distance_squared_to(mark.global_position) <= 240.0 * 240.0 and mark.has_method("reveal_from_light"):
            mark.call("reveal_from_light", mark.global_position)

func _open(method: String) -> void:
    if opened or Engine.is_editor_hint():
        return
    opened = true
    burning = false
    PHYSICAL_FEEL.burst(get_parent(), global_position, "wood" if lattice_kind == "timber" else "stone", 1.28, Vector2.DOWN, lattice_id.hash())
    PHYSICAL_FEEL.rumble(global_position, 4.0)
    remove_from_group("v146_live_fire")
    flash = 1.0
    _save(lattice_id)
    get_tree().call_group("v145_world_response", "report_world_change", global_position, method)
    remove_from_group("hook_switch")
    remove_from_group("v140_flammable")
    remove_from_group("rose_bloom_relay")
    _set_collision()
    # One small impact only. Decorative falling pieces are not hitboxes.
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if is_instance_valid(enemy) and enemy is Node2D and enemy.global_position.distance_squared_to(global_position) < 68.0 * 68.0 and enemy.has_method("hit"):
            enemy.call("hit", impact_damage, 0.5)
    _show(display_name.to_upper() + " OPENS · " + method.to_upper(), Color("e8cfdd"))
    for other in get_tree().get_nodes_in_group("v144_moonroot_lattice"):
        if other != self and is_instance_valid(other) and other.has_method("on_neighbor_opened"):
            other.call("on_neighbor_opened", global_position)
    queue_redraw()

func _show(message: String, tint: Color) -> void:
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", message, tint)

func _process(delta: float) -> void:
    age += delta
    flash = maxf(0.0, flash - delta * 1.7)
    if burning and not opened:
        burn_time += delta
        if burn_time > 0.9:
            _open("spreading fire")
    queue_redraw()

func _draw() -> void:
    var wood: Color = Color("68515d")
    var silver: Color = Color("9b8497") if lattice_kind == "timber" else Color("96b7ca")
    if opened:
        for i in range(4):
            var x: float = -barrier_width * 0.44 + float(i) * barrier_width * 0.27
            draw_line(Vector2(x, barrier_depth * 0.32), Vector2(x + 18, barrier_depth * 0.54), Color("4d3d48"), 4.0, true)
        return
    # Thin wooden/iron root lattice: no giant circular warning rings.
    for i in range(4):
        var x: float = -barrier_width * 0.43 + float(i) * (barrier_width * 0.86 / 3.0)
        draw_line(Vector2(x - 9, -barrier_depth * 0.65), Vector2(x + 10, barrier_depth * 0.68), wood, 7.0, true)
    draw_line(Vector2(-barrier_width * 0.50, -barrier_depth * 0.32), Vector2(barrier_width * 0.50, -barrier_depth * 0.32), silver, 3.0, true)
    draw_line(Vector2(-barrier_width * 0.50, barrier_depth * 0.28), Vector2(barrier_width * 0.50, barrier_depth * 0.28), silver, 3.0, true)
    if frost_ready and lattice_kind == "frost_joint":
        for n in range(5):
            var t: float = float(n) / 5.0
            draw_line(Vector2(-barrier_width * 0.40 + t * barrier_width, -barrier_depth * 0.50), Vector2(-barrier_width * 0.25 + t * barrier_width, barrier_depth * 0.38), Color(0.71, 0.85, 0.91, 0.65), 1.2, true)
    if burning:
        for j in range(5):
            var x: float = float(j - 2) * 23.0
            draw_line(Vector2(x, -8), Vector2(x + sin(age * 3.0 + float(j)) * 4, -25), Color(0.95, 0.56, 0.35, 0.46), 2.0, true)
    if flash > 0.0:
        draw_line(Vector2(-barrier_width * 0.4, 0), Vector2(barrier_width * 0.4, 0), Color(0.89, 0.85, 0.95, flash * 0.3), 2.0, true)
