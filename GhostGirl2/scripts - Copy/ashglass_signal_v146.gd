@tool
extends Node2D
## Two optional Blackbrick Court mechanisms. Each has multiple environmental
## solutions, a persistent route opening and a persistent treasure reveal.
## These devices do not change combat damage or generate enemy loot.
@export_enum("ember", "frost") var signal_kind: String = "ember"
@export var signal_id: String = "v146_ashglass_signal"
@export var display_name: String = "Ashglass lantern"
@export_range(25.0, 70.0, 1.0) var trigger_radius: float = 44.0
@export var gate_path: NodePath
@export var chest_path: NodePath
var inventory: Node = null
var unlocked: bool = false
var frost_prepared: bool = false
var shimmer_left: float = 0.0
var time: float = 0.0
var hook_body: StaticBody2D = null
var hook_shape: CollisionShape2D = null

func _ready() -> void:
    _ensure_hook_target()
    if Engine.is_editor_hint():
        return
    add_to_group("hook_switch")
    add_to_group("v139_elemental_world")
    if signal_kind == "ember":
        add_to_group("v140_flammable")
    else:
        add_to_group("v135_frost_targets")
    _set_hook_active()

func _ensure_hook_target() -> void:
    hook_body = get_node_or_null("HookBody") as StaticBody2D
    if hook_body == null:
        hook_body = StaticBody2D.new()
        hook_body.name = "HookBody"
        add_child(hook_body)
    hook_body.collision_layer = 2
    hook_body.collision_mask = 0
    hook_shape = hook_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if hook_shape == null:
        hook_shape = CollisionShape2D.new()
        hook_shape.name = "CollisionShape2D"
        hook_body.add_child(hook_shape)
    var circle: CircleShape2D = CircleShape2D.new()
    circle.radius = 19.0
    hook_shape.shape = circle

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    unlocked = inventory != null and inventory.has_collected(signal_id)
    frost_prepared = unlocked or (inventory != null and inventory.has_collected(signal_id + "_chilled"))
    if unlocked:
        remove_from_group("hook_switch")
        remove_from_group("v140_flammable")
        remove_from_group("v135_frost_targets")
    _set_hook_active()
    _refresh_links()
    queue_redraw()

func _set_hook_active() -> void:
    if hook_body == null or hook_shape == null or Engine.is_editor_hint():
        return
    hook_body.set_deferred("collision_layer", 0 if unlocked else 2)
    hook_shape.set_deferred("disabled", unlocked)

func hook_prompt() -> String:
    if unlocked:
        return ""
    if signal_kind == "frost" and not frost_prepared:
        return "Z  CHILL THE GLASS · F  PULL THE MECHANISM"
    return "F  PULL " + display_name.to_upper()

func on_hook_latched() -> void:
    if unlocked:
        return
    if signal_kind == "frost" and not frost_prepared:
        _show("THE ASHGLASS NEEDS FROST FIRST", Color("bcd9e8"))
        return
    _unlock("rose-hook")

func ignite_from_environment() -> void:
    if signal_kind == "ember" and not unlocked:
        _unlock("spreading fire")

func on_elemental_arrow_hit(element: int, _formation: int, _charged: bool, _airborne: bool) -> bool:
    if unlocked:
        return false
    if signal_kind == "ember" and element == 1:
        _unlock("ember arrow")
        return true
    if signal_kind == "frost" and element == 2:
        _unlock("frost arrow")
        return true
    return false

func on_moonfall() -> bool:
    if unlocked or signal_kind != "frost":
        return false
    frost_prepared = true
    _save(signal_id + "_chilled")
    shimmer_left = 1.0
    _show("ASHGLASS CHILLED · PULL WITH THE ROSE-HOOK", Color("bdddec"))
    queue_redraw()
    return true

func _unlock(method: String) -> void:
    if unlocked or Engine.is_editor_hint():
        return
    unlocked = true
    shimmer_left = 2.1
    _save(signal_id)
    remove_from_group("hook_switch")
    remove_from_group("v140_flammable")
    remove_from_group("v135_frost_targets")
    _set_hook_active()
    _refresh_links()
    get_tree().call_group("v145_world_response", "report_world_change", global_position, "ashglass opened")
    _show(display_name.to_upper() + " RELEASED · " + method.to_upper(), Color("e6c9d6"))
    queue_redraw()

func _refresh_links() -> void:
    var gate: Node = get_node_or_null(gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", unlocked)
    var chest: Node2D = get_node_or_null(chest_path) as Node2D
    if chest == null:
        return
    chest.visible = unlocked
    if unlocked and not bool(chest.get("opened")):
        chest.add_to_group("interactable")
    else:
        chest.remove_from_group("interactable")

func _save(key: String) -> void:
    if inventory == null:
        var root: Node = get_tree().current_scene
        inventory = root.get_node_or_null("Inventory") if root != null else null
    if inventory != null:
        var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
        flags[key] = true
        inventory.call("save_game")

func _show(message: String, color: Color) -> void:
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", message, color)

func _process(delta: float) -> void:
    time += delta
    shimmer_left = maxf(0.0, shimmer_left - delta)
    if Engine.is_editor_hint() or shimmer_left > 0.0:
        queue_redraw()

func _draw() -> void:
    # Compact vertical antique signal. No large ring hovering over the scene.
    var ink: Color = Color("706173")
    var glow: Color = Color("e4aaa0") if signal_kind == "ember" else Color("a8d6e9")
    draw_line(Vector2(0, -41), Vector2(0, -25), ink, 3.0, true)
    draw_line(Vector2(-12, -24), Vector2(12, -24), ink, 3.0, true)
    draw_line(Vector2(-12, -24), Vector2(-9, 8), ink, 2.0, true)
    draw_line(Vector2(12, -24), Vector2(9, 8), ink, 2.0, true)
    draw_line(Vector2(-9, 8), Vector2(9, 8), ink, 2.0, true)
    var intensity: float = 0.12 + shimmer_left * 0.08 + (0.12 if unlocked else 0.0)
    draw_line(Vector2(0, -20), Vector2(0, 1), Color(glow.r, glow.g, glow.b, intensity), 5.0, true)
    draw_line(Vector2(0, -20), Vector2(0, 1), Color(glow.r, glow.g, glow.b, intensity * 1.7), 1.7, true)
    if Engine.is_editor_hint():
        draw_line(Vector2(-trigger_radius, 12), Vector2(trigger_radius, 12), Color(glow.r, glow.g, glow.b, 0.22), 1.0, true)
