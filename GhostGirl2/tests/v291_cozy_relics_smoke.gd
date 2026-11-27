extends SceneTree
const ARSENAL = preload("res://scripts/relic_arsenal_v277.gd")
const SPECIAL = preload("res://scripts/unique_specials_v261.gd")
const INNATE = preload("res://scripts/unique_innate_v274.gd")
const COZY = preload("res://scripts/lanternhaven_cozy_v291.gd")
const ROOM = preload("res://scripts/room_atmosphere_v278.gd")
const SETTINGS = preload("res://scripts/atmosphere_settings_v278.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(ARSENAL.PROFILES.size()==29)
	assert(SPECIAL.SPECIALS.size()==6)
	assert(INNATE.POWERS.size()==59)
	var throw_count: int = 0
	for base in SPECIAL.SPECIALS:
		if SPECIAL.is_throw(SPECIAL.SPECIALS[base]):
			throw_count+=1
		assert(not INNATE.POWERS.has(base))
	assert(throw_count==2)
	for base in ARSENAL.PROFILES:
		assert(not INNATE.POWERS.has(base))
	for base in ["nightglass_rapier_v286","moonneedle_rapier_v283","briar_hatchet_v283","mourning_longsword","moonlace_dual_daggers_v173","mourninglace_dual_daggers_v231","gloamrose_dual_swords_v174","cathedral_dual_swords_v233","vesperthorn_dual_swords_v231","widowglass_twinblade_v231","vesper_recurve_bow_v238","mourning_girder_bow","choral_moonbow","vesper_latch_crossbow_v237","v203_nightchain_flail","cinderveil_dirk_v238","roseglass_dagger_v169","silkglass_dirk_v276","bellthorn_lance_v276","ivory_misericorde_v233","reliquary_knife_v238"]:
		var definition: GhostItemData = load("res://items/"+base+".tres")
		assert(definition!=null)
		var unique: GhostItemInstance = GhostItemGenerator.create(definition,291101,"unique")
		var normal: GhostItemInstance = GhostItemGenerator.create(definition,291101,"normal")
		assert(SPECIAL.kind(unique).is_empty())
		assert(not INNATE.label(unique).is_empty())
		assert(INNATE.bonuses(unique).size()==2)
		assert(INNATE.bonuses(normal).is_empty())
	assert(COZY.ambient_color(0.0)==Color.WHITE)
	assert(COZY.ambient_color(1.0).g<1.0)
	var audio: AudioStreamWAV = COZY.fire_stream()
	assert(audio.data.size()==COZY.RATE*COZY.DURATION*2)
	assert(audio.loop_mode==AudioStreamWAV.LOOP_FORWARD)
	assert(audio==COZY.fire_stream())
	SETTINGS.loaded=true
	SETTINGS.preset=2
	SETTINGS.revision+=1
	var room: Node2D = Node2D.new()
	root.add_child(room)
	var actor: Node2D = Node2D.new()
	root.add_child(actor)
	var hearth: Node2D = preload("res://scripts/hearth_light_v242.gd").new()
	hearth.name="GatheringHearth"
	room.add_child(hearth)
	var ambience: Node2D = ROOM.new()
	ambience.call("setup",room,actor,"lanternhaven")
	room.add_child(ambience)
	var cozy: Node2D = ambience.get_node("LanternhavenCozyV291")
	assert(cozy.get("fire").playing)
	assert(cozy.get("shade").visible)
	SETTINGS.preset=0
	SETTINGS.revision+=1
	cozy.call("_refresh")
	assert(not cozy.get("fire").playing)
	assert(not cozy.get("shade").visible)
	room.free()
	assert(not is_instance_valid(cozy))
	actor.free()
	print("v2.91 curated relic powers, town contrast, hearth audio and cleanup PASS")
	quit(0)
