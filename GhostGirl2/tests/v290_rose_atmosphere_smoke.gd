extends SceneTree
const ROOM = preload("res://scripts/room_atmosphere_v278.gd")
const DETAIL = preload("res://scripts/lanternhaven_atmosphere_v290.gd")
const SETTINGS = preload("res://scripts/atmosphere_settings_v278.gd")
const PERF = preload("res://scripts/performance_profiles_v230.gd")
const RELIC = preload("res://scripts/relic_mechanics_v288.gd")
const FX = preload("res://scripts/relic_cyclone_fx_v288.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	SETTINGS.loaded=true
	SETTINGS.preset=2
	SETTINGS.revision+=1
	PERF.profile=PERF.Profile.HIGH
	assert(DETAIL.mote_budget()==48)
	assert(RELIC.bloom_v290(0.35)==0.0)
	assert(RELIC.hybrid_radius_v290(0.75)>111.0)
	assert(RELIC.hybrid_radius_v290(1.15)==132.0)
	var audio: AudioStreamWAV = DETAIL.wind_stream()
	assert(audio.data.size()==DETAIL.RATE*DETAIL.SECONDS*2)
	assert(audio.loop_end==DETAIL.RATE*DETAIL.SECONDS)
	assert(audio.loop_mode==AudioStreamWAV.LOOP_FORWARD)
	assert(audio==DETAIL.wind_stream())
	var town: Node2D = Node2D.new()
	root.add_child(town)
	var actor: Node2D = Node2D.new()
	root.add_child(actor)
	var atmosphere: Node2D = ROOM.new()
	atmosphere.call("setup",town,actor,"lanternhaven")
	town.add_child(atmosphere)
	var detail: Node2D = atmosphere.get_node("LanternhavenLivingAirV290")
	assert(detail.get("veil").visible)
	assert(detail.get("sound").playing)
	PERF.profile=PERF.Profile.LOW
	PERF.revision+=1
	assert(DETAIL.mote_budget()==12)
	SETTINGS.preset=0
	SETTINGS.revision+=1
	detail.call("_refresh")
	assert(DETAIL.mote_budget()==0)
	assert(not detail.get("veil").visible)
	assert(not detail.get("sound").playing)
	town.free()
	assert(not is_instance_valid(detail))
	actor.free()
	print("v2.90 hybrid buildup, ambient budget, cached audio and room lifetime PASS")
	quit(0)
