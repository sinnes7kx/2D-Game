@tool
extends Node2D
## Art-directed, placed bow rune. The *physical* arrow must pass nearby.
## The charged / airborne requirement is optional per target.
@export_enum("Fire", "Ice", "Light", "Triple") var required_arrow: String = "Fire"
@export var discovery_id: String = "v138_arrow_fire"
@export_range(20.0, 65.0, 1.0) var trigger_radius: float = 36.0
@export var require_charged: bool = false
@export var require_airborne: bool = false
var inventory: Node = null
var activated: bool = false
var age: float = 0.0
var flash_left: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v138_arrow_targets")

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    activated = inventory != null and inventory.has_collected(discovery_id)
    queue_redraw()

func on_elemental_arrow_hit(element_index: int, formation_index: int, charged: bool, airborne: bool) -> bool:
    if Engine.is_editor_hint() or activated or (require_charged and not charged) or (require_airborne and not airborne):
        return false
    var matches: bool = false
    match required_arrow:
        "Fire": matches = element_index == 1
        "Ice": matches = element_index == 2
        "Light": matches = element_index == 3
        "Triple": matches = formation_index == 1
    if not matches:
        return false
    if inventory == null:
        var root: Node = get_tree().current_scene
        if root != null:
            inventory = root.get_node_or_null("Inventory")
    if inventory == null:
        return false
    activated = true
    var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
    flags[discovery_id] = true
    inventory.call("save_game")
    flash_left = 1.0
    for vault in get_tree().get_nodes_in_group("v138_bow_vaults"):
        if is_instance_valid(vault) and vault.has_method("refresh"):
            vault.call("refresh")
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", "%s SIGIL ANSWERS YOUR ARROW" % required_arrow.to_upper(), Color("f1dbab"))
    queue_redraw()
    return true

func _ink() -> Color:
    match required_arrow:
        "Fire": return Color("f5aa78")
        "Ice": return Color("9ce4f5")
        "Light": return Color("fff0b3")
        "Triple": return Color("d7b0f1")
    return Color("d7b0f1")

func _process(delta: float) -> void:
    age += delta
    flash_left = maxf(0.0, flash_left - delta)
    queue_redraw()

func _draw() -> void:
    var c: Color = _ink()
    var shimmer: float = 0.5 + 0.5 * sin(age * 1.8)
    var alpha: float = 0.22 if activated else 0.46 + shimmer * 0.26
    draw_circle(Vector2.ZERO, trigger_radius + 9.0, Color(c.r, c.g, c.b, alpha * 0.13))
    draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 42, Color(c.r, c.g, c.b, alpha), 2.3, true)
    for i in range(3 if required_arrow == "Triple" else 4):
        var angle: float = age * 0.38 + float(i) * TAU / float(3 if required_arrow == "Triple" else 4)
        var pos: Vector2 = Vector2.from_angle(angle) * trigger_radius * 0.73
        draw_circle(pos, 3.5, Color(c.r, c.g, c.b, alpha))
    if activated:
        draw_circle(Vector2.ZERO, 6.0, Color(c.r, c.g, c.b, 0.9))
    if flash_left > 0.0:
        var t: float = 1.0 - flash_left
        draw_arc(Vector2.ZERO, 48.0 + t * 62.0, 0.0, TAU, 46, Color(c.r, c.g, c.b, flash_left * 0.7), 3.0, true)
