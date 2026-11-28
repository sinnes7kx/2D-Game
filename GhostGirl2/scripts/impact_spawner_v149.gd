extends RefCounted
## Centralized cosmetic emitters. No gameplay damage/physics/save mutations.
const BURST: Script = preload("res://scripts/impact_burst_v149.gd")
const POOL: Script = preload("res://scripts/blood_pool_v149.gd")
const MAX_BURSTS: int = 26
const MAX_POOLS: int = 24

# Set the local position before _ready: seeded debris/puddles read their
# actual world location during initialization, not the parent's origin.
static func _attach_at(parent: Node, child: Node2D, where: Vector2) -> void:
    child.position = parent.to_local(where) if parent is Node2D else where
    parent.add_child(child)
    child.global_position = where

static func _trim(group: Array[Node], limit: int) -> void:
    var live: Array[Node] = []
    for node in group:
        if is_instance_valid(node) and not node.is_queued_for_deletion():
            live.append(node)
    var remove_count: int = maxi(0,live.size()-limit+1)
    for i in range(remove_count):
        live[i].queue_free()

static func burst(parent: Node, where: Vector2, kind: String = "stone", strength: float = 1.0, heading: Vector2 = Vector2.ZERO, seed: int = 0) -> void:
    if not is_instance_valid(parent) or not parent.is_inside_tree():
        return
    var scene: SceneTree = parent.get_tree()
    var existing: Array[Node] = scene.get_nodes_in_group("v149_impact_fx")
    _trim(existing,MAX_BURSTS)
    var fx: Node2D = BURST.new() as Node2D
    fx.set("effect_kind", kind)
    fx.set("intensity", strength)
    fx.set("direction", heading)
    fx.set("seed_value", seed)
    _attach_at(parent,fx,where)

static func pool(parent: Node, where: Vector2, seed: int = 0, scale_value: float = 1.0, tint: Color = Color("481d2b")) -> void:
    if not is_instance_valid(parent) or not parent.is_inside_tree():
        return
    var existing: Array[Node] = parent.get_tree().get_nodes_in_group("v149_blood_pools")
    _trim(existing,MAX_POOLS)
    var stain: Node2D = POOL.new() as Node2D
    stain.set("seed_value", seed)
    stain.set("size_factor", scale_value)
    stain.set("ink", tint)
    _attach_at(parent,stain,where+Vector2(0.0,6.0))

static func rumble(where: Vector2, strength: float = 6.0) -> void:
    # Spatial attenuation is calculated by the player, never by the caller.
    var tree: SceneTree = Engine.get_main_loop() as SceneTree
    if tree == null:
        return
    for character in tree.get_nodes_in_group("ghost_girl_player"):
        if is_instance_valid(character) and character.has_method("on_world_impact"):
            character.call("on_world_impact", where, strength)
