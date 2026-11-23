@tool
extends "res://scripts/collapse_support_v135.gd"
## A chain-sensitive falling support. A nearby, genuinely landed piece of
## debris can release this support after a readable delay; cosmetic particles
## cannot. Existing support save flags and one-hit impacts are reused.
@export var chain_reach: float = 70.0
@export var chain_delay: float = 0.32
@export var chain_next_path: NodePath
@export var starting_support: bool = false
@export var chain_only: bool = false
@export var accepted_source_site: String = ""
var chain_pending: bool = false

func _ready() -> void:
    super._ready()
    if Engine.is_editor_hint():
        return
    add_to_group("v136_chain_receivers")

func on_falling_debris_impact(point: Vector2, impact_radius: float, source_id: String) -> void:
    if activated or chain_pending or starting_support or source_id == site_id or Engine.is_editor_hint():
        return
    if not accepted_source_site.is_empty() and source_id != accepted_source_site:
        return
    if global_position.distance_squared_to(point) > pow(impact_radius + chain_reach, 2.0):
        return
    chain_pending = true
    _say("THE FALL SHAKES " + display_name.to_upper(), Color("e1bdd5"))
    queue_redraw()
    get_tree().create_timer(maxf(0.12, chain_delay)).timeout.connect(_complete_chain)

func _complete_chain() -> void:
    if not is_inside_tree() or activated:
        return
    _collapse()

func hook_prompt() -> String:
    if chain_only and not activated:
        return "DROP DEBRIS ON THE LINKED SUPPORT"
    return super.hook_prompt()

func on_hook_latched() -> void:
    if chain_only:
        _say("THE LINK WAITS FOR FALLING STONE", Color("d6b4e4"))
        return
    super.on_hook_latched()

func receive_damage(amount: float) -> void:
    if chain_only:
        return
    super.receive_damage(amount)

func restore_from_inventory(saved_inventory: Node) -> void:
    super.restore_from_inventory(saved_inventory)
    chain_pending = false
    queue_redraw()

func _draw() -> void:
    super._draw()
    if activated:
        return
    var halo: Color = Color("f2d0b7") if chain_pending else Color("b8a9d4")
    var alpha: float = 0.48 if chain_pending else 0.19
    draw_arc(Vector2.ZERO, 47.0, pulse * TAU, pulse * TAU + PI * 1.24, 35, Color(halo.r, halo.g, halo.b, alpha), 2.0, true)
    if not chain_next_path.is_empty():
        var next: Node2D = get_node_or_null(chain_next_path) as Node2D
        if next != null and not bool(next.get("activated")):
            var relative: Vector2 = to_local(next.global_position)
            draw_dashed_line(Vector2.ZERO, relative, Color(0.76, 0.61, 0.84, 0.26), 3.0, 19.0)
