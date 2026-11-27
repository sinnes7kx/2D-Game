extends SceneTree
const MODELS = preload("res://scripts/weapon_models_v283.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const AIR = preload("res://scripts/airborne_attacks_v203.gd")
const CHOICES = preload("res://scripts/visual_choices_v216.gd")
const FORGE = preload("res://scripts/bow_dagger_forge_v238.gd")
const ARSENAL = preload("res://scripts/relic_arsenal_v277.gd")
const SPECIAL = preload("res://scripts/unique_specials_v261.gd")
const INVENTORY = preload("res://scripts/inventory.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(MODELS.MODELS.size()==15)
	for id in MODELS.MODELS:
		assert(MODELS.MODELS[id] is Texture2D)
	var frames: SpriteFrames = SpriteFrames.new()
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient=Gradient.new()
	for face in ["front","back","left","right"]:
		var source: String = "attack_unarmed_light_"+face
		frames.add_animation(source)
		for i in range(8):
			frames.add_frame(source,texture)
	MODELS.install(frames)
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames=frames
	AIR.install(sprite)
	var clips: int = 0
	for face in ["front","back","left","right"]:
		for family in ["rapier","axe"]:
			var names: Array[String] = [family+"_idle_"+face,family+"_walk_"+face]
			if family=="rapier":
				names.append_array(["attack_rapier_pierce_"+face,"attack_rapier_heavy_pierce_"+face])
			else:
				names.append_array(["attack_axe_light_"+face,"attack_axe_heavy_"+face])
			for name in names:
				assert(frames.has_animation(name))
				assert(frames.get_frame_count(name)==8)
				var looping: bool = bool(frames.call("get_animation_loop_mode",name)==1) if frames.has_method("get_animation_loop_mode") else bool(frames.call("get_animation_loop",name))
				assert(looping==not name.begins_with("attack_"))
				for i in range(8):
					var span: PackedVector2Array = MODELS.span(name,face,i)
					var anchor: Vector2 = HAND.hand_anchor(face,MODELS.sequence(name,face)[i],0 if face=="left" else 1)
					if anchor==Vector2.INF:
						assert(span.is_empty())
					else:
						assert(span.size()==2 and span[0].is_equal_approx(anchor))
						assert(span[0].distance_to(span[1])>50.0)
				clips+=1
			assert(frames.has_animation(AIR.air_name(names[3])))
	assert(clips==32)
	sprite.free()
	for id in ["cathedral_rapier_v283","moonneedle_rapier_v283","briar_hatchet_v283","gravecleaver_axe_v283","gallows_greataxe_v283"]:
		var data: GhostItemData = load("res://items/"+id+".tres")
		var item: GhostItemInstance = GhostItemGenerator.create(data,283123,"unique")
		assert(ARSENAL.has_skill(id))
		assert(not SPECIAL.label(item).is_empty())
		assert(SPECIAL.label(GhostItemGenerator.create(data,283123,"normal")).is_empty())
		assert(item.physical_damage_kind()==("pierce" if id.contains("rapier") else "slash"))
		assert(id in INVENTORY.RELIC_DELIVERY_V282)
	var bow: GhostItemInstance = GhostItemGenerator.create(preload("res://items/frostveil_bow_v277.tres"),283124,"unique")
	assert(bow.uses_forge_bow())
	bow.glow_level_override=4
	for mode in range(4):
		bow.bow_glow_mode_override=mode
		assert(CHOICES.bow_body_visible(bow)==(mode!=0))
		assert(CHOICES.bow_string_visible(bow)==(mode in [2,3]))
	bow.glow_level_override=0
	assert(not CHOICES.bow_body_visible(bow) and not CHOICES.bow_string_visible(bow))
	assert(FORGE.limbs(Vector2.ZERO,Vector2.RIGHT,"frostveil_bow_v277",1.0).size()==2)
	assert(ARSENAL.PROFILES.size()==44)
	print("v2.83 held models, 32 animation clips, 256 frame grips, unique skills and bow controls PASS")
	quit(0)
