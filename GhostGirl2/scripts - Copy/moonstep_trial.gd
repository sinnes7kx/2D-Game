@tool
extends Node2D
## Requires an actual mid-air landing on the far moon seal, rather than a
## simple E-key interaction. Persistent reward uses existing collected IDs.
@export var discovery_id: String = "moonwake_moonstep_trial_v123"
@export var reward_data: GhostItemData
@export var reward_seed: int = 231234
@export_enum("normal", "magic", "rare", "set", "unique") var reward_quality: String = "set"
@export var trigger_radius: float = 45.0
var solved: bool = false
var age: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        var root: Node = get_tree().current_scene
        if root != null and root.has_node("Inventory"):
            solved = bool(root.get_node("Inventory").call("has_collected", discovery_id))

func _physics_process(_delta: float) -> void:
    if Engine.is_editor_hint() or solved:
        return
    var player: Node = get_tree().get_first_node_in_group("ghost_girl_player")
    if not (player is Node2D):
        return
    var remaining: float = float(player.get("jump_time_left"))
    var total: float = float(player.get("jump_duration"))
    if remaining <= 0.0 or total <= 0.0:
        return
    var fraction: float = 1.0 - remaining / total
    if fraction < 0.35 or fraction > 0.98:
        return
    if (player as Node2D).global_position.distance_to(global_position) > trigger_radius:
        return
    var root: Node = get_tree().current_scene
    if root == null or not root.has_node("Inventory"):
        return
    var inventory: Node = root.get_node("Inventory")
    var reward: GhostItemInstance = inventory.add_loot(reward_data, reward_seed, reward_quality) if reward_data != null else null
    if reward == null:
        if root.has_node("HUD"):
            root.get_node("HUD").call("show_pickup", "BACKPACK FULL · RETURN TO MOONSTEP")
        return
    var records: Dictionary = inventory.get("collected_pickups") as Dictionary
    records[discovery_id] = true
    inventory.save_game()
    solved = true
    if root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", "MOONSTEP COMPLETE · " + reward.display_name(), Color("eed4b3"))
    queue_redraw()

func _process(delta: float) -> void:
    age += delta
    queue_redraw()

func _draw() -> void:
    var c: Color = Color("cbb1e2") if not solved else Color("8d8c9c")
    var glow: float = (0.43 + 0.17 * sin(age * 2.8)) if not solved else 0.16
    draw_circle(Vector2.ZERO, trigger_radius + 12, Color(c.r, c.g, c.b, glow * 0.24))
    draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 50, Color(c.r, c.g, c.b, glow + 0.28), 3.3, true)
    draw_arc(Vector2.ZERO, trigger_radius * 0.61, age * 0.6, age * 0.6 + PI * 1.3, 30, Color("eee1fa"), 2.0, true)
    for i in range(6):
        var a: float = float(i) * TAU / 6.0
        draw_circle(Vector2.from_angle(a) * (trigger_radius * 0.8), 3.5, Color("e7c4ec"))
    if not solved:
        draw_line(Vector2(-19, 7), Vector2(0, -20), Color("efcef7"), 2.5, true)
        draw_line(Vector2(0, -20), Vector2(19, 7), Color("efcef7"), 2.5, true)
