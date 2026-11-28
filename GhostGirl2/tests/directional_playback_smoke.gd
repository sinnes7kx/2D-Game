extends SceneTree
const PLAYBACK = preload("res://scripts/animation/directional_playback.gd")
const MOTION = preload("res://scripts/gentle_weapon_motion_v191.gd")
const DIR = preload("res://scripts/direction_controller_v245.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _add(frames: SpriteFrames,texture: Texture2D,name: String,count: int,looping: bool=false) -> void:
	frames.add_animation(name)
	frames.set_animation_loop(name,looping)
	frames.set_animation_speed(name,16.0)
	for i in range(count):
		frames.add_frame(name,texture,1.0)

func _verify() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient=Gradient.new()
	for i in range(8):
		var face: String = DIR.NAMES[i]
		var count: int = 16 if face in ["front","back","left","right"] else 8
		_add(frames,texture,"attack_sword_modular_heavy_"+face,count)
		_add(frames,texture,"sword_modular_walk_"+face,count,true)
		_add(frames,texture,"idle_"+face,8,true)
	for i in range(8):
		var face: String = DIR.NAMES[i]
		var fallback: String = DIR.pose_name(i)
		assert(PLAYBACK.action_clip("attack_sword_modular_heavy_"+fallback,face,frames)=="attack_sword_modular_heavy_"+face)
		assert(PLAYBACK.locomotion_clip("sword_modular_walk_"+fallback,face,fallback,true,frames)=="sword_modular_walk_"+face)
		assert(PLAYBACK.retarget_request("attack_sword_modular_heavy_"+face,"front")=="attack_sword_modular_heavy_front")
	assert(PLAYBACK.retarget_request("unknown_clip","front")=="unknown_clip")
	assert(not PLAYBACK.has_clip(null,"idle_front"))
	frames.add_animation("attack_axe_light_front_right")
	_add(frames,texture,"attack_axe_light_front",8)
	assert(PLAYBACK.action_clip("attack_axe_light_front","front_right",frames)=="attack_axe_light_front")
	var body: AnimatedSprite2D = AnimatedSprite2D.new()
	body.sprite_frames=frames
	root.add_child(body)
	body.speed_scale=1.5
	var rate: float = PLAYBACK.play_action(body,"attack_sword_modular_heavy_front","front","front",0.5)
	assert(is_equal_approx(rate,2.0) and is_equal_approx(body.speed_scale,1.0))
	body.set_frame_and_progress(12,0.0)
	body.pause()
	rate=PLAYBACK.retarget_action(body,"front","front_right",0.5,rate)
	assert(str(body.animation)=="attack_sword_modular_heavy_front_right" and body.frame==6)
	assert(is_equal_approx(rate,1.0) and not body.is_playing())
	assert(is_equal_approx(MOTION.phase_of(body),0.75))
	PLAYBACK.resume_action(body,rate)
	assert(body.is_playing() and body.frame==6 and is_zero_approx(body.frame_progress))
	body.set_frame_and_progress(7,1.0)
	body.pause()
	rate=PLAYBACK.retarget_action(body,"left","left",0.5,rate)
	assert(body.frame==15 and is_equal_approx(body.frame_progress,1.0))
	assert(not body.is_playing())
	PLAYBACK.play_locomotion(body,"sword_modular_walk_front")
	body.set_frame_and_progress(10,0.5)
	var phase: float=MOTION.phase_of(body)
	PLAYBACK.play_locomotion(body,"sword_modular_walk_back_left")
	assert(is_equal_approx(MOTION.phase_of(body),phase))
	assert(PLAYBACK.bow_draw_frame(1.0,8)==5)
	assert(PLAYBACK.bow_draw_frame(0.5,8)==2)
	assert(PLAYBACK.bow_draw_frame(1.0,3)==2)
	assert(PLAYBACK.bow_draw_frame(-1.0,8)==0)
	PLAYBACK.apply_bow_draw(body,1.0)
	assert(body.frame==5 and not body.is_playing())
	PLAYBACK.apply_bow_release(body,1.0)
	assert(body.frame==6 and body.is_playing())
	body.free()
	print("Directional playback: all eight headings, missing/empty clips, weighted phase, charge and resume PASS")
	quit(0)
