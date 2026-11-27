extends SceneTree
const TACTICS = preload("res://scripts/forge_tactics_v286.gd")
const MODELS = preload("res://scripts/weapon_models_v283.gd")
const SPECIAL = preload("res://scripts/unique_specials_v261.gd")
const ARSENAL = preload("res://scripts/relic_arsenal_v277.gd")
const INVENTORY = preload("res://scripts/inventory.gd")
const AUDIO = preload("res://scripts/combat_juice_v194.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(TACTICS.thrust_contact(Vector2(160,20),Vector2.RIGHT,176.0,false))
	assert(not TACTICS.thrust_contact(Vector2(160,25),Vector2.RIGHT,176.0,false))
	assert(TACTICS.thrust_contact(Vector2(160,30),Vector2.RIGHT,214.0,true))
	assert(not TACTICS.thrust_contact(Vector2(-40,0),Vector2.RIGHT,214.0,true))
	assert(not TACTICS.thrust_contact(Vector2(215,0),Vector2.RIGHT,214.0,true))
	assert(not TACTICS.thrust_contact(Vector2(20,0),Vector2.ZERO,214.0,true))
	assert(float(TACTICS.tuning("briar_hatchet_v283")["time"])<float(TACTICS.tuning("ossuary_poleaxe_v286")["time"]))
	assert(float(TACTICS.tuning("ossuary_poleaxe_v286")["reach"])>float(TACTICS.tuning("rosehook_bearded_axe_v286")["reach"]))
	for face in ["front","back","left","right"]:
		var light: Array[int] = MODELS.sequence("attack_axe_light_"+face,face)
		var heavy: Array[int] = MODELS.sequence("attack_axe_heavy_"+face,face)
		assert(light.size()==8 and heavy.size()==8 and light!=heavy)
		for index in heavy:
			assert(index>=0 and index<8)
	var names: Dictionary = {}
	for id in ["ivory_duelist_rapier_v286","nightglass_rapier_v286","rosehook_bearded_axe_v286","ossuary_poleaxe_v286"]:
		var data: GhostItemData = load("res://items/"+id+".tres")
		assert(data!=null and data.icon!=null and MODELS.MODELS.has(id))
		assert(id in INVENTORY.RELIC_DELIVERY_V282)
		var item: GhostItemInstance = GhostItemGenerator.create(data,286101,"unique")
		var normal: GhostItemInstance = GhostItemGenerator.create(data,286101,"normal")
		var name: String = SPECIAL.label(item)
		if name.is_empty():
			name=preload("res://scripts/unique_innate_v274.gd").label(item)
		assert(not name.is_empty() and not names.has(name))
		names[name]=true
		assert(SPECIAL.label(normal).is_empty())
		assert(item.physical_damage_kind()==("pierce" if id.contains("rapier") else "slash"))
		assert(ARSENAL.PROFILES.has(id) or preload("res://scripts/unique_innate_v274.gd").POWERS.has(id))
	for cue in ["axe_swing","axe_heavy_swing","axe_impact","rapier_thrust","rapier_impact"]:
		var sound: AudioStreamWAV = AUDIO._render(cue)
		assert(sound.data.size()>0 and sound.mix_rate==AUDIO.RATE)
	print("v2.86 new held models, unique skills, thrust geometry, axe timing and audio PASS")
	quit(0)
