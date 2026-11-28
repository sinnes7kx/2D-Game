extends SceneTree
const DIAGONAL = preload("res://scripts/ghost_diagonal_art_v247.gd")
const BOW = preload("res://scripts/bow_palette_overlay_v139.gd")
const DIRECTION = preload("res://scripts/direction_controller_v245.gd")
const AIR = preload("res://scripts/airborne_attacks_v203.gd")
const PLAY = preload("res://scripts/animation/directional_playback.gd")
const RENDER = preload("res://scripts/animation/weapon_render_contract.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var count: int = 0
	for direction in DIAGONAL.DIRECTIONS:
		var cardinal: String = "back" if direction.begins_with("back") else "front"
		var left: bool = direction.ends_with("left")
		var rear: bool = direction.begins_with("back")
		for family in ["thornrose", "moonveil", "forge_bow"]:
			for motion in ["idle", "walk"]:
				var clip: String = family + "_" + motion + "_" + direction
				var fallback: String = family + "_" + motion + "_" + cardinal
				assert(DIAGONAL.armed_clip(fallback,direction,cardinal,frames)==fallback)
				frames.add_animation(clip)
				assert(DIAGONAL.armed_clip(fallback,direction,cardinal,frames)==clip)
				for i in range(8):
					var wrist: Vector2 = Vector2((-30.0 if left else 30.0)+float(i),20.0-float(i))
					var pose: Dictionary = BOW.diagonal_hold_pose(clip,wrist)
					var source: Vector2 = pose["source_handle"]
					var position: Vector2 = pose["position"]
					assert((position+source.rotated(deg_to_rad(float(pose["rotation_deg"])))).is_equal_approx(wrist))
					assert(bool(pose["flip_h"])==left)
					assert(bool(pose["behind"])==rear)
					count+=1
		assert(BOW.diagonal_hold_pose("thornrose_walk_"+direction,Vector2.INF).is_empty())
		for motion in ["jump","dodge"]:
			var action: String = "moonveil_"+motion+"_"+direction
			frames.add_animation(action)
			assert(DIAGONAL.armed_action_clip(motion,"moonveil_walk_",direction,"fallback",frames)==action)
		for style in ["thornrose","moonveil"]:
			for action in ["light","heavy"]:
				var requested: String = "attack_"+style+"_"+action+"_"+cardinal
				var clip: String = "attack_"+style+"_"+action+"_"+direction
				var air: String = AIR.air_name(clip)
				assert(AIR.base_name(air)==clip and AIR.air_name(air)==air)
				assert(DIAGONAL.is_painted_bow_combat(clip) and DIAGONAL.is_painted_bow_combat(air))
				assert(DIAGONAL.combat_body_source_v294(clip)=="idle_"+direction)
				assert(DIAGONAL.combat_body_source_v294(air)=="jump_"+direction)
				frames.add_animation(clip)
				frames.add_animation(air)
				var texture: GradientTexture2D = GradientTexture2D.new()
				texture.gradient = Gradient.new()
				frames.add_frame(clip, texture)
				frames.add_frame(air, texture)
				assert(PLAY.action_clip(requested,direction,frames)==clip)
				assert(PLAY.action_clip(AIR.air_name(requested),direction,frames)==air)
				for i in range(8):
					var wrist: Vector2 = Vector2(-24.0 if left else 24.0, 30.0)
					var heading: Vector2 = DIAGONAL.heading_v294(direction)
					var pose: Dictionary = BOW.diagonal_shoot_pose(clip,wrist,heading,style,float(i))
					var angle: float = deg_to_rad(float(pose["rotation_deg"]))
					assert(((pose["position"] as Vector2)+(pose["source_handle"] as Vector2).rotated(angle)).is_equal_approx(wrist))
					var chord: Vector2 = Vector2(17.1,88.5) if style=="moonveil" else Vector2(16.4,87.7)
					if left:
						chord.x = -chord.x
					if i<6:
						assert(absf(chord.rotated(angle).normalized().dot(heading))<0.001)
					assert(bool(pose["behind"])==rear)
					count+=1
	for direction_index in range(8):
		var heading: Vector2 = DIRECTION.heading(direction_index)
		for hand in [-1,0,1]:
			var axis: Vector2 = RENDER.guard_axis(heading,Vector2(12,20),hand)
			assert(axis.is_finite() and is_equal_approx(axis.length(),1.0) and axis.y<0.0)
	for dx in [-1,1]:
		for dy in [-1,1]:
			var movement: Vector2 = DIRECTION.digital_vector(dx<0,dx>0,dy<0,dy>0)
			assert(is_equal_approx(movement.length(),1.0))
	# Guard clips must use the exact source cell referenced by wrist sampling.
	var guard_frames: SpriteFrames = SpriteFrames.new()
	for face in DIAGONAL.GUARD_FACES:
		var source: String = DIAGONAL.guard_source("parry_"+face)
		guard_frames.add_animation(source)
		for i in range(8):
			var tex: GradientTexture2D = GradientTexture2D.new()
			tex.gradient=Gradient.new()
			guard_frames.add_frame(source,tex)
	DIAGONAL.install_guards(guard_frames)
	for face in DIAGONAL.GUARD_FACES:
		var cardinal: String = DIAGONAL.cardinal_for_clip("parry_"+face)
		for family in ["","sword_","sword_modular_","dagger_","nocturne_dagger_","dual_dagger_","dual_sword_","spear_","briarwake_spear_","scythe_","halberd_","maul_","ashglass_maul_","twinblade_","rosemirror_twinblade_","rapier_","axe_","seraph_scythe_","thornrose_","moonveil_","forge_bow_","crossbow_","forge_dagger_","wand_"]:
			var clip: String = DIAGONAL.guard_clip(family+"idle_",face,cardinal,guard_frames)
			assert(not clip.is_empty() and guard_frames.get_frame_count(clip)==8)
			for i in range(8):
				var source: String = DIAGONAL.guard_source(clip)
				var neutral: Texture2D = DIAGONAL.guard_neutral_texture(clip,i)
				var expected: Texture2D = neutral if neutral!=null else guard_frames.get_frame_texture(source,DIAGONAL.guard_source_frame(clip,i))
				assert(guard_frames.get_frame_texture(clip,i)==expected)
				if neutral!=null:
					assert(i in [0,7] and DIAGONAL.diagonal_name(clip).is_empty())
					var carry = preload("res://scripts/cardinal_paired_carry_v296.gd")
					assert(DIAGONAL.guard_wrist(clip,i)==carry.lead_grip(DIAGONAL.guard_idle_clip(clip),0))
				var grip: Vector2 = DIAGONAL.guard_wrist(clip,i)
				var span: PackedVector2Array = DIAGONAL.guard_base_span(clip,i,60.0)
				if grip!=Vector2.INF:
					assert(span.size()==2 and span[0]==grip and is_equal_approx(span[0].distance_to(span[1]),60.0))
					if family in ["thornrose_","moonveil_"]:
						var pose: Dictionary = BOW.guard_hold_pose(clip,grip,Vector2.DOWN)
						assert(((pose["position"] as Vector2)+(pose["source_handle"] as Vector2).rotated(deg_to_rad(float(pose["rotation_deg"])))).is_equal_approx(grip))
				else:
					assert(span.is_empty())
	assert(DIAGONAL.guard_frame(0.0,0.55)==0)
	assert(DIAGONAL.guard_frame(0.2,0.35)==4)
	assert(DIAGONAL.guard_frame(0.2,0.10)==5)
	assert(DIAGONAL.guard_frame(0.25,0.05)==6)
	assert(DIAGONAL.guard_frame(0.55,0.0)==7)
	# Synthetic texture tests only validate importer contracts; never ship test
	# pixels or treat them as finished character artwork.
	var authored: SpriteFrames = SpriteFrames.new()
	var fallback: String = "sword_modular_parry_front"
	var target: String = "sword_modular_parry_front_right"
	var tile: GradientTexture2D = GradientTexture2D.new()
	tile.gradient=Gradient.new()
	authored.add_animation(fallback)
	authored.set_animation_speed(fallback,16.0)
	for i in range(16):
		authored.add_frame(fallback,tile,0.5)
	var atlas: GradientTexture2D = GradientTexture2D.new()
	atlas.width=2048
	atlas.height=1760
	atlas.gradient=Gradient.new()
	var guides: Dictionary = {"near_hand":1,"left":[],"right":[]}
	for i in range(8):
		guides["left"].append([] if i==3 else [80+i,130])
		guides["right"].append([140+i,125-i])
	var invalid: Dictionary = guides.duplicate(true)
	invalid["right"][0]=[256,20]
	assert(not DIAGONAL.install_authored_row(authored,atlas,2,target,invalid))
	assert(not authored.has_animation(target))
	assert(not DIAGONAL.install_authored_row(authored,tile,2,target,guides))
	assert(DIAGONAL.install_authored_row(authored,atlas,2,target,guides))
	assert(authored.get_frame_count(target)==8 and authored.get_animation_speed(target)==16.0)
	assert(authored.get_meta("authored_combat_"+target,false))
	for i in range(8):
		var cell: AtlasTexture = authored.get_frame_texture(target,i) as AtlasTexture
		assert(cell.atlas==atlas and cell.region==Rect2(256*i,440,256,220))
		assert(is_equal_approx(authored.get_frame_duration(target,i),1.0))
		assert(DIAGONAL.guard_wrist(target,i)==Vector2(12+i,15-i))
	assert(DIAGONAL.guard_wrist(target,3,0)==Vector2.INF)
	assert(not DIAGONAL.missing_authored_guards(authored).has(target))
	assert(not DIAGONAL.install_authored_row(authored,atlas,8,target,guides))
	assert(authored.get_frame_count(target)==8)
	assert(DIAGONAL.guard_frame(0.04,0.12,true)==4)
	assert(DIAGONAL.guard_frame(0.04,0.22,true)==4)
	assert(DIAGONAL.guard_frame(0.08,0.09,true)==5)
	assert(DIAGONAL.guard_frame(0.15,0.04,true)==6)
	assert(DIAGONAL.guard_frame(0.2,0.01,true)==7)
	print("v2.75 bow diagonal carry, shooting, airborne aliases, guard clips and axes PASS: ",count," samples")
	quit(0)
