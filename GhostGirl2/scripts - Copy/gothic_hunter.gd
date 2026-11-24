@tool
extends CharacterBody2D
## Deliberate, visibly telegraphed combat. Editable per-enemy aggression,
## windup, damage, stagger, and seeded Diablo-style ground loot.
const HIT_EFFECT_SCRIPT: Script = preload("res://scripts/combat_impact.gd")
const DEATH_FX: Script = preload("res://scripts/enemy_death_burst_v131.gd")
const PHYSICAL_FEEL: Script = preload("res://scripts/impact_spawner_v149.gd")
const FIRE_STEERING: Script = preload("res://scripts/environment_navigation_v146.gd")
const HEX_BOLT_SCENE: PackedScene = preload("res://scenes/enemy_hex_bolt.tscn")
const COMBAT_RESPONSE_V157: Script = preload("res://scripts/combat_response_v157.gd")
# New v0.9 authored animations. Old enemy archetypes still use their silhouettes.
const BLADE_HUNTER_FRAMES: SpriteFrames = preload("res://assets/enemies/blade_hunter/animations.tres")
const OCCULTIST_FRAMES: SpriteFrames = preload("res://assets/enemies/occultist/animations.tres")
@export_enum("mourner", "warder", "bell_keeper", "blade_hunter", "occultist") var archetype: String = "mourner"
@export var maximum_health: float = 56.0
@export var move_speed: float = 95.0
@export var notice_range: float = 510.0
@export var attack_distance: float = 100.0
@export var windup_duration: float = 0.70
@export var strike_damage: float = 13.0
@export var loot_template: GhostItemData
@export var loot_seed: int = 93041
@export var is_elite: bool = false
@export_enum("random", "normal", "magic", "rare", "set", "unique") var loot_quality: String = "random"

const REST: int = 0
const PURSUE: int = 1
const WARN: int = 2
const RECOVER: int = 3
const STAGGER: int = 4
const LUNGE: int = 5
const FEINT: int = 6 # v1.59: visible, non-damaging blade-hunter fake-out
const CIRCLE: int = 7 # v1.61: deliberate, non-attacking flanking approach
var state: int = REST
var disturbance_left: float = 0.0
var disturbance_point: Vector2 = Vector2.ZERO
var fire_alert_left: float = 0.0
var fire_alert_point: Vector2 = Vector2.ZERO
var remaining: float = 0.0
var active_warning_duration: float = 0.70
var hp: float = 56.0
var scene_time: float = 0.0
var stagger_flash: float = 0.0
var last_target: Vector2 = Vector2.DOWN
var strike_done: bool = false
var home_position: Vector2 = Vector2.ZERO
var poise_damage: float = 0.0
var stagger_resistance: float = 0.0
var hit_number_time: float = 0.0
var recent_hit: int = 0
var hook_yank_left: float = 0.0
var hook_yank_speed: float = 0.0
var hook_yank_direction: Vector2 = Vector2.ZERO
var death_in_progress: bool = false
var frost_slow_left: float = 0.0
var frost_speed_factor: float = 1.0
var attack_visual_hold: float = 0.0
var contact_push_left: float = 0.0
var contact_push_velocity: Vector2 = Vector2.ZERO
var configured_sprite_archetype: String = ""
var attack_pattern_count: int = 0
var feint_cooldown: float = 0.0
var feint_side: float = 1.0
var occultist_bolt_count: int = 0
var flank_cooldown: float = 2.3
var flank_side: float = 1.0
var opening_left: float = 0.0
@onready var illustrated_body: AnimatedSprite2D = get_node_or_null("EnemyVisual") as AnimatedSprite2D


func _ready() -> void:
	hp = maximum_health
	home_position = global_position
	_update_enemy_animation(true)
	collision_layer = 16
	collision_mask = 2
	if not Engine.is_editor_hint():
		add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var root: Node = get_tree().current_scene
	if root != null and root.has_node("HUD") and root.get_node("HUD").is_menu_open():
		velocity = Vector2.ZERO
		return
	var girl: CharacterBody2D = get_tree().get_first_node_in_group("ghost_girl_player") as CharacterBody2D
	if girl == null:
		return
	frost_slow_left = maxf(0.0, frost_slow_left - delta)
	if frost_slow_left <= 0.0:
		frost_speed_factor = 1.0
	remaining = maxf(0.0, remaining - delta)
	feint_cooldown = maxf(0.0, feint_cooldown - delta)
	flank_cooldown = maxf(0.0, flank_cooldown - delta)
	opening_left = maxf(0.0, opening_left - delta)
	disturbance_left = maxf(0.0, disturbance_left - delta)
	fire_alert_left = maxf(0.0, fire_alert_left - delta)
	attack_visual_hold = maxf(0.0, attack_visual_hold - delta)
	stagger_flash = maxf(0.0, stagger_flash - delta)
	stagger_resistance = maxf(0.0, stagger_resistance - delta)
	poise_damage = maxf(0.0, poise_damage - 11.0 * delta)
	hit_number_time = maxf(0.0, hit_number_time - delta)
	if hook_yank_left > 0.0:
		hook_yank_left = maxf(0.0, hook_yank_left - delta)
		if global_position.distance_to(girl.global_position) > 78.0:
			velocity = hook_yank_direction * hook_yank_speed
		else:
			velocity = Vector2.ZERO
			hook_yank_left = 0.0
		velocity *= frost_speed_factor
		move_and_slide()
		return
	var offset: Vector2 = girl.global_position - global_position
	var distance: float = offset.length()
	if state in [REST, PURSUE] and distance > 1.0:
		last_target = offset.normalized()
	match state:
		REST:
			if distance < notice_range and _can_see_player(girl):
				state = PURSUE
			elif fire_alert_left > 0.0 and global_position.distance_to(fire_alert_point) < 210.0:
				velocity = (global_position - fire_alert_point).normalized() * move_speed * 0.70
			elif disturbance_left > 0.0 and global_position.distance_to(disturbance_point) > 42.0:
				velocity = _pursuit_heading((disturbance_point - global_position).normalized()) * move_speed * 0.57
			elif global_position.distance_to(home_position) > 32.0:
				velocity = (home_position - global_position).normalized() * move_speed * 0.65
			else:
				velocity = Vector2.ZERO
		PURSUE:
			if distance > notice_range * 1.55 or global_position.distance_to(home_position) > notice_range * 1.9:
				state = REST
				velocity = Vector2.ZERO
			elif archetype == "occultist":
				if distance < 340.0 and _can_see_player(girl) and distance > 75.0:
					_start_warning(offset, 1.05)
				elif distance < 175.0:
					velocity = _pursuit_heading(-offset.normalized()) * move_speed * 0.80
				else:
					velocity = _pursuit_heading(offset.normalized()) * move_speed * 0.84
			elif archetype == "blade_hunter" and not is_elite and flank_cooldown <= 0.0 and distance > attack_distance + 22.0 and distance < attack_distance + 165.0 and _can_see_player(girl):
				# Short, collision-aware circling before committing to the player.
				# No extra hitboxes, no change to attack interval or damage.
				state = CIRCLE
				remaining = 0.42
				flank_cooldown = 5.9
				flank_side = -1.0 if posmod(loot_seed + attack_pattern_count, 2) == 0 else 1.0
				last_target = offset.normalized()
			elif distance < attack_distance and _can_see_player(girl):
				if archetype == "blade_hunter" and attack_pattern_count % 3 == 2 and feint_cooldown <= 0.0:
					_start_feint(offset)
				else:
					_start_warning(offset, windup_duration)
			else:
				velocity = _pursuit_heading(offset.normalized()) * move_speed
		CIRCLE:
			var circle_sideways: Vector2 = Vector2(-last_target.y, last_target.x) * flank_side
			var circle_drift: Vector2 = (circle_sideways * 0.83 + offset.normalized() * 0.32).normalized()
			velocity = _pursuit_heading(circle_drift) * move_speed * 0.72
			if remaining <= 0.0 or distance < attack_distance * 0.85:
				state = PURSUE
		FEINT:
			# A clearly different, dimmer warning. Sidesteps for 0.30 s, then
			# begins the normal telegraphed real strike. Never deals damage.
			velocity = Vector2(-last_target.y, last_target.x) * (move_speed * 0.55 * feint_side)
			if remaining <= 0.0:
				_start_warning(girl.global_position - global_position, windup_duration * 0.92)
		WARN:
			velocity = Vector2.ZERO
			if remaining <= 0.0:
				_emit_attack_release_cue()
				match archetype:
					"bell_keeper", "blade_hunter":
						state = LUNGE
						remaining = 0.32 if archetype == "bell_keeper" else 0.23
					"occultist":
						_release_hex_bolt(girl)
						attack_visual_hold = 0.42
						strike_done = true
						state = RECOVER
						remaining = 1.65
					_:
						var in_reach: bool = distance < attack_distance + (42.0 if archetype == "warder" else 27.0)
						var in_arc: bool = archetype == "warder" or (distance > 0.01 and last_target.dot(offset.normalized()) > 0.15)
						if not strike_done and in_reach and in_arc:
							if girl.has_method("register_confirmed_evade"):
								girl.call("register_confirmed_evade", self, global_position)
							girl.call("receive_damage", strike_damage, global_position)
						strike_done = true
						state = RECOVER
						remaining = 0.84 if archetype == "mourner" else 1.12
		LUNGE:
			var lunge_speed: float = 4.6 if archetype == "bell_keeper" else 3.4
			velocity = last_target * move_speed * lunge_speed
			var reach: float = 76.0 if archetype == "bell_keeper" else 63.0
			if not strike_done and distance < reach and distance > 0.01 and last_target.dot(offset.normalized()) > -0.1:
				if girl.has_method("register_confirmed_evade"):
					girl.call("register_confirmed_evade", self, global_position)
				girl.call("receive_damage", strike_damage, global_position)
				strike_done = true
			if remaining <= 0.0:
				state = RECOVER
				if archetype == "blade_hunter" and not strike_done:
					# A whiffed lunge has a clearly exposed recovery; players can
					# exploit it using the pre-existing counter/damage system.
					opening_left = 0.90
				remaining = 1.30 if archetype == "bell_keeper" else (1.20 if opening_left > 0.0 else 0.94)
		RECOVER:
			velocity = Vector2.ZERO
			if archetype == "occultist" and remaining > 0.60 and distance < 450.0:
				# A short sideways release-step means ranged foes do not stand
				# completely still; it remains collision-aware and slow.
				var recover_sideways: Vector2 = Vector2(-offset.y, offset.x).normalized()
				var drift_side: float = -1.0 if posmod(occultist_bolt_count + loot_seed, 2) == 0 else 1.0
				var recover_drift: Vector2 = recover_sideways * drift_side
				if distance < 135.0:
					recover_drift = (recover_drift * 0.55 - offset.normalized() * 0.55).normalized()
				velocity = _pursuit_heading(recover_drift) * move_speed * 0.43
			if remaining <= 0.0:
				state = PURSUE
		STAGGER:
			velocity = -last_target * 55.0
			if remaining <= 0.0:
				state = PURSUE
	# Short, collision-aware physical flinch on confirmed damage. Unlike
	# a stun, this doesn't reset the attack clock or change enemy stats.
	if contact_push_left > 0.0:
		contact_push_left = maxf(0.0, contact_push_left - delta)
		velocity += contact_push_velocity * (contact_push_left / 0.12)
	velocity *= frost_speed_factor
	if state in [REST, PURSUE, CIRCLE]:
		velocity = FIRE_STEERING.avoid_fire(self, velocity)
	move_and_slide()

func on_environment_threat(world_point: Vector2, seconds: float) -> void:
	if hp <= 0.0 or state in [WARN, FEINT, RECOVER, STAGGER, LUNGE, CIRCLE]:
		return
	fire_alert_point = world_point
	fire_alert_left = maxf(fire_alert_left, clampf(seconds, 0.3, 3.0))

func on_world_disturbance(world_point: Vector2, seconds: float) -> void:
	if hp <= 0.0 or state in [WARN, FEINT, RECOVER, STAGGER, LUNGE, CIRCLE]:
		return
	disturbance_point = world_point
	disturbance_left = maxf(disturbance_left, clampf(seconds, 0.4, 4.0))

func _start_feint(offset: Vector2) -> void:
	state = FEINT
	remaining = 0.30
	active_warning_duration = 0.30
	strike_done = false
	feint_cooldown = 5.0
	feint_side = -1.0 if posmod(attack_pattern_count + loot_seed, 2) == 0 else 1.0
	last_target = offset.normalized() if offset.length_squared() > 0.001 else Vector2.DOWN

func _start_warning(offset: Vector2, windup: float) -> void:
	attack_pattern_count += 1
	state = WARN
	remaining = windup
	active_warning_duration = maxf(0.05, windup)
	strike_done = false
	velocity = Vector2.ZERO
	last_target = offset.normalized() if offset.length_squared() > 0.001 else Vector2.DOWN


func _emit_attack_release_cue() -> void:
	# A small, archetype-tinted release spark distinguishes the moment the
	# warning becomes an actual attack, without adding another hitbox.
	var root: Node = get_tree().current_scene
	if root == null or get_tree().get_nodes_in_group("combat_feedback_v157").size() >= 18:
		return
	var fx: Node2D = Node2D.new()
	fx.set_script(COMBAT_RESPONSE_V157)
	fx.set("kind", "release")
	fx.set("direction", last_target)
	fx.set("tint", Color("b38ace") if archetype == "occultist" else (Color("e8ad83") if archetype == "warder" else Color("d7a2a2")))
	root.add_child(fx)
	fx.global_position = global_position + last_target * 25.0 + Vector2(0.0, -30.0)

func _release_hex_bolt(girl: CharacterBody2D) -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var bolt: Node2D = HEX_BOLT_SCENE.instantiate() as Node2D
	root.add_child(bolt)
	if root.has_method("track_room_effect"):
		root.call("track_room_effect", bolt)
	var origin: Vector2 = global_position + Vector2(0, -34) + last_target * 35.0
	bolt.global_position = origin
	var target_pos: Vector2 = girl.global_position + Vector2(0, -14)
	bolt.set("heading", (target_pos - origin).normalized())
	bolt.set("caster_rid", get_rid())
	bolt.set("damage", strike_damage)
	# Every third occultist bolt has a shallow, readable weaving trajectory.
	# Still ONE raycast projectile and the exact same per-bolt damage.
	occultist_bolt_count += 1
	bolt.set("curved_flight", occultist_bolt_count % 3 == 0)
	bolt.set("curve_sign", -1.0 if posmod(occultist_bolt_count + loot_seed, 2) == 0 else 1.0)


# Local obstacle steering rather than always running into the nearest wall.
# This is deliberately lightweight: rooms have hand-editable collision geometry
# but no automatically generated navmesh yet.
func _pursuit_heading(desired: Vector2) -> Vector2:
	var origin: Vector2 = global_position + Vector2(0, -20)
	var options: Array[float] = [0.0, 0.40, -0.40, 0.82, -0.82, 1.42, -1.42, 2.2, -2.2]
	var best: Vector2 = Vector2.ZERO
	var best_score: float = -INF
	for angle in options:
		var direction: Vector2 = desired.rotated(angle)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(origin, origin + direction * 112.0)
		query.collision_mask = 2
		query.exclude = [get_rid()]
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			continue
		var score: float = direction.dot(desired) - absf(angle) * 0.075
		if score > best_score:
			best = direction
			best_score = score
	return best

func _can_see_player(girl: CharacterBody2D) -> bool:
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -30), girl.global_position + Vector2(0, -30))
	ray.collision_mask = 2
	ray.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func offers_backstep_counter(player_position: Vector2) -> bool:
	# Telegraph must be nearing completion and the opponent in striking range.
	# Enemies without this method do not accidentally award a counterattack.
	return hp > 0.0 and state == WARN and remaining <= 0.44 and remaining > 0.0 and global_position.distance_to(player_position) < attack_distance + 115.0

func on_hook_yank(destination: Vector2, strength: float) -> void:
	if hp <= 0.0:
		return
	hook_yank_direction = (destination - global_position).normalized()
	hook_yank_speed = strength * (0.46 if is_elite else 1.0)
	hook_yank_left = 0.14 if is_elite else 0.32
	state = STAGGER
	remaining = 0.19 if is_elite else 0.48
	poise_damage = 0.0
	stagger_resistance = maxf(stagger_resistance, 0.8)

func apply_frost_slow(seconds: float, speed_factor: float) -> void:
	frost_slow_left = maxf(frost_slow_left, seconds)
	var safe_factor: float = maxf(0.72 if is_elite else 0.40, speed_factor)
	frost_speed_factor = minf(frost_speed_factor, clampf(safe_factor, 0.40, 1.0))

func hit(amount: float, poise_multiplier: float = 1.0) -> void:
	if Engine.is_editor_hint() or hp <= 0.0:
		return
	# A whiffed enemy attack creates a real punish window: not just UI decoration.
	var applied_damage: float = amount * (1.16 if state == RECOVER else 1.0)
	hp = maxf(0.0, hp - applied_damage)
	stagger_flash = 0.22
	hit_number_time = 0.64
	recent_hit = roundi(applied_damage)
	# The sprite and its collider travel together; obstacles are respected.
	# Elites resist displacement. This is not extra hit damage.
	var source: Node2D = get_tree().get_first_node_in_group("ghost_girl_player") as Node2D
	var away: Vector2 = global_position - source.global_position if source != null else -last_target
	contact_push_velocity = away.normalized() * clampf(applied_damage * 2.4, 26.0, 90.0) * (0.40 if is_elite else 1.0)
	contact_push_left = 0.12
	var impact: Node2D = Node2D.new()
	impact.set_script(HIT_EFFECT_SCRIPT)
	get_tree().current_scene.add_child(impact)
	impact.global_position = global_position + Vector2(0, -36)
	PHYSICAL_FEEL.burst(get_tree().current_scene, global_position + Vector2(0, -30), "flesh", 0.70 if is_elite else 0.54, -last_target, loot_seed + recent_hit)
	poise_damage += applied_damage * poise_multiplier
	if hp <= 0.0:
		_begin_enemy_death()
	elif stagger_resistance <= 0.0 and poise_damage >= (72.0 if is_elite else (26.0 if archetype == "mourner" else (43.0 if archetype in ["warder", "blade_hunter"] else (35.0 if archetype == "occultist" else 55.0)))):
		# Heavy hits or repeated deliberate strikes break balance. One light
		# strike does not permanently interrupt an armored enemy's attack.
		state = STAGGER
		remaining = 0.32 if archetype == "mourner" else 0.25
		poise_damage = 0.0
		stagger_resistance = 1.3
		PHYSICAL_FEEL.burst(get_tree().current_scene, global_position + Vector2(0.0, -35.0), "poise", 0.90 if is_elite else 0.73, -last_target, loot_seed + recent_hit)

func _process(delta: float) -> void:
	scene_time += delta
	_update_enemy_animation()
	queue_redraw()


func _illustrated_enemy() -> bool:
	return illustrated_body != null and illustrated_body.visible and illustrated_body.sprite_frames != null


func _update_enemy_animation(force: bool = false) -> void:
	# Runs in the editor as well, so placed enemies have an editable art preview.
	if illustrated_body == null:
		return
	var wants_art: bool = archetype in ["blade_hunter", "occultist"]
	if not wants_art:
		illustrated_body.visible = false
		configured_sprite_archetype = ""
		return
	illustrated_body.visible = true
	if configured_sprite_archetype != archetype:
		illustrated_body.sprite_frames = BLADE_HUNTER_FRAMES if archetype == "blade_hunter" else OCCULTIST_FRAMES
		configured_sprite_archetype = archetype
		force = true
	var desired: String = "idle"
	if death_in_progress:
		desired = "death"
	elif state == STAGGER:
		desired = "hit"
	elif state in [WARN, FEINT]:
		desired = "windup"
	elif state == LUNGE or attack_visual_hold > 0.0:
		desired = "attack"
	elif state == RECOVER:
		desired = "recover"
	elif state == CIRCLE:
		desired = "walk"
	elif velocity.length_squared() > 260.0:
		desired = "walk"
	if force or illustrated_body.animation != desired:
		illustrated_body.play(desired)
		illustrated_body.frame = 0
	if not death_in_progress:
		# The artwork faces slightly left; mirror to track a target on the right.
		if absf(last_target.x) > 0.12:
			illustrated_body.flip_h = last_target.x > 0.0
		illustrated_body.modulate = Color(1.0, 0.82, 0.82) if stagger_flash > 0.0 else (Color(0.76, 0.86, 1.0) if frost_slow_left > 0.0 else Color.WHITE)
	if Engine.is_editor_hint():
		illustrated_body.stop()
		illustrated_body.frame = 0


func _begin_enemy_death() -> void:
	if death_in_progress:
		return
	var root: Node = get_tree().current_scene
	if root != null:
		var death_flash: Node2D = Node2D.new()
		death_flash.set_script(DEATH_FX)
		death_flash.set("kind", "hunter")
		death_flash.set("seed_value", loot_seed)
		death_flash.set("elite", is_elite)
		death_flash.set("ink", Color("d5aaa5") if archetype in ["mourner", "warder", "blade_hunter"] else Color("b6a1d8"))
		death_flash.set("accent", Color("f7ddd4") if archetype in ["mourner", "warder", "blade_hunter"] else Color("e9dfff"))
		root.add_child(death_flash)
		death_flash.global_position = global_position
	# Physical bodies leave a low, muted puddle; spectral foes leave dark ichor.
	PHYSICAL_FEEL.pool(get_parent(), global_position, loot_seed, 1.43 if is_elite else 0.92, Color("342039") if archetype == "occultist" else Color("491e2b"))
	PHYSICAL_FEEL.burst(get_parent(), global_position + Vector2(0, -16), "flesh", 1.1 if is_elite else 0.75, last_target, loot_seed)
	# Enemies no longer print equipment every kill. Placed chests and quest
	# pickups are deliberately unaffected by this roll.
	var drop_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	drop_rng.seed = absi(loot_seed) + 51979 + absi(str(name).hash())
	if root != null and loot_template != null and root.has_method("spawn_world_loot") and drop_rng.randf() < (0.42 if is_elite else 0.14):
		root.call("spawn_world_loot", loot_template, loot_seed + drop_rng.randi_range(1, 99999), "random", global_position)
	if illustrated_body == null or not (archetype in ["blade_hunter", "occultist"]):
		queue_free()
		return
	death_in_progress = true
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	set_physics_process(false)
	_update_enemy_animation(true)
	var fade: Tween = create_tween()
	fade.tween_interval(0.86)
	fade.tween_property(illustrated_body, "modulate:a", 0.0, 0.22)
	fade.tween_callback(queue_free)

func _draw() -> void:
	# Legacy silhouettes remain only for mourner/warder/bell_keeper.
	# New AnimatedSprite2D frames replace them for blade_hunter and occultist.
	draw_circle(Vector2(0, 11), 18.0, Color(0, 0, 0, 0.20))
	if not _illustrated_enemy():
		var gray: Color = Color("a1a0a4") if archetype == "mourner" else (Color("8c7a76") if archetype == "blade_hunter" else (Color("706b80") if archetype == "occultist" else Color("77767d")))
		if stagger_flash > 0.0:
			gray = Color("dbc6bb")
		var sway: float = sin(scene_time * 2.0) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(-25, 0),Vector2(-30, -25),Vector2(-17, -57),Vector2(18, -57),Vector2(30, -24),Vector2(25, 0),Vector2(10, -6),Vector2(0, 4),Vector2(-10, -6)]), Color(gray.r * 0.55, gray.g * 0.53, gray.b * 0.59, 0.96))
		draw_circle(Vector2(0, -51 + sway), 19.0 if archetype == "mourner" else 24.0, gray)
		draw_circle(Vector2(-7, -54 + sway), 3.2, Color("29181b"))
		draw_circle(Vector2(7, -54 + sway), 3.2, Color("29181b"))
		if archetype == "blade_hunter":
			draw_line(Vector2(-18, -38), Vector2(-49, 3), Color("bcaaa4"), 5.0, true)
			draw_line(Vector2(-47, 1), Vector2(-53, -7), Color("e0c5b0"), 3.0, true)
		if archetype == "occultist":
			draw_circle(Vector2(0, -43), 13, Color(0.54, 0.27, 0.37, 0.18))
			draw_arc(Vector2(0, -42), 18.0, 0, TAU, 22, Color("b08a99"), 2.0, true)
		if archetype == "bell_keeper":
			draw_arc(Vector2(0, -75), 26.0, 0.12, PI - 0.12, 22, Color("c2a48e"), 2.4, true)
			draw_circle(Vector2(0, -80), 6.0, Color("cfab81"))
		if archetype == "warder" or archetype == "bell_keeper":
			draw_line(Vector2(19,-49), Vector2(47,-3), Color("9b8b80"), 6.0, true)
			draw_line(Vector2(34,-9), Vector2(55,-9), Color("c6b5a4"), 4.0, true)
	if frost_slow_left > 0.0:
		draw_arc(Vector2(0, 11), 34.0, 0.0, TAU, 32, Color(0.61, 0.82, 1.0, 0.43), 1.6, true)
		for mark in range(5):
			var phase: float = float(mark) * TAU / 5.0 + scene_time * 0.28
			draw_circle(Vector2.from_angle(phase) * 32.0 + Vector2(0, -20), 1.8, Color("d8efff"))
		var ink: Color = Color("e3cebb", hit_number_time)
		draw_string(ThemeDB.fallback_font, Vector2(-26.0, -116.0 - (0.64 - hit_number_time) * 30.0), str(recent_hit), HORIZONTAL_ALIGNMENT_CENTER, 52.0, 16, ink)
	if hp < maximum_health:
		draw_rect(Rect2(-26, -96, 52, 5), Color("1a1217"), true)
		draw_rect(Rect2(-25, -95, 50.0 * hp / maximum_health, 3), Color("9d6569"), true)
	if state == RECOVER:
		# Restrained pale ring conveys the punishable recovery opportunity.
		draw_arc(Vector2(0, 13), 30.0, 0.0, TAU, 28, Color(0.77, 0.72, 0.62, 0.43), 2.0, true)
		if opening_left > 0.0:
			# An interrupted crescent above a whiffed hunter communicates
			# a genuine opening without any additional floating HUD text.
			var exposure: float = minf(1.0, opening_left / 0.3)
			for arc_index in range(3):
				var begin: float = PI * (1.04 + float(arc_index) * 0.32)
				draw_arc(Vector2(0, -54), 16.0, begin, begin + 0.20, 6, Color(0.98, 0.84, 0.67, 0.56 * exposure), 1.8, true)
	if is_elite and hp > 0.0:
		draw_arc(Vector2(0, 11), 40.0, 0.0, TAU, 38, Color(0.84, 0.53, 0.69, 0.45), 2.0, true)
	if state == FEINT:
		# Pale broken arc means a fake, not a hitbox. The later normal red
		# warning still shows before the actual lunge.
		var direction_angle: float = last_target.angle()
		var center: Vector2 = Vector2(0.0, -15.0)
		for i in range(4):
			var start_angle: float = direction_angle - 0.65 + float(i) * 0.38
			draw_arc(center, 28.0, start_angle, start_angle + 0.18, 5, Color(0.66, 0.69, 0.94, 0.46), 1.7, true)
	if state == WARN:
		var tell_progress: float = clampf(1.0 - remaining / maxf(0.05, active_warning_duration), 0.0, 1.0)
		var pulse: float = sin(scene_time * 13.0) * 0.08
		var warning_color: Color = Color(0.88, 0.44, 0.39, 0.57 + pulse)
		var sweep: float = PI if archetype == "warder" else (0.57 if archetype == "bell_keeper" else (0.38 if archetype == "blade_hunter" else 1.1))
		var angle: float = last_target.angle()
		draw_arc(Vector2.ZERO, attack_distance + (35.0 if archetype == "warder" else 0.0), -PI if archetype == "warder" else angle - sweep, PI if archetype == "warder" else angle + sweep, 52, warning_color, 3.0, true)
		# The thin inner sweep closes as the real windup reaches its release;
		# a different tint per archetype makes attack timing readable.
		var tell_color: Color = Color("b7a1ed") if archetype == "occultist" else (Color("efc88f") if archetype == "warder" else Color("edb0a2"))
		var tell_radius: float = 40.0 if archetype == "occultist" else 29.0
		draw_arc(Vector2(0, -16), tell_radius, angle - 0.85, angle - 0.85 + tell_progress * 1.7, 20, Color(tell_color.r, tell_color.g, tell_color.b, 0.18 + 0.50 * tell_progress), 1.6, true)
		if tell_progress > 0.78:
			var peak: float = (tell_progress - 0.78) / 0.22
			draw_circle(last_target * (24.0 if archetype == "blade_hunter" else 14.0) + Vector2(0, -24), 2.0 + peak * 2.0, Color(tell_color.r, tell_color.g, tell_color.b, 0.25 + peak * 0.45))
		if archetype == "bell_keeper":
			draw_line(Vector2.ZERO, last_target * (attack_distance + 155), Color(0.91, 0.48, 0.40, 0.49), 4.0, true)
		elif archetype == "occultist":
			draw_line(Vector2(0, -34), last_target * 310.0, Color(0.72, 0.39, 0.49, 0.70), 3.0, true)
			draw_circle(Vector2(0, -34), 21.0 + 5.0 * sin(scene_time * 15.0), Color(0.77, 0.48, 0.56, 0.12))
	elif state == LUNGE:
		draw_line(-last_target * 20.0, last_target * 57.0, Color(0.92, 0.53, 0.42, 0.53), 5.0, true)

# Aim at the illustrated body, not the much lower movement/feet collider.
func spell_aim_point() -> Vector2:
	return $SpellHurtbox/Body.global_position if has_node("SpellHurtbox/Body") else global_position + Vector2(0, -27)
