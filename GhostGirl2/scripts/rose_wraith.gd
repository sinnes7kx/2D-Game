@tool
extends CharacterBody2D
## Light introductory enemy: chasing rose-wraith, clickable target for wand spells.
## Temporary visual draft, not an aggressive survival mechanic.
@export var max_health: float = 35.0
@export var move_speed: float = 90.0
@export var aggro_radius: float = 380.0
@export var damage_to_player: float = 8.0
@export var drop_data: GhostItemData
@export var drop_seed: int = 410
@export_enum("random", "magic", "rare", "set", "unique") var drop_quality: String = "random"
const HIT_EFFECT_SCRIPT: Script = preload("res://scripts/combat_impact.gd")
const DEATH_FX: Script = preload("res://scripts/enemy_death_burst_v131.gd")
const FIRE_STEERING: Script = preload("res://scripts/environment_navigation_v146.gd")
var health: float = 35.0
var time_counter: float = 0.0
var contact_cooldown: float = 0.0
var hook_yank_left: float = 0.0
var hook_yank_velocity: Vector2 = Vector2.ZERO
var windup_left: float = 0.0
var recovery_left: float = 0.0
var stagger_left: float = 0.0
var attack_heading: Vector2 = Vector2.DOWN
var impact_flash: float = 0.0
var frost_slow_left: float = 0.0
var frost_speed_factor: float = 1.0
var disturbance_left: float = 0.0
var disturbance_point: Vector2 = Vector2.ZERO
var fire_alert_left: float = 0.0
var fire_alert_point: Vector2 = Vector2.ZERO

func _ready() -> void:
    collision_layer = 16
    collision_mask = 2
    health = max_health
    if not Engine.is_editor_hint():
        add_to_group("enemies")

func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD") and root.get_node("HUD").is_menu_open():
        velocity = Vector2.ZERO
        return
    frost_slow_left = maxf(0.0, frost_slow_left - delta)
    if frost_slow_left <= 0.0:
        frost_speed_factor = 1.0
    contact_cooldown = maxf(0.0, contact_cooldown - delta)
    disturbance_left = maxf(0.0, disturbance_left - delta)
    fire_alert_left = maxf(0.0, fire_alert_left - delta)
    impact_flash = maxf(0.0, impact_flash - delta)
    var girl: CharacterBody2D = get_tree().get_first_node_in_group("ghost_girl_player") as CharacterBody2D
    if girl == null:
        return
    if hook_yank_left > 0.0:
        hook_yank_left = maxf(0.0, hook_yank_left - delta)
        velocity = hook_yank_velocity if global_position.distance_to(girl.global_position) > 75.0 else Vector2.ZERO
        move_and_slide()
        return
    if stagger_left > 0.0:
        stagger_left = maxf(0.0, stagger_left - delta)
        velocity = Vector2.ZERO
        move_and_slide()
        return
    var towards: Vector2 = girl.global_position - global_position
    var distance: float = towards.length()
    if windup_left > 0.0:
        windup_left = maxf(0.0, windup_left - delta)
        velocity = Vector2.ZERO
        if windup_left <= 0.0:
            # The strike only lands when the ghost remains in reach and within
            # the clearly telegraphed attack direction.
            if distance < 66.0 and distance > 1.0 and attack_heading.dot(towards.normalized()) > 0.20:
                if girl.has_method("try_parry_contact") and bool(girl.call("try_parry_contact",self)):
                    return
                if girl.has_method("register_confirmed_evade"):
                    girl.call("register_confirmed_evade",self,global_position)
                girl.call("receive_damage", damage_to_player, global_position)
            recovery_left = 0.77
            contact_cooldown = 0.78
        move_and_slide()
        return
    if recovery_left > 0.0:
        recovery_left = maxf(0.0, recovery_left - delta)
        velocity = Vector2.ZERO
        move_and_slide()
        return
    if distance < 67.0 and contact_cooldown <= 0.0:
        attack_heading = towards.normalized() if distance > 1.0 else Vector2.DOWN
        windup_left = 0.52
        velocity = Vector2.ZERO
    elif distance < aggro_radius:
        velocity = towards.normalized() * move_speed * frost_speed_factor if distance > 1.0 else Vector2.ZERO
    elif fire_alert_left > 0.0 and global_position.distance_to(fire_alert_point) < 210.0:
        velocity = (global_position - fire_alert_point).normalized() * move_speed * 0.65 * frost_speed_factor
    elif disturbance_left > 0.0 and global_position.distance_to(disturbance_point) > 42.0:
        velocity = (disturbance_point - global_position).normalized() * move_speed * 0.55 * frost_speed_factor
    else:
        velocity = Vector2(sin(time_counter * 0.4), cos(time_counter * 0.6)) * (move_speed * 0.15 * frost_speed_factor)
    velocity = FIRE_STEERING.avoid_fire(self, velocity)
    move_and_slide()

func on_environment_threat(world_point: Vector2, seconds: float) -> void:
    if health <= 0.0 or windup_left > 0.0 or stagger_left > 0.0:
        return
    fire_alert_point = world_point
    fire_alert_left = maxf(fire_alert_left, clampf(seconds, 0.3, 3.0))

func on_world_disturbance(world_point: Vector2, seconds: float) -> void:
    if health <= 0.0 or windup_left > 0.0 or stagger_left > 0.0:
        return
    disturbance_point = world_point
    disturbance_left = maxf(disturbance_left, clampf(seconds, 0.4, 4.0))

func _process(delta: float) -> void:
    time_counter += delta
    queue_redraw()

func offers_backstep_counter(player_position: Vector2) -> bool:
    return health > 0.0 and windup_left > 0.0 and windup_left <= 0.36 and global_position.distance_to(player_position) < 160.0

func on_parried(perfect: bool) -> void:
    if health <= 0.0:
        return
    windup_left = 0.0
    recovery_left = 0.0
    stagger_left = 1.15 if perfect else 0.42
    contact_cooldown = maxf(contact_cooldown,stagger_left)
    impact_flash = 0.30
    velocity = Vector2.ZERO

func on_hook_yank(destination: Vector2, strength: float) -> void:
    if health <= 0.0:
        return
    contact_cooldown = maxf(contact_cooldown, 0.50)
    windup_left = 0.0
    recovery_left = 0.0
    hook_yank_left = 0.25
    hook_yank_velocity = (destination - global_position).normalized() * strength
    stagger_left = 0.23
    impact_flash = 0.30

func apply_frost_slow(seconds: float, speed_factor: float) -> void:
    frost_slow_left = maxf(frost_slow_left, seconds)
    frost_speed_factor = minf(frost_speed_factor, clampf(speed_factor, 0.35, 1.0))

func hit(damage: float, _poise_multiplier: float = 1.0) -> void:
    if Engine.is_editor_hint() or health <= 0.0:
        return
    var applied_damage: float = damage * (1.12 if recovery_left > 0.0 else 1.0)
    health -= applied_damage
    contact_cooldown = maxf(contact_cooldown, 0.34)
    windup_left = 0.0
    stagger_left = 0.22 if _poise_multiplier < 1.25 else 0.36
    impact_flash = 0.24
    var impact: Node2D = Node2D.new()
    impact.set_script(HIT_EFFECT_SCRIPT)
    get_tree().current_scene.add_child(impact)
    impact.global_position = global_position + Vector2(0, -30)
    if health <= 0.0:
        var game: Node = get_tree().current_scene
        if game != null and game.has_method("grant_enemy_loot"):
            game.grant_enemy_loot(drop_data, randi(), drop_quality)
        _spawn_death_burst()
        queue_free()

func _draw() -> void:
    var beat: float = sin(time_counter * 2.7)
    if frost_slow_left > 0.0:
        draw_arc(Vector2(0, 10), 30.0, 0.0, TAU, 24, Color(0.68, 0.86, 1.0, 0.45), 1.8, true)
        for frost_mark in range(4):
            var a: float = float(frost_mark) * TAU / 4.0 + time_counter * 0.32
            draw_circle(Vector2.from_angle(a) * 24.0 + Vector2(0, -16), 2.0, Color("d8efff"))
    var body: Color = Color(0.92, 0.51, 0.59, 0.78) if impact_flash > 0.0 else Color(0.61, 0.50, 0.76, 0.66)
    if windup_left > 0.0:
        var warning: float = 0.3 + 0.7 * (1.0 - windup_left / 0.52)
        draw_arc(Vector2(0, -18), 40.0, 0.0, TAU, 32, Color(0.94, 0.39, 0.56, warning), 2.5, true)
        draw_line(Vector2(0, -18), attack_heading * 45.0 + Vector2(0, -18), Color(1.0, 0.78, 0.86, warning), 2.0)
    draw_circle(Vector2(0, -19), 24.0 + beat * 2.0, Color(0.76, 0.47, 0.83, 0.07))
    draw_colored_polygon(PackedVector2Array([Vector2(-20,-17), Vector2(-24,16), Vector2(-12,8), Vector2(-2,18), Vector2(12,7), Vector2(23,16), Vector2(18,-17)]), body)
    draw_circle(Vector2(0,-25),22.0,Color(0.64,0.59,0.75,0.85))
    draw_circle(Vector2(-8,-27),4.8, Color("181022"))
    draw_circle(Vector2(8,-27),4.8, Color("181022"))
    draw_circle(Vector2(0,-4),5.0,Color(0.75,0.35,0.57,0.6))
    for i in range(5):
        var a: float = time_counter * 0.7 + float(i) * TAU / 5
        draw_circle(Vector2.from_angle(a) * (32.0 + beat*3) + Vector2(0,-18), 2.5,Color(0.94,0.71,0.88,0.6))

# Aim at the illustrated body, not the much lower movement/feet collider.
func spell_aim_point() -> Vector2:
    return $SpellHurtbox/Body.global_position if has_node("SpellHurtbox/Body") else global_position + Vector2(0, -27)

func _spawn_death_burst() -> void:
    var root: Node = get_tree().current_scene
    if root == null:
        return
    var flash: Node2D = Node2D.new()
    flash.set_script(DEATH_FX)
    flash.set("kind", "wraith")
    flash.set("seed_value", drop_seed)
    flash.set("ink", Color("c3a3de"))
    flash.set("accent", Color("efc7e9"))
    root.add_child(flash)
    flash.global_position = global_position
