@tool
extends CharacterBody2D
## Two original, lightweight Hollow Veil Moor creatures.
## Editor-visible silhouettes, generous windup warnings and very little health.
## No new damage effects are attached to the visual particles.
@export_enum("hush_moth", "gloom_lantern") var creature_kind: String = "hush_moth"
@export var max_health: float = 13.0
@export var chase_speed: float = 92.0
@export var attack_damage: float = 3.0
@export var alert_distance: float = 300.0
@export var loot_template: GhostItemData
@export var loot_seed: int = 129000
const IMPACT: Script = preload("res://scripts/combat_impact.gd")
const DEATH_FX: Script = preload("res://scripts/enemy_death_burst_v131.gd")
const FIRE_STEERING: Script = preload("res://scripts/environment_navigation_v146.gd")
const MOTH_ATLAS: Texture2D = preload("res://assets/enemies/hush_moth_v130_4frames.png")
const LANTERN_ATLAS: Texture2D = preload("res://assets/enemies/gloom_lantern_v130_4frames.png")
var health: float = 13.0
var clock: float = 0.0
var windup: float = 0.0
var recovery: float = 0.0
var stagger: float = 0.0
var slow_left: float = 0.0
var slow_factor: float = 1.0
var hit_flash: float = 0.0
var heading: Vector2 = Vector2.DOWN
var roost: Vector2 = Vector2.ZERO
var attack_cooldown: float = 0.35
var hurt_once: bool = false
var disturbance_left: float = 0.0
var disturbance_point: Vector2 = Vector2.ZERO
var fire_alert_left: float = 0.0
var fire_alert_point: Vector2 = Vector2.ZERO

func _ready() -> void:
    roost = global_position
    health = max_health
    collision_layer = 16
    collision_mask = 2
    if not Engine.is_editor_hint():
        add_to_group("enemies")

func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    var game: Node = get_tree().current_scene
    if game != null and game.has_node("HUD") and game.get_node("HUD").call("is_menu_open"):
        velocity = Vector2.ZERO
        return
    var girl: CharacterBody2D = get_tree().get_first_node_in_group("ghost_girl_player") as CharacterBody2D
    if girl == null:
        return
    slow_left = maxf(0.0, slow_left - delta)
    if slow_left <= 0.0:
        slow_factor = 1.0
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    disturbance_left = maxf(0.0, disturbance_left - delta)
    fire_alert_left = maxf(0.0, fire_alert_left - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    var to_girl: Vector2 = girl.global_position - global_position
    var distance: float = to_girl.length()
    if stagger > 0.0:
        stagger = maxf(0.0, stagger - delta)
        velocity *= 0.52
        move_and_slide()
        return
    if windup > 0.0:
        windup = maxf(0.0, windup - delta)
        velocity = Vector2.ZERO
        if windup <= 0.0:
            var reach: float = 63.0 if creature_kind == "hush_moth" else 94.0
            var aligned: bool = creature_kind == "gloom_lantern" or (distance > 0.01 and heading.dot(to_girl.normalized()) > 0.22)
            if not hurt_once and distance < reach and aligned and _can_see(girl):
                girl.call("receive_damage", attack_damage, global_position)
            hurt_once = true
            recovery = 0.95 if creature_kind == "hush_moth" else 1.45
            attack_cooldown = recovery + 0.35
        move_and_slide()
        return
    if recovery > 0.0:
        recovery = maxf(0.0, recovery - delta)
        velocity = Vector2.ZERO
        move_and_slide()
        return
    if distance < (57.0 if creature_kind == "hush_moth" else 88.0) and attack_cooldown <= 0.0:
        windup = 0.58 if creature_kind == "hush_moth" else 0.95
        heading = to_girl.normalized() if distance > 0.01 else Vector2.DOWN
        hurt_once = false
        velocity = Vector2.ZERO
    elif distance < alert_distance and global_position.distance_to(roost) < alert_distance * 1.75 and distance > 0.01:
        var direction: Vector2 = to_girl.normalized()
        if creature_kind == "hush_moth" and distance < 115.0:
            direction = direction.rotated(0.44 * sin(clock * 1.3 + float(posmod(loot_seed, 7))))
        velocity = direction * chase_speed * slow_factor
    elif fire_alert_left > 0.0 and distance > alert_distance and global_position.distance_to(fire_alert_point) < 210.0:
        velocity = (global_position - fire_alert_point).normalized() * chase_speed * 0.70 * slow_factor
    elif disturbance_left > 0.0 and distance > 155.0 and global_position.distance_to(disturbance_point) > 42.0:
        var seek: Vector2 = (disturbance_point - global_position).normalized()
        velocity = seek * chase_speed * 0.57 * slow_factor
    elif global_position.distance_to(roost) > 30.0:
        velocity = (roost - global_position).normalized() * chase_speed * 0.43 * slow_factor
    else:
        velocity = Vector2.ZERO
    velocity = FIRE_STEERING.avoid_fire(self, velocity)
    move_and_slide()

func on_environment_threat(world_point: Vector2, seconds: float) -> void:
    if health <= 0.0 or windup > 0.0 or stagger > 0.0:
        return
    fire_alert_point = world_point
    fire_alert_left = maxf(fire_alert_left, clampf(seconds, 0.3, 3.0))

func on_world_disturbance(world_point: Vector2, seconds: float) -> void:
    if health <= 0.0 or windup > 0.0 or stagger > 0.0:
        return
    disturbance_point = world_point
    disturbance_left = maxf(disturbance_left, clampf(seconds, 0.4, 4.0))

func _can_see(girl: CharacterBody2D) -> bool:
    var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -22), girl.global_position + Vector2(0, -22))
    ray.collision_mask = 2
    return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func _process(delta: float) -> void:
    clock += delta
    queue_redraw()

func spell_aim_point() -> Vector2:
    return global_position + Vector2(0, -28)

func offers_backstep_counter(player_position: Vector2) -> bool:
    return health > 0.0 and windup > 0.0 and windup <= 0.30 and global_position.distance_to(player_position) < 125.0

func on_hook_yank(destination: Vector2, strength: float) -> void:
    windup = 0.0
    recovery = 0.0
    stagger = 0.32
    hit_flash = 0.22
    velocity = (destination - global_position).normalized() * strength * 0.28

func apply_frost_slow(seconds: float, speed_factor: float) -> void:
    slow_left = maxf(slow_left, seconds)
    slow_factor = minf(slow_factor, clampf(speed_factor, 0.38, 1.0))

func hit(damage: float, _poise_multiplier: float = 1.0) -> void:
    if Engine.is_editor_hint() or health <= 0.0:
        return
    health -= damage
    hit_flash = 0.20
    if health <= 0.0:
        # Very weak creatures contribute almost no additional loot.
        var root: Node = get_tree().current_scene
        if loot_template != null and posmod(loot_seed, 9) == 0 and root != null and root.has_method("grant_enemy_loot"):
            root.call("grant_enemy_loot", loot_template, loot_seed, "random")
        _spawn_death_burst()
        queue_free()
        return
    windup = 0.0
    stagger = 0.18
    var root: Node = get_tree().current_scene
    if root != null:
        var burst: Node2D = Node2D.new()
        burst.set_script(IMPACT)
        root.add_child(burst)
        burst.global_position = global_position + Vector2(0, -25)

func _draw() -> void:
    # v1.30: each enemy now has four separately illustrated frames.
    # Movement, damage and telegraphs remain in this script; the texture is
    # only presentation and cannot change hit counts or collision geometry.
    var frame_index: int = int(floor(clock * (5.0 if creature_kind == "hush_moth" else 3.5))) % 4
    var atlas: Texture2D = MOTH_ATLAS if creature_kind == "hush_moth" else LANTERN_ATLAS
    var tint: Color = Color(1.0, 0.75, 0.80, 1.0) if hit_flash > 0.0 else Color.WHITE
    draw_circle(Vector2(0, 2), 23.0, Color(0.05, 0.02, 0.07, 0.19))
    var sprite_rect: Rect2 = Rect2(-59.0, -86.0, 118.0, 118.0) if creature_kind == "hush_moth" else Rect2(-63.0, -92.0, 126.0, 126.0)
    draw_texture_rect_region(atlas, sprite_rect, Rect2(float(frame_index * 256), 0.0, 256.0, 256.0), tint)
    if creature_kind == "gloom_lantern":
        var flicker: float = 0.5 + 0.5 * sin(clock * 2.7 + float(posmod(loot_seed, 19)))
        draw_circle(Vector2(0.0, -35.0), 19.0 + flicker * 5.0, Color(0.54, 0.89, 0.78, 0.10 + flicker * 0.035))
    else:
        for n in range(3):
            var theta: float = clock * (0.7 + float(n) * 0.2) + TAU * float(n) / 3.0
            var mote: Vector2 = Vector2.from_angle(theta) * (27.0 + 5.0 * sin(clock * 2.1 + float(n))) + Vector2(0.0, -26.0)
            draw_circle(mote, 1.4, Color(0.85, 0.70, 0.91, 0.45))
    if slow_left > 0.0:
        draw_arc(Vector2(0, -26), 36.0, 0.0, TAU, 30, Color(0.65, 0.87, 1.0, 0.58), 1.7, true)
    if windup > 0.0:
        var total: float = 0.58 if creature_kind == "hush_moth" else 0.95
        var progress: float = 1.0 - windup / total
        var alert: Color = Color(0.96, 0.44, 0.60, 0.28 + progress * 0.56)
        draw_arc(Vector2(0, -22), (37.0 if creature_kind == "hush_moth" else 74.0), 0.0, TAU, 40, alert, 2.3, true)
        if creature_kind == "hush_moth":
            draw_line(Vector2(0, -22), heading * 41.0 + Vector2(0, -22), alert, 1.7, true)

func _spawn_death_burst() -> void:
    var root: Node = get_tree().current_scene
    if root == null:
        return
    var flash: Node2D = Node2D.new()
    flash.set_script(DEATH_FX)
    flash.set("kind", "moth" if creature_kind == "hush_moth" else "lantern")
    flash.set("seed_value", loot_seed)
    flash.set("ink", Color("d8b8e8") if creature_kind == "hush_moth" else Color("7bc7b7"))
    flash.set("accent", Color("f5dcef") if creature_kind == "hush_moth" else Color("d5ffdf"))
    root.add_child(flash)
    flash.global_position = global_position
