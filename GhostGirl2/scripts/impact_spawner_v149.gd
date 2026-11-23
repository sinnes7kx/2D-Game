extends RefCounted
## Centralized cosmetic emitters. No gameplay damage/physics/save mutations.
const BURST: Script = preload("res://scripts/impact_burst_v149.gd")
const POOL: Script = preload("res://scripts/blood_pool_v149.gd")
const MAX_BURSTS: int = 26
const MAX_POOLS: int = 24

static func burst(parent: Node, where: Vector2, kind: String = "stone", strength: float = 1.0, heading: Vector2 = Vector2.ZERO, seed: int = 0) -> void:
    if not is_instance_valid(parent) or not parent.is_inside_tree():
        return
    var scene: SceneTree = parent.get_tree()
    var existing: Array[Node] = scene.get_nodes_in_group("v149_impact_fx")
    if existing.size() >= MAX_BURSTS and is_instance_valid(existing[0]):
        existing[0].queue_free()
    var fx: Node2D = BURST.new() as Node2D
    fx.set("effect_kind", kind)
    fx.set("intensity", strength)
    fx.set("direction", heading)
    fx.set("seed_value", seed)
    parent.add_child(fx)
    fx.global_position = where

static func pool(parent: Node, where: Vector2, seed: int = 0, scale_value: float = 1.0, tint: Color = Color("481d2b")) -> void:
    if not is_instance_valid(parent) or not parent.is_inside_tree():
        return
    var existing: Array[Node] = parent.get_tree().get_nodes_in_group("v149_blood_pools")
    if existing.size() >= MAX_POOLS and is_instance_valid(existing[0]):
        existing[0].queue_free()
    var stain: Node2D = POOL.new() as Node2D
    stain.set("seed_value", seed)
    stain.set("size_factor", scale_value)
    stain.set("ink", tint)
    parent.add_child(stain)
    stain.global_position = where + Vector2(0.0, 6.0)

static func rumble(where: Vector2, strength: float = 6.0) -> void:
    # Spatial attenuation is calculated by the player, never by the caller.
    var tree: SceneTree = Engine.get_main_loop() as SceneTree
    if tree == null:
        return
    for character in tree.get_nodes_in_group("ghost_girl_player"):
        if is_instance_valid(character) and character.has_method("on_world_impact"):
            character.call("on_world_impact", where, strength)
