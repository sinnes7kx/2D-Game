@tool
extends Node2D
## v1.33: a post-Warden three-part wilderness hunt. Each echo has exactly one
## required gameplay interaction: hook, Moonfall, or airborne charged arrow.
## The choice is editor-authored. Every echo is saved via collected_pickups;
## no preexisting item seeds, affixes, saves or combat values are changed.
@export_enum("hook", "frost", "airborne_bow") var echo_kind: String = "hook"
@export var echo_id: String = "v133_echo_willow"
@export var echo_title: String = "BELLGLASS ECHO"
@export var vault_path: NodePath
@export_range(18.0, 60.0, 1.0) var trigger_radius: float = 35.0
@export_range(40.0, 160.0, 1.0) var bloom_radius: float = 70.0
var awakened: bool = false
var time_passed: float = 0.0
var flash_left: float = 0.0
var inventory: Node = null
const WARDEN_FLAG: String = "v132_moor_warden_defeated"

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    match echo_kind:
        "hook": add_to_group("hook_switch")
        "frost": add_to_group("v130_triune_relay")
        "airborne_bow": add_to_group("moon_archery_targets")
    add_to_group("v133_bellglass_echo")

func restore_from_inventory(save_data: Node) -> void:
    inventory = save_data
    awakened = inventory != null and inventory.has_collected(echo_id)
    _refresh_vault()
    queue_redraw()

func _warden_defeated() -> bool:
    return inventory != null and inventory.has_collected(WARDEN_FLAG)

func hook_prompt() -> String:
    if awakened:
        return ""
    if not _warden_defeated():
        return "F  THE ECHO SLEEPS UNTIL THE WARDEN FALLS"
    return "F  DRAW OUT THE BELLGLASS ECHO"

func on_hook_latched() -> void:
    if echo_kind == "hook":
        _try_awaken()

func on_moonfall() -> bool:
    return _try_awaken() if echo_kind == "frost" else false

func on_bow_hit(charged: bool, airborne: bool) -> bool:
    return _try_awaken() if echo_kind == "airborne_bow" and charged and airborne else false

func _try_awaken() -> bool:
    if Engine.is_editor_hint() or awakened:
        return false
    if inventory == null:
        var game: Node = get_tree().current_scene
        if game != null:
            inventory = game.get_node_or_null("Inventory")
    if not _warden_defeated():
        return false
    var records: Dictionary = inventory.get("collected_pickups") as Dictionary
    records[echo_id] = true
    inventory.call("save_game")
    awakened = true
    flash_left = 1.0
    _refresh_vault()
    var root: Node = get_tree().current_scene
    if root != null:
        if root.has_node("HUD"):
            root.get_node("HUD").call("show_pickup", "BELLGLASS ECHO AWAKENED  ·  " + echo_title, Color("d8cefa"))
        if root.has_method("refresh_vigil_hud"):
            root.call("refresh_vigil_hud")
    queue_redraw()
    return true

func _refresh_vault() -> void:
    var vault: Node = get_node_or_null(vault_path)
    if vault != null and vault.has_method("refresh_from_inventory"):
        vault.call("refresh_from_inventory", inventory)

func _process(delta: float) -> void:
    time_passed += delta
    flash_left = maxf(0.0, flash_left - delta)
    if Engine.is_editor_hint() or not awakened or flash_left > 0.0:
        queue_redraw()

func _draw() -> void:
    var unlocked: bool = _warden_defeated() or Engine.is_editor_hint()
    var ink: Color = Color("908394") if awakened else (Color("d3badf") if unlocked else Color("706677"))
    var alpha: float = 0.28 if awakened else (0.54 if unlocked else 0.22)
    var pulse: float = 0.5 + 0.5 * sin(time_passed * 2.0)
    var center: Vector2 = Vector2(0, -22)
    draw_circle(Vector2(0, 4), 30.0, Color(0.04, 0.025, 0.05, 0.35))
    draw_circle(center, 32.0 + pulse * 4.0, Color(ink.r, ink.g, ink.b, alpha * 0.13 + flash_left * 0.17))
    draw_arc(center, trigger_radius, time_passed * 0.25, time_passed * 0.25 + TAU * 0.83, 42, Color(ink.r, ink.g, ink.b, alpha * 0.8), 2.0, true)
    draw_colored_polygon(PackedVector2Array([Vector2(-14, -39), Vector2(-8, -57), Vector2(8, -57), Vector2(14, -39), Vector2(10, 6), Vector2(-10, 6)]), Color("3b3347"))
    draw_line(Vector2(-14, -39), Vector2(-8, -57), ink, 1.7, true)
    draw_line(Vector2(-8, -57), Vector2(8, -57), ink, 1.7, true)
    draw_line(Vector2(8, -57), Vector2(14, -39), ink, 1.7, true)
    draw_line(Vector2(0, -47), Vector2(0, -17), ink, 2.0, true)
    draw_arc(center, 11.0, 0.0, TAU, 28, ink, 1.8, true)
    var glyph: String = "" if awakened else echo_kind
    if glyph == "hook":
        draw_arc(center + Vector2(0, -3), 7.0, -PI * 0.1, PI * 1.2, 16, Color("e6d6f1"), 2.0, true)
    elif glyph == "frost":
        for n in range(3):
            var direction: Vector2 = Vector2.RIGHT.rotated(float(n) * PI / 3.0)
            draw_line(center - direction * 7.0, center + direction * 7.0, Color("c6e5ef"), 1.2, true)
    elif glyph == "airborne_bow":
        draw_arc(center, 8.0, -PI * 0.48, PI * 0.48, 16, Color("e6c6df"), 1.7, true)
        draw_line(center + Vector2(0, -8), center + Vector2(0, 8), ink, 1.4, true)
    if awakened:
        draw_circle(center, 4.0, Color("b8e6d2"))
