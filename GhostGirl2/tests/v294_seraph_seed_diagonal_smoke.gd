extends SceneTree
const SKILL = preload("res://scripts/seraph_descent_v292.gd")
const MODELS = preload("res://scripts/weapon_models_v283.gd")
const DIAG = preload("res://scripts/ghost_diagonal_art_v247.gd")
const AIR = preload("res://scripts/airborne_attacks_v203.gd")
const MODS = preload("res://scripts/weapon_mods_v250.gd")
const FX = preload("res://scripts/seraph_wings_fx_v292.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(is_equal_approx(SKILL.DURATION,1.44))
	assert(SKILL.RISE_HIT<SKILL.TURN and SKILL.TURN<SKILL.FALL_HIT and SKILL.FALL_HIT<SKILL.DURATION)
	for heading in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2(1,1).normalized(),Vector2(-1,-1).normalized()]:
		for left in [false,true]:
			assert(MODELS.seraph_axis(heading,0.46,0.46,left).dot(heading)>0.999)
			assert(MODELS.seraph_axis(heading,0.0,0.46,left).dot(heading)>0.0)
			assert(MODELS.seraph_axis(heading,1.0,0.46,left).dot(heading)>0.0)
	var ids: Array[String] = [
		"briar_hatchet_v283","gravecleaver_axe_v283","gallows_greataxe_v283",
		"rosehook_bearded_axe_v286","ossuary_poleaxe_v286","cathedral_rapier_v283",
		"moonneedle_rapier_v283","ivory_duelist_rapier_v286","nightglass_rapier_v286",
		"blackthorn_crossbow_v236","silver_reliquary_crossbow_v236","vesper_latch_crossbow_v237",
		"ossuary_arbalest_v237","mourning_star_crossbow_v277","seraph_reaper_v292"
	]
	for id in ids:
		var data: GhostItemData = load("res://items/"+id+".tres")
		assert(data!=null)
		var item: GhostItemInstance = GhostItemGenerator.create(data,294123,"unique")
		var stats: Dictionary = item.all_stats()
		var damage: float = item.weapon_damage()
		var mod: String = item.weapon_mod
		var seed_value: int = item.item_seed
		assert(not item.collector_appearance().is_empty())
		assert(item.glow_gradient_colors().size()>=2)
		item.apply_cosmetic_seed(294124)
		var first: Array[Color] = item.glow_gradient_colors()
		item.apply_cosmetic_seed(294125)
		assert(first!=item.glow_gradient_colors())
		item.apply_cosmetic_seed(294124)
		assert(first==item.glow_gradient_colors())
		assert(item.item_seed==seed_value and item.weapon_mod==mod and item.all_stats()==stats and is_equal_approx(item.weapon_damage(),damage))
		assert(not MODS.allowed("sword",item.weapon_style()).is_empty())
		if item.weapon_style()!="crossbow":
			assert(MODELS.cutting_edge(id).size()>=2)
	var frames: SpriteFrames = SpriteFrames.new()
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient=Gradient.new()
	for face in ["front","back","left","right"]:
		for action in ["idle_","walk_","attack_unarmed_light_"]:
			var source: String = action+face
			frames.add_animation(source)
			DIAG._set_loop_v293(frames,source,not action.begins_with("attack_"))
			for i in range(8):
				frames.add_frame(source,texture)
	MODELS.install(frames)
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames=frames
	AIR.install(sprite)
	if DIAG.install(frames) and DIAG._load_sheet(DIAG.REVISED_ACTIONS)!=null:
		var count: int = 0
		for stem in DIAG.MODULAR_COMBAT_V294:
			for air in ["","air_"]:
				for direction in DIAG.DIRECTIONS:
					var clip: String = stem+air+direction
					if not frames.has_animation(clip):
						continue
					assert(frames.get_frame_count(clip)==8)
					assert(DIAG.missing_combat_clips_v293(frames).has(clip))
					for i in range(8):
						var span: PackedVector2Array = MODELS.diagonal_attack_span(clip,i)
						assert(span.size()==2)
						assert(span[0].is_equal_approx(DIAG.wrist(clip,i)))
					count+=1
		assert(count>=24)
		print("v2.94 diagonal modular clip count: ",count)
	else:
		push_warning("Install the v2.93 diagonal atlas restore pack to exercise diagonal art tests.")
	sprite.free()
	print("v2.94 Seraph forward head alignment and cosmetic seed invariants checked")
	quit(0)
