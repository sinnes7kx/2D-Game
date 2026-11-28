extends CharacterBody2D
## Original 2D Ghost Girl. 4 directions, editor-authored SpriteFrames.
## New gesture frames (hook_front / back / left / right) contain the ornate
## rose hook at her hand, with slight reach/lean animation during casting.

const COMBAT_GEOMETRY = preload("res://scripts/combat_geometry.gd")
const MELEE_RULES = preload("res://scripts/combat/melee_rules.gd")
const PLAYBACK = preload("res://scripts/animation/directional_playback.gd")
const GROUNDED = preload("res://scripts/combat/grounded_motion.gd")
const BOW_ARROW_SCENE: PackedScene = preload("res://scenes/bow_arrow_v126.tscn")
const BOW_RELEASE_FX: Script = preload("res://scripts/bow_release_v127.gd")
const CROSSBOW_V236 = preload("res://scripts/crossbow_v236.gd")
const WEAPON_MODS_V250 = preload("res://scripts/weapon_mods_v250.gd")
const FORGE_V238 = preload("res://scripts/bow_dagger_forge_v238.gd")
const VISUAL_CHOICES_V216 = preload("res://scripts/visual_choices_v216.gd")
const WAND_ANCHORS_V216 = preload("res://scripts/wand_anchors_v216.gd")
const EXTRA_ANIMATIONS = preload("res://scripts/ghost_animation_library.gd")
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const WALK_V223 = preload("res://scripts/walk_inbetweens_v223.gd")
const SWORD_V224 = preload("res://scripts/sword_attack_frames_v224.gd")
const SILK_V226 = preload("res://scripts/silk_motion_v226.gd")
var silk_motion: RefCounted = SILK_V226.new()
var had_player_draw: bool = false
const MOTION_V225 = preload("res://scripts/action_motion_samples_v225.gd")
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
const FORGE_TACTICS_V286 = preload("res://scripts/forge_tactics_v286.gd")
const COMBAT_JUICE: Script = preload("res://scripts/combat_juice_v194.gd")
const SWING_WAKE: Script = preload("res://scripts/swing_wake_v198.gd")
const TIP_EXTENSION_V198: Script = preload("res://scripts/weapon_tip_extension_v198.gd")
const RIPOSTE_SFX: AudioStream = preload("res://assets/audio/riposte_chime_v113.wav")
const COMBAT_RESPONSE_V157: Script = preload("res://scripts/combat_response_v157.gd")
const DODGE_SFX: AudioStream = preload("res://assets/audio/dodge_wisp.wav")
const HOOK_SFX: AudioStream = preload("res://assets/audio/hook_chime.wav")
const WALK_SPEED: float = GROUNDED.WALK_SPEED
const SPRINT_SPEED: float = GROUNDED.SPRINT_SPEED
const MOVE_ACCELERATION: float = GROUNDED.MOVE_ACCELERATION
const MOVE_BRAKE: float = GROUNDED.MOVE_BRAKE
const TURN_ACCELERATION: float = GROUNDED.TURN_ACCELERATION
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
const CHARGE_WALK_FACTOR: float = GROUNDED.CHARGE_WALK_FACTOR
const PARRY_WINDOW: float = 0.32
const PARRY_PERFECT_START: float = 0.04
const PARRY_PERFECT_END: float = 0.15
const PARRY_DURATION: float = 0.55
var parry_left: float = 0.0
var parry_age: float = 0.0
var parry_used: bool = false
var parry_heading: Vector2 = Vector2.DOWN
const AIR_LANDING_BUFFER: float = 0.19  # Accept dodge/follow-up just before feet touch the ground.
const STAMINA_RECOVERY_WAIT: float = 0.50


var world
# Isolated character-screen actor, never registered as a gameplay player.
var equipment_preview_only: bool = false
var facing: Vector2 = Vector2.DOWN
const DIRECTIONS_V245 = preload("res://scripts/direction_controller_v245.gd")
const SKIN_V246 = preload("res://scripts/rose_nocturne_skin_v246.gd")
const DIAGONAL_ART_V247 = preload("res://scripts/ghost_diagonal_art_v247.gd")
# facing_name stays the existing artwork suffix used by every weapon rig.
var facing_name: String = "front"
var facing_octant: int = 2
var facing_eight_name: String = "front"
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
var crossbow_stage: int = 0
var crossbow_left: float = 0.0
var crossbow_heavy: bool = false
var crossbow_item: GhostItemInstance = null
var crossbow_heading: Vector2 = Vector2.RIGHT
var crossbow_fired: bool = false
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
var buffered_special_v261: bool = false
const THROW_MIN_V276: float = 0.16
const THROW_MAX_V276: float = 0.90
var throw_charge_active_v276: bool = false
var throw_charge_time_v276: float = 0.0
var throw_charge_ready_v276: bool = false
var thrown_lock_v273 = preload("res://scripts/thrown_weapon_lock_v273.gd").new()

func thrown_weapon_busy_v273() -> bool:
	return thrown_lock_v273.busy()

func throw_charge_ratio_v276() -> float:
	return clampf((throw_charge_time_v276-THROW_MIN_V276)/(THROW_MAX_V276-THROW_MIN_V276),0.0,1.0)

func clear_throw_charge_v276() -> void:
	throw_charge_active_v276=false
	throw_charge_time_v276=0.0
	throw_charge_ready_v276=false
	dagger_charge_active=false

func thrown_impact_v276(where: Vector2, heading: Vector2, charge: float) -> void:
	camera_kick=maxf(camera_kick,lerpf(3.2,7.2,charge))
	camera_push=heading*lerpf(2.0,4.0,charge)
	COMBAT_JUICE.play(get_tree().current_scene,where,"throw_impact",-15.0)
	PHYSICAL_FEEL.burst(get_tree().current_scene,where,"slam",lerpf(0.45,0.95,charge),heading,roundi(visual_time*97.0))
	# Never pause a different action or locomotion on a distant projectile hit.
	if attack_time_left>0.0 and attack_hit_done and not active_special_v261.is_empty():
		hitstop_left=maxf(hitstop_left,lerpf(0.025,0.065,charge))
		body_art.pause()

func register_thrown_weapon_v273(shot: Node) -> void:
	thrown_lock_v273.register(shot)
	queued_action=""
	buffered_attack_valid=false
var special_mouse_frame_v272: int = -100
var twinblade_weapon_v272: GhostItemInstance
var twinblade_second_v272: bool = false
var twinblade_reward_v272: bool = false
var twinblade_wear_v272: bool = false
const TWINBLADE_HIT_POWER_V272: float = 0.65
const TWINBLADE_FIRST_GATE_V272: float = 0.66
const TWINBLADE_SECOND_GATE_V272: float = 0.30
const RELIC_MECHANICS_V288 = preload("res://scripts/relic_mechanics_v288.gd")
const RELIC_GROUND_V288 = preload("res://scripts/relic_ground_v288.gd")
var relic_channel_v288: String = ""
var relic_channel_owner_v288: GhostItemInstance
var relic_channel_age_v288: float = 0.0
var relic_spin_angle_v288: float = 0.0
var relic_pulse_v288: float = 0.0
var relic_channel_worn_v288: bool = false
var relic_spin_hits_v288: Dictionary = {}
var relic_cooldowns_v288: Dictionary = {}
const SERAPH_V292 = preload("res://scripts/seraph_descent_v292.gd")
var seraph_item_v292: GhostItemInstance
var seraph_age_v292: float = 0.0
var seraph_axis_v292: Vector2 = Vector2.DOWN
var seraph_hits_v292: int = 0
var ivory_guard_left_v289: float = 0.0
var ivory_guard_item_v289: GhostItemInstance
var ivory_guard_direction_v289: Vector2 = Vector2.DOWN
var active_special_v261: String = ""
var special_weapon_v261: GhostItemInstance = null
const RELIC_ARSENAL_V277 = preload("res://scripts/relic_arsenal_v277.gd")
var ranged_relic_v277: String = ""
var ranged_relic_item_v277: GhostItemInstance = null
const UNIQUE_SPECIALS_V261 = preload("res://scripts/unique_specials_v261.gd")
const DANCE_V262 = preload("res://scripts/eclipse_dance_v262.gd")
var dance_stage_v262: int = 0
var dance_elapsed_v262: float = 0.0
var dance_hit_index_v262: int = 0
var dance_follow_v262: bool = false
var dance_worn_v262: bool = false
var dance_heading_v262: Vector2 = Vector2.RIGHT

var dodge_time_left: float = 0.0
var dodge_direction: Vector2 = Vector2.DOWN
var jump_time_left: float = 0.0
var jump_duration: float = 0.0
var jump_direction: Vector2 = Vector2.DOWN
var jump_strike_direction: Vector2 = Vector2.DOWN
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
var finisher_lights: int = 0
var finisher_weapon: GhostItemInstance = null
var active_finisher: bool = false
var active_lunge: bool = false
var lunge_window: float = 0.0
const IMPACT_MATERIAL_V239 = preload("res://scripts/arrow_impact_audio_v233.gd")
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
	_install_empty_throw_carry_v276()
	# Replace only two malformed baked-weapon ATTACKS with the untouched, approved
	# body action frames; the v172 pose layer supplies the weapon per frame.
	V172_POSE_SCRIPT.install_attack_frames(body_art)
	CROSSBOW_V236.install(body_art.sprite_frames)
	FORGE_V238.install(body_art.sprite_frames)
	preload("res://scripts/weapon_models_v283.gd").install(body_art.sprite_frames)
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
		SKIN_V246.install(body_art.sprite_frames)
		DIAGONAL_ART_V247.install(body_art.sprite_frames)
		GENTLE.prepare_timing(body_art.sprite_frames)
		body_art.play("idle_front")
		_update_hand()
		return
	# Preview never walks; avoid allocating its extra locomotion textures.
	WALK_V223.install(body_art)
	# After AIR installation: airborne art and frame-indexed charge gates
	# remain unchanged. Only ordinary ground sword clips gain samples.
	SWORD_V224.install(body_art)
	SKIN_V246.install(body_art.sprite_frames)
	if not DIAGONAL_ART_V247.install(body_art.sprite_frames):
		push_warning(DIAGONAL_ART_V247.diagnostic()+" Cardinal fallback remains active.")
	GENTLE.prepare_timing(body_art.sprite_frames)
	collision_mask |= JUMPABLE_BARRIER_MASK
	add_to_group("ghost_girl_player")
	blink_rng.randomize()
	blink_cooldown = blink_rng.randf_range(4.5, 9.0)
	body_art.play("idle_front")
	_update_hand()

# Reset interpolation AFTER a teleport so rooms and shrines never streak.
func snap_render_after_teleport() -> void:
	silk_motion.call("reset")
	reset_physics_interpolation()
	var camera: Camera2D = get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.reset_smoothing()

func _physics_process(delta: float) -> void:
	if world == null:
		return
	if world.ui.is_menu_open() or world.ui.has_cursor_item():
		parry_left = 0.0
		_clear_seraph_v292()
		_clear_ivory_guard_v289()
		_end_relic_channel_v288()
		if throw_charge_active_v276:
			clear_throw_charge_v276()
			attack_time_left=0.0
			active_special_v261=""
			special_weapon_v261=null
			_play_if_changed(_weapon_motion_prefix(false)+facing_name)
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
	lunge_window = maxf(0.0, lunge_window - delta)
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
	if Input.is_action_just_pressed("use_dew") and parry_left <= 0.0 and healing_time_left <= 0.0 and attack_time_left <= 0.0 and crossbow_stage == 0 and dodge_time_left <= 0.0 and jump_time_left <= 0.0 and relic_channel_v288.is_empty() and ivory_guard_left_v289<=0.0 and seraph_item_v292==null:
		_begin_heal()
	if parry_left > 0.0:
		parry_age += delta
		parry_left = maxf(0.0,parry_left-delta)
		velocity = Vector2.ZERO
		move_and_slide()
		return
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
	if seraph_item_v292!=null:
		_advance_seraph_v292(delta)
		return
	if ivory_guard_left_v289>0.0:
		_advance_ivory_guard_v289(delta)
		return
	if not relic_channel_v288.is_empty():
		_advance_relic_channel_v288(delta)
		return
	if attack_time_left <= 0.0 and crossbow_stage == 0 and bow_time_left <= 0.0 and not bow_draw_active and dodge_time_left <= 0.0 and jump_time_left <= 0.0 and stamina_recovery_left <= 0.0:
		stamina = minf(MAX_STAMINA, stamina + 39.0 * (1.0 + _stat("stamina_recovery_pct") / 100.0) * delta)
	world.ui.set_stamina(stamina, MAX_STAMINA)
	# HOLD is a real state: frame 5 stays visible for as long as RMB is held.
	# A released button fires exactly one arrow and plays recovery frames 6-7.
	if crossbow_stage != 0:
		_advance_crossbow(delta)
		if jump_time_left > 0.0:
			_advance_jump(delta)
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		return
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
		if jump_time_left <= 0.0 and Input.is_action_just_pressed("dodge") and stamina >= _action_cost(DODGE_COST,true):
			_cancel_bow_charge_for_dodge()
			_begin_dodge()
			return
		_advance_bow_draw(delta)
		if jump_time_left > 0.0:
			_advance_jump(delta)
		elif bow_draw_active:
			_charge_walk(delta)
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
			elif Input.is_action_just_pressed("attack_light") and stamina >= (_attack_action_cost(false) if _weapon_style() in ["bow", "crossbow"] else _attack_action_cost(true)):
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
			lunge_window = 0.48
			backstep_counter_armed = false
			precision_evade_registered = false
		return
	if attack_time_left > 0.0:
		if active_special_v261 == DANCE_V262.ID:
			_advance_eclipse_dance_v262(delta)
			return
		# Press during late recovery to flow into a follow-up strike or dodge.
		if attack_hit_done and attack_time_left <= 0.25:
			if Input.is_action_just_pressed("dodge"):
				_queue_combat("dodge")
			elif Input.is_action_just_pressed("attack_heavy"):
				_queue_combat("heavy")
			elif Input.is_action_just_pressed("attack_light"):
				_queue_combat("light")
		if dagger_charge_active or throw_charge_active_v276:
			if Input.is_action_just_pressed("dodge") and stamina >= _action_cost(DODGE_COST,true):
				clear_throw_charge_v276()
				dagger_charge_active = false
				attack_time_left = 0.0
				active_special_v261 = ""
				special_weapon_v261 = null
				queued_action = ""
				buffered_attack_valid = false
				_begin_dodge()
				return
			_refresh_melee_charge_aim()
		_advance_attack(delta)
		if throw_charge_active_v276 or dagger_charge_active:
			_charge_walk(delta)
			move_and_slide()
			return
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
		if active_lunge and not attack_hit_done and not dagger_charge_active:
			velocity += attack_direction * (380.0 if active_special_v261 == "penitent_plunge" else 240.0) * thrust
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
		if Input.is_action_just_pressed("parry") and carrying == null and stamina >= _action_cost(16.0,false):
			_begin_parry()
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

	var direction: Vector2 = _movement_input()
	# Deliberate grounded movement: controlled acceleration, firm braking, and
	# a slight cost for turning sharply instead of instantly floating sideways.
	var moving: bool = direction.length_squared() > 0.01
	var sprinting: bool = moving and Input.is_action_pressed("sprint") and stamina > 12.0
	var speed_bonus: float = world.inventory.get_stat_total("move_speed_pct") if world.inventory != null else 0.0
	var desired_speed: float = (SPRINT_SPEED if sprinting else WALK_SPEED) * (1.0 + speed_bonus / 100.0)
	# Shallow moor water impedes grounded movement; Moonfall's temporary ice
	# restores normal footing. Jumping, dodging and the rose hook are unaffected.
	desired_speed = GROUNDED.terrain_speed(self,desired_speed)
	velocity = GROUNDED.walking_velocity(velocity,direction,desired_speed,delta)
	if sprinting:
		stamina = maxf(0.0, stamina - SPRINT_STAMINA_PER_SECOND * delta)
		stamina_recovery_left = maxf(stamina_recovery_left, 0.25)
		world.ui.set_stamina(stamina, MAX_STAMINA)
	sprint_dust_time = maxf(0.0, sprint_dust_time - delta)
	if sprinting and velocity.length() > WALK_SPEED * 1.05 and sprint_dust_time <= 0.0:
		sprint_dust_time = 0.28
		PHYSICAL_FEEL.burst(get_tree().current_scene, global_position + Vector2(0, -6), "landing", 0.35, -direction, roundi(visual_time * 51.0))
	# Face the aim even when standing still, backpedalling or strafing.
	# Committed actions return above this block and retain their own facing.
	set_facing(_free_facing_direction(direction))
	if moving:
		blink_active = 0.0
		var travel_prefix: String = _weapon_motion_prefix(true)
		_play_if_changed(travel_prefix + facing_name)
		body_art.speed_scale = clampf(velocity.length() / WALK_SPEED, 0.75, 1.55)
	else:
		body_art.speed_scale = 1.0
		blink_cooldown -= delta
		if facing_name != "back" and blink_cooldown <= 0.0 and blink_active <= 0.0:
			blink_active = 0.52
			blink_cooldown = blink_rng.randf_range(4.5, 10.5)
		if world.inventory.get_equipped("sword") != null or world.inventory.get_equipped("wand") != null:
			blink_active = 0.0  # Keep the actual equipped idle pose and wrist guide.
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
	# CanvasItem retains draw commands; don't rebuild an empty canvas at
	# render FPS when no target/charge/dodge/jump indicator is present.
	var needs_draw: bool = parry_left > 0.0 or throw_charge_active_v276 or dance_stage_v262 == 1 or bow_draw_active or is_instance_valid(lock_target) or counter_window > 0.0 or dodge_time_left > 0.0 or jump_time_left > 0.0
	if needs_draw or had_player_draw:
		queue_redraw()
	had_player_draw = needs_draw
	if not is_instance_valid(body_art):
		return
	silk_motion.call("update", body_art, velocity, delta, hitstop_left > 0.0)
	if hurt_recoil_left > 0.0:
		var recoil: float = hurt_recoil_left / 0.19
		body_art.position = BASE_ART_POS - hurt_direction * 3.0 * recoil
		body_art.rotation = 0.065 * hurt_direction.x * recoil
		body_art.scale = Vector2.ONE * BASE_ART_SCALE
	elif seraph_item_v292!=null:
		var lift: float = SERAPH_V292.height_at(seraph_age_v292)
		body_art.position=BASE_ART_POS+Vector2(seraph_axis_v292.x*lift*0.06,-lift)
		body_art.rotation=seraph_axis_v292.x*0.07*sin(PI*seraph_age_v292/SERAPH_V292.DURATION)
		body_art.scale=Vector2.ONE*BASE_ART_SCALE
		hand.position=_hand_position_for_facing()+Vector2(0,-lift)
	elif dance_stage_v262 > 0 and attack_time_left > 0.0:
		var spin: float = DANCE_V262.spin(dance_stage_v262,dance_elapsed_v262)
		var envelope: float = sin(clampf(dance_elapsed_v262/attack_duration,0.0,1.0)*PI)
		body_art.position = BASE_ART_POS + Vector2(0,-5.0*envelope*absf(sin(spin)))
		body_art.rotation = sin(spin)*0.065*envelope
		body_art.scale = Vector2.ONE*BASE_ART_SCALE
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
	# Attach the shared hand marker to the actual diagonal wrist after body motion.
	var visible_hand: Vector2 = DIAGONAL_ART_V247.hand_local(body_art)
	if visible_hand != Vector2.INF and not is_throwing and hook_gesture_left<=0.0 and not rose_hook.is_pulling_player():
		hand.position = to_local(body_art.to_global(visible_hand))
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
	if held != null and held.uses_forge_bow():
		return "forge_bow"
	return held.bow_art_style() if held != null else "thornrose"

func _uses_modular_sword() -> bool:
	if world == null or world.inventory == null:
		return false
	var held: GhostItemInstance = world.inventory.get_equipped("sword")
	return held != null and held.uses_modular_single_sword()

func _weapon_art_style() -> String:
	# Different bases within a combat class use truly different painted frames.
	# Animation identity only: no gameplay/stat/save field is changed.
	if world == null or world.inventory == null:
		return _weapon_style()
	var weapon: GhostItemInstance = world.inventory.get_equipped("sword")
	if weapon == null or weapon.definition == null:
		return _weapon_style()
	if weapon.uses_forge_dagger():
		return "forge_dagger"
	match str(weapon.definition.item_id):
		"ashglass_warmaul_v170": return "ashglass_maul"
		"rosemirror_twinblade_v170": return "rosemirror_twinblade"
		"nocturne_stiletto_v171": return "nocturne_dagger"
		"briarwake_trident_v171": return "briarwake_spear"
		"seraph_reaper_v292": return "seraph_scythe"
	return weapon.weapon_style()

func _install_empty_throw_carry_v276() -> void:
	var frames: SpriteFrames = body_art.sprite_frames
	for face in ["front","back","left","right"]:
		var source: String = "attack_unarmed_light_"+face
		if not frames.has_animation(source) or frames.get_frame_count(source)<8:
			continue
		for motion in ["idle","walk"]:
			var clip: String = "throw_empty_"+motion+"_"+face
			if frames.has_animation(clip):
				continue
			frames.add_animation(clip)
			frames.set_animation_loop(clip,true)
			frames.set_animation_speed(clip,8.0)
			var sequence: Array[int] = [0,0,0,0,0,0,0,0]
			if motion == "walk":
				sequence.assign([0,1,2,1,0,1,2,1])
			for i in sequence:
				frames.add_frame(clip,frames.get_frame_texture(source,i))

func _weapon_motion_prefix(moving: bool) -> String:
	if thrown_weapon_busy_v273():
		return "throw_empty_walk_" if moving else "throw_empty_idle_"
	if _weapon_style() == "crossbow":
		return "crossbow_walk_" if moving else "crossbow_idle_"
	if _weapon_style() == "bow":
		# v1.68: the generic idle/walk images contain a painted rose hook.
		# Use the dedicated, hook-free bow locomotion atlases instead.
		# The attack/draw/release sprites are intentionally unchanged.
		return _bow_art_style() + ("_walk_" if moving else "_idle_")
	if world.inventory.get_equipped("wand") != null:
		return "wand_walk_" if moving else "wand_idle_"
	var style: String = _weapon_style()
	if style in ["scythe", "halberd", "dagger", "spear", "maul", "twinblade", "dual_dagger", "dual_sword", "rapier", "axe"]:
		return _weapon_art_style() + ("_walk_" if moving else "_idle_")
	if style == "blade":
		return "sword_modular_" + ("walk_" if moving else "idle_") if _uses_modular_sword() else ("sword_walk_" if moving else "sword_idle_")
	return "walk_" if moving else "idle_"

func _melee_cost(heavy: bool) -> float:
	if thrown_weapon_busy_v273():
		return INF
	var base: float = _action_cost(HEAVY_ATTACK_COST if heavy else LIGHT_ATTACK_COST, false)
	match _weapon_style():
		"scythe": return base * 1.05
		"halberd": return base * 1.13
		"dagger": return base * 0.79
		"dual_dagger": return base * 0.88
		"dual_sword": return base * 1.14
		"spear": return base * 1.09
		"maul": return base * 1.25
		"rapier": return base * 0.90
		"axe": return base * 1.20
		"twinblade": return base * 0.90
		_: return base

func _attack_action_cost(heavy: bool) -> float:
	if thrown_weapon_busy_v273():
		return INF
	if heavy and world!=null and (_special_modifier_v272() or (buffered_attack_valid and buffered_special_v261)):
		var skill_v289: String = UNIQUE_SPECIALS_V261.kind(world.inventory.get_equipped("sword"))
		if skill_v289=="seraph_descent":
			return _action_cost(SERAPH_V292.COST,false)
		if skill_v289=="ivory_duelist_rapier_v286":
			return _action_cost(18.0,false)
		if RELIC_MECHANICS_V288.is_channel(skill_v289):
			return 5.0
	if _weapon_style() == "crossbow":
		return _action_cost(26.0 if heavy else 18.0, false)
	if _weapon_style() == "bow":
		return _action_cost(29.0 if heavy else 14.0, false)
	if world != null and world.inventory != null and world.inventory.get_equipped("wand") != null:
		return _action_cost(HEAVY_ATTACK_COST if heavy else LIGHT_ATTACK_COST, false)
	return _melee_cost(heavy)

func _resolve_skin_clip(animation_name: String) -> String:
	var armed: bool = world == null or world.inventory == null
	if not armed:
		armed = world.inventory.get_equipped("sword") != null or world.inventory.get_equipped("wand") != null
	return PLAYBACK.locomotion_clip(animation_name,facing_eight_name,facing_name,armed,body_art.sprite_frames)

func _play_if_changed(animation_name: String) -> void:
	PLAYBACK.play_locomotion(body_art,_resolve_skin_clip(animation_name))

# Combat state owns duration; the shared playback module owns display timing.
func _play_action_frames(animation_name: String, duration: float) -> void:
	action_animation_rate=PLAYBACK.play_action(body_art,animation_name,facing_eight_name,facing_name,duration)

func _resume_timed_action() -> void:
	if crossbow_stage != 0:
		return # Crossbow poses follow the physics clock, not sprite playback.
	PLAYBACK.resume_action(body_art,action_animation_rate)

func set_facing(direction: Vector2) -> void:
	if direction.length_squared() < DIRECTIONS_V245.DEAD_ZONE_SQUARED:
		return
	facing_octant = DIRECTIONS_V245.octant(direction, facing_octant)
	facing_eight_name = DIRECTIONS_V245.NAMES[facing_octant]
	facing = DIRECTIONS_V245.heading(facing_octant)
	facing_name = DIRECTIONS_V245.pose_name(facing_octant)
	# Keep the visual hand marker aligned to the actual cardinal sprite.
	_update_hand()

var controller_active_v260: bool = false
var touch_aim_active: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
		special_mouse_frame_v272=Engine.get_physics_frames() if event.shift_pressed else -100
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		touch_aim_active = true
		controller_active_v260 = false
	elif event is InputEventJoypadButton and event.pressed:
		controller_active_v260 = true
		touch_aim_active = false
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.30:
		controller_active_v260 = true
		touch_aim_active = false
	elif (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed and event.device != -1) or (event is InputEventMouseMotion and event.device != -1 and event.relative.length_squared() > 4.0):
		controller_active_v260 = false
		touch_aim_active = false

func _special_modifier_v272() -> bool:
	return Input.is_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_SHIFT) or Engine.get_physics_frames()-special_mouse_frame_v272<=2

func _movement_input() -> Vector2:
	var keyboard: Vector2 = DIRECTIONS_V245.keyboard_vector()
	var touch: Vector2 = Vector2.ZERO
	if world != null:
		var ui: Node = world.get("ui") as Node
		if ui != null and ui.has_method("get_joystick_vector"):
			touch = ui.call("get_joystick_vector")
	return DIRECTIONS_V245.movement(keyboard, touch, DIRECTIONS_V245.stick(JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y))

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
	# The old area-cast entry points cannot bypass unique item ownership.
	if moonfall or not new_kind.is_empty():
		return
	if thrown_weapon_busy_v273() or carrying != null:
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
	spell_aim_point = _select_wand_target(global_position + _combat_aim_direction() * 350.0 if controller_active_v260 else get_global_mouse_position())
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
	parry_left = 0.0
	_clear_seraph_v292()
	_clear_ivory_guard_v289()
	_end_relic_channel_v288()
	thrown_lock_v273.clear()
	clear_throw_charge_v276()
	ranged_relic_v277=""
	ranged_relic_item_v277=null
	_clear_eclipse_dance_v262()
	active_special_v261 = ""
	special_weapon_v261 = null
	buffered_special_v261 = false
	special_mouse_frame_v272=-100
	twinblade_weapon_v272=null
	twinblade_second_v272=false
	_reset_combo_v239()
	_clear_crossbow()
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
	if amount>0.0 and _try_ivory_guard_v289(attacker_position):
		return
	parry_left = 0.0
	_clear_seraph_v292()
	_clear_ivory_guard_v289()
	_end_relic_channel_v288()
	clear_throw_charge_v276()
	ranged_relic_v277=""
	ranged_relic_item_v277=null
	_clear_eclipse_dance_v262()
	twinblade_second_v272=false
	twinblade_weapon_v272=null
	active_special_v261=""
	special_weapon_v261=null
	_reset_combo_v239()
	# Interrupted reload must not allow instant repeat shots. Keep reload
	# stage after a fired bolt; cancel an unfired wind-up.
	if crossbow_stage == 1 and not crossbow_fired:
		_clear_crossbow()
	elif crossbow_stage != 0:
		crossbow_stage = 2
		crossbow_left = maxf(crossbow_left, CROSSBOW_V236.HEAVY_RELOAD if crossbow_heavy else CROSSBOW_V236.RELOAD_TIME)
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
	_reset_combo_v239()
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
	var movement: Vector2 = _movement_input()
	if movement.length_squared() > 0.04:
		jump_direction = movement.normalized()
	else:
		jump_direction = _free_facing_direction(Vector2.ZERO)
	if jump_direction.length_squared() < 0.001:
		jump_direction = Vector2.DOWN
	jump_direction = jump_direction.normalized()
	set_facing(_free_facing_direction(movement))
	body_art.speed_scale = 1.0
	var clip: String = _diagonal_action_clip("jump", _weapon_motion_prefix(true) + facing_name)
	_play_action_frames(clip, jump_duration)

func _begin_jump_attack(_from_heavy_button: bool = true) -> void:
	if jump_time_left <= 0.0 or jump_attack_active or carrying != null:
		return
	if _weapon_style() == "crossbow":
		_begin_crossbow(_from_heavy_button, true)
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
	jump_strike_direction = attack_direction
	COMBAT_JUICE.play(get_tree().current_scene, global_position, "jump_swing", -14.0)
	var attack_animation: String = ""
	var holding_sword: bool = world.inventory != null and world.inventory.get_equipped("sword") != null
	if holding_sword:
		if active_attack_style in ["scythe", "halberd", "dagger", "spear", "maul", "twinblade", "dual_dagger", "dual_sword", "rapier", "axe"]:
			attack_animation = "attack_" + _weapon_art_style() + ("_heavy_pierce_" if active_attack_style in ["dagger", "dual_dagger", "spear", "rapier"] else "_heavy_") + facing_name
		else:
			attack_animation = ("attack_sword_modular_heavy_" if _uses_modular_sword() else "attack_sword_heavy_") + facing_name
	else:
		attack_animation = "attack_wand_heavy_" + facing_name if world.inventory != null and world.inventory.get_equipped("wand") != null else "attack_unarmed_heavy_" + facing_name
	# Every style has a distinct airborne heavy clip with a faster plunge beat.
	# The physical hit remains the existing single jump-hit event.
	_play_action_frames(AIR_V203.air_name(attack_animation), maxf(0.26, jump_time_left))

func _refresh_air_facing() -> void:
	# Ranged draws, casts and committed strikes own their own animation.
	if jump_attack_active or bow_draw_active or bow_time_left > 0.0 or crossbow_stage != 0:
		return
	var before: String = facing_eight_name
	set_facing(_free_facing_direction(_movement_input()))
	if before == facing_eight_name:
		return
	var clip: String = _diagonal_action_clip("jump", _weapon_motion_prefix(true) + facing_name)
	if clip == str(body_art.animation) or not body_art.sprite_frames.has_animation(clip):
		return
	# Match the current point in the jump instead of restarting it.
	var phase: float = clampf(1.0 - jump_time_left / maxf(0.01, jump_duration), 0.0, 0.999)
	_play_action_frames(clip, jump_duration)
	GENTLE.seek_phase(body_art, phase)

func _advance_jump(delta: float) -> void:
	_refresh_air_facing()
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
		if _weapon_style() not in ["bow", "crossbow"]:
			_strike_jump_attack()
	if jump_time_left <= 0.0:
		# A tiny carry-through avoids a hard dead stop at the first grounded frame.
		velocity = jump_direction * (28.0 if jump_attack_active else 18.0)
		landing_recoil_left = LANDING_RECOIL
		# A small landing cue makes traversal timing legible without changing damage.
		if jump_attack_active and _weapon_style() not in ["bow", "crossbow"]:
			COMBAT_JUICE.play(get_tree().current_scene, global_position, "ground_slam", -13.5)
			PHYSICAL_FEEL.burst(get_tree().current_scene, global_position, "slam", 1.0, jump_direction, roundi(visual_time * 91.0))
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
	attack_direction = jump_strike_direction
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
	_reset_combo_v239()
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
		# Sample the cursor at the start of the backstep, not one tick earlier.
		# Controller/touch retain their previous facing-based retreat.
		var retreat_aim: Vector2 = facing if controller_active_v260 or touch_aim_active else _free_facing_direction(Vector2.ZERO)
		set_facing(retreat_aim)
		dodge_direction = -retreat_aim
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
	var clip: String = _diagonal_action_clip("dodge", "dodge_" + facing_name)
	_play_action_frames(clip, DODGE_DURATION)
	body_art.set_frame_and_progress(0, 0.0)


# Called only from a confirmed hostile strike/bolt collision, directly before
# the existing receive_damage call. Does not create an iframe or remove damage.
# The existing receive_damage() is still the sole authority on health.
func _begin_parry() -> void:
	stamina -= _action_cost(16.0,false)
	stamina_recovery_left = STAMINA_RECOVERY_WAIT
	parry_left = PARRY_DURATION
	parry_age = 0.0
	parry_used = false
	parry_heading = _combat_aim_direction().normalized()
	set_facing(parry_heading)
	velocity = Vector2.ZERO
	_reset_combo_v239()
	_play_if_changed(_weapon_motion_prefix(false)+facing_name)
	world.ui.set_stamina(stamina,MAX_STAMINA)

static func parry_result(age: float, heading: Vector2, offset: Vector2) -> int:
	if age < 0.0 or age > PARRY_WINDOW or not COMBAT_GEOMETRY.facing_contact(offset, heading, 1.0, 0.50):
		return 0
	return 2 if age >= PARRY_PERFECT_START and age <= PARRY_PERFECT_END else 1

# Only a confirmed melee contact from an enemy supporting stagger may parry.
# Hazards, projectiles, and speculative nearby attacks cannot award a parry.
func try_parry_contact(attacker: Node2D) -> bool:
	if parry_left <= 0.0 or parry_used or invulnerable_time > 0.0 or not is_instance_valid(attacker) or not attacker.has_method("on_parried"):
		return false
	var result: int = parry_result(parry_age,parry_heading,attacker.global_position-global_position)
	if result == 0:
		return false
	parry_used = true
	var perfect: bool = result == 2
	attacker.call("on_parried",perfect)
	parry_left = minf(parry_left,0.12 if perfect else 0.22)
	counter_window = 0.95 if perfect else 0.50
	_spawn_precision_feedback("riposte" if perfect else "ready",global_position+Vector2(0,-31),parry_heading)
	COMBAT_JUICE.play(get_tree().current_scene,global_position,"parry",-10.0 if perfect else -16.0)
	camera_kick = maxf(camera_kick,5.0 if perfect else 2.5)
	world.ui.show_pickup("PERFECT PARRY · COUNTER NOW" if perfect else "PARRY")
	return true

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
	var special_requested_v288: bool = buffered_special_v261 if buffered_attack_valid else _special_modifier_v272()
	if heavy and special_requested_v288:
		var owner_v288: GhostItemInstance = world.inventory.get_equipped("sword")
		var id_v288: String = UNIQUE_SPECIALS_V261.kind(owner_v288)
		if id_v288=="seraph_descent":
			buffered_attack_valid=false
			_begin_seraph_v292(owner_v288)
			return
		if id_v288=="ivory_duelist_rapier_v286":
			buffered_attack_valid=false
			_begin_ivory_guard_v289(owner_v288)
			return
		if RELIC_MECHANICS_V288.is_channel(id_v288):
			buffered_attack_valid=false
			_begin_relic_channel_v288(owner_v288,id_v288)
			return
		if not relic_ready_v288(id_v288):
			buffered_attack_valid=false
			world.ui.show_pickup("UNIQUE SKILL IS RECHARGING")
			return
	if stamina < _attack_action_cost(heavy):
		return
	if _weapon_style() in ["bow", "crossbow"] or world.inventory.get_equipped("wand") != null:
		_reset_combo_v239()
	if _weapon_style() == "crossbow":
		_begin_crossbow(heavy, false)
	elif _weapon_style() == "bow":
		_begin_bow_shot(heavy, false)
	elif world.inventory.get_equipped("wand") != null:
		if spell_time_left <= 0.0 and spell_cooldown <= 0.0:
			_begin_spell_cast(heavy)
	else:
		_begin_attack(heavy)


func _begin_seraph_v292(item: GhostItemInstance) -> void:
	var cost: float = _action_cost(SERAPH_V292.COST,false)
	if item==null or item.is_broken() or stamina<cost or not relic_ready_v288("seraph_descent"):
		return
	if attack_time_left>0.0 or jump_time_left>0.0 or dodge_time_left>0.0 or thrown_weapon_busy_v273() or rose_hook.is_pulling_player() or hook_gesture_left>0.0 or is_throwing:
		return
	seraph_item_v292=item
	seraph_age_v292=0.0
	seraph_hits_v292=0
	seraph_axis_v292=_combat_aim_direction().normalized()
	if seraph_axis_v292.is_zero_approx():
		seraph_axis_v292=facing.normalized()
	if seraph_axis_v292.is_zero_approx():
		seraph_axis_v292=Vector2.DOWN
	set_facing(seraph_axis_v292)
	stamina-=cost
	stamina_recovery_left=STAMINA_RECOVERY_WAIT
	queued_action=""
	buffered_attack_valid=false
	_reset_combo_v239()
	relic_commit_v288("seraph_descent",4.0)
	velocity=Vector2.ZERO
	_play_action_frames("attack_seraph_scythe_light_"+facing_name,SERAPH_V292.TURN)
	var fx: Node2D = preload("res://scripts/seraph_wings_fx_v292.gd").new()
	fx.set("actor",self)
	add_child(fx)
	world.ui.set_stamina(stamina,MAX_STAMINA)
	COMBAT_JUICE.play(get_tree().current_scene,global_position,"jump_swing",-15.0)

func _clear_seraph_v292() -> void:
	if seraph_item_v292==null:
		return
	seraph_item_v292=null
	seraph_hits_v292=0
	seraph_age_v292=0.0
	velocity=Vector2.ZERO
	stamina_recovery_left=maxf(stamina_recovery_left,STAMINA_RECOVERY_WAIT)
	if is_instance_valid(body_art):
		body_art.position=BASE_ART_POS
		body_art.rotation=0.0
		body_art.speed_scale=1.0

func _advance_seraph_v292(delta: float) -> void:
	var item: GhostItemInstance = seraph_item_v292
	if item==null or item.is_broken() or world.inventory.get_equipped("sword")!=item:
		_clear_seraph_v292()
		return
	var before: float = seraph_age_v292
	seraph_age_v292=minf(SERAPH_V292.DURATION,before+delta)
	stamina_recovery_left=STAMINA_RECOVERY_WAIT
	# A physical movement skill: keep all solid collision masks enabled.
	velocity=seraph_axis_v292*SERAPH_V292.speed_at(seraph_age_v292)
	move_and_slide()
	if before<SERAPH_V292.TURN and seraph_age_v292>=SERAPH_V292.TURN:
		_play_action_frames(AIR_V203.air_name("attack_seraph_scythe_heavy_"+facing_name),SERAPH_V292.DURATION-SERAPH_V292.TURN)
	if seraph_hits_v292==0 and seraph_age_v292>=SERAPH_V292.RISE_HIT:
		seraph_hits_v292=1
		_seraph_strike_v292(item,false)
	if seraph_hits_v292==1 and seraph_age_v292>=SERAPH_V292.FALL_HIT:
		seraph_hits_v292=2
		_seraph_strike_v292(item,true)
	if seraph_age_v292>=SERAPH_V292.DURATION:
		_clear_seraph_v292()
		landing_recoil_left=LANDING_RECOIL
		_play_if_changed(_weapon_motion_prefix(false)+facing_name)

func _seraph_strike_v292(item: GhostItemInstance,descending: bool) -> void:
	var power: float = (18.0+item.weapon_damage())*(0.78 if not descending else 1.35)*(1.0+_stat("melee_power_pct")/100.0)
	if descending:
		power*=1.0+_stat("heavy_power_pct")/100.0
	var hits: int = SERAPH_V292.strike(self,seraph_axis_v292,power,descending)
	var root: Node = get_tree().current_scene
	COMBAT_JUICE.play(root,global_position,"heavy_swing" if descending else "charged_swing",-14.0)
	if descending:
		PHYSICAL_FEEL.burst(root,global_position,"slam",0.9,seraph_axis_v292,item.visual_seed())
	if hits>0:
		camera_kick=maxf(camera_kick,5.5 if descending else 2.6)
		camera_push=seraph_axis_v292*(2.5 if descending else 1.1)
		COMBAT_JUICE.play(root,global_position,"blade_hit",-15.0)
		if descending and item.ethereal:
			world.inventory.wear_ethereal(item)

func _begin_ivory_guard_v289(item: GhostItemInstance) -> void:
	var cost: float = _action_cost(18.0,false)
	if item==null or item.is_broken() or stamina<cost or not relic_ready_v288("ivory_duelist_rapier_v286"):
		return
	if thrown_weapon_busy_v273() or attack_time_left>0.0 or jump_time_left>0.0 or dodge_time_left>0.0:
		return
	stamina-=cost
	stamina_recovery_left=STAMINA_RECOVERY_WAIT
	ivory_guard_item_v289=item
	ivory_guard_left_v289=0.46
	ivory_guard_direction_v289=_combat_aim_direction().normalized()
	if ivory_guard_direction_v289.is_zero_approx():
		ivory_guard_direction_v289=facing
	set_facing(ivory_guard_direction_v289)
	velocity=Vector2.ZERO
	_reset_combo_v239()
	relic_commit_v288("ivory_duelist_rapier_v286",2.5)
	_play_if_changed(_weapon_motion_prefix(false)+facing_name)
	var fx: Node2D = preload("res://scripts/relic_guard_fx_v289.gd").new()
	fx.set("actor",self)
	add_child(fx)
	COMBAT_JUICE.play(get_tree().current_scene,global_position,"rapier_thrust",-21.0)
	world.ui.set_stamina(stamina,MAX_STAMINA)

func _clear_ivory_guard_v289() -> void:
	ivory_guard_left_v289=0.0
	ivory_guard_item_v289=null

func _advance_ivory_guard_v289(delta: float) -> void:
	if ivory_guard_item_v289==null or ivory_guard_item_v289.is_broken() or world.inventory.get_equipped("sword")!=ivory_guard_item_v289:
		_clear_ivory_guard_v289()
	else:
		ivory_guard_left_v289=maxf(0.0,ivory_guard_left_v289-delta)
		if ivory_guard_left_v289<=0.0:
			_clear_ivory_guard_v289()
	velocity=Vector2.ZERO
	move_and_slide()

func _try_ivory_guard_v289(attacker_position: Vector2) -> bool:
	if ivory_guard_left_v289<=0.0 or ivory_guard_item_v289==null or world==null or world.inventory.get_equipped("sword")!=ivory_guard_item_v289 or ivory_guard_item_v289.is_broken():
		return false
	if not RELIC_MECHANICS_V288.parry_contact_v289(attacker_position-global_position,ivory_guard_direction_v289):
		return false
	# Match a nearby living enemy, rather than granting immunity to hazards.
	var target: Node2D = null
	var best: float = 48.0*48.0
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or not candidate is Node2D or not candidate.has_method("hit"):
			continue
		var point: Vector2 = (candidate as Node2D).global_position
		var distance: float = point.distance_squared_to(attacker_position)
		if distance<best and RELIC_GROUND_V288.clear_path(self,global_position,point):
			target=candidate as Node2D
			best=distance
	if target==null:
		return false
	_clear_ivory_guard_v289()
	counter_window=0.95
	_spawn_precision_feedback("ready",global_position+Vector2(0,-31),ivory_guard_direction_v289)
	COMBAT_JUICE.play(get_tree().current_scene,global_position,"evade",-13.0)
	world.ui.show_pickup("PARRY · STRIKE NOW")
	camera_kick=maxf(camera_kick,2.4)
	return true

func relic_ready_v288(id: String) -> bool:
	return Time.get_ticks_msec()>=int(relic_cooldowns_v288.get(id,0))

func relic_commit_v288(id: String,seconds: float) -> void:
	relic_cooldowns_v288[id]=Time.get_ticks_msec()+roundi(seconds*1000.0)

func _begin_relic_channel_v288(item: GhostItemInstance,id: String) -> void:
	if item==null or item.is_broken() or stamina<5.0 or not Input.is_action_pressed("attack_heavy") or not relic_channel_v288.is_empty():
		return
	if thrown_weapon_busy_v273() or jump_time_left>0.0 or dodge_time_left>0.0 or attack_time_left>0.0:
		return
	var profile: Dictionary = RELIC_MECHANICS_V288.CHANNELS[id]
	relic_channel_owner_v288=item
	relic_channel_v288=str(profile["mode"])
	relic_channel_age_v288=0.0
	relic_spin_angle_v288=0.0
	relic_pulse_v288=0.16
	relic_channel_worn_v288=false
	relic_spin_hits_v288.clear()
	stamina-=5.0
	stamina_recovery_left=STAMINA_RECOVERY_WAIT
	queued_action=""
	buffered_attack_valid=false
	_reset_combo_v239()
	var fx: Node2D = preload("res://scripts/relic_cyclone_fx_v288.gd").new()
	fx.set("actor",self)
	fx.set("mode",relic_channel_v288)
	fx.set("ink",item.glow_gradient_colors()[0])
	add_child(fx)
	world.ui.set_stamina(stamina,MAX_STAMINA)
	COMBAT_JUICE.play(get_tree().current_scene,global_position,"charged_swing",-15.0)

func _end_relic_channel_v288() -> void:
	if relic_channel_v288.is_empty():
		return
	relic_channel_v288=""
	relic_channel_owner_v288=null
	relic_spin_hits_v288.clear()
	stamina_recovery_left=maxf(stamina_recovery_left,STAMINA_RECOVERY_WAIT)
	velocity=Vector2.ZERO

func _advance_relic_channel_v288(delta: float) -> void:
	var item: GhostItemInstance = relic_channel_owner_v288
	var id: String = UNIQUE_SPECIALS_V261.kind(item)
	if item==null or world.inventory.get_equipped("sword")!=item or not RELIC_MECHANICS_V288.is_channel(id) or not Input.is_action_pressed("attack_heavy") or stamina<=0.0:
		_end_relic_channel_v288()
		move_and_slide()
		return
	if Input.is_action_just_pressed("dodge"):
		_end_relic_channel_v288()
		if stamina>=_action_cost(DODGE_COST,true):
			_begin_dodge()
		return
	var profile: Dictionary = RELIC_MECHANICS_V288.CHANNELS[id]
	var drain: float = maxf(float(profile["drain"])*0.55,_action_cost(float(profile["drain"]),false))
	stamina=maxf(0.0,stamina-drain*delta)
	stamina_recovery_left=STAMINA_RECOVERY_WAIT
	world.ui.set_stamina(stamina,MAX_STAMINA)
	if stamina<=0.0:
		_end_relic_channel_v288()
		return
	relic_channel_age_v288+=delta
	var ramp: float = clampf(relic_channel_age_v288/0.85,0.0,1.0)
	var previous_angle: float = relic_spin_angle_v288
	var travel: float = delta*(lerpf(15.0,29.0,RELIC_MECHANICS_V288.bloom_v290(relic_channel_age_v288)) if relic_channel_v288=="hybrid" else lerpf(19.0,35.0,ramp))
	relic_spin_angle_v288=wrapf(previous_angle+travel,0.0,TAU)
	var direction: Vector2 = _movement_input()
	var moving: bool = direction.length_squared()>0.01
	var speed: float = WALK_SPEED*float(profile["move"])*(1.0+_stat("move_speed_pct")/100.0)
	speed=GROUNDED.terrain_speed(self,speed)
	velocity=GROUNDED.channel_velocity(velocity,direction,speed,delta)
	if moving:
		set_facing(direction)
	# Cycle approved cardinal poses instead of rotating the whole sprite upside down.
	var spin_faces: Array[String] = ["right","front","left","back"]
	var spin_face: String = spin_faces[posmod(floori((relic_spin_angle_v288+PI*0.25)/(PI*0.5)),4)]
	var spin_clip: String = _weapon_motion_prefix(moving)+spin_face
	if body_art.sprite_frames.has_animation(spin_clip):
		_play_if_changed(spin_clip)
	else:
		_play_if_changed(_weapon_motion_prefix(moving)+facing_name)
	body_art.speed_scale=1.0
	move_and_slide()
	var radius: float = float(profile["radius"])*(lerpf(0.65,1.0,ramp) if relic_channel_v288=="cyclone" else 1.0)
	var power: float = (15.0+item.weapon_damage())*float(profile["power"])*(1.0+_stat("melee_power_pct")/100.0)
	var hits: int = 0
	relic_pulse_v288-=delta
	if relic_channel_v288=="hybrid":
		if relic_channel_age_v288>=0.16:
			hits=RELIC_GROUND_V288.hit_spin(self,previous_angle,travel,radius,power,relic_channel_age_v288,relic_spin_hits_v288,float(profile["pulse"]))
	if relic_pulse_v288<=0.0:
		relic_pulse_v288+=float(profile["pulse"])
		if relic_channel_v288=="cyclone":
			hits=RELIC_GROUND_V288.hit_disk(self,global_position,radius,power,0.40,{},false)
		elif relic_channel_v288=="hybrid" and relic_channel_age_v288>0.35:
			var bloom: float = RELIC_MECHANICS_V288.bloom_v290(relic_channel_age_v288)
			var outer: float = RELIC_MECHANICS_V288.hybrid_radius_v290(relic_channel_age_v288)
			# Annulus only: the inner physical blades and outer wind never double-hit the same position.
			if outer>radius+0.5:
				hits+=RELIC_GROUND_V288.hit_disk(self,global_position,outer,power*float(profile["outer_power"])/float(profile["power"])*bloom,0.28,{},false,radius+0.01)
		COMBAT_JUICE.play(get_tree().current_scene,global_position,"swing",-24.0)
	if hits>0:
		camera_kick=maxf(camera_kick,1.6)
		if not relic_channel_worn_v288 and item.ethereal:
			relic_channel_worn_v288=true
			world.inventory.wear_ethereal(item)
			if item.is_broken():
				_end_relic_channel_v288()

func _capture_ranged_relic_v277(item: GhostItemInstance, heavy: bool) -> void:
	ranged_relic_v277=""
	ranged_relic_item_v277=null
	var requested: bool = buffered_special_v261 if buffered_attack_valid else _special_modifier_v272()
	buffered_attack_valid=false
	if not heavy or not requested:
		return
	var id: String = UNIQUE_SPECIALS_V261.kind(item)
	if RELIC_ARSENAL_V277.has_skill(id):
		ranged_relic_v277=id
		ranged_relic_item_v277=item

func _release_ranged_relic_v277(item: GhostItemInstance, heading: Vector2, origin: Vector2, eligible: bool) -> bool:
	var id: String = ranged_relic_v277
	var owner: GhostItemInstance = ranged_relic_item_v277
	ranged_relic_v277=""
	ranged_relic_item_v277=null
	return eligible and owner!=null and owner==item and UNIQUE_SPECIALS_V261.kind(item)==id and RELIC_ARSENAL_V277.launch(self,item,heading,id,origin)

func _clear_crossbow() -> void:
	ranged_relic_v277=""
	ranged_relic_item_v277=null
	crossbow_stage = 0
	crossbow_left = 0.0
	crossbow_item = null
	crossbow_fired = false

func _begin_crossbow(heavy: bool, airborne: bool) -> void:
	if crossbow_stage != 0 or carrying != null or world == null or world.inventory == null:
		return
	var held: GhostItemInstance = world.inventory.get_equipped("sword")
	var cost: float = _attack_action_cost(heavy)
	if held == null or held.weapon_style() != "crossbow" or stamina < cost:
		return
	stamina -= cost
	stamina_recovery_left = STAMINA_RECOVERY_WAIT
	_capture_ranged_relic_v277(held,heavy)
	crossbow_item = held
	crossbow_heavy = heavy
	crossbow_fired = false
	crossbow_stage = 1
	crossbow_left = CROSSBOW_V236.FIRE_TIME
	crossbow_heading = _combat_aim_direction().normalized()
	if crossbow_heading == Vector2.ZERO:
		crossbow_heading = facing
	set_facing(crossbow_heading)
	if airborne:
		jump_attack_active = true
		jump_attack_triggered = true
	_play_action_frames("attack_crossbow_fire_" + facing_name, CROSSBOW_V236.FIRE_TIME)
	_sync_crossbow_pose()

func _sync_crossbow_pose() -> void:
	var duration: float = CROSSBOW_V236.FIRE_TIME if crossbow_stage == 1 else (CROSSBOW_V236.HEAVY_RELOAD if crossbow_heavy else CROSSBOW_V236.RELOAD_TIME)
	var sample: Vector2 = CROSSBOW_V236.action_sample(crossbow_left, duration)
	body_art.pause()
	body_art.set_frame_and_progress(int(sample.x), sample.y)

func _advance_crossbow(delta: float) -> void:
	if world.inventory.get_equipped("sword") != crossbow_item:
		_clear_crossbow()
		return
	crossbow_left = maxf(0.0, crossbow_left - delta)
	if crossbow_stage == 1:
		_sync_crossbow_pose()
		if not crossbow_fired and crossbow_left <= CROSSBOW_V236.FIRE_TIME - CROSSBOW_V236.RELEASE_AT:
			crossbow_fired = true
			_launch_crossbow_bolt()
		if crossbow_left <= 0.0:
			crossbow_stage = 2
			crossbow_left = CROSSBOW_V236.HEAVY_RELOAD if crossbow_heavy else CROSSBOW_V236.RELOAD_TIME
			_play_action_frames("attack_crossbow_reload_" + facing_name, crossbow_left)
			_sync_crossbow_pose()
			COMBAT_JUICE.play(get_tree().current_scene, global_position, "crossbow_reload", -17.0)
	elif crossbow_stage == 2:
		if not str(body_art.animation).contains("crossbow_reload_"):
			_play_action_frames("attack_crossbow_reload_" + facing_name, maxf(0.05, crossbow_left))
		_sync_crossbow_pose()
		if crossbow_left <= 0.0:
			_clear_crossbow()
			body_art.play()

func _launch_crossbow_bolt() -> void:
	if crossbow_item == null or crossbow_item.definition == null:
		return
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var base: String = str(crossbow_item.definition.item_id)
	var base_count: int = CROSSBOW_V236.bolt_count(base)
	var mod: String = crossbow_item.active_weapon_mod(world.room == "lanternhaven")
	var count: int = WEAPON_MODS_V250.projectile_count(mod, base_count)
	var heading: Vector2 = crossbow_heading.normalized()
	var clip: String = str(body_art.animation)
	var points: PackedVector2Array = CROSSBOW_V236.aimed_span(body_art, CROSSBOW_V236.span(clip, facing_name, body_art.frame), heading)
	var origin: Vector2 = global_position + Vector2(0, -39) + heading * 31.0
	if points.size() == 2:
		origin = body_art.to_global(points[0].lerp(points[1], CROSSBOW_V236.weapon_scale(base)))
	if _release_ranged_relic_v277(crossbow_item,heading,origin,crossbow_heavy):
		return
	var second_origin: Vector2 = origin
	if base_count == 2:
		# Use the second authored wrist where visible. A hidden wrist fires
		# from a nearby, occluded muzzle rather than drawing a detached model.
		var local_axis: Vector2 = (points[1] - points[0]).normalized() if points.size() == 2 else (body_art.to_local(body_art.global_position + heading)).normalized()
		var off: PackedVector2Array = CROSSBOW_V236.offhand_span(clip, facing_name, body_art.frame, local_axis)
		if off.size() == 2:
			second_origin = body_art.to_global(off[0].lerp(off[1], CROSSBOW_V236.weapon_scale(base)))
		else:
			second_origin = origin + heading.orthogonal() * 9.0
	var total_damage: float = crossbow_item.weapon_damage() * (1.55 if crossbow_heavy else 1.0) * (1.0 + _stat("melee_power_pct") / 100.0)
	for index in range(count):
		var bolt: Node2D = BOW_ARROW_SCENE.instantiate() as Node2D
		if bolt == null:
			continue
		bolt.set("direction", heading.rotated(WEAPON_MODS_V250.angle(index, count) if count != base_count else CROSSBOW_V236.bolt_angle(index, count)))
		bolt.set("damage", total_damage * WEAPON_MODS_V250.volley_multiplier(mod) / float(count))
		bolt.set("can_return", mod == WEAPON_MODS_V250.RETURN)
		bolt.set("secondary_projectile", index > 0)
		bolt.set("charged", false)
		bolt.set("is_crossbow_bolt", true)
		bolt.set("speed", (1380.0 if crossbow_heavy else 1240.0)*0.88)
		bolt.set("range_left", 930.0)
		bolt.set("caster", self)
		bolt.set("caster_rid", get_rid())
		bolt.set("visual_glow_scale", VISUAL_CHOICES_V216.effect_scale(crossbow_item))
		bolt.set("full_palette", crossbow_item.glow_gradient_colors())
		root.add_child(bolt)
		bolt.global_position = second_origin if base_count == 2 and index % 2 == 1 else origin
	COMBAT_JUICE.play(root, origin, "crossbow_fire", -13.0 if count == 2 else -14.5)
	camera_kick = maxf(camera_kick, 1.6 if crossbow_heavy else 0.8)

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
	_capture_ranged_relic_v277(world.inventory.get_equipped("sword"),charged)
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

# Charge travel uses normal world collision and water modifiers, without
# sprinting or resetting the held animation. The actual released strike
# continues to use its original committed movement.
static func charge_target_velocity(direction: Vector2, walk_speed: float) -> Vector2:
	return GROUNDED.charge_target(direction,walk_speed)

func _charge_walk(delta: float) -> void:
	var direction: Vector2 = _movement_input()
	var speed: float = WALK_SPEED*(1.0+_stat("move_speed_pct")/100.0)
	speed=GROUNDED.terrain_speed(self,speed)
	velocity=GROUNDED.charge_velocity(velocity,direction,speed,delta)

func _refresh_melee_charge_aim() -> void:
	var aim: Vector2 = _combat_aim_direction().normalized()
	if aim.is_zero_approx():
		return
	attack_direction=aim
	var old_face: String = facing_eight_name
	set_facing(aim)
	if old_face!=facing_eight_name:
		action_animation_rate=PLAYBACK.retarget_action(body_art,facing_name,facing_eight_name,attack_duration,action_animation_rate)

func _cancel_bow_charge_for_dodge() -> void:
	bow_draw_active=false
	bow_draw_time=0.0
	bow_draw_airborne=false
	bow_release_done=true
	ranged_relic_v277=""
	ranged_relic_item_v277=null

func _advance_bow_draw(delta: float) -> void:
	if _weapon_style() != "bow" or carrying != null:
		bow_draw_active = false
		body_art.play()
		return
	var release_requested: bool = not Input.is_action_pressed("attack_heavy")
	if not release_requested:
		bow_draw_time += delta
	# Cursor aiming remains manual. Draw angle and facing can change while
	# holding, but the shot won't launch until the physical button releases.
	var aim: Vector2 = _combat_aim_direction().normalized()
	if aim.length_squared() > 0.001:
		bow_firing_direction = aim
		var previous_face: String = facing_eight_name
		set_facing(aim)
		if facing_eight_name != previous_face:
			var name: String = "attack_" + _bow_art_style() + "_heavy_" + facing_name
			if bow_draw_airborne or jump_time_left > 0.0:
				name = AIR_V203.air_name(name)
			_play_action_frames(name, 0.70)
			body_art.pause()
	# Resolve the current draw pose before firing, including a direction
	# change on the exact release tick, so the projectile uses the right wrist.
	PLAYBACK.apply_bow_draw(body_art,bow_draw_time/BOW_FULL_DRAW_TIME)
	if release_requested:
		_release_bow_charge()
		return
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
	PLAYBACK.apply_bow_release(body_art,action_animation_rate)
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
	var relic_origin: Vector2 = global_position+Vector2(0,-39)+heading.normalized()*31.0
	if DIAGONAL_ART_V247.is_painted_bow_combat(str(body_art.animation)) and not equipped.uses_forge_bow():
		var wrist: Vector2 = DIAGONAL_ART_V247.hand_local(body_art)
		if wrist != Vector2.INF:
			relic_origin = body_art.to_global(wrist) + heading.normalized() * 4.0
	elif equipped.uses_forge_bow():
		var relic_span: PackedVector2Array = FORGE_V238.bow_span(body_art,str(body_art.animation),facing_name,body_art.frame,heading)
		if relic_span.size()==2:
			relic_origin=body_art.to_global(relic_span[0]+(relic_span[1]-relic_span[0]).normalized()*8.0)
	if _release_ranged_relic_v277(equipped,heading,relic_origin,charged):
		return
	var arrow: Node2D = BOW_ARROW_SCENE.instantiate() as Node2D
	var root: Node = get_tree().current_scene
	if root == null or arrow == null:
		return
	arrow.set("direction", heading.normalized())
	arrow.set("damage", equipped.weapon_damage() * (1.65 if charged else 1.0) * (1.0 + _stat("melee_power_pct") / 100.0 + (0.01 * _stat("charged_spell_pct") if charged else 0.0)))
	arrow.set("charged", charged)
	arrow.set("launched_in_air", jump_time_left > 0.0)
	arrow.set("speed", (1180.0 if charged else 1030.0)*0.88)
	arrow.set("caster", self)
	arrow.set("caster_rid", get_rid())
	arrow.set("bow_style", equipped.bow_art_style())
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
	var shot_origin: Vector2 = relic_origin # Same physical release point for normal and relic shots.
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
		release.global_position = shot_origin - heading.normalized() * 5.0
	var mod: String = equipped.active_weapon_mod(world.room == "lanternhaven")
	var count: int = WEAPON_MODS_V250.projectile_count(mod, 1)
	var volley_damage: float = float(arrow.get("damage")) * WEAPON_MODS_V250.volley_multiplier(mod)
	var shots: Array[Node2D] = [arrow]
	for i in range(1, count):
		var extra: Node2D = BOW_ARROW_SCENE.instantiate() as Node2D
		WEAPON_MODS_V250.copy_launch(arrow, extra, ["charged", "launched_in_air", "speed", "caster", "caster_rid", "bow_style", "ink", "accent", "fx_tier", "motif", "trail_style", "visual_variant", "element_index", "formation_index", "bow_glow_index", "bow_trail_index", "bow_detail_index", "projectile_style", "visual_glow_scale", "procedural_look", "full_palette", "glow_a", "glow_b", "glow_c"])
		shots.append(extra)
	for i in range(shots.size()):
		var shot: Node2D = shots[i]
		shot.set("direction", heading.normalized().rotated(WEAPON_MODS_V250.angle(i, count)))
		shot.set("damage", volley_damage / float(count))
		shot.set("can_return", mod == WEAPON_MODS_V250.RETURN)
		shot.set("secondary_projectile", i != (count - 1) / 2.0)
		root.add_child(shot)
		shot.global_position = shot_origin
	# Exactly one authentic released arrow per scored range shot; cosmetic
	# formation wisps never report extra shots to the optional fletcher trial.
	COMBAT_JUICE.play(root, shot_origin, "bow_release", -17.0)
	get_tree().call_group("v202_archery_range", "on_player_arrow_launched", global_position)

func _reset_combo_v239() -> void:
	finisher_lights = 0
	finisher_weapon = null
	active_finisher = false
	active_lunge = false
	lunge_window = 0.0
	combo_grace = 0.0
	previous_light = false

func _begin_attack(heavy: bool) -> void:
	if carrying != null or stamina < _melee_cost(heavy):
		return
	var combo_item: GhostItemInstance = world.inventory.get_equipped("sword")
	var special_requested: bool = buffered_special_v261 if buffered_attack_valid else _special_modifier_v272()
	active_special_v261 = UNIQUE_SPECIALS_V261.kind(combo_item) if heavy and special_requested else ""
	special_weapon_v261 = combo_item if not active_special_v261.is_empty() else null
	if combo_grace <= 0.0 or combo_item != finisher_weapon:
		finisher_lights = 0
	active_finisher = heavy and combo_item != null and finisher_lights == 2
	active_lunge = heavy and combo_item != null and (lunge_window > 0.0 or active_special_v261 == "penitent_plunge")
	lunge_window = 0.0
	finisher_weapon = combo_item
	finisher_lights = 0 if heavy else mini(3, finisher_lights + 1)
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
			attack_duration = 1.12 if heavy else [0.49, 0.52, 0.56][combo_step]
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
			attack_duration = 0.60 if heavy else [0.47, 0.50, 0.54][combo_step]
			attack_hit_threshold = 0.58
		"spear":
			attack_duration = 0.96 if heavy else [0.53, 0.56, 0.60][combo_step]
			attack_hit_threshold = 0.57
		"rapier":
			attack_duration = 0.73 if heavy else [0.35,0.37,0.40][combo_step]
			attack_hit_threshold = 0.51
		"axe":
			attack_duration = 1.03 if heavy else [0.57,0.61,0.65][combo_step]
			attack_hit_threshold = 0.52
		"maul":
			attack_duration = 1.13 if heavy else [0.67, 0.70, 0.74][combo_step]
			attack_hit_threshold = 0.54
		"twinblade":
			attack_duration = 0.77 if heavy else [0.36, 0.39, 0.42][combo_step]
			attack_hit_threshold = 0.55
		_:
			attack_duration = 0.80 if heavy else [0.40, 0.43, 0.51][combo_step]
			attack_hit_threshold = 0.58
	if active_attack_style in ["axe","rapier"] and combo_item!=null:
		var tuning: Dictionary = FORGE_TACTICS_V286.tuning(str(combo_item.definition.item_id))
		attack_duration*=float(tuning["time"])
	if active_special_v261 == "penitent_plunge":
		attack_duration = 0.86
		attack_hit_threshold = 0.40
		active_finisher = false
		relic_commit_v288("penitent_plunge", 3.0)
	attack_duration /= 1.0 + _stat("attack_speed_pct") / 100.0
	attack_time_left = attack_duration
	twinblade_weapon_v272=combo_item if heavy and active_attack_style=="twinblade" and active_special_v261.is_empty() else null
	twinblade_second_v272=twinblade_weapon_v272!=null
	twinblade_reward_v272=false
	twinblade_wear_v272=false
	if twinblade_second_v272:
		attack_hit_threshold=TWINBLADE_FIRST_GATE_V272
	clear_throw_charge_v276()
	throw_charge_active_v276 = UNIQUE_SPECIALS_V261.is_throw(active_special_v261)
	if throw_charge_active_v276:
		active_lunge=false
		active_finisher=false
	if UNIQUE_SPECIALS_V261.is_dagger_throw(active_special_v261):
		attack_duration = 0.56 / (1.0+_stat("attack_speed_pct")/100.0)
		attack_time_left = attack_duration
		attack_hit_threshold = 0.48
		active_lunge = false
		active_finisher = false
	dagger_charge_active = heavy and active_attack_style == "dagger" and not UNIQUE_SPECIALS_V261.is_dagger_throw(active_special_v261)
	dagger_charge_time = 0.0
	# Actual moving-air sound, without the old bright WAV transient on swords.
	var swing_cue: String = "scythe_heavy" if heavy and active_attack_style == "scythe" else ("heavy_swing" if heavy else "swing")
	if active_attack_style == "maul":
		swing_cue = "blunt_swing"
	elif active_attack_style=="axe":
		swing_cue="axe_heavy_swing" if heavy else "axe_swing"
	elif active_attack_style=="rapier":
		swing_cue="rapier_thrust"
	elif active_attack_style in ["dagger", "dual_dagger"] and not heavy:
		swing_cue = "dagger_swing"
	elif active_attack_style in ["spear", "halberd"] and not heavy:
		swing_cue = "polearm_swing"
	COMBAT_JUICE.play(get_tree().current_scene, global_position, "throw_charge" if throw_charge_active_v276 else swing_cue, -15.0 if throw_charge_active_v276 or swing_cue == "scythe_heavy" else (-16.5 if heavy else -18.5))
	attack_hit_done = false
	heavy_attack = heavy
	# The empty-hand branch must always play visible unarmed attack frames.
	# Swords use a separate atlas; counter frames remain available for both.
	var holding_sword: bool = world.inventory != null and world.inventory.get_equipped("sword") != null
	var attack_animation: String = ""
	if counter_window > 0.0 and active_attack_style == "dual_sword":
		# A dedicated crossed-blade riposte on the existing confirmed counter.
		attack_animation = "attack_dual_sword_riposte_" + facing_name
	elif counter_window > 0.0 and active_attack_style not in ["scythe", "halberd", "dagger", "spear", "maul", "twinblade", "dual_dagger", "dual_sword", "rapier", "axe"]:
		attack_animation = ("attack_sword_modular_counter_" if _uses_modular_sword() else "attack_counter_") + facing_name
	elif holding_sword:
		if active_attack_style in ["scythe", "halberd", "dagger", "spear", "maul", "twinblade", "dual_dagger", "dual_sword", "rapier", "axe"]:
			if active_attack_style == "dagger":
				# Always use the hand-anchored thrust, not the legacy slash atlas.
				attack_animation = "attack_" + _weapon_art_style() + ("_heavy_pierce_" if heavy else "_pierce_") + facing_name
			elif active_attack_style == "dual_dagger" and (heavy or combo_step == 2 or counter_window > 0.0):
				attack_animation = "attack_" + _weapon_art_style() + ("_heavy_pierce_" if heavy else "_pierce_") + facing_name
			elif active_attack_style == "dual_dagger" and not heavy:
				attack_animation = "attack_dual_dagger_light_" + ["a", "b", "c"][combo_step] + "_" + facing_name
			elif active_attack_style == "dual_sword" and not heavy:
				attack_animation = "attack_dual_sword_light_" + ["a", "b", "c"][combo_step] + "_" + facing_name
			elif active_attack_style in ["spear","rapier"]:
				attack_animation = "attack_" + _weapon_art_style() + ("_heavy_pierce_" if heavy else "_pierce_") + facing_name
			else:
				attack_animation = "attack_" + _weapon_art_style() + ("_heavy_" if heavy else "_light_") + facing_name
		else:
			attack_animation = ("attack_sword_modular_" if _uses_modular_sword() else "attack_sword_") + ("heavy_" if heavy else "light_") + facing_name
	else:
		attack_animation = ("attack_unarmed_heavy_" if heavy else "attack_unarmed_light_") + facing_name
	if active_special_v261 == DANCE_V262.ID:
		_start_eclipse_dance_v262()
		return
	_play_action_frames(attack_animation, attack_duration)
	# Repeated same-direction combo attacks are new actions, not resumes.
	body_art.set_frame_and_progress(0, 0.0)

func _free_facing_direction(travel: Vector2) -> Vector2:
	if is_instance_valid(lock_target):
		var locked: Vector2 = lock_target.global_position - global_position
		if locked.length_squared() > 4.0:
			return locked.normalized()
	if controller_active_v260:
		var stick_aim: Vector2 = DIRECTIONS_V245.stick(JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y)
		if stick_aim.length_squared() > 0.01:
			return stick_aim.normalized()
	if controller_active_v260 or touch_aim_active:
		return travel.normalized() if travel.length_squared() > 0.01 else facing
	return DIRECTIONS_V245.cursor_heading(get_global_mouse_position() - global_position, facing)

func _combat_aim_direction() -> Vector2:
	if is_instance_valid(lock_target):
		var locked_heading: Vector2 = lock_target.global_position - global_position
		if locked_heading.length_squared() > 4.0:
			return locked_heading.normalized()
	if controller_active_v260:
		var aim: Vector2 = DIRECTIONS_V245.stick(JOY_AXIS_RIGHT_X,JOY_AXIS_RIGHT_Y)
		if aim.length_squared() > 0.01:
			return DIRECTIONS_V245.heading(DIRECTIONS_V245.octant(aim))
		var movement: Vector2 = _movement_input()
		return DIRECTIONS_V245.heading(DIRECTIONS_V245.octant(movement)) if movement.length_squared() > 0.01 else facing
	# Use the same aim as free locomotion so a close cursor does not make
	# an attack unexpectedly turn toward the held movement key.
	return _free_facing_direction(_movement_input())

func _queue_combat(action: String) -> void:
	if action in ["light","heavy"] and thrown_weapon_busy_v273():
		return
	queued_action = action
	queue_time_left = INPUT_BUFFER
	if action == "light" or action == "heavy":
		buffered_attack_direction = _combat_aim_direction()
		buffered_special_v261 = action == "heavy" and _special_modifier_v272()
		buffered_attack_valid = true
	else:
		buffered_attack_valid = false

func _advance_attack(delta: float) -> void:
	if throw_charge_active_v276:
		if world.inventory.get_equipped("sword")!=special_weapon_v261 or UNIQUE_SPECIALS_V261.kind(special_weapon_v261)!=active_special_v261:
			clear_throw_charge_v276()
			attack_time_left=0.0
			active_special_v261=""
			special_weapon_v261=null
			return
		throw_charge_time_v276=minf(THROW_MAX_V276,throw_charge_time_v276+delta)
		if throw_charge_time_v276>=THROW_MAX_V276 and not throw_charge_ready_v276:
			throw_charge_ready_v276=true
			COMBAT_JUICE.play(get_tree().current_scene,global_position,"throw_ready",-17.0)
		if throw_charge_time_v276<THROW_MIN_V276 or Input.is_action_pressed("attack_heavy"):
			if body_art.frame>=2:
				body_art.set_frame_and_progress(2,0.0)
				body_art.pause()
			return
		throw_charge_active_v276=false
		_resume_timed_action()
		attack_time_left=attack_duration*maxf(0.67,attack_hit_threshold+0.12)
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
		if active_special_v261 == "penitent_plunge":
			if world.inventory.get_equipped("sword") == special_weapon_v261 and UNIQUE_SPECIALS_V261.kind(special_weapon_v261) == "penitent_plunge":
				_strike_nearby_enemies(1.40)
		elif not active_special_v261.is_empty():
			if world.inventory.get_equipped("sword") == special_weapon_v261:
				UNIQUE_SPECIALS_V261.launch(self,special_weapon_v261,attack_direction,active_special_v261,throw_charge_ratio_v276())
		else:
			if twinblade_weapon_v272==null:
				_strike_nearby_enemies(1.25 if active_finisher else 1.0)
			elif world.inventory.get_equipped("sword")==twinblade_weapon_v272 and not twinblade_weapon_v272.is_broken():
				_strike_nearby_enemies((1.25 if active_finisher else 1.0)*TWINBLADE_HIT_POWER_V272,true,false)
	# Second blade passes the forward arc later in the same committed spin.
	# Re-check range, obstruction and equipment; no automatic follow-up damage.
	if twinblade_second_due_v272(twinblade_second_v272,attack_time_left,attack_duration):
		twinblade_second_v272=false
		if world.inventory.get_equipped("sword")==twinblade_weapon_v272 and not twinblade_weapon_v272.is_broken():
			COMBAT_JUICE.play(get_tree().current_scene,global_position,"swing",-24.0)
			_strike_nearby_enemies((1.25 if active_finisher else 1.0)*TWINBLADE_HIT_POWER_V272,true,true)
	if attack_time_left <= 0.0:
		twinblade_weapon_v272=null
		twinblade_second_v272=false
		active_special_v261 = ""
		special_weapon_v261 = null
		active_finisher = false
		active_lunge = false
		combo_grace = 0.48 if not heavy_attack else 0.0

func _strike_nearby_enemies(power_multiplier: float = 1.0, twin_edge: bool = false, second_edge: bool = false) -> void:
	var sword: GhostItemInstance = world.inventory.get_equipped("sword") if world.inventory != null else null
	var profile = MELEE_RULES.base_profile(active_attack_style,heavy_attack,sword!=null,combo_step)
	var reach: float = profile.reach
	var power: float = profile.power
	var attack_arc: float = profile.arc
	var poise_bonus: float = profile.poise
	if sword != null:
		if active_attack_style in ["axe","rapier"]:
			var tuning: Dictionary = FORGE_TACTICS_V286.tuning(str(sword.definition.item_id))
			reach*=float(tuning["reach"])
			poise_bonus*=float(tuning["poise"])
			if active_attack_style=="axe":
				attack_arc=clampf(attack_arc+float(tuning["arc"]),-0.25,0.85)
		power += sword.weapon_damage()
		match sword.active_weapon_mod(world.room == "lanternhaven"):
			"long_reach": reach *= 1.20
			"crushing": poise_bonus *= 1.35
			"cleaving": attack_arc = cos(minf(PI, acos(clampf(attack_arc, -1.0, 1.0)) * 1.25))
			"execution":
				if heavy_attack: power *= 1.25
			"finisher":
				if active_finisher and not jump_attack_active: power *= 1.25
			"riposte":
				if counter_window > 0.0: power *= 1.35
	if active_special_v261 == "penitent_plunge":
		reach = minf(reach, 190.0)
		attack_arc = 0.88
		poise_bonus *= 1.35
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
	var finisher_shown: bool = false
	var struck_world: bool = false
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not COMBAT_GEOMETRY.is_hittable(candidate):
			continue
		var delta_to: Vector2 = candidate.global_position - global_position
		if delta_to.length() > reach or delta_to.length_squared() < 20.0:
			continue
		if attack_direction.dot(delta_to.normalized()) < attack_arc:
			continue
		if active_attack_style=="rapier" and not FORGE_TACTICS_V286.thrust_contact(delta_to,attack_direction,reach,heavy_attack):
			continue
		if not COMBAT_GEOMETRY.obstruction(self, global_position + Vector2(0, -18), candidate.global_position + Vector2(0, -18), COMBAT_GEOMETRY.WORLD_MASK).is_empty():
			continue
		candidate.call("hit", power, poise_bonus * (0.65 if twin_edge else 1.0) * (1.0 + _stat("poise_power_pct") / 100.0))
		if sword != null and sword.active_weapon_mod(world.room == "lanternhaven") == "frostbite" and is_instance_valid(candidate) and not candidate.is_queued_for_deletion() and candidate.has_method("apply_frost_slow"):
			candidate.call("apply_frost_slow", 1.5, 0.78)
			_spawn_spectacle("strike", candidate.global_position + Vector2(0,-27), Color("9ed5f6"), fx_motif, fx_tier, Color("c9e8ff"), fx_trail)
		var blunt_contact: bool = sword != null and sword.physical_damage_kind() == "blunt"
		if jump_attack_active or blunt_contact:
			PHYSICAL_FEEL.burst(get_tree().current_scene, candidate.global_position + Vector2(0, -14), "slam", 1.40 if jump_attack_active else 0.92, attack_direction, sword.visual_seed() if sword != null else 1)
		if not blunt_contact and sword != null and IMPACT_MATERIAL_V239.material_for(candidate, "flesh") == "flesh":
			_spawn_blade_blood(candidate.global_position + Vector2(0.0, -32.0), fx_color, fx_accent, fx_impact, fx_tier, sword.visual_seed() if sword != null else 0)
			# Daggers already have a physical blade and dedicated tip glow;
			# the large crescent slash contradicted the stabbing motion.
			if active_attack_style not in ["dagger","rapier","spear"]:
				_spawn_rose_slash(candidate.global_position + Vector2(0.0, -28.0))
		_spawn_spectacle("strike", candidate.global_position + Vector2(0.0, -27.0), fx_color, fx_motif, fx_tier, fx_accent, fx_trail)
		if counter_hit and not counter_shown:
			_spawn_precision_feedback("riposte", candidate.global_position + Vector2(0.0, -30.0), attack_direction)
			counter_shown = true
		if active_finisher and not jump_attack_active and not finisher_shown and not second_edge:
			var burst: Node2D = Node2D.new()
			burst.set_script(IMPACT_PRESTIGE)
			get_tree().current_scene.add_child(burst)
			burst.global_position = candidate.global_position + Vector2(0, -28)
			burst.call("configure", "finisher", fx_color, fx_accent, 3, 2, attack_direction, sword.visual_seed() if sword != null else 0)
			COMBAT_JUICE.play(get_tree().current_scene, burst.global_position, "combo_finisher", -12.0)
			finisher_shown = true
		struck = true
		camera_kick = maxf(camera_kick, 8.3 if jump_attack_active else (3.9 if heavy_attack else 2.1))
		if active_attack_style=="axe" and heavy_attack:
			camera_kick=maxf(camera_kick,5.8)
		camera_push = attack_direction * (6.5 if jump_attack_active else (3.5 if heavy_attack else 1.8))
	# Heavy and plunging attacks physically interact with ordinary wooden
	# barricades, not progression locks. Each prop is hit once per strike.
	if (heavy_attack or sword != null) and not second_edge:
		var broken_attempts: int = 0
		for object in get_tree().get_nodes_in_group("breakable_cover"):
			if not is_instance_valid(object) or not object is Node2D or not object.has_method("receive_damage") or bool(object.get("broken")):
				continue
			if not heavy_attack and not object.is_in_group("breakable_container") and not (object.is_in_group("fellable_tree") and sword != null and sword.physical_damage_kind() != "blunt"):
				continue
			var toward: Vector2 = object.global_position - global_position
			if toward.length_squared() > pow(minf(reach, 167.0), 2.0) or toward.length_squared() < 100.0:
				continue
			if attack_direction.dot(toward.normalized()) < 0.30:
				continue
			# Stone walls must still block hits through geometry. The breakable
			# object itself is the acceptable first hit on this physics ray.
			var obstruction: Dictionary = COMBAT_GEOMETRY.obstruction(self, global_position + Vector2(0.0, -12.0), object.global_position + Vector2(0.0, -12.0), COMBAT_GEOMETRY.WORLD_MASK)
			if not obstruction.is_empty() and obstruction.get("collider") != object:
				continue
			object.call("receive_damage", power * (0.90 if jump_attack_active else 0.80), global_position)
			PHYSICAL_FEEL.burst(get_tree().current_scene, object.global_position + Vector2(0.0, -10.0), "wood", 0.72, attack_direction, roundi(object.global_position.x))
			if not struck_world:
				COMBAT_JUICE.play(get_tree().current_scene, object.global_position, "surface_wood", -15.0)
			struck_world = true
			broken_attempts += 1
			if broken_attempts >= 2:
				break
	if not struck and not struck_world and not jump_attack_active:
		var wall_ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -18), global_position + Vector2(0, -18) + attack_direction * reach)
		wall_ray.collision_mask = 2
		wall_ray.exclude = [get_rid()]
		var wall: Dictionary = get_world_2d().direct_space_state.intersect_ray(wall_ray)
		if not wall.is_empty():
			var surface: String = IMPACT_MATERIAL_V239.material_for(wall.get("collider"), "stone")
			COMBAT_JUICE.play(get_tree().current_scene, wall["position"], "surface_" + surface, -14.0 if heavy_attack else -18.0)
	if struck or struck_world:
		# Only confirmed creature or world contact holds the active frame;
		# misses never incur hitstop or resource gain.
		hitstop_left = (0.105 if counter_hit and struck else (0.089 if jump_attack_active else (0.065 if heavy_attack else 0.040)))
		if struck and active_attack_style=="axe":
			hitstop_left=maxf(hitstop_left,0.090 if heavy_attack else 0.050)
		body_art.pause()
		_play_action_sfx(RIPOSTE_SFX if counter_hit and struck else HIT_SFX)
		var contact_cue: String = "parry" if counter_hit and struck else ("blunt_hit" if active_attack_style == "maul" else ("blade_hit" if sword != null and struck else "hit"))
		if struck and not counter_hit:
			if active_attack_style=="axe":
				contact_cue="axe_impact"
			elif active_attack_style=="rapier":
				contact_cue="rapier_impact"
		COMBAT_JUICE.play(get_tree().current_scene, global_position, contact_cue, -14.0 if counter_hit and struck else -16.5)
		if struck_world and not struck:
			camera_kick = maxf(camera_kick, 4.5 if jump_attack_active else 3.0)
			camera_push = attack_direction * (4.0 if jump_attack_active else 2.5)
		if counter_hit and struck:
			camera_kick = maxf(camera_kick, 7.0)
			counter_window = 0.0
	# Resource gains are once per attack, not once per enemy or scenery hit.
	if struck and sword != null and (not twin_edge or not twinblade_reward_v272):
		if twin_edge:
			twinblade_reward_v272=true
		if sword.active_weapon_mod(world.room == "lanternhaven") == "soul_siphon":
			health = minf(maximum_health(), health + 2.0)
			world.ui.set_health(health, maximum_health())
		elif sword.active_weapon_mod(world.room == "lanternhaven") == "vigor":
			stamina = minf(MAX_STAMINA, stamina + 5.0)
			world.ui.set_stamina(stamina, MAX_STAMINA)
	if struck and rally_pool > 0.0 and rally_time_left > 0.0:
		var gained: float = minf(rally_pool, power * 0.38 * (1.0 + _stat("rally_power_pct") / 100.0))
		rally_pool -= gained
		health = minf(maximum_health(), health + gained)
		world.ui.set_health(health, maximum_health())

	if (struck or struck_world) and sword != null and sword.ethereal and (not twin_edge or not twinblade_wear_v272):
		if twin_edge:
			twinblade_wear_v272=true
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
	if parry_left > 0.0 and not parry_used and parry_age <= PARRY_WINDOW:
		var center: Vector2 = Vector2(0,-26)+parry_heading*10.0
		var angle: float = parry_heading.angle()
		var ink: Color = Color("f4d6a8") if parry_age >= PARRY_PERFECT_START and parry_age <= PARRY_PERFECT_END else Color("aa95b7")
		draw_arc(center,23.0,angle-0.8,angle+0.8,24,ink,1.8,true)
	if throw_charge_active_v276:
		var ratio: float = throw_charge_ratio_v276()
		var at: Vector2 = Vector2(0,-39)+attack_direction*18.0
		var rig: Node = body_art.get_node_or_null("WeaponPoseV172")
		if rig!=null:
			var span: PackedVector2Array = rig.call("get_weapon_span",str(body_art.animation),body_art.frame)
			if span.size()==2:
				at=to_local(body_art.to_global(span[0]))
		var ink: Color = Color("f6ddae") if throw_charge_ready_v276 else Color("cdb1ed")
		var opacity: float = 0.3+ratio*0.55
		draw_arc(at,17.0-ratio*6.0,-PI*0.5,-PI*0.5+TAU*maxf(0.05,ratio),32,Color(ink.r,ink.g,ink.b,opacity),1.5,true)
		for i in range(5):
			var axis: Vector2 = Vector2.from_angle(visual_time*3.0+float(i)*TAU/5.0)
			var p: Vector2 = at+axis*(20.0-ratio*11.0)
			draw_line(p,p+axis*(3.0+ratio*3.0),Color(ink.r,ink.g,ink.b,opacity*0.7),1.1,true)
	if dance_stage_v262 == 1 and (DANCE_V262.can_chain(dance_elapsed_v262) or dance_follow_v262):
		var ratio: float = DANCE_V262.chain_remaining(dance_elapsed_v262)
		var enough: bool = stamina >= _action_cost(DANCE_V262.FOLLOW_COST,false)
		var ink: Color = Color("e4c59d") if dance_follow_v262 else (Color("c49ab9") if enough else Color("8b7882"))
		draw_line(Vector2(-16,9),Vector2(16,9),Color(0.31,0.24,0.31,0.65),1.6,true)
		draw_line(Vector2(-16,9),Vector2(-16+32.0*(1.0 if dance_follow_v262 else ratio),9),ink,1.8,true)
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
	var aim: Vector2 = _combat_aim_direction() if controller_active_v260 else (cursor.normalized() if cursor.length_squared() > 1.0 else facing)
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

# Action atlas is currently unarmed; keep equipped action rigs intact.
func _diagonal_action_clip(action: String, fallback: String) -> String:
	if world == null or world.inventory == null:
		return fallback
	var armed: bool = world.inventory.get_equipped("sword")!=null or world.inventory.get_equipped("wand")!=null
	return PLAYBACK.gesture_clip(action,fallback,facing_eight_name,facing_name,_weapon_motion_prefix(true),armed,thrown_weapon_busy_v273(),body_art.sprite_frames)

func _start_eclipse_dance_v262() -> void:
	dance_stage_v262 = 1
	dance_elapsed_v262 = 0.0
	dance_hit_index_v262 = 0
	dance_follow_v262 = false
	dance_worn_v262 = false
	dance_heading_v262 = attack_direction
	active_finisher = false
	active_lunge = false
	dagger_charge_active = false
	counter_window = 0.0
	queued_action = ""
	attack_duration = DANCE_V262.FIRST
	attack_time_left = attack_duration
	_sync_eclipse_pose_v263()

func _clear_eclipse_dance_v262() -> void:
	dance_stage_v262 = 0
	dance_elapsed_v262 = 0.0
	dance_hit_index_v262 = 0
	dance_follow_v262 = false
	if active_special_v261 == DANCE_V262.ID:
		active_special_v261 = ""
		special_weapon_v261 = null

func eclipse_spin_v262() -> float:
	return DANCE_V262.spin(dance_stage_v262,dance_elapsed_v262) if dance_stage_v262 > 0 and attack_time_left > 0.0 else 0.0

func eclipse_axis_v263() -> Vector2:
	return DANCE_V262.blade_axis(dance_heading_v262,dance_stage_v262,dance_elapsed_v262) if dance_stage_v262 > 0 and attack_time_left > 0.0 else Vector2.ZERO

func _sync_eclipse_pose_v263() -> void:
	var face: String = DANCE_V262.facing_at(dance_heading_v262,dance_stage_v262,dance_elapsed_v262)
	var clip: String = "attack_twinblade_heavy_"+face
	if not body_art.sprite_frames.has_animation(clip):
		clip = "attack_twinblade_heavy_"+facing_name
	if not body_art.sprite_frames.has_animation(clip):
		return
	if str(body_art.animation) != clip:
		body_art.play(clip)
	body_art.pause()
	var count: int = body_art.sprite_frames.get_frame_count(clip)
	if count > 0:
		body_art.set_frame_and_progress(DANCE_V262.frame_at(dance_stage_v262,dance_elapsed_v262,count),0.0)


func _advance_eclipse_dance_v262(delta: float) -> void:
	if dance_stage_v262 == 0 or world.inventory.get_equipped("sword") != special_weapon_v261 or UNIQUE_SPECIALS_V261.kind(special_weapon_v261) != DANCE_V262.ID:
		_clear_eclipse_dance_v262()
		attack_time_left = 0.0
		velocity = Vector2.ZERO
		return
	if dance_stage_v262 == 1 and DANCE_V262.can_chain(dance_elapsed_v262) and Input.is_action_just_pressed("attack_heavy") and _special_modifier_v272():
		if not dance_follow_v262 and stamina >= _action_cost(DANCE_V262.FOLLOW_COST,false):
			dance_follow_v262 = true
			COMBAT_JUICE.play(get_tree().current_scene,global_position,"evade",-23.0)
	var previous: float = dance_elapsed_v262
	dance_elapsed_v262 = minf(attack_duration,dance_elapsed_v262+delta)
	attack_time_left = maxf(0.0,attack_duration-dance_elapsed_v262)
	_sync_eclipse_pose_v263()
	# Real collision movement. Only the optional retreat gets a brief evade.
	velocity = dance_heading_v262*DANCE_V262.motion(dance_stage_v262,dance_elapsed_v262)
	if dance_stage_v262 == 2 and previous < 0.36 and dance_elapsed_v262 >= 0.36:
		invulnerable_time = maxf(invulnerable_time,0.18)
	move_and_slide()
	var gates: Array[float] = DANCE_V262.timings(dance_stage_v262)
	while dance_hit_index_v262 < gates.size() and dance_elapsed_v262 >= gates[dance_hit_index_v262]:
		_eclipse_dance_hit_v262(DANCE_V262.hit_multiplier(dance_stage_v262,dance_hit_index_v262))
		if dance_stage_v262 == 0:
			attack_time_left = 0.0
			return
		dance_hit_index_v262 += 1
	if attack_time_left > 0.0:
		return
	var extra_cost: float = _action_cost(DANCE_V262.FOLLOW_COST,false)
	if dance_stage_v262 == 1 and dance_follow_v262 and stamina >= extra_cost:
		stamina -= extra_cost
		stamina_recovery_left = STAMINA_RECOVERY_WAIT
		dance_stage_v262 = 2
		dance_elapsed_v262 = 0.0
		dance_hit_index_v262 = 0
		attack_duration = DANCE_V262.FOLLOW
		attack_time_left = attack_duration
		_sync_eclipse_pose_v263()
		return
	_clear_eclipse_dance_v262()
	velocity = Vector2.ZERO
	combo_grace = 0.0

func _eclipse_dance_hit_v262(multiplier: float) -> void:
	var item: GhostItemInstance = special_weapon_v261
	if item == null or item.is_broken():
		return
	var damage: float = (34.0*1.05+item.weapon_damage())*multiplier*(1.0+_stat("melee_power_pct")/100.0)*(1.0+_stat("heavy_power_pct")/100.0)
	var colors: Array[Color] = item.glow_gradient_colors()
	var tint: Color = colors[0] if not colors.is_empty() else Color("b76c84")
	var mod: String = item.active_weapon_mod(world.room == "lanternhaven")
	var reach: float = 184.0 if mod == "long_reach" else 156.0
	var poise: float = 0.37*(1.0+_stat("poise_power_pct")/100.0)*(1.35 if mod == "crushing" else 1.0)
	if mod == "execution":
		damage *= 1.25
	var contact: bool = false
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or not candidate is Node2D or candidate.is_queued_for_deletion() or not candidate.has_method("hit"):
			continue
		var distance: Vector2 = candidate.global_position-global_position
		if distance.length_squared() > reach*reach:
			continue
		var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position+Vector2(0,-18),candidate.global_position+Vector2(0,-18))
		ray.collision_mask = 2
		ray.exclude = [get_rid()]
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		candidate.call("hit",damage,poise)
		contact = true
		if is_instance_valid(candidate) and not candidate.is_queued_for_deletion():
			if mod == "frostbite" and candidate.has_method("apply_frost_slow"):
				candidate.call("apply_frost_slow",1.5,0.78)
			_spawn_spectacle("strike",candidate.global_position+Vector2(0,-27),tint,0,2,tint.lightened(0.2),0)
	var root: Node = get_tree().current_scene
	COMBAT_JUICE.play(root,global_position,"blade_hit" if contact else "polearm_swing",-18.0)
	if root != null:
		var arc: Node2D = preload("res://scripts/eclipse_dance_arc_v262.gd").new()
		arc.set("ink",tint)
		var axis: Vector2 = eclipse_axis_v263()
		arc.set("heading",axis.angle() if not axis.is_zero_approx() else dance_heading_v262.angle())
		arc.set("reverse",dance_stage_v262==2)
		arc.set("strength",preload("res://scripts/visual_choices_v216.gd").effect_scale(item))
		root.add_child(arc)
		arc.global_position = global_position+Vector2(0,-28)
		var rig: Node = body_art.get_node_or_null("WeaponPoseV172")
		if rig != null:
			var span: PackedVector2Array = rig.call("get_weapon_span",str(body_art.animation),body_art.frame)
			if span.size()==2:
				arc.global_position = body_art.to_global(span[0])
		world.track_room_effect(arc)
	if contact:
		camera_kick = maxf(camera_kick,2.1)
		if not dance_worn_v262:
			dance_worn_v262 = true
			if mod == "soul_siphon":
				health = minf(maximum_health(),health+2.0)
				world.ui.set_health(health,maximum_health())
			elif mod == "vigor":
				stamina = minf(MAX_STAMINA,stamina+5.0)
				world.ui.set_stamina(stamina,MAX_STAMINA)
			if item.ethereal and world.inventory.wear_ethereal(item):
				world.ui.show_pickup("ETHEREAL WEAPON BROKEN",Color("d9b6cf"))
				_clear_eclipse_dance_v262()

static func twinblade_second_due_v272(pending: bool,remaining: float,duration: float) -> bool:
	return pending and duration>0.0 and remaining<=duration*TWINBLADE_SECOND_GATE_V272
