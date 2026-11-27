extends SceneTree
const ART = preload("res://scripts/ghost_diagonal_art_v247.gd")

func _initialize() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	for cardinal in ["front", "back"]:
		for action in ["idle", "walk"]:
			var name: String = action + "_" + cardinal
			frames.add_animation(name)
			frames.set_animation_speed(name, 6.0)
			for i in range(8):
				frames.add_frame(name, GradientTexture2D.new())
	assert(ART._load_sheet("res://missing_diagonal_test_v271.png")==null)
	assert(not ART._valid_dimensions(GradientTexture2D.new()))
	if ART.available():
		assert(ART.install(frames))
		for direction in ART.DIRECTIONS:
			for action in ["idle", "walk"]:
				assert(frames.get_frame_count(action + "_" + direction) == 8)
	else:
		assert(not ART.install(frames))
	# Test resolver even when the optional image has not been installed.
	if not frames.has_animation("idle_front_right"):
		frames.add_animation("idle_front_right")
	assert(ART.resolve("idle_front", "front_right", "front", false, frames) == "idle_front_right")
	assert(ART.resolve("idle_front", "front_right", "front", true, frames) == "idle_front")
	assert(ART.resolve("sword_idle_front", "front_right", "front", false, frames) == "sword_idle_front")
	assert(ART.resolve("attack_front", "front_right", "front", false, frames) == "attack_front")
	assert(ART.resolve("idle_front", "front", "front", false, frames) == "idle_front")
	var controller = preload("res://scripts/direction_controller_v245.gd")
	var inputs: Array[Vector2] = [controller.digital_vector(false,true,true,false),controller.digital_vector(true,false,true,false),controller.digital_vector(false,true,false,true),controller.digital_vector(true,false,false,true)]
	var names: Array[String] = ["back_right","back_left","front_right","front_left"]
	for i in range(4):
		assert(is_equal_approx(inputs[i].length(),1.0))
		assert(controller.NAMES[controller.octant(inputs[i])]==names[i])
	assert(controller.digital_vector(true,true,true,true)==Vector2.ZERO)
	for family in ART.WEAPON_PREFIXES:
		for direction in ART.DIRECTIONS:
			var cardinal: String = "back" if direction.begins_with("back") else "front"
			for motion in ["idle_","walk_"]:
				var clip: String = family+motion+direction
				assert(ART.is_carried_clip(clip))
				if frames.has_animation(clip):
					assert(ART.armed_clip(family+motion+cardinal,direction,cardinal,frames)==clip)
					assert(frames.get_frame_count(clip)==8)
					assert(frames.get_frame_texture(clip,7)==frames.get_frame_texture(motion+direction,7))
	# Opening a live equipment preview reruns these legacy installers on
	# shared SpriteFrames; they must never touch a diagonal alias.
	if ART.available() and frames.has_animation("scythe_idle_front_right"):
		var fixture: AnimatedSprite2D = AnimatedSprite2D.new()
		fixture.sprite_frames=frames
		for face in ["front","back","left","right"]:
			var source: String = "attack_unarmed_light_"+face
			frames.add_animation(source)
			for i in range(8):
				frames.add_frame(source,GradientTexture2D.new())
		var expected_textures: Dictionary = {}
		for clip in frames.get_animation_names():
			if ART.is_carried_clip(str(clip)):
				expected_textures[clip]=frames.get_frame_texture(clip,7)
		preload("res://scripts/v175_hookfree_weapon_body.gd").install(fixture)
		preload("res://scripts/scythe_art_v190.gd").install(fixture)
		preload("res://scripts/heavy_weapon_art_v192.gd").install(fixture)
		preload("res://scripts/gentle_weapon_motion_v191.gd").install(fixture)
		preload("res://scripts/steady_weapon_idles_v195.gd").install(fixture)
		for clip in expected_textures:
			assert(frames.get_frame_count(clip)==8)
			assert(frames.get_frame_texture(clip,7)==expected_textures[clip])
		fixture.free()
	assert(not ART.is_carried_clip("attack_dagger_heavy_front_right"))
	assert(ART.is_painted_bow_carry("moonveil_walk_back_left"))
	if frames.has_animation("sword_modular_idle_front_right"):
		assert(ART.armed_clip("sword_modular_idle_front", "front_right", "front", frames) == "sword_modular_idle_front_right")
	assert(ART.wrist("sword_modular_idle_front_right",0) != Vector2.INF)
	# Actual repaired-atlas near wrist pixel centers. Keep legacy fallback.
	if ResourceLoader.exists(ART.REVISED_ATLAS,"Texture2D"):
		assert(ART.wrist("sword_modular_idle_front_right",0)==Vector2(-3,29))
		assert(ART.wrist("nocturne_dagger_idle_front_left",0)==Vector2(-2,28))
		assert(ART.wrist("wand_walk_front_right",0)==Vector2(0,34))
		assert(ART.wrist("spear_idle_back_right",0)==Vector2(48,27))
		assert(ART.far_wrist("dual_sword_walk_front_left",0)==Vector2.INF)
		for direction in ART.DIRECTIONS:
			for action in ["idle","walk"]:
				for frame in range(8):
					var clip: String = "sword_modular_"+action+"_"+direction
					var points: PackedVector2Array = ART.carried_span(clip,frame,67.0)
					assert(points.size()==2 and points[0]==ART.wrist(clip,frame))
	assert(ART.cardinal_for_clip("wand_walk_back_left") == "back")
	assert(ART.cardinal_for_clip("sword_modular_idle_front_right") == "front")
	if frames.has_animation("sword_modular_idle_back_left"):
		assert(ART.wrist("sword_modular_idle_back_left",0) != Vector2.INF)
	if frames.has_animation("dodge_back_left"):
		assert(ART.action_clip("dodge","back_left","dodge_back",frames) == "dodge_back_left")
	else:
		assert(ART.action_clip("dodge","back_left","dodge_back",frames) == "dodge_back")
	if frames.has_animation("jump_front_right"):
		assert(frames.get_frame_count("jump_front_right") == 8)
		assert(not frames.get_animation_loop("jump_front_right"))
	for prefix in ["scythe_", "halberd_", "maul_", "ashglass_maul_", "forge_bow_"]:
		var clip: String = prefix + "walk_front_right"
		for i in range(8):
			var points: PackedVector2Array = ART.carried_span(clip,i,70.0,true)
			assert(points.size()==2 and points[0]==ART.wrist(clip,i))
			assert(is_equal_approx(points[0].distance_to(points[1]),70.0))
		if frames.has_animation(clip):
			assert(ART.armed_clip(prefix+"walk_front","front_right","front",frames)==clip)
	for direction in ART.DIRECTIONS:
		for frame in range(8):
			var clip: String = "dual_sword_walk_"+direction
			var pair: Array = ART.paired_spans(clip,frame,70.0)
			assert(pair.size()==2)
			for hand in range(2):
				var span: PackedVector2Array = pair[hand]
				var wrist: Vector2 = ART.hand_wrist(clip,frame,hand)
				if wrist==Vector2.INF:
					assert(span.is_empty())
				else:
					assert(span.size()==2 and span[0]==wrist and is_equal_approx(span[0].distance_to(span[1]),70.0))
			if direction.begins_with("back"):
				assert(pair[1-ART.near_hand(clip)].is_empty())
			var cross: PackedVector2Array = ART.crossbow_span("crossbow_walk_"+direction,frame)
			if not cross.is_empty():
				assert(is_equal_approx(cross[0].distance_to(cross[1]),32.0))
	for prefix in ["spear_", "briarwake_spear_", "nocturne_dagger_"]:
		for direction in ART.DIRECTIONS:
			var clip: String = prefix+"walk_"+direction
			var cardinal: String = "back" if direction.begins_with("back") else "front"
			for i in range(8):
				if prefix != "nocturne_dagger_":
					var shaft: PackedVector2Array = ART.spear_span(clip,i)
					var wrist: Vector2 = ART.wrist(clip,i)
					if wrist == Vector2.INF:
						assert(shaft.is_empty())
					else:
						assert(shaft.size()==2 and shaft[0]==wrist)
						assert(is_equal_approx(shaft[0].distance_to(shaft[1]),74.0))
			var fallback: String = prefix+"walk_"+cardinal
			var expected: String = clip if frames.has_animation(clip) else fallback
			assert(ART.armed_jump_carry(fallback,direction,cardinal,frames)==expected)
			assert(ART.armed_jump_carry("dodge_"+cardinal,direction,cardinal,frames)=="dodge_"+cardinal)
	var wand = preload("res://scripts/wand_anchors_v216.gd")
	var result: PackedVector2Array = wand.transformed_span(PackedVector2Array([Vector2(12,5),Vector2(32,-10)]),Vector2(-20,30),0.17)
	assert(result[0]==Vector2(-20,30))
	assert(result[1].is_equal_approx(Vector2(-20,30)+Vector2(20,-15).rotated(0.17)*wand.VISUAL_SCALE))
	var audio = preload("res://scripts/combat_juice_v194.gd")
	for cue in ["blunt_hit","blade_hit","bow_release","crossbow_fire","crossbow_reload","dagger_swing","polearm_swing"]:
		var stream: AudioStreamWAV = audio._render(cue)
		assert(stream.mix_rate==audio.RATE and stream.data.size()>1000)
	print("v257 diagonal anchors, shared wand transform and audio cue assertions")
	quit(0)
