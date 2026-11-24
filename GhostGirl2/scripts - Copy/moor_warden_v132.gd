@tool
extends CharacterBody2D
## Original optional wilderness boss. Persistent defeat, nonpersistent encounter.
## Every attack has a visible windup, one damage decision, and a recovery gap.
## Spell/arrow visuals never create additional hit events.
@export var maximum_health: float = 270.0
@export var move_speed: float = 102.0
@export var shockwave_damage: float = 12.0
@export var swipe_damage: float = 9.0
@export var beam_damage: float = 10.0
@export var arena_radius: float = 710.0
@export var altar_path: NodePath
const MOTH_SCENE: PackedScene = preload("res://scenes/moor_creature_v129.tscn")
const DEATH_FX: Script = preload("res://scripts/enemy_death_burst_v131.gd")
const PHYSICAL_FEEL: Script = preload("res://scripts/impact_spawner_v149.gd")
const ATTACK_FX: Script = preload("res://scripts/warden_attack_echo_v134.gd")
const DEFEAT_ID: String = "v132_moor_warden_defeated"
var health: float = 270.0
var awakened: bool = false
var defeated: bool = false
var elapsed: float = 0.0
var mode: int = 0 # 0 seek, 1 tell, 2 recovery, 3 stagger
var attack_kind: int = 0 # 0 crescent sweep, 1 ground pulse, 2 line lance
var windup_left: float = 0.0
var windup_total: float = 0.0
var cooldown: float = 0.6
var stagger_left: float = 0.0
var frost_left: float = 0.0
var slow_factor: float = 1.0
var flash_left: float = 0.0
var chosen_direction: Vector2 = Vector2.DOWN
var arena_origin: Vector2 = Vector2.ZERO
var attack_index: int = 0
var summoned: bool = false
var poise: float = 0.0
var aggro_player: CharacterBody2D = null

func _ready() -> void:
    health = maximum_health
    arena_origin = global_position
    collision_layer = 16
    collision_mask = 2
    if not Engine.is_editor_hint():
        _set_corporeal(false)
        hide()

func restore_warden(already_defeated: bool) -> void:
    defeated = already_defeated
    awakened = false
    mode = 0
    health = maximum_health
    summoned = false
    cooldown = 0.7
    _set_corporeal(false)
    hide()
    remove_from_group("enemies")

func begin_encounter() -> void:
    if defeated or awakened or Engine.is_editor_hint():
        return
    awakened = true
    health = maximum_health
    mode = 0
    cooldown = 1.0
    _set_corporeal(true)
    add_to_group("enemies")
    show()
    _set_storm_rain(0.68)
    var game: Node = get_tree().current_scene
    if game != null and game.has_node("HUD"):
        game.get_node("HUD").call("show_pickup", "THE MOOR WARDEN RISES", Color("eac6ae"))

func _set_corporeal(enabled: bool) -> void:
    # Dormant bosses must not form invisible walls or absorb arrow rays.
    collision_layer = 16 if enabled else 0
    collision_mask = 2 if enabled else 0
    var hurtbox: Area2D = get_node_or_null("SpellHurtbox") as Area2D
    if hurtbox != null:
        hurtbox.collision_layer = 32 if enabled else 0
        hurtbox.monitorable = enabled

func _set_storm_rain(intensity: float) -> void:
    var room_view: Node = get_parent()
    while room_view != null and room_view.name != "Room":
        room_view = room_view.get_parent()
    if room_view != null:
        var rain: Node = room_view.get_node_or_null("MoorRain")
        if rain != null:
            rain.set("intensity", intensity)

func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint() or not awakened or defeated:
        return
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD") and root.get_node("HUD").call("is_menu_open"):
        velocity = Vector2.ZERO
        return
    flash_left = maxf(0.0, flash_left - delta)
    frost_left = maxf(0.0, frost_left - delta)
    if frost_left <= 0.0:
        slow_factor = 1.0
    poise = maxf(0.0, poise - delta * 12.0)
    var girl: CharacterBody2D = get_tree().get_first_node_in_group("ghost_girl_player") as CharacterBody2D
    if girl == null:
        return
    aggro_player = girl
    var towards: Vector2 = girl.global_position - global_position
    var distance: float = towards.length()
    if not summoned and health <= maximum_health * 0.53:
        _summon_hush_moths()
        summoned = true
    if mode == 3:
        stagger_left = maxf(0.0, stagger_left - delta)
        velocity = Vector2.ZERO
        if stagger_left <= 0.0:
            mode = 2
            cooldown = 0.5
        return
    if mode == 1:
        windup_left = maxf(0.0, windup_left - delta)
        velocity = Vector2.ZERO
        if windup_left <= 0.0:
            _resolve_attack(girl)
            mode = 2
            cooldown = 1.05 if health > maximum_health * 0.5 else 0.81
        return
    if mode == 2:
        cooldown = maxf(0.0, cooldown - delta)
        velocity = Vector2.ZERO
        if cooldown <= 0.0:
            mode = 0
        return
    if distance > arena_radius:
        # Returning to the altar keeps the fight local and the main moor safe.
        var home: Vector2 = arena_origin - global_position
        velocity = home.normalized() * move_speed * 0.65 if home.length() > 55.0 else Vector2.ZERO
        move_and_slide()
        return
    if distance < (145.0 if health > maximum_health * 0.5 else 175.0):
        _start_attack(towards)
    else:
        velocity = towards.normalized() * move_speed * slow_factor if distance > 2.0 else Vector2.ZERO
        move_and_slide()

func _start_attack(towards: Vector2) -> void:
    mode = 1
    velocity = Vector2.ZERO
    attack_kind = attack_index % 3
    attack_index += 1
    chosen_direction = towards.normalized() if towards.length_squared() > 1.0 else Vector2.DOWN
    windup_total = 0.82 if attack_kind == 0 else (1.15 if attack_kind == 1 else 0.94)
    windup_left = windup_total

func _resolve_attack(girl: CharacterBody2D) -> void:
    if not is_instance_valid(girl):
        return
    var offset: Vector2 = girl.global_position - global_position
    var distance: float = offset.length()
    var in_line: bool = distance < 330.0 and absf(offset.cross(chosen_direction)) < 51.0 and chosen_direction.dot(offset) > 0.0
    var in_arc: bool = distance < 155.0 and (distance < 2.0 or offset.normalized().dot(chosen_direction) > -0.05)
    var hits: bool = in_arc if attack_kind == 0 else (distance < 228.0 if attack_kind == 1 else in_line)
    # The ground pulse is explicitly a jumpable hazard. Existing dodge
    # invulnerability is still controlled by receive_damage on the player.
    if attack_kind == 1 and float(girl.get("jump_time_left")) > 0.0:
        hits = false
    if hits and _can_see(girl):
        var amount: float = swipe_damage if attack_kind == 0 else (shockwave_damage if attack_kind == 1 else beam_damage)
        girl.call("receive_damage", amount, global_position)
    flash_left = 0.17
    _release_attack_echo()

func _release_attack_echo() -> void:
    # One short purely visual release per resolved boss attack. This method
    # intentionally never calls receive_damage or creates new hitboxes.
    var root: Node = get_tree().current_scene
    if root == null:
        return
    var burst: Node2D = Node2D.new()
    burst.set_script(ATTACK_FX)
    burst.set("kind", attack_kind)
    burst.set("facing", chosen_direction)
    root.add_child(burst)
    burst.global_position = global_position

func _can_see(girl: CharacterBody2D) -> bool:
    var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -35), girl.global_position + Vector2(0, -35))
    ray.collision_mask = 2
    return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func apply_frost_slow(seconds: float, factor: float) -> void:
    if not awakened or defeated:
        return
    frost_left = maxf(frost_left, seconds * 0.65)
    slow_factor = minf(slow_factor, clampf(factor, 0.7, 1.0))

func on_hook_yank(_destination: Vector2, _strength: float) -> void:
    if not awakened or defeated:
        return
    mode = 3
    stagger_left = 0.42
    windup_left = 0.0
    flash_left = 0.34

func offers_backstep_counter(player_position: Vector2) -> bool:
    return awakened and health > 0.0 and mode == 1 and windup_left < 0.35 and global_position.distance_to(player_position) < 190.0

func spell_aim_point() -> Vector2:
    return global_position + Vector2(0, -50)

func hit(amount: float, poise_multiplier: float = 1.0) -> void:
    if not awakened or defeated or Engine.is_editor_hint():
        return
    health -= amount
    poise += amount * maxf(0.5, poise_multiplier) * 0.25
    flash_left = 0.25
    if health <= 0.0:
        _defeat()
        return
    if poise >= 62.0:
        poise = 0.0
        mode = 3
        stagger_left = 0.56
        windup_left = 0.0

func _summon_hush_moths() -> void:
    var root: Node = get_tree().current_scene
    if root == null:
        return
    var container: Node = get_parent()
    if container == null:
        return
    for n in range(2):
        var moth: CharacterBody2D = MOTH_SCENE.instantiate() as CharacterBody2D
        if moth == null:
            return
        moth.set("creature_kind", "hush_moth")
        moth.set("max_health", 11.0)
        moth.set("attack_damage", 2.5)
        moth.set("loot_template", null)
        container.add_child(moth)
        moth.add_to_group("v132_warden_summons")
        moth.global_position = global_position + Vector2(-105.0 if n == 0 else 105.0, 75.0)

func _defeat() -> void:
    defeated = true
    awakened = false
    _set_corporeal(false)
    _set_storm_rain(0.38)
    remove_from_group("enemies")
    # Despawn only the boss's temporary reinforcements; do not touch any
    # unrelated moor moths or the normal enemy-loot economy.
    for summoned_moth in get_tree().get_nodes_in_group("v132_warden_summons"):
        if is_instance_valid(summoned_moth):
            summoned_moth.queue_free()
    var root: Node = get_tree().current_scene
    if root != null:
        var inventory: Node = root.get_node_or_null("Inventory")
        if inventory != null:
            var saved: Dictionary = inventory.get("collected_pickups") as Dictionary
            saved[DEFEAT_ID] = true
            inventory.call("save_game")
        var altar: Node = get_node_or_null(altar_path)
        if altar != null and altar.has_method("mark_completed"):
            altar.call("mark_completed")
        if root.has_node("HUD"):
            root.get_node("HUD").call("show_pickup", "MOOR WARDEN DEFEATED · RELIC GATE RELEASED", Color("f6deac"))
        if root.has_method("refresh_vigil_hud"):
            root.call("refresh_vigil_hud")
        var burst: Node2D = Node2D.new()
        burst.set_script(DEATH_FX)
        burst.set("kind", "hunter")
        burst.set("seed_value", 132321)
        burst.set("ink", Color("c1a7dd"))
        burst.set("accent", Color("f5d6b6"))
        root.add_child(burst)
        burst.global_position = global_position
        PHYSICAL_FEEL.pool(get_parent(), global_position, 132321, 1.95, Color("392339"))
        PHYSICAL_FEEL.burst(get_parent(), global_position + Vector2(0, -18), "stone", 1.65, Vector2.UP, 132321)
        PHYSICAL_FEEL.rumble(global_position, 8.5)
    queue_free()

func _process(delta: float) -> void:
    elapsed += delta
    if Engine.is_editor_hint() or awakened:
        queue_redraw()

func _draw() -> void:
    if defeated or (not awakened and not Engine.is_editor_hint()):
        return
    var hurt: Color = Color("f3b4c4") if flash_left > 0.0 else Color("b2a0bd")
    var pulse: float = sin(elapsed * 1.8)
    var shadow: Color = Color("17111f")
    draw_circle(Vector2(0, 8), 54.0, Color(0.04, 0.03, 0.04, 0.30))
    draw_circle(Vector2(0, -59), 66.0 + 4.0 * pulse, Color(hurt.r, hurt.g, hurt.b, 0.075))
    # A distinctive, hand-authored spectral warden silhouette, not a scaled
    # copy or recolour of Ghost Girl's existing character atlas.
    draw_colored_polygon(PackedVector2Array([Vector2(-42, -73), Vector2(-70, 19), Vector2(-30, 5), Vector2(0, 31), Vector2(32, 5), Vector2(70, 19), Vector2(44, -73)]), Color("30283b"))
    draw_colored_polygon(PackedVector2Array([Vector2(-38, -73), Vector2(-48, -11), Vector2(-4, 17), Vector2(48, -11), Vector2(38, -73)]), Color("564858"))
    draw_line(Vector2(-40, -68), Vector2(-43, 7), hurt, 3.0, true)
    draw_line(Vector2(40, -68), Vector2(43, 7), hurt, 3.0, true)
    draw_circle(Vector2(0, -98), 37.0, Color("7a7084"))
    draw_colored_polygon(PackedVector2Array([Vector2(-37, -102), Vector2(-54, -147), Vector2(-18, -122), Vector2(0, -143), Vector2(18, -122), Vector2(54, -147), Vector2(37, -102)]), Color("78617d"))
    draw_circle(Vector2(-13, -99), 5.4, Color("e6d3f7"))
    draw_circle(Vector2(13, -99), 5.4, Color("e6d3f7"))
    draw_line(Vector2(-14, -69), Vector2(14, -69), Color("b7a0b8"), 2.0, true)
    draw_line(Vector2(0, -70), Vector2(0, -14), Color("e3be9d"), 2.0, true)
    draw_circle(Vector2(0, -50), 14.0 + 1.5 * pulse, Color(0.90, 0.71, 0.78, 0.16))
    draw_arc(Vector2(0, -50), 14.0, 0.0, TAU, 30, Color("cdb6d8"), 1.7, true)
    for i in range(7):
        var theta: float = elapsed * 0.33 + TAU * float(i) / 7.0
        var p: Vector2 = Vector2.from_angle(theta) * 58.0 + Vector2(0, -68)
        draw_circle(p, 2.0, Color(0.85, 0.71, 0.96, 0.46))
    if not awakened:
        return
    # Boss health bar always corresponds to actual gameplay HP.
    draw_rect(Rect2(-76, -177, 152, 8), Color("201821"), true)
    draw_rect(Rect2(-74, -175, 148.0 * clampf(health / maximum_health, 0.0, 1.0), 4), Color("bd768d") if health < maximum_health * 0.5 else Color("b7a1cb"), true)
    if mode == 1:
        var progress: float = 1.0 - windup_left / maxf(0.01, windup_total)
        var alpha: float = 0.27 + 0.56 * progress
        var ink: Color = Color(1.0, 0.59, 0.72, alpha)
        if attack_kind == 1:
            draw_arc(Vector2(0, 0), 228.0, 0.0, TAU, 72, ink, 3.0, true)
            draw_arc(Vector2(0, 0), 228.0 * progress, 0.0, TAU, 66, ink, 2.0, true)
        elif attack_kind == 0:
            draw_arc(Vector2(0, 0), 155.0, chosen_direction.angle() - PI * 0.54, chosen_direction.angle() + PI * 0.54, 42, ink, 3.0, true)
        else:
            draw_line(Vector2.ZERO, chosen_direction * 330.0, ink, 7.0, true)
            draw_line(Vector2.ZERO, chosen_direction * 330.0, Color(1.0, 0.85, 0.91, alpha * 0.54), 2.0, true)
