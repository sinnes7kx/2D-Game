@tool
extends Node2D
## v1.48: Replayable hook-and-movement route. The reward is a one-time chest.
## All three hook targets and the start altar are individually editor-positionable.
const RECORD_FILE: String = "user://ghost_girl_rose_run_bests_v148.json"
@export var route_id: String = "v148_garden_bridge_rose_run"
@export var time_limit: float = 60.0
@export var reward_chest: NodePath = NodePath("../TreasureChests/RoseRunCache")
var inventory: Node
var active: bool = false
var completed: bool = false
var progress: int = 0
var remaining: float = 0.0
var elapsed: float = 0.0
var best_ms: int = 0
var clock: float = 0.0
var flash: float = 0.0
var hud_timer: float = 0.0

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    add_to_group("interactable")
    add_to_group("v148_rose_run")
    remaining = time_limit

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    completed = inventory != null and inventory.call("has_collected", route_id)
    if completed:
        _reveal(true)
    var records: Dictionary = _read_records()
    best_ms = int(records.get(route_id, 0))
    queue_redraw()

func prompt_text() -> String:
    if active:
        return "E  RESTART ROSE RUN · %d / 3" % progress
    if best_ms > 0:
        return "E  RUN ROSE PATH · BEST %.1f s" % (float(best_ms) / 1000.0)
    return "E  START ROSE PATH · HOOK 1 → 2 → 3"

func interact() -> String:
    if inventory == null:
        return "ROSE PATH UNAVAILABLE"
    active = true
    progress = 0
    remaining = time_limit
    elapsed = 0.0
    hud_timer = 0.0
    flash = 0.7
    _refresh_hud()
    queue_redraw()
    return "ROSE PATH · HOOK THE THREE LANTERNS IN ORDER"

func ring(step: int) -> void:
    if Engine.is_editor_hint():
        return
    if not active:
        _message("THE LANTERNS SLEEP · FIND THE ROSE PATH ALTAR", Color("bba5bc"))
        return
    if step != progress + 1:
        # Incorrect order costs time but does not force a tedious full restart.
        remaining = maxf(0.0, remaining - 4.0)
        flash = 0.45
        _message("ROSE PATH · WRONG CHIME · -4 s", Color("e3afbd"))
        if remaining <= 0.0:
            _fail()
        return
    progress += 1
    flash = 0.7
    # The hook route is about movement and timing, not emptying your stamina bar.
    _restore_stamina(10.0)
    if progress >= 3:
        _complete()
    else:
        _message("ROSE PATH · %d / 3 · %.0f s LEFT" % [progress, remaining], Color("dbc9ef"))
        _refresh_hud()
    queue_redraw()

func _restore_stamina(amount: float) -> void:
    var game: Node = get_tree().current_scene
    if game == null:
        return
    var girl: Node = game.get_node_or_null("GhostGirl")
    if girl != null:
        var new_stamina: float = minf(100.0, float(girl.get("stamina")) + amount)
        girl.set("stamina", new_stamina)
        if game.has_node("HUD"):
            game.get_node("HUD").call("set_stamina", new_stamina, 100.0)

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    clock += delta
    flash = maxf(0.0, flash - delta)
    if active:
        var game: Node = get_tree().current_scene
        if game != null and game.has_node("HUD") and game.get_node("HUD").call("is_menu_open"):
            queue_redraw()
            return
        var girl: Node = game.get_node_or_null("GhostGirl") if game != null else null
        if girl != null and float(girl.get("health")) <= 0.0:
            _fail()
            return
        elapsed += delta
        remaining -= delta
        hud_timer -= delta
        if remaining <= 0.0:
            _fail()
        elif hud_timer <= 0.0:
            hud_timer = 0.12
            _refresh_hud()
    queue_redraw()

func _fail() -> void:
    active = false
    progress = 0
    remaining = 0.0
    _refresh_hud()
    _message("THE ROSE PATH FADES · E TO TRY AGAIN", Color("d7b1cb"))
    queue_redraw()

func _complete() -> void:
    active = false
    var elapsed_ms: int = maxi(1, roundi(elapsed * 1000.0))
    if best_ms <= 0 or elapsed_ms < best_ms:
        best_ms = elapsed_ms
        var records: Dictionary = _read_records()
        records[route_id] = best_ms
        var out: FileAccess = FileAccess.open(RECORD_FILE, FileAccess.WRITE)
        if out != null:
            out.store_string(JSON.stringify(records))
    if not completed:
        completed = true
        if inventory != null:
            var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
            flags[route_id] = true
            inventory.call("save_game")
        _reveal(false)
        _message("ROSE PATH COMPLETE · HIDDEN COFFER UNCOVERED · %.1f s" % elapsed, Color("f0d9b2"))
    else:
        _message("ROSE PATH COMPLETE · %.1f s · BEST %.1f s" % [elapsed, float(best_ms) / 1000.0], Color("e4d4c1"))
    _refresh_hud()
    queue_redraw()

func _reveal(restoring: bool) -> void:
    var coffer: Node = get_node_or_null(reward_chest)
    if coffer != null and coffer.has_method("reveal_from_collapse"):
        coffer.call("reveal_from_collapse", restoring)

func _read_records() -> Dictionary:
    if not FileAccess.file_exists(RECORD_FILE):
        return {}
    var file: FileAccess = FileAccess.open(RECORD_FILE, FileAccess.READ)
    if file == null:
        return {}
    var decoded: Variant = JSON.parse_string(file.get_as_text())
    return decoded as Dictionary if decoded is Dictionary else {}

func _refresh_hud() -> void:
    var game: Node = get_tree().current_scene
    if game != null and game.has_node("HUD"):
        game.get_node("HUD").call("set_rose_run_progress", active, progress, remaining)

func _message(message: String, tint: Color) -> void:
    var game: Node = get_tree().current_scene
    if game != null and game.has_node("HUD"):
        game.get_node("HUD").call("show_pickup", message, tint)

func _draw() -> void:
    var bloom: float = 0.6 + 0.2 * sin(clock * 2.1)
    draw_circle(Vector2(0, 7), 43.0, Color(0.05, 0.03, 0.06, 0.47))
    draw_arc(Vector2.ZERO, 37.0, 0.0, TAU, 40, Color("b38aab"), 2.3, true)
    draw_arc(Vector2.ZERO, 30.0, -PI * 0.65, PI * 0.65, 35, Color(0.92, 0.66, 0.86, bloom if active else 0.20), 2.2, true)
    draw_line(Vector2(-16, 12), Vector2(0, -20), Color("c9abc0"), 3.0, true)
    draw_line(Vector2(0, -20), Vector2(16, 12), Color("c9abc0"), 3.0, true)
    draw_circle(Vector2(0, -17), 7.0, Color("f0dce9") if active else Color("9d778f"))
    for i in range(3):
        draw_circle(Vector2((i - 1) * 21, 23), 4.6, Color("f2d7aa") if completed or progress >= i + 1 else Color("58465c"))
    if flash > 0.0:
        draw_arc(Vector2.ZERO, 47.0 + (1.0 - flash / 0.7) * 24.0, 0.0, TAU, 36, Color(0.95, 0.65, 0.91, flash * 0.5), 2.2, true)
