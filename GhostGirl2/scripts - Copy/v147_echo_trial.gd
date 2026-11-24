@tool
extends Node2D
## v1.47: optional three-wave combat lesson / replayable mastery challenge.
## Wave groups contain editor-movable Marker2D nodes named Wraith*, Mourner*,
## BladeHunter*, WarderElite*, Occultist*, or BellKeeper*.
## Nothing is locked, spawned permanently, or farmable after a first-clear reward.
const WRAITH: PackedScene = preload("res://scenes/rose_wraith.tscn")
const HUNTER: PackedScene = preload("res://scenes/gothic_hunter.tscn")
const RECORD_FILE: String = "user://ghost_girl_echo_trial_bests_v147.json"
const WAITING: int = 0
const COUNTDOWN: int = 1
const IN_BATTLE: int = 2
const BETWEEN: int = 3

@export var trial_id: String = "v147_trial_crypt"
@export var trial_title: String = "MOONWAKE ECHOES"
@export var first_clear_reward: GhostItemData
@export var reward_seed: int = 147010
@export_enum("normal", "magic", "rare") var reward_quality: String = "magic"
@export var wave_heal: float = 12.0
@export var wave_stamina: float = 30.0

var inventory: Node
var state: int = WAITING
var round_number: int = 0
var total_rounds: int = 0
var countdown: float = 0.0
var elapsed: float = 0.0
var damage_events: int = 0
var last_health: float = -1.0
var enemies: Array[Node2D] = []
var already_cleared: bool = false
var reward_claimed: bool = false
var pulse_clock: float = 0.0
var result_glow: float = 0.0
var best_time_ms: int = 0
var hud_clock: float = 0.0

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    add_to_group("interactable")
    add_to_group("v147_echo_trial")
    total_rounds = _wave_count()

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    if inventory == null:
        return
    already_cleared = inventory.call("has_collected", trial_id + "_cleared")
    reward_claimed = inventory.call("has_collected", trial_id + "_claimed")
    var saved: Dictionary = _load_records().get(trial_id, {}) as Dictionary
    best_time_ms = int(saved.get("time_ms", 0))
    queue_redraw()

func prompt_text() -> String:
    if state != WAITING:
        return "F  RING ROSE BELL  ·  DEFEAT THE ECHOES"
    if already_cleared and not reward_claimed:
        return "E  CLAIM TRIAL REWARD"
    if already_cleared:
        return "E  REPLAY %s · BEST %.1f s" % [trial_title, float(best_time_ms) / 1000.0] if best_time_ms > 0 else "E  REPLAY " + trial_title
    return "E  BEGIN " + trial_title

func interact() -> String:
    if state != WAITING:
        return "CLEAR THE ECHOES BEFORE STARTING AGAIN"
    if inventory == null:
        return "THE MEMORIAL CANNOT REMEMBER THIS TRIAL"
    if already_cleared and not reward_claimed:
        return _claim_reward()
    total_rounds = _wave_count()
    if total_rounds == 0:
        return "NO ECHOES WERE PLACED IN THE TRIAL"
    _start()
    return trial_title + " · " + str(total_rounds) + " ROUNDS  ·  F TO RING THE BELL"

func _wave_count() -> int:
    var waves: Node = get_node_or_null("SpawnWaves")
    if waves == null:
        return 0
    var result: int = 0
    for group in waves.get_children():
        if group.get_child_count() > 0:
            result += 1
    return result

func _start() -> void:
    round_number = 0
    elapsed = 0.0
    damage_events = 0
    enemies.clear()
    result_glow = 0.0
    last_health = _player_health()
    state = COUNTDOWN
    countdown = 1.0
    hud_clock = 0.0
    _update_hud()
    queue_redraw()

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    pulse_clock += delta
    result_glow = maxf(0.0, result_glow - delta)
    if state != WAITING:
        var ui: Node = _hud()
        if ui != null and ui.call("is_menu_open"):
            return
        if _player_health() <= 0.0:
            _abort_failed_trial()
            return
    if state != WAITING:
        hud_clock -= delta
        if hud_clock <= 0.0:
            hud_clock = 0.15
            _update_hud()
    if state == COUNTDOWN or state == BETWEEN:
        countdown -= delta
        if countdown <= 0.0:
            _spawn_next_wave()
    elif state == IN_BATTLE:
        elapsed += delta
        var now: float = _player_health()
        if last_health >= 0.0 and now < last_health - 0.2:
            damage_events += 1
        last_health = now
        var alive: int = 0
        for enemy in enemies:
            if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
                alive += 1
        if alive == 0:
            _round_finished()
    queue_redraw()

func _abort_failed_trial() -> void:
    # No free round or reward on defeat. Rest/retry starts a fresh attempt.
    for creature in enemies:
        if is_instance_valid(creature):
            creature.queue_free()
    enemies.clear()
    state = WAITING
    round_number = 0
    _update_hud()

func _spawn_next_wave() -> void:
    if round_number >= total_rounds:
        _finish()
        return
    round_number += 1
    var source: Node = get_node_or_null("SpawnWaves/Wave%d" % round_number)
    enemies.clear()
    if source == null:
        state = WAITING
        _say("TRIAL SETUP INCOMPLETE · MISSING WAVE MARKERS", Color("f1bac7"))
        return
    for marker in source.get_children():
        if not marker is Marker2D:
            continue
        var code: String = str(marker.name).to_lower()
        var archetype_scene: PackedScene = WRAITH if code.begins_with("wraith") else HUNTER
        var creature: Node2D = archetype_scene.instantiate() as Node2D
        if code.begins_with("wraith"):
            creature.set("max_health", 27.0 if round_number == 1 else 33.0)
            creature.set("move_speed", 78.0 if round_number == 1 else 91.0)
            creature.set("damage_to_player", 6.5 if round_number == 1 else 8.0)
            creature.set("drop_data", null)
        else:
            var elite: bool = code.contains("elite")
            var archetype: String = "mourner"
            if code.begins_with("occultist"):
                archetype = "occultist"
            elif code.begins_with("bladehunter"):
                archetype = "blade_hunter"
            elif code.begins_with("bellkeeper"):
                archetype = "bell_keeper"
            elif code.begins_with("warder"):
                archetype = "warder"
            creature.set("archetype", archetype)
            creature.set("is_elite", elite)
            creature.set("maximum_health", 85.0 if elite else (39.0 if round_number < 3 else 50.0))
            creature.set("strike_damage", 12.0 if elite else 9.0)
            creature.set("move_speed", 80.0 if elite else 90.0)
            creature.set("notice_range", 680.0)
            creature.set("loot_template", null) # only the altar awards the one-time item
        add_child(creature)
        creature.global_position = marker.global_position
        if not code.begins_with("wraith"):
            creature.set("home_position", creature.global_position)
        creature.add_to_group("v147_trial_enemy")
        enemies.append(creature)
    state = IN_BATTLE
    last_health = _player_health()
    _say("ECHOES  %d / %d  ·  HOOK THE BELL TO BREAK THEIR ATTACKS" % [round_number, total_rounds], Color("e4c9e9"))
    # Missing markers should never create an unrecoverable combat encounter.
    if enemies.is_empty():
        _round_finished()

func _round_finished() -> void:
    enemies.clear()
    _recover_between_waves()
    if round_number >= total_rounds:
        _finish()
        return
    state = BETWEEN
    countdown = 1.75
    _say("ECHOES FADE · BREATH RETURNS · ROUND %d / %d" % [round_number, total_rounds], Color("c0e2cf"))

func _recover_between_waves() -> void:
    var girl: Node = _girl()
    if girl == null:
        return
    var new_health: float = minf(float(girl.call("maximum_health")), float(girl.get("health")) + wave_heal)
    girl.set("health", new_health)
    girl.set("stamina", minf(100.0, float(girl.get("stamina")) + wave_stamina))
    var ui: Node = _hud()
    if ui != null:
        ui.call("set_health", new_health, girl.call("maximum_health"))
        ui.call("set_stamina", girl.get("stamina"), 100.0)
    last_health = new_health

func _finish() -> void:
    state = WAITING
    _update_hud()
    already_cleared = true
    result_glow = 3.0
    var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
    flags[trial_id + "_cleared"] = true
    inventory.call("save_game")
    # Inventory's legacy loader deliberately restores every collected flag
    # as boolean; keep numeric personal bests in an independent sidecar file.
    var records: Dictionary = _load_records()
    var elapsed_ms: int = maxi(1, int(roundf(elapsed * 1000.0)))
    var old: Dictionary = records.get(trial_id, {}) as Dictionary
    if old.is_empty() or elapsed_ms < int(old.get("time_ms", 0)):
        records[trial_id] = {"time_ms": elapsed_ms, "hits": damage_events}
        best_time_ms = elapsed_ms
        var output: FileAccess = FileAccess.open(RECORD_FILE, FileAccess.WRITE)
        if output != null:
            output.store_string(JSON.stringify(records))
    var medal: String = "MOONLIT" if damage_events == 0 else ("SILVER" if damage_events <= 2 else "ASHEN")
    var award_text: String = ""
    if not reward_claimed:
        award_text = " · " + _claim_reward()
    _say("%s · %s · %.1f s · %d HITS%s" % [trial_title, medal, elapsed, damage_events, award_text], Color("ead4b0"))

func _load_records() -> Dictionary:
    if not FileAccess.file_exists(RECORD_FILE):
        return {}
    var source: FileAccess = FileAccess.open(RECORD_FILE, FileAccess.READ)
    if source == null:
        return {}
    var parsed: Variant = JSON.parse_string(source.get_as_text())
    return parsed as Dictionary if parsed is Dictionary else {}

func _claim_reward() -> String:
    if inventory == null:
        return "REWARD UNAVAILABLE"
    if reward_claimed:
        return "REWARD ALREADY CLAIMED"
    if first_clear_reward == null:
        return "NO REWARD ASSIGNED"
    var item: GhostItemInstance = inventory.call("add_loot", first_clear_reward, reward_seed, reward_quality) as GhostItemInstance
    if item == null:
        return "BACKPACK FULL · E TO CLAIM WHEN SPACE IS FREE"
    reward_claimed = true
    var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
    flags[trial_id + "_claimed"] = true
    inventory.call("save_game")
    return "RELIC EARNED · " + item.display_name().to_upper()

func _update_hud() -> void:
    var ui: Node = _hud()
    if ui != null and ui.has_method("set_echo_trial_progress"):
        ui.call("set_echo_trial_progress", state != WAITING, trial_title, round_number, total_rounds, elapsed, damage_events)

func _girl() -> Node:
    var game: Node = get_tree().current_scene
    return game.get_node_or_null("GhostGirl") if game != null else null

func _player_health() -> float:
    var girl: Node = _girl()
    return float(girl.get("health")) if girl != null else -1.0

func _hud() -> Node:
    var game: Node = get_tree().current_scene
    return game.get_node_or_null("HUD") if game != null else null

func _say(message: String, tint: Color) -> void:
    var ui: Node = _hud()
    if ui != null:
        ui.call("show_pickup", message, tint)

func _draw() -> void:
    var base: Color = Color("7d667e")
    var active: bool = state != WAITING
    draw_circle(Vector2(0, 12), 44, Color(0.06, 0.035, 0.09, 0.46))
    draw_arc(Vector2.ZERO, 39, 0.0, TAU, 40, Color(0.53, 0.43, 0.54, 0.8), 3.0, true)
    draw_arc(Vector2.ZERO, 33, -PI * 0.75, PI * 0.75, 40, Color(0.75, 0.49, 0.83, 0.7 if active else 0.20), 2.0, true)
    var bright: float = 0.50 + 0.18 * sin(pulse_clock * 2.8)
    draw_circle(Vector2(0, -10), 11, Color(0.65, 0.38, 0.72, 0.10 if not active else 0.28))
    draw_circle(Vector2(0, -10), 4.0 + bright * 3.0, Color("f0c6e9") if active else base)
    for n in range(3):
        var pos: Vector2 = Vector2(-23.0 + float(n) * 23.0, 25.0)
        var reached: bool = already_cleared or (active and n < round_number)
        draw_circle(pos, 4.7, Color("e6c2a0") if reached else Color("5d475d"))
    if already_cleared:
        draw_arc(Vector2.ZERO, 49.0, 0.0, TAU, 45, Color(0.94, 0.75, 0.86, 0.22 + result_glow * 0.10), 2.5, true)
