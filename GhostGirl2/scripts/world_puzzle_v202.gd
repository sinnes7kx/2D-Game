@tool
extends Node2D
## Original world puzzles with multiple authored solutions; no single-key gate.
## Root knot: fire, frost+hook, rose magic, repeated patient hook.
## Bell stone: luminous arrow, charged aerial shot, frost+hook, repeated hook.
@export_enum("root_knot", "bell_stone") var puzzle_kind: String = "root_knot"
@export var discovery_id: String = "v202_world_puzzle"
@export var reward_chest_path: NodePath
@export_range(25.0, 100.0, 1.0) var trigger_radius: float = 55.0
var inventory: Node = null
var resolved: bool = false
var iced: bool = false
var hook_tugs: int = 0
var phase: float = 0.0

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    _sync_groups()

func restore_from_inventory(value: Node) -> void:
    inventory = value
    resolved = inventory != null and inventory.has_collected(discovery_id)
    _sync_groups()
    queue_redraw()

func is_resolved() -> bool:
    return resolved

func _sync_groups() -> void:
    for group in ["interactable", "v202_world_puzzle", "hook_switch", "v135_frost_targets", "v139_elemental_world", "rose_bloom_relay", "moon_archery_targets"]:
        if resolved:
            remove_from_group(group)
        else:
            add_to_group(group)
    var chest: Node2D = get_node_or_null(reward_chest_path) as Node2D
    if chest != null:
        chest.visible = resolved
        if resolved and not bool(chest.get("opened")):
            chest.add_to_group("interactable")
        else:
            chest.remove_from_group("interactable")

func inspect_text() -> String:
    if resolved:
        return "THE ROOTS REMEMBER HOW YOU FOUND THE WAY" if puzzle_kind == "root_knot" else "THE BELL RINGS CLEARLY AGAIN"
    if iced:
        return "THE FROST HAS LOOSENED SOMETHING · TRY A DIFFERENT FORCE"
    return "AN OLD ROOT KNOT HIDES A RELIC · FIRE, ROSES, ICE, AND FORCE?" if puzzle_kind == "root_knot" else "THIS BELL HAS FORGOTTEN ITS NOTE · TRY LIGHT, MOTION, OR SOUND"

func hook_prompt() -> String:
    return "" if resolved else "F  TEST THE OLD ROOT" if puzzle_kind == "root_knot" else "F  PULL THE HOLLOW BELL"

func on_hook_latched() -> void:
    if resolved:
        return
    hook_tugs += 1
    if iced:
        _solve("frost_then_hook")
    elif hook_tugs >= (3 if puzzle_kind == "root_knot" else 2):
        _solve("patient_hook")
    else:
        _hint("THE OLD MATERIAL SHIFTS · KEEP EXPERIMENTING")

func on_moonfall() -> bool:
    if resolved:
        return false
    iced = true
    _hint("FROST RUNS THROUGH THE FRACTURES")
    queue_redraw()
    return true

func on_grasping_roses() -> bool:
    return _solve("rose_magic") if not resolved else false

func on_bow_hit(charged: bool, airborne: bool) -> bool:
    return _solve("aerial_bow") if not resolved and charged and airborne else false

func on_elemental_arrow_hit(element: int, _formation: int, charged: bool, airborne: bool) -> bool:
    if resolved:
        return false
    if puzzle_kind == "root_knot":
        if element == 1:
            return _solve("emberfire")
        if element == 2:
            return on_moonfall()
        if element == 3 and charged:
            return _solve("light")
    else:
        if element == 3:
            return _solve("luminous")
        if element == 2:
            return on_moonfall()
        if charged and airborne:
            return _solve("aerial_bow")
    return false

func _solve(method: String) -> bool:
    if resolved:
        return false
    if inventory == null:
        var root: Node = get_tree().current_scene
        inventory = root.get_node_or_null("Inventory") if root != null else null
    if inventory == null:
        return false
    var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
    flags[discovery_id] = true
    flags[discovery_id + "_" + method] = true
    if not bool(inventory.call("save_game")):
        flags.erase(discovery_id)
        flags.erase(discovery_id + "_" + method)
        _hint("DISCOVERY NOT SAVED · TRY AGAIN")
        return false
    resolved = true
    _sync_groups()
    _hint("HIDDEN RELIC REVEALED · THE WORLD REMEMBERS")
    queue_redraw()
    return true

func _hint(message: String) -> void:
    if not is_inside_tree():
        return
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", message, Color("d0bfdc"))

func _process(delta: float) -> void:
    phase += delta
    if Engine.is_editor_hint() or not resolved:
        queue_redraw()

func _draw() -> void:
    var glow: float = 0.7 + 0.2 * sin(phase * 1.6)
    if puzzle_kind == "root_knot":
        for side in [-1.0, 1.0]:
            draw_line(Vector2(side * 31, 17), Vector2(side * 8, -48), Color("4f4053"), 12.0, true)
            draw_line(Vector2(side * 8, -48), Vector2(-side * 21, -20), Color("7c6877"), 7.0, true)
        draw_circle(Vector2(0, -20), 13.0, Color("5d4d61"))
        draw_arc(Vector2(0, -20), 15.0, -PI, PI, 26, Color("c4a4bc"), 2.0, true)
    else:
        draw_line(Vector2(0, -65), Vector2(0, -38), Color("a58f9b"), 3.0, true)
        draw_circle(Vector2(0, -17), 26.0, Color("5a4c60"))
        draw_arc(Vector2(0, -19), 26.0, -PI, PI, 28, Color("bfadbc"), 3.0, true)
        draw_line(Vector2(-25, -8), Vector2(25, -8), Color("aa98a6"), 3.5, true)
        draw_circle(Vector2(0, 8), 7.0, Color("c8b1c8"))
    if resolved:
        draw_circle(Vector2(0, -21), 17.0, Color(0.75, 0.78, 1.0, 0.07 * glow))
    elif iced:
        draw_arc(Vector2(0, -20), 30.0, -PI * 0.7, PI * 0.7, 25, Color("b3d9fa"), 2.0, true)
