@tool
extends Node2D
## Three-stage fletcher range: one real arrow per attempt; no fake beams or
## additional hitboxes. A 300/300 clear reveals one fixed, save-safe rare bow.
const COMPLETED: String = "v202_fletcher_perfect"
@export var reward_chest_path: NodePath
@export var lane_radius: float = 500.0
var inventory: Node = null
var active: bool = false
var completed: bool = false
var stage: int = 0
var shots: int = 0
var score: int = 0
var hits: int = 0
var last_message: String = ""
var flash: float = 0.0

const STAGE_HINTS: Array[String] = [
    "I  DISTANCE · HIT THE NEAREST VANE",
    "II  CONTROL · LAND ONE FULLY DRAWN SHOT",
    "III  FLIGHT · LAND A FULLY DRAWN JUMP SHOT"
]

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    add_to_group("interactable")
    add_to_group("v202_archery_range")
    _refresh_reward()

func restore_from_inventory(value: Node) -> void:
    inventory = value
    completed = inventory != null and inventory.has_collected(COMPLETED)
    _refresh_reward()

func _refresh_reward() -> void:
    var chest: Node2D = get_node_or_null(reward_chest_path) as Node2D
    if chest == null:
        return
    chest.visible = completed
    if completed and not bool(chest.get("opened")):
        chest.add_to_group("interactable")
    else:
        chest.remove_from_group("interactable")

func prompt_text() -> String:
    if completed:
        return "E  FLETCHER RANGE · PERFECT SCORE RECORDED"
    if active:
        return "E  RESET RANGE  ·  STAGE %d/3  ·  %d/300" % [stage + 1, score]
    return "E  BEGIN THREE-STAGE FLETCHER RANGE"

func interact() -> void:
    var root: Node = get_tree().current_scene if is_inside_tree() else null
    if inventory == null and root != null:
        inventory = root.get_node_or_null("Inventory")
    var bow: GhostItemInstance = inventory.get_equipped("sword") if inventory != null else null
    if bow == null or bow.weapon_style() != "bow":
        _say("EQUIP A BOW TO ENTER THE FLETCHER'S TRIAL")
        return
    stage = 0
    shots = 0
    hits = 0
    score = 0
    active = not completed
    if completed:
        _say("PERFECT 300/300 · YOUR FLETCHER PRIZE IS UNLOCKED")
    else:
        _say("THREE VANES · THREE ARROWS · " + STAGE_HINTS[0])
    queue_redraw()

func on_player_arrow_launched(source: Vector2) -> void:
    if active and global_position.distance_squared_to(source) <= lane_radius * lane_radius:
        shots += 1

func on_target_hit(index: int, charged: bool, airborne: bool) -> bool:
    if not active or stage != index:
        return false
    if index == 1 and not charged:
        _say("STAGE II · DRAW THE STRING FULLY")
        return false
    if index == 2 and (not charged or not airborne):
        _say("STAGE III · JUMP, HOLD, THEN RELEASE")
        return false
    # A miss or wasted/early shot does not become a false perfect score.
    hits += 1
    if shots == hits:
        score += 100
    else:
        score += 60
    flash = 0.9
    stage += 1
    if stage < 3:
        _say("VANE %d/3 · SCORE %d/300 · %s" % [stage, score, STAGE_HINTS[stage]])
    else:
        active = false
        if score == 300 and shots == 3:
            if _award_perfect():
                _say("PERFECT 300/300 · FLETCHER'S MOONFLIGHT BOW UNLOCKED")
            else:
                _say("PERFECT CLEAR · COULD NOT SAVE REWARD; RETRY WHEN STORAGE IS READY")
        else:
            _say("SCORE %d/300 · E TO TRY AGAIN FOR A PERFECT CLEAR" % score)
    queue_redraw()
    return true

func _award_perfect() -> bool:
    if inventory == null:
        return false
    var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
    if flags.has(COMPLETED):
        completed = true
        _refresh_reward()
        return true
    flags[COMPLETED] = true
    if not bool(inventory.call("save_game")):
        flags.erase(COMPLETED)
        return false
    completed = true
    _refresh_reward()
    return true

func _say(message: String) -> void:
    last_message = message
    if not is_inside_tree():
        return
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", message, Color("e5d4af"))

func _process(delta: float) -> void:
    flash = maxf(0.0, flash - delta)
    if Engine.is_editor_hint() or flash > 0.0:
        queue_redraw()

func _draw() -> void:
    draw_line(Vector2(-28, 0), Vector2(-28, -68), Color("62505a"), 5.0, true)
    draw_line(Vector2(28, 0), Vector2(28, -68), Color("62505a"), 5.0, true)
    draw_rect(Rect2(-52, -78, 104, 40), Color("2d2531"), true)
    draw_rect(Rect2(-52, -78, 104, 40), Color("a58c9c"), false, 2.0)
    draw_line(Vector2(-34, -62), Vector2(34, -62), Color("d0b6a1"), 1.7, true)
    for i in range(3):
        var at: Vector2 = Vector2(-18 + i * 18, -53)
        draw_circle(at, 5.0, Color("81718a") if i >= stage else Color("d8c6e5"))
    if flash > 0.0:
        draw_arc(Vector2(0, -57), 52, -PI * 0.7, PI * 0.7, 26, Color(0.86, 0.76, 0.96, flash * 0.40), 2.0, true)
