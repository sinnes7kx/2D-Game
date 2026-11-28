extends SceneTree
const PLAYBACK = preload("res://scripts/animation/directional_playback.gd")
const MOTION = preload("res://scripts/gentle_weapon_motion_v191.gd")
const DIR = preload("res://scripts/direction_controller_v245.gd")
const CARDINAL = preload("res://scripts/cardinal_refresh_v295.gd")
const PAIRED_CARRY = preload("res://scripts/cardinal_paired_carry_v296.gd")

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
	# Actual source resource: normal cardinal locomotion has no painted hook,
	# halo or sword. Equipment and explicit hook gestures keep their layers.
	var original: SpriteFrames = load("res://resources/ghost_girl_frames.tres") as SpriteFrames
	assert(original!=null)
	for face in CARDINAL.FACES:
		for motion in ["idle","walk","blink"]:
			var clip: String = motion+"_"+face
			var count: int = 6 if motion=="idle" else (8 if motion=="walk" else 7)
			assert(original.has_animation(clip) and original.get_frame_count(clip)==count)
			var source_motion: String = "walk" if motion=="walk" else "idle"
			for i in range(count):
				var source: Texture2D = original.get_frame_texture(clip,i)
				assert(source!=null and source.get_size()==Vector2(256,220))
				assert(source.resource_path.begins_with("res://assets/ghost/weapon_body_v110/"+source_motion+"_"+face+"_"))
	# Visually inspected original left idle images 0,1,2,3,6,7 all have
	# an open eye. The separate blink uses closed frames 4/5 briefly.
	var open_left: Array[int] = [0,1,2,3,6,7]
	for i in range(open_left.size()):
		assert(original.get_frame_texture("idle_left",i).resource_path.ends_with("idle_left_%02d.png" % open_left[i]))
	assert(original.get_frame_texture("blink_left",3).resource_path.ends_with("idle_left_04.png"))
	assert(original.get_frame_texture("blink_left",4).resource_path.ends_with("idle_left_05.png"))
	# All supported equipped cardinal clips reuse clean eight-frame body rows.
	var paired: SpriteFrames = SpriteFrames.new()
	for family in PAIRED_CARRY.FAMILIES:
		for face in PAIRED_CARRY.FACES:
			for motion in ["idle","walk"]:
				_add(paired,texture,family+motion+"_"+face,8,true)
		_add(paired,texture,family+"idle_front_left",8,true)
		_add(paired,texture,family+"parry_front",8)
	assert(PAIRED_CARRY.install(paired)==(PAIRED_CARRY.FAMILIES.size()-2)*8)
	assert(PAIRED_CARRY.install(paired)==0)
	var painted: int = 0
	for style in ["thornrose","moonveil"]:
		if ResourceLoader.exists("res://assets/equipment/bows_v166/%s_carry_only_2048x1760.png" % style,"Texture2D") and ResourceLoader.exists("res://assets/ghost/bows_v139/%s_locomotion_mask_2048x1760.png" % style,"Texture2D"):
			painted+=8
	assert(PAIRED_CARRY.install(paired,true)==painted)
	assert(PAIRED_CARRY.install(paired,true)==0)
	for family in PAIRED_CARRY.FAMILIES:
		assert(paired.get_frame_texture(family+"idle_front_left",0)==texture)
		assert(paired.get_frame_texture(family+"parry_front",0)==texture)
		for face in PAIRED_CARRY.FACES:
			for motion in ["idle","walk"]:
				var clip: String = family+motion+"_"+face
				if not PAIRED_CARRY.matches_source(paired,clip):
					assert(family in ["thornrose_","moonveil_"])
					continue
				assert(paired.get_frame_count(clip)==8)
				assert(is_equal_approx(paired.get_animation_speed(clip),16.0))
				var total: float = 0.0
				for i in range(8):
					var tile: Texture2D = paired.get_frame_texture(clip,i)
					assert(tile.resource_path==PAIRED_CARRY.ROOT+"%s_%s_%02d.png" % [motion,face,i])
					total+=paired.get_frame_duration(clip,i)
					var spans: Array = PAIRED_CARRY.spans(clip,i,60.0)
					assert(spans.size()==2)
					for hand in range(2):
						var grip: Vector2 = PAIRED_CARRY.grip(clip,i,hand)
						var span: PackedVector2Array = spans[hand]
						if grip==Vector2.INF:
							assert(span.is_empty())
						else:
							assert(span.size()==2 and span[0]==grip)
							assert(is_equal_approx(span[0].distance_to(span[1]),60.0))
				assert(is_equal_approx(total,8.0))
		if not PAIRED_CARRY.matches_source(paired,family+"idle_left"):
			continue
		assert(paired.get_frame_duration(family+"idle_left",4)<paired.get_frame_duration(family+"idle_left",0))
		assert(paired.get_frame_duration(family+"idle_left",5)<paired.get_frame_duration(family+"idle_left",0))
		assert(PAIRED_CARRY.grip(family+"idle_back",0,0)==Vector2.INF)
	# An expanded legacy idle still retains its weighted cycle duration.
	var expanded: String = "sword_modular_idle_front"
	paired.clear(expanded)
	for i in range(24):
		paired.add_frame(expanded,texture,0.5)
	assert(PAIRED_CARRY.install(paired,true)==1)
	assert(paired.get_frame_count(expanded)==8)
	var expanded_total: float = 0.0
	for i in range(8):
		expanded_total+=paired.get_frame_duration(expanded,i)
	assert(is_equal_approx(expanded_total,12.0))
	for family in PAIRED_CARRY.FAMILIES:
		for face in PAIRED_CARRY.FACES:
			var clip: String = family+"walk_"+face
			for i in range(8):
				var wrist: Vector2 = PAIRED_CARRY.lead_grip(clip,i)
				var single: PackedVector2Array = PAIRED_CARRY.single_span(clip,i,74.0,true)
				assert(single.size()==2 and single[0]==wrist)
				assert(is_equal_approx(single[0].distance_to(single[1]),74.0))
				if family in ["thornrose_","moonveil_"]:
					var pose: Dictionary = preload("res://scripts/bow_palette_overlay_v139.gd").clean_cardinal_hold_pose(clip,wrist)
					var angle: float = deg_to_rad(float(pose["rotation_deg"]))
					assert(((pose["position"] as Vector2)+(pose["source_handle"] as Vector2).rotated(angle)).is_equal_approx(wrist))
	body.sprite_frames=paired
	assert(PAIRED_CARRY.applies(body,"dual_sword_idle_front"))
	assert(not PAIRED_CARRY.applies(body,"dual_sword_idle_front_left"))
	body.sprite_frames=frames
	# Original clips stay selected and their normalized idle phase follows the turn.
	for face in CARDINAL.FACES:
		assert(CARDINAL.supports("idle_"+face))
		for index in range(8):
			assert(CARDINAL.is_polished_source("res://assets/ghost/idle_%s_%02d.png" % [face,index]))
			assert(CARDINAL.is_polished_source("res://assets/ghost/%s_%02d.png" % [face,index]))
			assert(CARDINAL.is_polished_source("res://assets/ghost/combat_v14/attack_unarmed_light_%s_%02d.png" % [face,index]))
		assert(not CARDINAL.is_polished_source("res://assets/ghost/hook_%s_00.png" % face))
		assert(CARDINAL.supports("walk_"+face))
		assert(CARDINAL.supports("sword_modular_parry_"+face))
		assert(CARDINAL.supports("attack_sword_modular_heavy_"+face))
		assert(CARDINAL.strength_for("idle_"+face,Vector2(256,220),true,Vector2.ZERO,false)>0.0)
	for face in CARDINAL.DIAGONALS:
		assert(not CARDINAL.supports("idle_"+face))
		assert(not CARDINAL.supports("dual_sword_parry_"+face))
		assert(CARDINAL.strength_for("walk_"+face,Vector2(256,220),true,Vector2.ZERO,false)==0.0)
	assert(not CARDINAL.supports("rose_nocturne_idle_front"))
	assert(not CARDINAL.supports("cardinal_refresh_idle_front"))
	assert(CARDINAL.strength_for("idle_front",Vector2(128,110),true,Vector2.ZERO,false)==0.0)
	assert(CARDINAL.strength_for("idle_front",Vector2(256,220),false,Vector2.ZERO,false)==0.0)
	assert(CARDINAL.strength_for("idle_front",Vector2(256,220),true,Vector2.ONE,false)==0.0)
	assert(CARDINAL.strength_for("idle_front",Vector2(256,220),true,Vector2.ZERO,true)==0.0)
	assert(MOTION.same_locomotion_family("idle_front","idle_front_right"))
	assert(MOTION.same_locomotion_family("walk_back_left","walk_back"))
	assert(not MOTION.same_locomotion_family("idle_front","sword_modular_idle_front"))
	PLAYBACK.play_locomotion(body,"idle_front")
	body.set_frame_and_progress(5,0.5)
	var idle_phase: float=MOTION.phase_of(body)
	PLAYBACK.play_locomotion(body,"idle_back_right")
	assert(is_equal_approx(MOTION.phase_of(body),idle_phase))
	PLAYBACK.play_locomotion(body,"idle_back")
	assert(is_equal_approx(MOTION.phase_of(body),idle_phase))
	body.free()
	print("Directional playback: all eight headings, missing/empty clips, weighted phase, charge and resume PASS")
	quit(0)
