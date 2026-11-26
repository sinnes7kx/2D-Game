extends CharacterBody2D
## Original 2D Ghost Girl. 4 directions, editor-authored SpriteFrames.
## New gesture frames (hook_front / back / left / right) contain the ornate
## rose hook at her hand, with slight reach/lean animation during casting.

const BOW_ARROW_SCENE: PackedScene = preload("res://scenes/bow_arrow_v126.tscn")
const BOW_RELEASE_FX: Script = preload("res://scripts/bow_release_v127.gd")
const VISUAL_CHOICES_V216 = preload("res://scripts/visual_choices_v216.gd")
const WAND_ANCHORS_V216 = preload("res://scripts/wand_anchors_v216.gd")
const EXTRA_ANIMATIONS = preload("res://scripts/ghost_animation_library.gd")
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const WALK_V223 = preload("res://scripts/walk_inbetweens_v223.gd")
const MOTION_V225 = preload("res://scripts/action_motion_samples_v225.gd")
const SWORD_V224 = preload("res://scripts/sword_attack_frames_v224.gd")
const STEADY_IDLE = preload("res://scripts/steady_weapon_idles_v195.gd")
const AIR_V203 = preload("res://scripts/airborne_attacks_v203.gd")
const HEAVY_V192 = preload("res://scripts/heavy_weapon_art_v192.gd")
const SCYTHE_V190 = preload("res://scripts/scythe_art_v190.gd")
const SCYTHE_RIG_V190 = preload("res://scripts/scythe_rig_v190.gd")
const FRAME_GUARD_V186 = preload("res://scripts/frame_guard_v186.gd")
const DAGGER_THRUST_V186 = preload("res://scripts/dagger_thrust_v186.gd")
const V172_POSE_SCRIPT = preload("res://scripts/v172_weapon_pose.gd")
const V173_DUAL_DAGGER_SCRIPT = preload("res://scripts/v173_dual_daggers.gd")
const V174_DUAL_SWORD_SCRIPT = preload("res://scripts/v174_dual_swords.gd")
const V175_CLEAN_WEAPON_BODY = preload("res://scripts/v175_hookfree_weapon_body.gd")
const SWING_SFX: AudioStream = preload("res://assets/audio/melee_swing.wav")
const HIT_SFX: AudioStream = preload("res://assets/audio/melee_hit.wav")
const ROSE_SLASH_FX: SpriteFrames = preload("res://resources/rose_slash_fx.tres")
const SPECTACLE: Script = preload("res://scripts/weapon_spectacle.gd")
const IMPACT_PRESTIGE: Script = preload("res://scripts/impact_prestige_v116.gd")
const PHYSICAL_FEEL: Script = preload("res://scripts/impact_spawner_v149.gd")
const COMBAT_JUICE: Script = preload("res://scripts/combat_juice_v194.gd")
const SWING_WAKE: Script = preload("res://scripts/swing_wake_v198.gd")
const TIP_EXTENSION_V198: Script = preload("res://scripts/weapon_tip_extension_v198.gd")
const RIPOSTE_SFX: AudioStream = preload("res://assets/audio/riposte_chime_v113.wav")
const COMBAT_RESPONSE_V157: Script = preload("res://scripts/combat_response_v157.gd")
const DODGE_SFX: AudioStream = preload("res://assets/audio/dodge_wisp.wav")
const HOOK_SFX: AudioStream = preload("res://assets/audio/hook_chime.wav")
const WALK_SPEED: float = 175.0
const SPRINT_SPEED: float = 246.0
const MOVE_ACCELERATION: float = 2020.0
const MOVE_BRAKE: float = 2900.0
const TURN_ACCELERATION: float = 2170.0
const SPRINT_STAMINA_PER_SECOND: float = 9.0
const BASE_ART_POS: Vector2 = Vector2(0.0, -57.0)
const BASE_ART_SCALE: float = 0.52
const THROW_DURATION: float = 0.38
const THROW_RELEASE_TIME: float = 0.17
const HOOK_GESTURE_TIME: float = 0.42
const SPELL_CAST_DURATION: float = 0.48
const SPELL_SHOT_TIME: float = 0.22
const MAX_STAMINA: float = 100.0
const LIGHT_ATTACK_COST: float = 14.0
const HEAVY_ATTACK_COST: float = 30.0
const DODGE_COST: float = 24.0
const DODGE_DURATION: float = 0.33
const DODGE_SPEED: float = 362.0
const JUMP_COST: float = 16.0
const JUMP_DURATION: float = 0.62
const JUMP_SPEED: float = 208.0
const JUMP_ATTACK_TRIGGER: float = 0.58
const JUMP_ATTACK_DAMAGE_BONUS: float = 1.10
const JUMPABLE_BARRIER_MASK: int = 32 # Dedicated low hedge layer; enemy layer remains unaffected.
const MAX_DEW: int = 3
const HEAL_WINDUP: float = 0.63
const LOCK_RANGE: float = 620.0
const INPUT_BUFFER: float = 0.38
const AIR_LANDING_BUFFER: float = 0.19  # Accept dodge/follow-up just before feet touch the ground.
const STAMINA_RECOVERY_WAIT: float = 0.50


var world
# Isolated character-screen actor, never registered as a gameplay player.
var equipment_preview_only: bool = false
var facing: Vector2 = Vector2.DOWN
var facing_name: String = "front"
var carrying: RigidBody2D = null
var is_throwing: bool = false
var throw_time: float = 0.0
var throw_released: bool = false
var throw_direction: Vector2 = Vector2.DOWN
var hook_gesture_left: float = 0.0
var hook_direction: Vector2 = Vector2.DOWN
var visual_time: float = 0.0
var health: float = 100.0
var stamina: float = MAX_STAMINA
var bow_time_left: float = 0.0
var bow_duration: float = 0.0
var bow_release_done: bool = false
var bow_charge: bool = false
var bow_firing_direction: Vector2 = Vector2.RIGHT
# v1.39: explicit charge -> hold -> release state, no timer-fired charged arrows.
const BOW_FULL_DRAW_TIME: float = 0.46
var bow_draw_active: bool = false
var bow_draw_time: float = 0.0
var bow_draw_airborne: bool = false
var attack_time_left: float = 0.0
var attack_duration: float = 0.0
# Retain the timed clip rate when resuming confirmed-contact hitstop.
var action_animation_rate: float = 1.0
var attack_hit_done: bool = false
var heavy_attack: bool = false
# v2.12 single dagger only: hold heavy for a bounded, single-hit stab.
const DAGGER_CHARGE_MIN: float = 0.16
const DAGGER_CHARGE_MAX: float = 0.58
var dagger_charge_active: bool = false
var dagger_charge_time: float = 0.0
var active_attack_style: String = "unarmed"
var attack_hit_threshold: float = 0.58
var attack_direction: Vector2 = Vector2.DOWN
var buffered_attack_direction: Vector2 = Vector2.ZERO
var buffered_attack_valid: bool = false
var dodge_time_left: float = 0.0
var dodge_direction: Vector2 = Vector2.DOWN
var jump_time_left: float = 0.0
var jump_duration: float = 0.0
var jump_direction: Vector2 = Vector2.DOWN
var jump_origin: Vector2 = Vector2.ZERO
var jump_attack_active: bool = false
var jump_attack_triggered: bool = false
var rally_pool: float = 0.0
var rally_time_left: float = 0.0
var invulnerable_time: float = 0.0
var spell_time_left: float = 0.0
var spell_shot: bool = false
var spell_is_moonfall: bool = false
var moonfall_cooldown: float = 0.0
var astral_cooldown: float = 0.0
var roses_cooldown: float = 0.0
var special_spell_kind: String = ""
var spell_cast_duration: float = SPELL_CAST_DURATION
var spell_shot_time: float = SPELL_SHOT_TIME
var wand_heavy_attack: bool = false
var spell_direction: Vector2 = Vector2.RIGHT
var spell_aim_point: Vector2 = Vector2.ZERO
var spell_cooldown: float = 0.0
var blink_cooldown: float = 5.0
var blink_active: float = 0.0
var blink_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var dew_charges: int = MAX_DEW
var healing_time_left: float = 0.0
var lock_target: Node2D = null
var counter_window: float = 0.0
var backstep_counter_armed: bool = false
var precision_evade_registered: bool = false
var backstep_origin: Vector2 = Vector2.ZERO
var queued_action: String = ""
var queue_time_left: float = 0.0
var stamina_recovery_left: float = 0.0
var combo_step: int = 0
var combo_grace: float = 0.0
var previous_light: bool = false
var camera_kick: float = 0.0
var hurt_recoil_left: float = 0.0
var hurt_direction: Vector2 = Vector2.DOWN
var hitstop_left: float = 0.0
var landing_recoil_left: float = 0.0
var camera_push: Vector2 = Vector2.ZERO
var sprint_dust_time: float = 0.0
const LANDING_RECOIL: float = 0.145


@onready var body_art: AnimatedSprite2D = $Ghost
@onready var hand: Marker2D = $Hand
@onready var action_sfx: AudioStreamPlayer2D = $ActionSFX
@onready var rose_hook = $RoseHook

func _ready() -> void:
	# Only the physical player root is interpolated. The frame-driven art,
	# camera and hand keep their independent render-time local transforms.
	for child in get_children():
		child.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	EXTRA_ANIMATIONS.install(body_art)
	# Replace only two malformed baked-weapon ATTACKS with the untouched, approved
	# body action frames; the v172 pose layer supplies the weapon per frame.
	V172_POSE_SCRIPT.install_attack_frames(body_art)
	V173_DUAL_DAGGER_SCRIPT.install_animations(body_art)
	V174_DUAL_SWORD_SCRIPT.install_animations(body_art)
	V175_CLEAN_WEAPON_BODY.install(body_art)
	DAGGER_THRUST_V186.install(body_art)
	FRAME_GUARD_V186.install(body_art)
	SCYTHE_V190.install(body_art)
	HEAVY_V192.install(body_art)
	WAND_ANCHORS_V216.install(body_art)
	GENTLE.install(body_art)
	STEADY_IDLE.install(body_art)
	AIR_V203.install(body_art)
	if not equipment_preview_only:
		MOTION_V225.install(body_art)
	var scythe_rig: Node2D = SCYTHE_RIG_V190.new()
	scythe_rig.name = "ScytheRigV190"
	body_art.add_child(scythe_rig)
	var blade_tips: Node2D = TIP_EXTENSION_V198.new() as Node2D
	blade_tips.name = "WeaponTipExtensionV198"
	body_art.add_child(blade_tips)
	if equipment_preview_only:
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		collision_layer = 0
		collision_mask = 0
		set_physics_process(false)
		set_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)
		body_art.play("idle_front")
		_update_hand()
		return
	# Preview never walks; avoid allocating its extra locomotion textures.
	WALK_V223.install(body_art)
	# After AIR installation: airborne art and frame-indexed charge gates
	# remain unchanged. Only ordinary ground sword clips gain samples.
	SWORD_V224.install(body_art)
	collision_mask |= JUMPABLE_BARRIER_MASK
	add_to_group("ghost_girl_player")
	blink_rng.randomize()
	blink_cooldown = blink_rng.randf_range(4.5, 9.0)
	body_art.play("idle_front")
	_update_hand()

# Reset interpolation AFTER a teleport so rooms and shrines never streak.
func snap_render_after_teleport() -> void:
	reset_physics_interpolation()
	var camera: Camera2D = get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.reset_smoothing()

func _physics_process(delta: float) -> void:
	if world == null:
		return
	if world.ui.is_menu_open() or world.ui.has_cursor_item():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	# Short local hitstop: freeze only Ghost Girl, never the whole world or HUD.
	if hitstop_left > 0.0:
		if Input.is_action_just_pressed("dodge"):
			_queue_combat("dodge")
		elif Input.is_action_just_pressed("attack_heavy"):
			_queue_combat("heavy")
		elif Input.is_action_just_pressed("attack_light"):
			_queue_combat("light")
		hitstop_left = maxf(0.0, hitstop_left - delta)
		velocity = Vector2.ZERO
		if hitstop_left <= 0.0:
			_resume_timed_action()  # Preserve both the active frame and its rate.
		move_and_slide()
		return
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	counter_window = maxf(0.0, counter_window - delta)
	stamina_recovery_left = maxf(0.0, stamina_recovery_left - delta)
	spell_cooldown = maxf(0.0, spell_cooldown - delta)
	moonfall_cooldown = maxf(0.0, moonfall_cooldown - delta)
	astral_cooldown = maxf(0.0, astral_cooldown - delta)
	roses_cooldown = maxf(0.0, roses_cooldown - delta)
	queue_time_left = maxf(0.0, queue_time_left - delta)
	combo_grace = maxf(0.0, combo_grace - delta)
	if queue_time_left <= 0.0:
		queued_action = ""
		buffered_attack_valid = false
	_validate_lock_target()
	if hurt_recoil_left > 0.0:
		hurt_recoil_left = maxf(0.0, hurt_recoil_left - delta)
		velocity = hurt_direction * (175.0 * hurt_recoil_left / 0.19)
		move_and_slide()
		return
	if Input.is_action_just_pressed("target_lock") and healing_time_left <= 0.0:
		_toggle_lock_target()
	if Input.is_action_just_pressed("use_dew") and healing_time_left <= 0.0 and attack_time_left <= 0.0 and dodge_time_left <= 0.0 and jump_time_left <= 0.0:
		_begin_heal()
	if healing_time_left > 0.0:
		healing_time_left = maxf(0.0, healing_time_left - delta)
		velocity = Vector2.ZERO
		_play_if_changed(_weapon_motion_prefix(false) + facing_name)
		if healing_time_left <= 0.0:
			health = minf(maximum_health(), health + maximum_health() * 0.43)
			world.ui.set_health(health, maximum_health())
		move_and_slide()
		return
	rally_time_left = maxf(0.0, rally_time_left - delta)
	if rally_time_left <= 0.0:
		rally_pool = 0.0
	if attack_time_left <= 0.0 and bow_time_left <= 0.0 and not bow_draw_active and dodge_time_left <= 0.0 and jump_time_left <= 0.0 and stamina_recovery_left <= 0.0:
		stamina = minf(MAX_STAMINA, stamina + 39.0 * (1.0 + _stat("stamina_recovery_pct") / 100.0) * delta)
	world.ui.set_stamina(stamina, MAX_STAMINA)
	# HOLD is a real state: frame 5 stays visible for as long as RMB is held.
	# A released button fires exactly one arrow and plays recovery frames 6-7.
	if bow_draw_active:
		# v1.42: a fully drawn bow may be carried into a jump. This makes
		# aerial charged targets practical instead of demanding the entire
		# 0.46-second draw inside the 0.56-second jump animation.
		if jump_time_left <= 0.0 and Input.is_action_just_pressed("jump") and stamina >= _action_cost(JUMP_COST, false):
			_begin_jump()
			bow_draw_airborne = true
			var keep_frame: int = mini(5, floori(clampf(bow_draw_time / BOW_FULL_DRAW_TIME, 0.0, 1.0) * 5.0))
			_play_action_frames(AIR_V203.air_name("attack_" + _bow_art_style() + "_heavy_" + facing_name), 0.70)
			body_art.set_frame_and_progress(keep_frame, 0.0)
			body_art.pause()
		_advance_bow_draw(delta)
		if jump_time_left > 0.0:
			_advance_jump(delta)
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		return
	if bow_time_left > 0.0:
		bow_time_left = maxf(0.0, bow_time_left - delta)
		if jump_time_left > 0.0:
			_advance_jump(delta)
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		return
	if jump_time_left > 0.0:
		var started_air_attack: bool = false
		if not jump_attack_active:
			if Input.is_action_just_pressed("attack_heavy") and stamina >= _attack_action_cost(true):
				_begin_jump_attack(false)
				started_air_attack = jump_attack_active
			elif Input.is_action_just_pressed("attack_light") and stamina >= (_attack_action_cost(false) if _weapon_style() == "bow" else _attack_action_cost(true)):
				_begin_jump_attack(true)
				started_air_attack = jump_attack_active
		# A late button press survives the landing transition. It never cancels
		# the airborne attack, skips its stamina cost, or triggers twice.
		if jump_time_left <= AIR_LANDING_BUFFER and not started_air_attack:
			if Input.is_action_just_pressed("dodge"):
				_queue_combat("dodge")
			elif jump_attack_active and Input.is_action_just_pressed("attack_light"):
				_queue_combat("light")
			elif jump_attack_active and Input.is_action_just_pressed("attack_heavy"):
				_queue_combat("heavy")
		_advance_jump(delta)
		move_and_slide()
		return
	if dodge_time_left > 0.0:
		# Late dodge input can buffer a counterstrike rather than vanishing.
		# Do not accept an attack at the start of the retreat as an early cancel.
		if dodge_time_left <= 0.21:
			if Input.is_action_just_pressed("attack_heavy"):
				_queue_combat("heavy")
			elif Input.is_action_just_pressed("attack_light"):
				_queue_combat("light")
		dodge_time_left = maxf(0.0, dodge_time_left - delta)
		velocity = dodge_direction * DODGE_SPEED * (0.52 + 0.48 * dodge_time_left / DODGE_DURATION)
		# Keep the action-specific retreat frames playing; walking would replace
		# them every physics tick and visually erase the backstep.
		move_and_slide()
		if dodge_time_left <= 0.0:
			# A real hostile strike or bolt must have intersected Ghost Girl's
			# active dodge I-frames. Merely retreating near a warning is not enough.
			if backstep_counter_armed and global_position.distance_to(backstep_origin) > 40.0:
				counter_window = 0.62
				stamina = minf(MAX_STAMINA, stamina + 9.0)
				_spawn_precision_feedback("ready", global_position + Vector2(0, -27), -dodge_direction)
				world.ui.set_stamina(stamina, MAX_STAMINA)
			backstep_counter_armed = false
			precision_evade_registered = false
		return
	if attack_time_left > 0.0:
		# Press during late recovery to flow into a follow-up strike or dodge.
		if attack_hit_done and attack_time_left <= 0.25:
			if Input.is_action_just_pressed("dodge"):
				_queue_combat("dodge")
			elif Input.is_action_just_pressed("attack_heavy"):
				_queue_combat("heavy")
			elif Input.is_action_just_pressed("attack_light"):
				_queue_combat("light")
		_advance_attack(delta)
		if queued_action == "dodge" and attack_hit_done and attack_time_left <= 0.16 and stamina >= _action_cost(DODGE_COST, true):
			attack_time_left = 0.0
			queued_action = ""
			_begin_dodge()
			velocity = dodge_direction * DODGE_SPEED
			move_and_slide()
			return
		# A short step during the strike adds reach without turning the attack into a dash.
		var phase: float = 1.0 - attack_time_left / maxf(attack_duration, 0.01)
		var thrust: float = sin(clampf(phase / 0.58, 0.0, 1.0) * PI)
		velocity = attack_direction * (92.0 if active_attack_style == "halberd" else (98.0 if active_attack_style == "scythe" else (105.0 if world.inventory.get_equipped("sword") != null else 65.0))) * thrust
		move_and_slide()
		return
	if spell_time_left <= 0.0 and not is_throwing and hook_gesture_left <= 0.0 and not rose_hook.is_pulling_player():
		if not queued_action.is_empty():
			var choice: String = queued_action
			queued_action = ""
			queue_time_left = 0.0
			if choice == "light" and stamina >= _attack_action_cost(false):
				_begin_weapon_attack(false)
				return
			if choice == "heavy" and stamina >= _attack_action_cost(true):
				_begin_weapon_attack(true)
				return
			if choice == "dodge" and stamina >= _action_cost(DODGE_COST, true):
				_begin_dodge()
				return
			# A buffered input that failed its stamina check must never aim a
			# future unrelated click in the old direction.
			buffered_attack_valid = false
		# Unlock Moonfall in Moonwake Crypt, equip a wand, then press Z.
		if Input.is_action_just_pressed("moonfall_blizzard"):
			if not world.inventory.has_collected("v125_moonfall_unlocked"):
				world.ui.show_pickup("LEARN MOONFALL AT THE FROST RELIQUARY")
			elif world.inventory.get_equipped("wand") == null:
				world.ui.show_pickup("EQUIP A WAND TO CAST MOONFALL")
			elif moonfall_cooldown > 0.0:
				world.ui.show_pickup("MOONFALL IS RECHARGING")
			elif carrying == null and stamina >= _action_cost(37.0, false):
				_begin_spell_cast(false, true)
				moonfall_cooldown = 6.2
			else:
				world.ui.show_pickup("NOT ENOUGH STAMINA FOR MOONFALL")
			return
		# v1.27 discovered area spells. V = Astral Rain, T = Grasping Roses.
		if Input.is_action_just_pressed("astral_rain") or Input.is_action_just_pressed("grasping_roses"):
			var kind: String = "astral" if Input.is_action_just_pressed("astral_rain") else "roses"
			var unlock: String = "v127_astral_rain_unlocked" if kind == "astral" else "v127_grasping_roses_unlocked"
			var cost: float = 40.0 if kind == "astral" else 32.0
			var waiting: float = astral_cooldown if kind == "astral" else roses_cooldown
			if not world.inventory.has_collected(unlock):
				world.ui.show_pickup("STUDY THE MATCHING RELIQUARY IN MOONWAKE CRYPT")
			elif world.inventory.get_equipped("wand") == null:
				world.ui.show_pickup("EQUIP A WAND TO CAST")
			elif waiting > 0.0:
				world.ui.show_pickup("SPELL IS RECHARGING")
			elif carrying == null and stamina >= _action_cost(cost, false):
				_begin_spell_cast_v127(false, false, kind)
				if kind == "astral":
					astral_cooldown = 7.8
				else:
					roses_cooldown = 7.1
			else:
				world.ui.show_pickup("NOT ENOUGH STAMINA")
			return
		if Input.is_action_just_pressed("jump") and stamina >= _action_cost(JUMP_COST, false):
			_begin_jump()
			return
		if Input.is_action_just_pressed("dodge") and stamina >= _action_cost(DODGE_COST, true):
			_begin_dodge()
			return
		if Input.is_action_just_pressed("attack_heavy") and stamina >= _attack_action_cost(true):
			_begin_weapon_attack(true)
			return
		if Input.is_action_just_pressed("attack_light") and stamina >= _attack_action_cost(false):
			_begin_weapon_attack(false)
			return
	# X remains a backward-compatible quick-cast shortcut; mouse buttons are primary.
	if Input.is_action_just_pressed("cast_spell") and spell_time_left <= 0.0 and spell_cooldown <= 0.0 and hook_gesture_left <= 0.0 and not is_throwing and stamina >= _action_cost(LIGHT_ATTACK_COST, false):
		if world.inventory.get_equipped("wand") != null and carrying == null:
			_begin_spell_cast(false)
	if spell_time_left > 0.0:
		if spell_time_left < 0.27:
			if Input.is_action_just_pressed("dodge"):
				_queue_combat("dodge")
			elif Input.is_action_just_pressed("attack_heavy"):
				_queue_combat("heavy")
			elif Input.is_action_just_pressed("attack_light"):
				_queue_combat("light")
		_advance_spell(delta)
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if Input.is_action_just_pressed("interact") and hook_gesture_left <= 0.0 and not is_throwing:
		world.interact()
	if Input.is_action_just_pressed("drop") and not is_throwing:
		world.drop_held(false)
	if Input.is_action_just_pressed("throw") and not is_throwing and carrying != null:
		_begin_throw(world.get_throw_direction())
	if not is_throwing:
		if Input.is_action_just_pressed("hook_object") and rose_hook.try_cast_object():
			_begin_hook_gesture()
		elif Input.is_action_just_pressed("hook_anchor") and rose_hook.try_cast_anchor():
			_begin_hook_gesture()

	if is_throwing:
		_advance_throw(delta)
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if hook_gesture_left > 0.0:
		hook_gesture_left = maxf(0.0, hook_gesture_left - delta)
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if rose_hook.is_pulling_player():
		velocity = rose_hook.pull_velocity()
		_play_if_changed("hook_hold_" + facing_name)
		move_and_slide()  # respects world collisions while being reeled in
		return

	var direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	var touch_vector: Vector2 = world.ui.get_joystick_vector()
	if touch_vector.length_squared() > 0.0064:
		direction = touch_vector
	# Deliberate grounded movement: controlled acceleration, firm braking, and
	# a slight cost for turning sharply instead of instantly floating sideways.
	var moving: bool = direction.length_squared() > 0.01
	var sprinting: bool = moving and Input.is_action_pressed("sprint") and stamina > 12.0
	var speed_bonus: float = world.inventory.get_stat_total("move_speed_pct") if world.inventory != null else 0.0
	var desired_speed: float = (SPRINT_SPEED if sprinting else WALK_SPEED) * (1.0 + speed_bonus / 100.0)
	# Shallow moor water impedes grounded movement; Moonfall's temporary ice
	# restores normal footing. Jumping, dodging and the rose hook are unaffected.
	for water in get_tree().get_nodes_in_group("water_body"):
		if is_instance_valid(water) and water.has_method("movement_multiplier_at"):
			desired_speed *= float(water.call("movement_multiplier_at", global_position))
	var target_velocity: Vector2 = direction.normalized() * desired_speed if moving else Vector2.ZERO
	var turn: bool = moving and velocity.length_squared() > 50.0 and velocity.normalized().dot(direction.normalized()) < 0.22
	var responsiveness: float = TURN_ACCELERATION if turn else (MOVE_ACCELERATION if moving else MOVE_BRAKE)
	velocity = velocity.move_toward(target_velocity, responsiveness * delta)
	if sprinting:
		stamina = maxf(0.0, stamina - SPRINT_STAMINA_PER_SECOND * delta)
		stamina_recovery_left = maxf(stamina_recovery_left, 0.25)
		world.ui.set_stamina(stamina, MAX_STAMINA)
	sprint_dust_time = maxf(0.0, sprint_dust_time - delta)
	if sprinting and velocity.length() > WALK_SPEED * 1.05 and sprint_dust_time <= 0.0:
		sprint_dust_time = 0.28
		PHYSICAL_FEEL.burst(get_tree().current_scene, global_position + Vector2(0, -6), "landing", 0.35, -direction, roundi(visual_time * 51.0))
	if moving:
		blink_active = 0.0
		set_facing(lock_target.global_position - global_position if is_instance_valid(lock_target) else direction)
		var travel_prefix: String = _weapon_motion_prefix(true)
		_play_if_changed(travel_prefix + facing_name)
		body_art.speed_scale = clampf(velocity.length() / WALK_SPEED, 0.75, 1.55)
	else:
		body_art.speed_scale = 1.0
		blink_cooldown -= delta
		if facing_name != "back" and blink_cooldown <= 0.0 and blink_active <= 0.0:
			blink_active = 0.52
			blink_cooldown = blink_rng.randf_range(4.5, 10.5)
		if world.inventory.get_equipped("sword") != null:
			blink_active = 0.0  # Sword poses already have their weapon painted in.
		if blink_active > 0.0:
			blink_active = maxf(0.0, blink_active - delta)
			_play_if_changed("blink_" + facing_name)
		else:
			var rest_prefix: String = _weapon_motion_prefix(false)
			_play_if_changed(rest_prefix + facing_name)
			if rest_prefix != "idle_" and not GENTLE.modular_idle(str(body_art.animation)) and not STEADY_IDLE.matches(str(body_art.animation)):
				body_art.speed_scale = 0.48
	move_and_slide()

func _process(delta: float) -> void:
	visual_time += delta
	landing_recoil_left = maxf(0.0, landing_recoil_left - delta)
	camera_kick = maxf(0.0, camera_kick - delta * 22.0)
	camera_push = camera_push.move_toward(Vector2.ZERO, delta * 85.0)
	if is_instance_valid(get_node_or_null("Camera2D")):
		var cam: Camera2D = $Camera2D
		cam.offset = (Vector2(sin(visual_time * 74.0), cos(visual_time * 59.0)) * camera_kick * 0.72 + camera_push) * COMBAT_JUICE.shake_level
	queue_redraw()
	if not is_instance_valid(body_art):
		return
	if hurt_recoil_left > 0.0:
		var recoil: float = hurt_recoil_left / 0.19
		body_art.position = BASE_ART_POS - hurt_direction * 3.0 * recoil
		body_art.rotation = 0.065 * hurt_direction.x * recoil
		body_art.scale = Vector2.ONE * BASE_ART_SCALE
	elif attack_time_left > 0.0:
		var t: float = 1.0 - attack_time_left / maxf(0.01, attack_duration)
		var motion: float = sin(t * PI)
		var turn: float = -1.0 if facing_name == "left" else 1.0
		if SWORD_V224.matches_ground(str(body_art.animation)):
			# Frame progress is render-time and stays frozen during hitstop.
			# The body, baked sword and child glow move as one transform.
			var flow: Vector3 = SWORD_V224.motion_at(GENTLE.phase_of(body_art), heavy_attack)
			body_art.position = BASE_ART_POS + attack_direction * flow.x + Vector2(0.0, -flow.y)
			body_art.rotation = flow.z * turn
		else:
			body_art.position = BASE_ART_POS + Vector2(0.0, -3.0 * motion)
			body_art.rotation = (0.045 if heavy_attack else 0.075) * motion * turn
		body_art.scale = Vector2.ONE * BASE_ART_SCALE
	elif dodge_time_left > 0.0:
		var flow: Vector3 = MOTION_V225.dodge_flow(GENTLE.phase_of(body_art))
		body_art.position = BASE_ART_POS - dodge_direction * flow.x + Vector2(0.0, -flow.y)
		body_art.rotation = -flow.z * dodge_direction.x
		body_art.scale = Vector2.ONE * BASE_ART_SCALE
	elif jump_time_left > 0.0:
		var jump_progress: float = 1.0 - jump_time_left / maxf(0.01, jump_duration)
		var air_pose: Dictionary = AIR_V203.airborne_pose(jump_progress, jump_attack_active, jump_direction.x)
		var arc: float = float(air_pose["arc"])
		var hover_x: float = jump_direction.x * 2.0 * arc
		var height: float = float(air_pose["height"])
		body_art.position = BASE_ART_POS + Vector2(hover_x, -height)
		body_art.rotation = float(air_pose["rotation"])
		body_art.scale = Vector2.ONE * (BASE_ART_SCALE + float(air_pose["stretch"]))
		# Hand marker stays attached to her raised art, not the ground shadow.
		hand.position = _hand_position_for_facing() + Vector2(hover_x, -height * 0.88)
	elif spell_time_left > 0.0:
		var charge: float = clampf(1.0 - spell_time_left / spell_cast_duration, 0.0, 1.0)
		body_art.position = BASE_ART_POS + Vector2(0, -3.0 * sin(charge * PI))
		body_art.rotation = sin(charge * PI) * 0.045
		body_art.scale = Vector2.ONE * BASE_ART_SCALE
		hand.position = _hand_position_for_facing() + spell_direction * (12.0 * sin(charge * PI))
	elif is_throwing:
		var progress: float = clampf(throw_time / THROW_DURATION, 0.0, 1.0)
		var gesture: float = sin(progress * PI)
		var sign_direction: float = -1.0 if facing_name == "left" else 1.0
		body_art.rotation = sign_direction * (0.07 * sin(progress * TAU) - 0.045 * gesture)
		body_art.position = BASE_ART_POS + Vector2(-throw_direction.x * 7.0 * gesture, -5.0 * gesture)
		body_art.scale = Vector2(BASE_ART_SCALE, BASE_ART_SCALE)
		hand.position = _hand_position_for_facing() + throw_direction * (13.0 * gesture)
	elif hook_gesture_left > 0.0 or rose_hook.is_pulling_player():
		var progress_hook: float = clampf(1.0 - hook_gesture_left / HOOK_GESTURE_TIME, 0.0, 1.0)
		var reach: float = sin(progress_hook * PI * 0.85) if hook_gesture_left > 0.0 else 0.70
		var turn: float = 1.0 if facing_name != "left" else -1.0
		body_art.rotation = turn * (-0.065 * reach)
		body_art.position = BASE_ART_POS - hook_direction * 5.0 * reach + Vector2(0.0, -3.5 * reach)
		body_art.scale = Vector2(BASE_ART_SCALE, BASE_ART_SCALE)
		hand.position = _hand_position_for_facing() + hook_direction * (16.0 * reach)
	else:
		var idle: bool = velocity.length_squared() < 1.0
		var float_y: float = sin(visual_time * 1.7) * 0.8 if idle else 0.0
		var breath: float = sin(visual_time * 1.7) if idle else 0.0
		body_art.rotation = sin(visual_time * 1.15) * 0.010 if idle else 0.0
		body_art.position = BASE_ART_POS + Vector2(0.0, float_y)
		body_art.scale = Vector2(BASE_ART_SCALE, BASE_ART_SCALE)
		if not idle and GENTLE.is_walk_clip(str(body_art.animation)):
			# Continuous render-time stride motion shared by body and child FX.
			# Do not modify movement speed, collider or gameplay hand origin.
			var gait: Vector2 = GENTLE.gait_motion(GENTLE.phase_of(body_art), velocity.length() / WALK_SPEED)
			body_art.position.y += gait.x
			body_art.rotation = gait.y
		hand.position = _hand_position_for_facing() + Vector2(0.0, float_y)
	# A restrained landing compression eases the transition into walking.
	# This scales the existing sprite; it never edits its approved pixels.
	if landing_recoil_left > 0.0 and jump_time_left <= 0.0 and hurt_recoil_left <= 0.0:
		var landing_weight: float = MOTION_V225.landing_weight(landing_recoil_left / LANDING_RECOIL)
		body_art.scale *= Vector2(1.0 + 0.065 * landing_weight, 1.0 - 0.095 * landing_weight)
		body_art.position.y += 3.6 * landing_weight
	# Feedback without altering Ghost Girl's approved textures or equipment tint.
	body_art.self_modulate = Color(1.0, 0.78, 0.84, 1.0) if hurt_recoil_left > 0.0 else Color.WHITE

func _begin_throw(aim: Vector2) -> void:
	throw_direction = aim.normalized() if aim.length_squared() > 0.0001 else facing
	set_facing(throw_direction)
	is_throwing = true
	throw_released = false
	throw_time = 0.0
	body_art.speed_scale = 1.0
	body_art.play("throw_" + facing_name)

func _advance_throw(delta: float) -> void:
	throw_time += delta
	if not throw_released and throw_time >= THROW_RELEASE_TIME:
		throw_released = true
		world.drop_held(true, throw_direction)
	if throw_time >= THROW_DURATION:
		is_throwing = false
		_update_hand()

func _begin_hook_gesture() -> void:
	_play_action_sfx(HOOK_SFX)
	hook_direction = (get_global_mouse_position() - global_position).normalized()
	if hook_direction.length_squared() < 0.001:
		hook_direction = facing
	set_facing(hook_direction)
	hook_gesture_left = HOOK_GESTURE_TIME
	body_art.speed_scale = 1.0
	# Supplied 16-frame rose-launch artwork is genuinely directional for up/down.
	# Use the existing approved hook poses for side views; no fake mirrored art.
	var cast_name: String = "hook_launch_" + facing_name if facing_name in ["front", "back"] else "hook_" + facing_name
	_play_action_frames(cast_name, HOOK_GESTURE_TIME)

func _weapon_style() -> String:
	if world == null or world.inventory == null:
		return "unarmed"
	var sword: GhostItemInstance = world.inventory.get_equipped("sword")
	return sword.weapon_style() if sword != null else "unarmed"

func _bow_art_style() -> String:
	if world == null or world.inventory == null:
		return "thornrose"
	var held: GhostItemInstance = world.inventory.get_equipped("sword")
	if held != null and held.definition != null and held.definition.item_id == "moonveil_bow":
		return "moonveil"
	return "thornrose"

func _weapon_art_style() -> String:
	# Different bases within a combat class use truly different painted frames.
	# Animation identity only: no gameplay/stat/save field is changed.
	if world == null or world.inventory == null:
		return _weapon_style()
	var weapon: GhostItemInstance = world.inventory.get_equipped("sword")
	if weapon == null or weapon.definition == null:
		return _weapon_style()
	match str(weapon.definition.item_id):
		"ashglass_warmaul_v170": return "ashglass_maul"
		"rosemirror_twinblade_v170": return "rosemirror_twinblade"
		"nocturne_stiletto_v171": return "nocturne_dagger"
		"briarwake_trident_v171": return "briarwake_spear"
	return weapon.weapon_style()

func _weapon_motion_prefix(moving: bool) -> String:
	if _weapon_style() == "bow":
		# v1.68: the generic idle/walk images contain a painted rose hook.
		# Use the dedicated, hook-free bow locomotion atlases instead.
		# The attack/draw/release sprites are intentionally unchanged.
		return _bow_art_style() + ("_walk_" if moving else "_idle_")
	if world.inventory.get_equipped("wand") != null:
		return "wand_walk_" if moving else "wand_idle_"
	var style: String = _weapon_style()
	if style in ["scythe", "halberd", "dagger", "spear", "maul", "twinblade", "dual_dagger", "dual_sword"]:
		return _weapon_art_style() + ("_walk_" if moving else "_idle_")
	if style == "blade":
		return "sword_walk_" if moving else "sword_idle_"
	return "walk_" if moving else "idle_"

func _melee_cost(heavy: bool) -> float:
	var base: float = _action_cost(HEAVY_ATTACK_COST if heavy else LIGHT_ATTACK_COST, false)
	match _weapon_style():
		"scythe": return base * 1.05
		"halberd": return base * 1.13
		"dagger": return base * 0.79
		"dual_dagger": return base * 0.88
		"dual_sword": return base * 1.14
		"spear": return base * 1.09
		"maul": return base * 1.25
		"twinblade": return base * 0.90
		_: return base

func _attack_action_cost(heavy: bool) -> float:
	if _weapon_style() == "bow":
		return _action_cost(29.0 if heavy else 14.0, false)
	if world != null and world.inventory != null and world.inventory.get_equipped("wand") != null:
		return _action_cost(HEAVY_ATTACK_COST if heavy else LIGHT_ATTACK_COST, false)
	return _melee_cost(heavy)

func _play_if_changed(animation_name: String) -> void:
	if body_art.animation != animation_name:
		var phase: float = -1.0
		if GENTLE.same_walk_family(str(body_art.animation), animation_name):
			phase = GENTLE.phase_of(body_art)
		body_art.play(animation_name)
		if phase >= 0.0:
			GENTLE.seek_phase(body_art, phase)

# Synchronize non-looping directional frames with the actual combat timing,
# including attack-speed modifiers. No animation-notify timing drift.
func _play_action_frames(animation_name: String, duration: float) -> void:
	# Walk/sprint/idle speed_scale otherwise multiplies the computed action
	# rate and can shorten or stretch the visual clip without changing damage.
	body_art.speed_scale = 1.0
	action_animation_rate = 1.0
	if body_art.sprite_frames == null or not body_art.sprite_frames.has_animation(animation_name):
		push_warning("Missing combat animation: " + animation_name)
		body_art.play("idle_" + facing_name)
		return
	action_animation_rate = GENTLE.playback_rate(body_art.sprite_frames, animation_name, duration)
	body_art.play(animation_name, action_animation_rate)

func _resume_timed_action() -> void:
	# AnimatedSprite2D.play() defaults to rate 1.0. Preserve the original
	# rate and exact frame/progress instead of speeding up or slowing down.
	var frame_index: int = body_art.frame
	var fraction: float = body_art.frame_progress
	body_art.play(body_art.animation, action_animation_rate)
	body_art.set_frame_and_progress(frame_index, fraction)

func set_facing(direction: Vector2) -> void:
	if direction.length_squared() < 0.0001:
		return
	if absf(direction.x) > absf(direction.y):
		facing_name = "left" if direction.x < 0.0 else "right"
		facing = Vector2.LEFT if direction.x < 0.0 else Vector2.RIGHT
	else:
		facing_name = "back" if direction.y < 0.0 else "front"
		facing = Vector2.UP if direction.y < 0.0 else Vector2.DOWN
	_update_hand()

func _hand_position_for_facing() -> Vector2:
	match facing_name:
		"left": return Vector2(-29.0, -39.0)
		"right": return Vector2(29.0, -39.0)
		"back": return Vector2(0.0, -54.0)
		_: return Vector2(0.0, -38.0)

func _update_hand() -> void:
	hand.position = _hand_position_for_facing()

func _select_wand_target(pointer: Vector2) -> Vector2:
	# v1.12: target lock is fully intentional. If the player has not manually
	# locked an enemy, spells aim exactly where the cursor points.
	if is_instance_valid(lock_target):
		return lock_target.call("spell_aim_point") if lock_target.has_method("spell_aim_point") else lock_target.global_position + Vector2(0, -30)
	return pointer

func on_wand_projectile_hit(_charged: bool) -> void:
	# Confirmed-contact feedback only; a missed spell never kicks the camera.
	camera_kick = maxf(camera_kick, 2.2)
	COMBAT_JUICE.play(get_tree().current_scene, global_position, "spell_hit", -15.0)

func _begin_spell_cast(heavy: bool = false, moonfall: bool = false) -> void:
	_begin_spell_cast_v127(heavy, moonfall, "")

func _begin_spell_cast_v127(heavy: bool, moonfall: bool, new_kind: String) -> void:
	if carrying != null:
		return
	var spell_cost: float = (40.0 if new_kind == "astral" else 32.0) if not new_kind.is_empty() else (37.0 if moonfall else (HEAVY_ATTACK_COST if heavy else LIGHT_ATTACK_COST))
	var cost: float = _action_cost(spell_cost)
	if stamina < cost:
		return
	buffered_attack_valid = false
	wand_heavy_attack = heavy
	spell_is_moonfall = moonfall
	special_spell_kind = new_kind
	stamina -= cost
	stamina_recovery_left = STAMINA_RECOVERY_WAIT
	spell_aim_point = _select_wand_target(get_global_mouse_position())
	var muzzle: Vector2 = WAND_ANCHORS_V216.world_tip(self)
	spell_direction = spell_aim_point - muzzle
	if spell_direction.length_squared() < 36.0:
		spell_direction = facing
	spell_direction = spell_direction.normalized()
	set_facing(spell_direction)
	var cast_rate: float = 1.0 + _stat("cast_speed_pct") / 100.0
	spell_cast_duration = (0.73 if not new_kind.is_empty() else (0.72 if moonfall else (0.79 if heavy else 0.46))) / cast_rate
	spell_shot_time = (0.39 if not new_kind.is_empty() else (0.38 if moonfall else (0.42 if heavy else 0.21))) / cast_rate
	spell_time_left = spell_cast_duration
	spell_shot = false
	# The cast animation itself is the recovery window; buffered attacks
	# must become available as soon as that animation finishes.
	spell_cooldown = spell_cast_duration
	body_art.speed_scale = 1.0
	_play_action_frames("wand_cast_" + facing_name, spell_cast_duration)
	body_art.set_frame_and_progress(0, 0.0)
	COMBAT_JUICE.play(get_tree().current_scene, global_position, "spell_heavy" if heavy or moonfall or not new_kind.is_empty() else "spell", -17.0)

func _advance_spell(delta: float) -> void:
	spell_time_left = maxf(0.0, spell_time_left - delta)
	if not spell_shot and spell_time_left <= spell_cast_duration - spell_shot_time:
		spell_shot = true
		var powerful: bool = wand_heavy_attack or spell_is_moonfall or not special_spell_kind.is_empty()
		COMBAT_JUICE.play(get_tree().current_scene, WAND_ANCHORS_V216.world_tip(self), "spell_release_heavy" if powerful else "spell_release", -16.0)
		if powerful:
			_emit_air_wake("charged", spell_direction)
			camera_kick = maxf(camera_kick, 1.6)
		if is_instance_valid(lock_target) and lock_target.has_method("spell_aim_point"):
			spell_aim_point = lock_target.call("spell_aim_point")
		if spell_is_moonfall:
			world.cast_moonfall(spell_aim_point)
		elif special_spell_kind == "astral":
			world.cast_astral_rain(spell_aim_point)
		elif special_spell_kind == "roses":
			world.cast_grasping_roses(spell_aim_point)
		else:
			world.cast_spell(spell_direction, wand_heavy_attack)
	if spell_time_left <= 0.0:
		_update_hand()

func reset_action_state() -> void:
	spell_is_moonfall = false
	special_spell_kind = ""
	collision_mask |= JUMPABLE_BARRIER_MASK
	attack_time_left = 0.0
	bow_time_left = 0.0
	bow_draw_active = false
	bow_draw_time = 0.0
	bow_duration = 0.0
	bow_release_done = false
	attack_duration = 0.0
	hitstop_left = 0.0
	attack_hit_done = false
	dodge_time_left = 0.0
	jump_time_left = 0.0
	jump_duration = 0.0
	jump_attack_active = false
	jump_attack_triggered = false
	spell_time_left = 0.0
	spell_cooldown = 0.0
	healing_time_left = 0.0
	is_throwing = false
	hook_gesture_left = 0.0
	queued_action = ""
	queue_time_left = 0.0
	buffered_attack_valid = false
	hurt_recoil_left = 0.0
	combo_step = 0
	combo_grace = 0.0
	previous_light = false
	backstep_counter_armed = false
	precision_evade_registered = false
	counter_window = 0.0
	body_art.self_modulate = Color.WHITE
	body_art.rotation = 0.0
	body_art.speed_scale = 1.0
	body_art.position = BASE_ART_POS
	hand.position = _hand_position_for_facing()
	_play_if_changed(_weapon_motion_prefix(false) + facing_name)

func receive_damage(amount: float, attacker_position: Vector2 = Vector2.ZERO) -> void:
	# I-frame contacts must not cancel a bow charge or punish valid dodges.
	if invulnerable_time > 0.0:
		return
	bow_time_left = 0.0
	bow_draw_active = false
	bow_draw_time = 0.0
	bow_release_done = true
	invulnerable_time = 0.64
	stamina_recovery_left = maxf(stamina_recovery_left, 0.35)
	camera_kick = maxf(camera_kick, clampf(4.6 + amount * 0.16, 5.6, 10.5))
	hurt_direction = (global_position - attacker_position).normalized() if attacker_position != Vector2.ZERO else -facing
	camera_push = hurt_direction * clampf(3.0 + amount * 0.17, 4.5, 9.5)
	hurt_recoil_left = 0.19
	landing_recoil_left = 0.0
	PHYSICAL_FEEL.burst(get_tree().current_scene, global_position + Vector2(0, -29), "hurt", 0.9 + minf(0.6, amount / 48.0), hurt_direction, roundi(amount * 21.0))
	collision_mask |= JUMPABLE_BARRIER_MASK
	_play_action_frames("hurt_" + facing_name, hurt_recoil_left)
	backstep_counter_armed = false
	precision_evade_registered = false
	counter_window = 0.0
	attack_time_left = 0.0
	jump_time_left = 0.0
	jump_duration = 0.0
	jump_attack_active = false
	jump_attack_triggered = false
	hitstop_left = 0.0
	queued_action = ""
	buffered_attack_valid = false
	spell_time_left = 0.0
	healing_time_left = 0.0  # A hit interrupts a healing attempt.
	rally_pool = minf(45.0, rally_pool + amount * (0.65 + _stat("rally_power_pct") / 200.0))
	rally_time_left = 3.0
	health = maxf(0.0, health - amount)
	world.ui.set_health(health, maximum_health())
	if health <= 0.0:
		world.return_after_defeat()

func _stat(id: String) -> float:
	if world == null or world.inventory == null:
		return 0.0
	return world.inventory.get_stat_total(id)

func _action_cost(base_cost: float, dodge: bool = false) -> float:
	var saved: float = _stat("stamina_efficiency_pct")
	if dodge:
		saved += _stat("backstep_efficiency_pct")
	return base_cost * (1.0 - clampf(saved, 0.0, 45.0) / 100.0)

func _begin_jump() -> void:
	if carrying != null or rose_hook.is_pulling_player() or is_throwing or hook_gesture_left > 0.0:
		return
	stamina -= _action_cost(JUMP_COST, false)
	stamina_recovery_left = maxf(stamina_recovery_left, 0.22)
	combo_grace = 0.0
	previous_light = false
	buffered_attack_valid = false
	jump_duration = JUMP_DURATION
	jump_time_left = jump_duration
	jump_origin = global_position
	collision_mask &= ~JUMPABLE_BARRIER_MASK
	jump_attack_active = false
	jump_attack_triggered = false
	var movement: Vector2 = Input.get_vector("left", "right", "up", "down")
	if is_instance_valid(lock_target):
		jump_direction = (lock_target.global_position - global_position).normalized()
	elif movement.length_squared() > 0.04:
		jump_direction = movement.normalized()
	else:
		jump_direction = facing
	if jump_direction.length_squared() < 0.001:
		jump_direction = Vector2.DOWN
	jump_direction = jump_direction.normalized()
	set_facing(jump_direction)
	body_art.speed_scale = 1.0
	_play_action_frames(_weapon_motion_prefix(true) + facing_name, jump_duration)

func _begin_jump_attack(_from_heavy_button: bool = true) -> void:
	if jump_time_left <= 0.0 or jump_attack_active or carrying != null:
		return
	if _weapon_style() == "bow":
		_begin_bow_shot(not _from_heavy_button, true)
		return
	var cost: float = _melee_cost(true)
	if stamina < cost:
		return
	stamina -= cost
	stamina_recovery_left = STAMINA_RECOVERY_WAIT
	jump_attack_active = true
	jump_attack_triggered = false
	heavy_attack = true
	active_attack_style = _weapon_style()
	attack_direction = _combat_aim_direction().normalized()
	if attack_direction.length_squared() < 0.001:
		attack_direction = jump_direction
	set_facing(attack_direction)
	jump_direction = attack_direction
	COMBAT_JUICE.play(get_tree().current_scene, global_position, "jump_swing", -14.0)
	var attack_animation: String = ""
	var holding_sword: bool = world.inventory != null and world.inventory.get_equipped("sword") != null
	if holding_sword:
		if active_attack_style in ["scythe", "halberd", "dagger", "spear", "maul", "twinblade", "dual_dagger", "dual_sword"]:
			attack_animation = "attack_" + _weapon_art_style() + ("_heavy_pierce_" if active_attack_style in ["dagger", "dual_dagger"] else "_heavy_") + facing_name
		else:
			attack_animation = "attack_sword_heavy_" + facing_name
	else:
		attack_animation = "attack_wand_heavy_" + facing_name if world.inventory != null and world.inventory.get_equipped("wand") != null else "attack_unarmed_heavy_" + facing_name
	# Every style has a distinct airborne heavy clip with a faster plunge beat.
	# The physical hit remains the existing single jump-hit event.
	_play_action_frames(AIR_V203.air_name(attack_animation), maxf(0.26, jump_time_left))

func _advance_jump(delta: float) -> void:
	jump_time_left = maxf(0.0, jump_time_left - delta)
	var progress: float = 1.0 - jump_time_left / maxf(0.01, jump_duration)
	var speed_scale: float = 0.88 + 0.20 * sin(progress * PI)
	if jump_attack_active:
		speed_scale *= 0.66
	velocity = jump_direction * JUMP_SPEED * speed_scale
	if jump_attack_active and not jump_attack_triggered and progress >= JUMP_ATTACK_TRIGGER:
		jump_attack_triggered = true
		# An airborne BOW only fires its genuine arrow on release; never
		# register a second invisible heavy melee hit during the jump.
		if _weapon_style() != "bow":
			_strike_jump_attack()
	if jump_time_left <= 0.0:
		# A tiny carry-through avoids a hard dead stop at the first grounded frame.
		velocity = jump_direction * (28.0 if jump_attack_active else 18.0)
		landing_recoil_left = LANDING_RECOIL
		# A small landing cue makes traversal timing legible without changing damage.
		if global_position.distance_to(jump_origin) > 28.0:
			_spawn_jump_landing_cue()
		collision_mask |= JUMPABLE_BARRIER_MASK
		jump_attack_active = false
		jump_attack_triggered = false
		jump_duration = 0.0
		_update_hand()

func _spawn_jump_landing_cue() -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var cue: Node2D = Node2D.new()
	cue.set_script(preload("res://scripts/jump_landing_cue.gd"))
	cue.set("enhanced", jump_attack_active)
	cue.set("motion", jump_direction)
	if world != null and world.inventory != null:
		var weapon: GhostItemInstance = world.inventory.get_equipped("sword")
		if weapon != null:
			var cosmetic: Dictionary = weapon.effect_rolls()
			cue.set("accent", GhostWeaponFXLibrary.color(int(cosmetic.get("color", 0))))
	root.add_child(cue)
	cue.global_position = global_position + Vector2(0.0, -8.0)
	# The dust is grounded at her feet, with a denser puff after a plunge.
	PHYSICAL_FEEL.burst(root, global_position + Vector2(0, -6), "slam" if jump_attack_active else "landing", 1.06 if jump_attack_active else 0.54, jump_direction, roundi(visual_time * 83.0))
	if jump_attack_active:
		camera_kick = maxf(camera_kick, 3.1)
		camera_push = jump_direction * 3.0

func _strike_jump_attack() -> void:
	var previous_heavy: bool = heavy_attack
	var previous_style: String = active_attack_style
	var previous_direction: Vector2 = attack_direction
	heavy_attack = true
	active_attack_style = _weapon_style()
	attack_direction = jump_direction if jump_direction.length_squared() > 0.0 else facing
	# Air movement and light camera response happen on commitment, NOT on hit.
	_emit_air_wake("jump", attack_direction)
	COMBAT_JUICE.play(get_tree().current_scene, global_position, "jump_swing", -23.0)
	camera_kick = maxf(camera_kick, 2.3)
	camera_push = attack_direction * 1.6
	_strike_nearby_enemies(JUMP_ATTACK_DAMAGE_BONUS)
	# Camera and hitstop are deliberately assigned only on a confirmed hit.
	heavy_attack = previous_heavy
	active_attack_style = previous_style
	attack_direction = previous_direction

func _begin_dodge() -> void:
	stamina -= _action_cost(DODGE_COST, true)
	stamina_recovery_left = STAMINA_RECOVERY_WAIT
	combo_grace = 0.0
	previous_light = false
	buffered_attack_valid = false
	# Backstep, not a free-direction dash. If locked on, retreat from the foe;
	# otherwise move exactly opposite Ghost Girl's current facing.
	if is_instance_valid(lock_target):
		set_facing(lock_target.global_position - global_position)
		dodge_direction = (global_position - lock_target.global_position).normalized()
	else:
		dodge_direction = -facing
	if dodge_direction.length_squared() < 0.05:
		dodge_direction = Vector2.UP
	dodge_direction = dodge_direction.normalized()
	dodge_time_left = DODGE_DURATION
	body_art.speed_scale = 1.0
	_play_action_sfx(DODGE_SFX)
	COMBAT_JUICE.play(get_tree().current_scene, global_position, "dodge", -19.0)
	PHYSICAL_FEEL.burst(get_tree().current_scene, global_position + Vector2(0, -6), "landing", 0.48, -dodge_direction, roundi(visual_time * 91.0))
	counter_window = 0.0
	backstep_origin = global_position
	# Reset the one-hit evade detector; the next real incoming strike can arm
	# it, but proximity to a windup alone never can.
	backstep_counter_armed = false
	precision_evade_registered = false
	# Brief safe window, then vulnerability during the final roll recovery.
	invulnerable_time = maxf(invulnerable_time, 0.24)
	_play_action_frames("dodge_" + facing_name, DODGE_DURATION)
	body_art.set_frame_and_progress(0, 0.0)


# Called only from a confirmed hostile strike/bolt collision, directly before
# the existing receive_damage call. Does not create an iframe or remove damage.
# The existing receive_damage() is still the sole authority on health.
func register_confirmed_evade(attacker: Node2D, _contact: Vector2) -> bool:
	if not is_instance_valid(attacker) or precision_evade_registered:
		return false
	if dodge_time_left <= 0.0 or invulnerable_time <= 0.0:
		return false
	# Dodge's first 0.24s is invulnerable; later recovery never earns a counter.
	if dodge_time_left < DODGE_DURATION - 0.24:
		return false
	precision_evade_registered = true
	backstep_counter_armed = true
	_spawn_precision_feedback("evade", global_position + Vector2(0, -31), -dodge_direction)
	COMBAT_JUICE.play(get_tree().current_scene, global_position, "evade", -15.0)
	return true

func _spawn_precision_feedback(kind: String, where: Vector2, direction: Vector2) -> void:
	var root: Node = get_tree().current_scene
	if root == null or get_tree().get_nodes_in_group("combat_feedback_v157").size() >= 18:
		return
	var fx: Node2D = Node2D.new()
	fx.set_script(COMBAT_RESPONSE_V157)
	fx.set("kind", kind)
	fx.set("direction", direction)
	fx.set("tint", Color("f4d6a8") if kind == "riposte" else Color("cfb6ec"))
	root.add_child(fx)
	fx.global_position = where

func _emit_air_wake(kind: String, heading: Vector2) -> void:
	var root: Node = get_tree().current_scene
	if root == null or get_tree().get_nodes_in_group("v198_air_wake").size() >= 12:
		return
	var wake: Node2D = SWING_WAKE.new() as Node2D
	if wake == null:
		return
	wake.set("kind", kind)
	wake.set("direction", heading)
	if world != null and world.inventory != null:
		var weapon: GhostItemInstance = world.inventory.get_equipped("sword")
		if weapon == null:
			weapon = world.inventory.get_equipped("wand")
		if weapon != null:
			var rolls: Dictionary = weapon.effect_rolls()
			wake.set("color", GhostWeaponFXLibrary.color(int(rolls.get("color", 0))).lerp(Color("d5cde1"), 0.38))
	root.add_child(wake)
	wake.global_position = global_position + Vector2(0.0, -29.0) + heading.normalized() * 16.0

func _begin_weapon_attack(heavy: bool) -> void:
	if carrying != null:
		return
	if stamina < _attack_action_cost(heavy):
		return
	if _weapon_style() == "bow":
		_begin_bow_shot(heavy, false)
	elif world.inventory.get_equipped("wand") != null:
		if spell_time_left <= 0.0 and spell_cooldown <= 0.0:
			_begin_spell_cast(heavy)
	else:
		_begin_attack(heavy)

func _begin_bow_shot(charged: bool, airborne: bool) -> void:
	if world == null or world.inventory == null or _weapon_style() != "bow" or carrying != null:
		return
	if bow_time_left > 0.0 or bow_draw_active:
		return
	# Charge stamina is paid once, at the beginning, not every held frame.
	var cost: float = _attack_action_cost(charged)
	if stamina < cost:
		return
	stamina -= cost
	stamina_recovery_left = STAMINA_RECOVERY_WAIT
	bow_charge = charged
	bow_firing_direction = _combat_aim_direction().normalized()
	if bow_firing_direction.length_squared() < 0.01:
		bow_firing_direction = facing
	set_facing(bow_firing_direction)
	var animation: String = "attack_" + _bow_art_style() + ("_heavy_" if charged else "_light_") + facing_name
	if airborne:
		animation = AIR_V203.air_name(animation)
	if airborne:
		jump_attack_active = true
		jump_attack_triggered = true
	if charged:
		bow_draw_active = true
		bow_draw_time = 0.0
		bow_draw_airborne = airborne
		_play_action_frames(animation, 0.70)
		body_art.pause()
		body_art.set_frame_and_progress(0, 0.0)
	else:
		# Ordinary LMB bow shots still release quickly, never use the heavy
		# hold state. Both shots share the same one-arrow collision system.
		bow_release_done = true
		bow_duration = 0.22
		bow_time_left = bow_duration
		_play_action_frames(animation, 0.30)
		_launch_bow_arrow(bow_firing_direction, false)
	_play_action_sfx(SWING_SFX)

func _advance_bow_draw(delta: float) -> void:
	if _weapon_style() != "bow" or carrying != null:
		bow_draw_active = false
		body_art.play()
		return
	if not Input.is_action_pressed("attack_heavy"):
		_release_bow_charge()
		return
	bow_draw_time += delta
	# Cursor aiming remains manual. Draw angle and facing can change while
	# holding, but the shot won't launch until the physical button releases.
	var aim: Vector2 = _combat_aim_direction().normalized()
	if aim.length_squared() > 0.001:
		bow_firing_direction = aim
		var previous_face: String = facing_name
		set_facing(aim)
		if facing_name != previous_face:
			var name: String = "attack_" + _bow_art_style() + "_heavy_" + facing_name
			if bow_draw_airborne or jump_time_left > 0.0:
				name = AIR_V203.air_name(name)
			_play_action_frames(name, 0.70)
			body_art.pause()
	var fraction: float = clampf(bow_draw_time / BOW_FULL_DRAW_TIME, 0.0, 1.0)
	var draw_frame: int = mini(5, floori(fraction * 5.0))
	body_art.set_frame_and_progress(draw_frame, 0.0)
	body_art.pause()
	queue_redraw()

func _release_bow_charge() -> void:
	if not bow_draw_active:
		return
	var fully_drawn: bool = bow_draw_time >= BOW_FULL_DRAW_TIME
	bow_draw_active = false
	bow_release_done = true
	bow_charge = fully_drawn
	# A rushed release still fires one normal arrow. Environmental targets
	# requiring a charged shot only accept fully drawn releases.
	_launch_bow_arrow(bow_firing_direction, fully_drawn)
	if bow_draw_airborne or jump_time_left > 0.0:
		var aerial_release: String = AIR_V203.air_name("attack_" + _bow_art_style() + "_heavy_" + facing_name)
		if body_art.sprite_frames.has_animation(aerial_release):
			_play_action_frames(aerial_release, 0.22)
	if fully_drawn:
		_emit_air_wake("charged", bow_firing_direction)
		COMBAT_JUICE.play(get_tree().current_scene, global_position, "charged_swing", -16.5)
		camera_kick = maxf(camera_kick, 1.7)
		camera_push = bow_firing_direction.normalized() * 1.2
	body_art.set_frame_and_progress(6, 0.0)
	body_art.play()
	bow_duration = 0.18
	bow_time_left = bow_duration
	bow_draw_time = 0.0
	bow_draw_airborne = false

func _launch_bow_arrow(heading: Vector2, charged: bool) -> void:
	if world == null or world.inventory == null:
		return
	var equipped: GhostItemInstance = world.inventory.get_equipped("sword")
	if equipped == null or equipped.weapon_style() != "bow":
		return
	var arrow: Node2D = BOW_ARROW_SCENE.instantiate() as Node2D
	var root: Node = get_tree().current_scene
	if root == null or arrow == null:
		return
	arrow.set("direction", heading.normalized())
	arrow.set("damage", equipped.weapon_damage() * (1.65 if charged else 1.0) * (1.0 + _stat("melee_power_pct") / 100.0 + (0.01 * _stat("charged_spell_pct") if charged else 0.0)))
	arrow.set("charged", charged)
	arrow.set("launched_in_air", jump_time_left > 0.0)
	arrow.set("speed", 1180.0 if charged else 1030.0)
	arrow.set("caster", self)
	arrow.set("caster_rid", get_rid())
	arrow.set("bow_style", _bow_art_style())
	var rolls: Dictionary = equipped.effect_rolls()
	arrow.set("ink", GhostWeaponFXLibrary.color(int(rolls["color"])))
	arrow.set("accent", GhostWeaponFXLibrary.color(int(rolls["accent"])))
	arrow.set("fx_tier", int(rolls["tier"]))
	arrow.set("motif", int(rolls["impact"]))
	arrow.set("trail_style", int(rolls["trail"]))
	# Rarity-gated ornamental variants do not affect the one-arrow hit logic.
	var rarity: int = GhostWeaponFXLibrary.tier(equipped.quality)
	var visual_variant: int = posmod(equipped.visual_seed() + 12719, 4) if rarity >= 2 else -1
	arrow.set("visual_variant", visual_variant)
	# v1.38: individual bow item seeds control element, formation, glow,
	# fletching and trail. None of these changes outgoing damage.
	var bow_look: Dictionary = equipped.bow_rolls()
	arrow.set("element_index", int(bow_look["element"]))
	arrow.set("formation_index", int(bow_look["formation"]))
	arrow.set("bow_glow_index", int(bow_look["glow"]))
	arrow.set("bow_trail_index", int(bow_look["trail"]))
	arrow.set("bow_detail_index", int(bow_look["detail"]))
	# One physical arrow; cosmetic decoration is stable per saved bow UID.
	arrow.set("projectile_style", VISUAL_CHOICES_V216.projectile_style(equipped))
	arrow.set("visual_glow_scale", VISUAL_CHOICES_V216.effect_scale(equipped))
	arrow.set("procedural_look", bow_look["procedural"])
	# Match the physical arrow's light to the equipped bow's saved 128-bit look.
	var shot_gradient: Array[Color] = equipped.glow_gradient_colors()
	arrow.set("full_palette", shot_gradient)
	arrow.set("glow_a", GhostCosmeticRNGV152.sample_palette(shot_gradient, 0.0))
	arrow.set("glow_b", GhostCosmeticRNGV152.sample_palette(shot_gradient, 0.5))
	arrow.set("glow_c", GhostCosmeticRNGV152.sample_palette(shot_gradient, 1.0))
	if VISUAL_CHOICES_V216.effect_scale(equipped) > 0.0:
		var release: Node2D = Node2D.new()
		release.set_script(BOW_RELEASE_FX)
		release.set("direction", heading)
		release.set("charged", charged)
		release.set("ink", GhostCosmeticRNGV152.sample_palette(shot_gradient, 0.0))
		release.set("accent", GhostCosmeticRNGV152.sample_palette(shot_gradient, 1.0))
		release.set("rare_variant", visual_variant)
		release.self_modulate.a = VISUAL_CHOICES_V216.effect_scale(equipped)
		root.add_child(release)
		release.global_position = global_position + Vector2(0, -39) + heading.normalized() * 26.0
	root.add_child(arrow)
	arrow.global_position = global_position + Vector2(0, -39) + heading.normalized() * 31.0
	# Exactly one authentic released arrow per scored range shot; cosmetic
	# formation wisps never report extra shots to the optional fletcher trial.
	get_tree().call_group("v202_archery_range", "on_player_arrow_launched", global_position)

func _begin_attack(heavy: bool) -> void:
	if carrying != null:
		return
	if heavy:
		combo_step = 0
		previous_light = false
	else:
		combo_step = (combo_step + 1) % 3 if previous_light and combo_grace > 0.0 else 0
		previous_light = true
	var attack_cost: float = _melee_cost(heavy)
	if stamina < attack_cost:
		return
	stamina -= attack_cost
	stamina_recovery_left = STAMINA_RECOVERY_WAIT
	# Preserve the direction at the buffered button press. For an immediate
	# attack, resolve it now; never inherit an unrelated dodge/old mouse heading.
	attack_direction = buffered_attack_direction if buffered_attack_valid else _combat_aim_direction()
	buffered_attack_valid = false
	attack_direction = attack_direction.normalized()
	set_facing(attack_direction)
	active_attack_style = _weapon_style()
	match active_attack_style:
		"scythe":
			attack_duration = 0.91 if heavy else [0.49, 0.52, 0.56][combo_step]
			attack_hit_threshold = 0.54
		"halberd":
			attack_duration = 1.02 if heavy else [0.57, 0.60, 0.65][combo_step]
			attack_hit_threshold = 0.58
		"dagger":
			# A fast straight jab, or a deliberately committed heavy stab.
			# The heavy clip spends longer drawing back before its single hit.
			attack_duration = 0.94 if heavy else [0.28, 0.30, 0.32][combo_step]
			attack_hit_threshold = 0.39 if heavy else 0.51
		"dual_dagger":
			# Three alternating cuts, one confirmed strike per animation.
			attack_duration = 0.72 if heavy else [0.32, 0.35, 0.38][combo_step]
			attack_hit_threshold = 0.56
		"dual_sword":
			# Broader alternating slashes, followed by a committed X strike.
			attack_duration = 0.96 if heavy else [0.47, 0.50, 0.54][combo_step]
			attack_hit_threshold = 0.58
		"spear":
			attack_duration = 0.96 if heavy else [0.53, 0.56, 0.60][combo_step]
			attack_hit_threshold = 0.57
		"maul":
			attack_duration = 1.13 if heavy else [0.67, 0.70, 0.74][combo_step]
			attack_hit_threshold = 0.54
		"twinblade":
			attack_duration = 0.77 if heavy else [0.36, 0.39, 0.42][combo_step]
			attack_hit_threshold = 0.55
		_:
			attack_duration = 0.80 if heavy else [0.40, 0.43, 0.51][combo_step]
			attack_hit_threshold = 0.58
	attack_duration /= 1.0 + _stat("attack_speed_pct") / 100.0
	attack_time_left = attack_duration
	dagger_charge_active = heavy and active_attack_style == "dagger"
	dagger_charge_time = 0.0
	# Actual moving-air sound, without the old bright WAV transient on swords.
	COMBAT_JUICE.play(get_tree().current_scene, global_position, "heavy_swing" if heavy else "swing", -16.5 if heavy else -18.5)
	attack_hit_done = false
	heavy_attack = heavy
	# The empty-hand branch must always play visible unarmed attack frames.
	# Swords use a separate atlas; counter frames remain available for both.
	var holding_sword: bool = world.inventory != null and world.inventory.get_equipped("sword") != null
	var attack_animation: String = ""
	if counter_window > 0.0 and active_attack_style == "dual_sword":
		# A dedicated crossed-blade riposte on the existing confirmed counter.
		attack_animation = "attack_dual_sword_riposte_" + facing_name
	elif counter_window > 0.0 and active_attack_style not in ["scythe", "halberd", "dagger", "spear", "maul", "twinblade", "dual_dagger", "dual_sword"]:
		attack_animation = "attack_counter_" + facing_name
	elif holding_sword:
		if active_attack_style in ["scythe", "halberd", "dagger", "spear", "maul", "twinblade", "dual_dagger", "dual_sword"]:
			if active_attack_style == "dagger":
				# Always use the hand-anchored thrust, not the legacy slash atlas.
				attack_animation = "attack_" + _weapon_art_style() + ("_heavy_pierce_" if heavy else "_pierce_") + facing_name
			elif active_attack_style == "dual_dagger" and (heavy or combo_step == 2 or counter_window > 0.0):
				attack_animation = "attack_" + _weapon_art_style() + ("_heavy_pierce_" if heavy else "_pierce_") + facing_name
			elif active_attack_style == "dual_dagger" and not heavy:
				attack_animation = "attack_dual_dagger_light_" + ["a", "b", "c"][combo_step] + "_" + facing_name
			elif active_attack_style == "dual_sword" and not heavy:
				attack_animation = "attack_dual_sword_light_" + ["a", "b", "c"][combo_step] + "_" + facing_name
			elif active_attack_style == "spear" and (heavy or combo_step == 2):
				attack_animation = "attack_" + _weapon_art_style() + ("_heavy_pierce_" if heavy else "_pierce_") + facing_name
			else:
				attack_animation = "attack_" + _weapon_art_style() + ("_heavy_" if heavy else "_light_") + facing_name
		else:
			attack_animation = ("attack_sword_heavy_" if heavy else "attack_sword_light_") + facing_name
	else:
		attack_animation = ("attack_unarmed_heavy_" if heavy else "attack_unarmed_light_") + facing_name
	_play_action_frames(attack_animation, attack_duration)
	# Repeated same-direction combo attacks are new actions, not resumes.
	body_art.set_frame_and_progress(0, 0.0)

func _combat_aim_direction() -> Vector2:
	if is_instance_valid(lock_target):
		var locked_heading: Vector2 = lock_target.global_position - global_position
		if locked_heading.length_squared() > 4.0:
			return locked_heading.normalized()
	# Mouse dead zone covers the character's full illustrated body. When the
	# pointer is inside it, use held movement or the last intentional facing.
	var cursor_heading: Vector2 = get_global_mouse_position() - global_position
	if cursor_heading.length_squared() > 58.0 * 58.0:
		return cursor_heading.normalized()
	var movement: Vector2 = Input.get_vector("left", "right", "up", "down")
	if movement.length_squared() > 0.04:
		return movement.normalized()
	return facing

func _queue_combat(action: String) -> void:
	queued_action = action
	queue_time_left = INPUT_BUFFER
	if action == "light" or action == "heavy":
		buffered_attack_direction = _combat_aim_direction()
		buffered_attack_valid = true
	else:
		buffered_attack_valid = false

func _advance_attack(delta: float) -> void:
	# The heavy dagger recoils first, then releases exactly one physical stab.
	# Do not reach the hit threshold while the player is charging.
	if dagger_charge_active:
		dagger_charge_time += delta
		if dagger_charge_time < DAGGER_CHARGE_MIN or (Input.is_action_pressed("attack_heavy") and dagger_charge_time < DAGGER_CHARGE_MAX):
			if body_art.frame >= 2:
				body_art.pause()
			return
		dagger_charge_active = false
		_resume_timed_action()
		# Continue from the authored stab/recovery section after wind-up;
		# damage, stamina cost and hit count remain the existing heavy values.
		attack_time_left = attack_duration * 0.65
	attack_time_left = maxf(0.0, attack_time_left - delta)
	if not attack_hit_done and attack_time_left <= attack_duration * attack_hit_threshold:
		attack_hit_done = true
		if heavy_attack:
			if active_attack_style != "dagger":
				_emit_air_wake("heavy", attack_direction)
			COMBAT_JUICE.play(get_tree().current_scene, global_position, "swing", -24.0)
			camera_kick = maxf(camera_kick, 1.9)
			camera_push = attack_direction * 1.4
		_strike_nearby_enemies()
	if attack_time_left <= 0.0:
		combo_grace = 0.48 if not heavy_attack else 0.0

func _strike_nearby_enemies(power_multiplier: float = 1.0) -> void:
	var sword: GhostItemInstance = world.inventory.get_equipped("sword") if world.inventory != null else null
	var reach: float = (174.0 if heavy_attack else 144.0) if sword != null else (128.0 if heavy_attack else 106.0)
	var power: float = 34.0 if heavy_attack else [16.0, 19.0, 24.0][combo_step]
	var attack_arc: float = 0.12 if heavy_attack else 0.32
	var poise_bonus: float = 1.0
	match active_attack_style:
		"scythe":
			reach = 216.0 if heavy_attack else 184.0
			power *= 1.06 if heavy_attack else 0.95
			attack_arc = -0.05 if heavy_attack else 0.12
			poise_bonus = 1.12
		"halberd":
			reach = 242.0 if heavy_attack else 206.0
			power *= 1.28 if heavy_attack else 1.08
			attack_arc = 0.34 if heavy_attack else 0.48
			poise_bonus = 1.35
		"dagger":
			reach = 143.0 if heavy_attack else 112.0
			power *= 0.90 if heavy_attack else 0.77
			# Dagger strikes have a narrow forward hit cone, not a sweep.
			attack_arc = 0.08 if heavy_attack else 0.10
			poise_bonus = 0.70
		"dual_dagger":
			reach = 153.0 if heavy_attack else 122.0
			power *= 0.96 if heavy_attack else 0.80
			attack_arc = 0.14 if heavy_attack else 0.15
			poise_bonus = 0.73
		"dual_sword":
			reach = 199.0 if heavy_attack else 165.0
			power *= 1.18 if heavy_attack else 0.97
			attack_arc = 0.08 if heavy_attack else 0.12
			poise_bonus = 0.96
		"spear":
			reach = 252.0 if heavy_attack else 213.0
			power *= 1.18 if heavy_attack else 0.96
			attack_arc = 0.64 if heavy_attack else 0.71
			poise_bonus = 1.12
		"maul":
			# Slow and committed, with a broad impact and exceptional stagger.
			reach = 211.0 if heavy_attack else 173.0
			power *= 1.45 if heavy_attack else 1.13
			attack_arc = 0.04 if heavy_attack else 0.23
			poise_bonus = 1.65
		"twinblade":
			# Quick circular sweeps, but not free extra hit checks.
			reach = 206.0 if heavy_attack else 168.0
			power *= 1.05 if heavy_attack else 0.87
			attack_arc = -0.10 if heavy_attack else 0.01
			poise_bonus = 0.85
	if sword != null:
		power += sword.weapon_damage()
	power *= 1.0 + _stat("melee_power_pct") / 100.0
	power *= power_multiplier
	if heavy_attack:
		power *= 1.0 + _stat("heavy_power_pct") / 100.0
	var counter_hit: bool = counter_window > 0.0
	if counter_hit:
		power *= 1.28 + _stat("counter_damage_pct") / 100.0
	var struck: bool = false
	var visual_item: GhostItemInstance = sword
	var aura: Dictionary = visual_item.effect_rolls() if visual_item != null else {}
	var fx_color: Color = GhostWeaponFXLibrary.color(int(aura.get("color", 3)))
	var fx_motif: int = int(aura.get("motif", 0))
	var fx_accent: Color = GhostWeaponFXLibrary.color(int(aura.get("accent", 2)))
	var fx_trail: int = int(aura.get("trail", 0))
	var fx_tier: int = int(aura.get("tier", 0))
	var fx_impact: int = int(aura.get("impact", 0))
	var counter_shown: bool = false
	var struck_world: bool = false
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or not candidate is Node2D or not candidate.has_method("hit"):
			continue
		var delta_to: Vector2 = candidate.global_position - global_position
		if delta_to.length() > reach or delta_to.length_squared() < 20.0:
			continue
		if attack_direction.dot(delta_to.normalized()) < attack_arc:
			continue
		var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -18), candidate.global_position + Vector2(0, -18))
		ray.collision_mask = 2
		ray.exclude = [get_rid()]
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		candidate.call("hit", power, poise_bonus * (1.0 + _stat("poise_power_pct") / 100.0))
		var blunt_contact: bool = sword != null and sword.physical_damage_kind() == "blunt"
		if jump_attack_active or blunt_contact:
			PHYSICAL_FEEL.burst(get_tree().current_scene, candidate.global_position + Vector2(0, -14), "slam", 1.40 if jump_attack_active else 0.92, attack_direction, sword.visual_seed() if sword != null else 1)
		if not blunt_contact:
			_spawn_blade_blood(candidate.global_position + Vector2(0.0, -32.0), fx_color, fx_accent, fx_impact, fx_tier, sword.visual_seed() if sword != null else 0)
			# Daggers already have a physical blade and dedicated tip glow;
			# the large crescent slash contradicted the stabbing motion.
			if active_attack_style != "dagger":
				_spawn_rose_slash(candidate.global_position + Vector2(0.0, -28.0))
		_spawn_spectacle("strike", candidate.global_position + Vector2(0.0, -27.0), fx_color, fx_motif, fx_tier, fx_accent, fx_trail)
		if counter_hit and not counter_shown:
			_spawn_precision_feedback("riposte", candidate.global_position + Vector2(0.0, -30.0), attack_direction)
			counter_shown = true
		struck = true
		camera_kick = maxf(camera_kick, 8.3 if jump_attack_active else (3.9 if heavy_attack else 2.1))
		camera_push = attack_direction * (6.5 if jump_attack_active else (3.5 if heavy_attack else 1.8))
	# Heavy and plunging attacks physically interact with ordinary wooden
	# barricades, not progression locks. Each prop is hit once per strike.
	if heavy_attack:
		var broken_attempts: int = 0
		for object in get_tree().get_nodes_in_group("breakable_cover"):
			if not is_instance_valid(object) or not object is Node2D or not object.has_method("receive_damage") or bool(object.get("broken")):
				continue
			var toward: Vector2 = object.global_position - global_position
			if toward.length_squared() > pow(minf(reach, 167.0), 2.0) or toward.length_squared() < 100.0:
				continue
			if attack_direction.dot(toward.normalized()) < 0.30:
				continue
			# Stone walls must still block hits through geometry. The breakable
			# object itself is the acceptable first hit on this physics ray.
			var probe: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + Vector2(0.0, -12.0), object.global_position + Vector2(0.0, -12.0))
			probe.collision_mask = 2
			probe.exclude = [get_rid()]
			var obstruction: Dictionary = get_world_2d().direct_space_state.intersect_ray(probe)
			if not obstruction.is_empty() and obstruction.get("collider") != object:
				continue
			object.call("receive_damage", power * (0.90 if jump_attack_active else 0.80), global_position)
			PHYSICAL_FEEL.burst(get_tree().current_scene, object.global_position + Vector2(0.0, -10.0), "wood", 0.72, attack_direction, roundi(object.global_position.x))
			struck_world = true
			broken_attempts += 1
			if broken_attempts >= 2:
				break
	if struck or struck_world:
		# Only confirmed creature or world contact holds the active frame;
		# misses never incur hitstop or resource gain.
		hitstop_left = (0.105 if counter_hit and struck else (0.089 if jump_attack_active else (0.065 if heavy_attack else 0.040)))
		body_art.pause()
		_play_action_sfx(RIPOSTE_SFX if counter_hit and struck else HIT_SFX)
		COMBAT_JUICE.play(get_tree().current_scene, global_position, "parry" if counter_hit and struck else "hit", -14.0 if counter_hit and struck else -18.0)
		if struck_world and not struck:
			camera_kick = maxf(camera_kick, 4.5 if jump_attack_active else 3.0)
			camera_push = attack_direction * (4.0 if jump_attack_active else 2.5)
		if counter_hit and struck:
			camera_kick = maxf(camera_kick, 7.0)
			counter_window = 0.0
	if struck and rally_pool > 0.0 and rally_time_left > 0.0:
		var gained: float = minf(rally_pool, power * 0.38 * (1.0 + _stat("rally_power_pct") / 100.0))
		rally_pool -= gained
		health = minf(maximum_health(), health + gained)
		world.ui.set_health(health, maximum_health())

	if (struck or struck_world) and sword != null and sword.ethereal:
		if world.inventory.wear_ethereal(sword):
			world.ui.show_pickup("ETHEREAL WEAPON BROKEN · " + sword.definition.display_name, Color("d9b6cf"))
		elif sword.durability == 10:
			world.ui.show_pickup("ETHEREAL WEAPON · 10 USES REMAIN", Color("d9b6cf"))

func on_world_impact(point: Vector2, strength: float) -> void:
	# Physical sources can shake the camera, but only if close enough to matter.
	var distance: float = global_position.distance_to(point)
	if distance > 750.0:
		return
	var falloff: float = pow(1.0 - distance / 750.0, 1.5)
	camera_kick = maxf(camera_kick, minf(12.0, strength * falloff))
	var away: Vector2 = (global_position - point).normalized() if distance > 0.01 else -facing
	camera_push = away * minf(7.5, strength * falloff * 0.64)

func _spawn_blade_blood(where: Vector2, tint: Color, accent: Color, impact_style: int, tier: int, seed_value: int) -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var splash: Node2D = Node2D.new()
	splash.set_script(IMPACT_PRESTIGE)
	root.add_child(splash)
	splash.global_position = where
	splash.call("configure", "blood", tint, accent, impact_style, tier, attack_direction, seed_value)

func _spawn_spectacle(kind: String, where: Vector2, tint: Color, motif: int, tier: int, accent: Color = Color("eacbed"), trail: int = 0) -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	var burst: Node2D = Node2D.new()
	burst.set_script(SPECTACLE)
	# Assign all state before entering the tree. No version-dependent
	# configure(...) calls: these previously caused argument-count errors.
	burst.set("effect_kind", kind)
	burst.set("ink", tint)
	burst.set("motif", motif)
	burst.set("accent", accent)
	burst.set("trail_style", trail)
	burst.set("rarity", maxi(0, tier))
	burst.set("facing", attack_direction.normalized() if attack_direction.length_squared() > 0.01 else Vector2.RIGHT)
	var duration: float = 0.52 if kind == "riposte" else (0.42 if kind == "ready" else 0.32)
	burst.set("lifetime", duration)
	burst.set("life", duration)
	parent.add_child(burst)
	burst.global_position = where

func _spawn_rose_slash(where: Vector2) -> void:
	var effect: AnimatedSprite2D = AnimatedSprite2D.new()
	effect.sprite_frames = ROSE_SLASH_FX
	effect.animation = ("heavy_" if heavy_attack else "light_") + facing_name
	effect.scale = Vector2(0.52, 0.52)
	effect.z_index = 40
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	scene_root.add_child(effect)
	effect.global_position = where
	effect.animation_finished.connect(effect.queue_free)
	effect.play()

func _draw() -> void:
	if bow_draw_active:
		# v1.42: quiet thin tension bar beneath her feet. No magic ring in front
		# of Ghost Girl or the bow, and the final frame holds until release.
		var ratio: float = clampf(bow_draw_time / BOW_FULL_DRAW_TIME, 0.0, 1.0)
		var ink: Color = Color("d8b9d6") if ratio < 1.0 else Color("c9dec6")
		draw_line(Vector2(-19, 6), Vector2(19, 6), Color(0.62, 0.54, 0.65, 0.25), 2.0, true)
		draw_line(Vector2(-19, 6), Vector2(-19 + ratio * 38.0, 6), Color(ink.r, ink.g, ink.b, 0.60), 1.7, true)
		if ratio >= 1.0:
			draw_line(Vector2(19, 2), Vector2(19, 10), Color(ink.r, ink.g, ink.b, 0.56), 1.2, true)
	if is_instance_valid(lock_target):
		var locked: Vector2 = to_local(lock_target.global_position)
		draw_arc(locked + Vector2(0, 8), 34.0, 0.0, TAU, 44, Color(0.82,0.63,0.57,0.52), 2.0, true)
		draw_circle(locked + Vector2(0,-72), 3.0, Color(0.98,0.76,0.60,0.83))
	if counter_window > 0.0:
		draw_arc(Vector2(0, -22), 35.0, 0.18, PI - 0.18, 24, Color(0.89, 0.76, 0.59, 0.32 * minf(1.0, counter_window * 4.0)), 2.0, true)
	# Sword/unarmed animations already include carefully aligned slash trails;
	# painting the old debug arc here created the doubled crescent in screenshots.
	if dodge_time_left > 0.0:
		draw_circle(Vector2(0, -28), 30, Color(0.70, 0.75, 0.90, 0.09))
	if jump_time_left > 0.0:
		var jump_progress: float = 1.0 - jump_time_left / maxf(0.01, jump_duration)
		var air: float = sin(jump_progress * PI)
		draw_arc(Vector2(0, -12), 22.0 + air * 8.0, 0.0, TAU, 28, Color(0.88, 0.78, 0.98, 0.10 + 0.07 * air), 1.4, true)
		if jump_attack_active:
			# Aerial silk-arc motion is presentation-only; the real hit path remains
			# _strike_jump_attack(), exactly once at its original progress gate.
			var fade: float = 0.55 * sin(clampf((jump_progress - 0.07) / 0.88, 0.0, 1.0) * PI)
			var side: float = -1.0 if facing_name == "left" else 1.0
			var center: Vector2 = Vector2(side * 13.0, -46.0 - air * 21.0)
			draw_arc(center, 29.0, -PI * 0.67, PI * 0.13, 20, Color(0.78, 0.71, 0.93, maxf(0.0, fade)), 1.45, true)

func maximum_health() -> float:
	var vitality: float = world.inventory.get_stat_total("vitality_pct") if world != null and world.inventory != null else 0.0
	return 100.0 * (1.0 + vitality / 100.0)

func _begin_heal() -> void:
	if dew_charges <= 0 or health >= maximum_health() - 0.01 or is_throwing or hook_gesture_left > 0.0 or rose_hook.is_pulling_player():
		return
	dew_charges -= 1
	healing_time_left = HEAL_WINDUP
	stamina_recovery_left = STAMINA_RECOVERY_WAIT
	world.ui.set_dew(dew_charges, MAX_DEW)

func clear_lock_target() -> void:
	lock_target = null
	if world != null and world.ui != null:
		world.ui.set_lock_target("")


# Mouse wheel cycles visible threats while locked on. The inventory remains
# the owner of wheel input when an equipment or backpack menu is open.
func _unhandled_input(event: InputEvent) -> void:
	if world == null or world.ui.is_menu_open() or not is_instance_valid(lock_target):
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_lock_target(1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_lock_target(-1)
			get_viewport().set_input_as_handled()

func _cycle_lock_target(direction: int) -> void:
	if not is_instance_valid(lock_target):
		return
	var center_angle: float = (lock_target.global_position - global_position).angle()
	var closest_offset: float = INF
	var best: Node2D = null
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or not candidate is Node2D or candidate == lock_target:
			continue
		var enemy: Node2D = candidate as Node2D
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() < 1.0 or offset.length() > LOCK_RANGE:
			continue
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -23), enemy.global_position + Vector2(0, -23))
		query.collision_mask = 2
		query.exclude = [get_rid()]
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			continue
		var difference: float = wrapf((offset.angle() - center_angle) * float(direction), 0.0, TAU)
		if difference < closest_offset and difference > 0.005:
			closest_offset = difference
			best = enemy
	if best != null:
		lock_target = best
		world.ui.set_lock_target("ENEMY")

func _validate_lock_target() -> void:
	if lock_target == null:
		return
	if not is_instance_valid(lock_target) or not lock_target.is_inside_tree() or not lock_target.is_in_group("enemies"):
		clear_lock_target()
		return
	if global_position.distance_to(lock_target.global_position) > LOCK_RANGE * 1.25:
		clear_lock_target()

func _toggle_lock_target() -> void:
	if is_instance_valid(lock_target):
		clear_lock_target()
		return
	var winner: Node2D = null
	var best_score: float = -INF
	var cursor: Vector2 = get_global_mouse_position() - global_position
	var aim: Vector2 = cursor.normalized() if cursor.length_squared() > 1.0 else facing
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or not candidate is Node2D:
			continue
		var enemy: Node2D = candidate as Node2D
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() > LOCK_RANGE or offset.length() < 0.1:
			continue
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -23), enemy.global_position + Vector2(0, -23))
		query.collision_mask = 2
		query.exclude = [get_rid()]
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			continue
		var alignment: float = aim.dot(offset.normalized())
		var score: float = alignment * 160.0 - offset.length() * 0.2
		if score > best_score:
			winner = enemy
			best_score = score
	lock_target = winner
	world.ui.set_lock_target("ENEMY" if winner != null else "")

# Original subdued one-shots; no external audio files or commercial samples.
func _play_action_sfx(stream: AudioStream) -> void:
	if action_sfx == null:
		return
	# Older baked attack samples layered too loudly over the new, softer
	# procedural foley. Keep contact audible without a metallic jump-scare.
	action_sfx.volume_db = -18.0 if stream == HIT_SFX else (-16.0 if stream == SWING_SFX else (-12.0 if stream == RIPOSTE_SFX else -10.0))
	action_sfx.stream = stream
	action_sfx.play()
