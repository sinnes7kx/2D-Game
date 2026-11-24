extends Node
## v1.46.2 Hollow Veil Moor distance budget. Never changes world state, save data,
## hitboxes, enemy quantities or loot. Inactive enemies remain in the tree and
## can still be hit / receive world-change signals, but stop running AI and VFX
## when safely beyond the player's camera and combat range.
@export_range(800.0, 3000.0, 50.0) var enemy_wake_distance: float = 1500.0
@export_range(1000.0, 3800.0, 50.0) var enemy_sleep_distance: float = 1950.0
@export_range(750.0, 3000.0, 50.0) var decoration_wake_distance: float = 1400.0
@export_range(900.0, 3600.0, 50.0) var decoration_sleep_distance: float = 1750.0
@export_range(0.1, 0.6, 0.02) var refresh_seconds: float = 0.24

# Inspect these in the Godot Remote inspector to confirm culling is working.
var awake_enemies: int = 0
var sleeping_enemies: int = 0
var paused_decorations: int = 0

const VISUAL_SCRIPTS: Array[String] = [
    "res://scripts/moor_waystone.gd",
    "res://scripts/moor_lantern.gd",
    "res://scripts/moor_story_slab_v134.gd",
    "res://scripts/moor_water_ripples.gd",
]

var _room_root: Node = null
var _decorations: Array[Node2D] = []
var _elapsed: float = 0.0

func _ready() -> void:
    if Engine.is_editor_hint():
        set_process(false)
        return
    _room_root = get_parent()
    _find_decorations(_room_root)
    # Defer the initial pass until the room is attached and the player is ready.
    call_deferred("_refresh_activity")

func _find_decorations(parent: Node) -> void:
    for child in parent.get_children():
        if child is Node2D:
            var script_resource: Script = child.get_script() as Script
            if script_resource != null and script_resource.resource_path in VISUAL_SCRIPTS:
                _decorations.append(child as Node2D)
        _find_decorations(child)

func _process(delta: float) -> void:
    _elapsed += delta
    if _elapsed < refresh_seconds:
        return
    _elapsed = 0.0
    _refresh_activity()

func _refresh_activity() -> void:
    if _room_root == null or not is_instance_valid(_room_root):
        return
    var player: Node2D = get_tree().get_first_node_in_group("ghost_girl_player") as Node2D
    if player == null:
        return
    var player_point: Vector2 = player.global_position
    var wake_enemy_sq: float = enemy_wake_distance * enemy_wake_distance
    var sleep_enemy_sq: float = maxf(enemy_sleep_distance, enemy_wake_distance + 100.0) ** 2
    var wake_visual_sq: float = decoration_wake_distance * decoration_wake_distance
    var sleep_visual_sq: float = maxf(decoration_sleep_distance, decoration_wake_distance + 100.0) ** 2
    awake_enemies = 0
    sleeping_enemies = 0
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not (candidate is CharacterBody2D):
            continue
        if not _room_root.is_ancestor_of(candidate) or candidate.is_queued_for_deletion():
            continue
        var enemy: CharacterBody2D = candidate as CharacterBody2D
        var distance_sq: float = enemy.global_position.distance_squared_to(player_point)
        var awake: bool = enemy.is_physics_processing()
        # Hysteresis: stay awake inside the buffer, sleep beyond the outer
        # radius and only wake again at the inner radius. No rapid toggling.
        if awake and distance_sq > sleep_enemy_sq:
            enemy.velocity = Vector2.ZERO
            enemy.set_physics_process(false)
            enemy.set_process(false)
            awake = false
        elif not awake and distance_sq < wake_enemy_sq:
            enemy.set_physics_process(true)
            enemy.set_process(true)
            awake = true
        if awake:
            awake_enemies += 1
        else:
            sleeping_enemies += 1
    paused_decorations = 0
    for visual in _decorations:
        if not is_instance_valid(visual) or visual.is_queued_for_deletion():
            continue
        var dist_sq: float = visual.global_position.distance_squared_to(player_point)
        if visual.is_processing() and dist_sq > sleep_visual_sq:
            visual.set_process(false)
        elif not visual.is_processing() and dist_sq < wake_visual_sq:
            visual.set_process(true)
            visual.queue_redraw()
        if not visual.is_processing():
            paused_decorations += 1
