extends SceneTree
const SKILL = preload("res://scripts/seraph_descent_v292.gd")
const SPECIAL = preload("res://scripts/unique_specials_v261.gd")
const MODELS = preload("res://scripts/weapon_models_v283.gd")
const AIR = preload("res://scripts/airborne_attacks_v203.gd")
const GARDEN = preload("res://scripts/garden_moonlight_v292.gd")
const ROOM = preload("res://scripts/room_atmosphere_v278.gd")
const SETTINGS = preload("res://scripts/atmosphere_settings_v278.gd")
const PERF = preload("res://scripts/performance_profiles_v230.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var data: GhostItemData = preload("res://items/seraph_reaper_v292.tres")
	var item: GhostItemInstance = GhostItemGenerator.create(data,292101,"unique")
	assert(SPECIAL.kind(item)=="seraph_descent")
	assert(item.display_name()=="Seraph Reaper")
	assert(not SPECIAL.is_throw("seraph_descent"))
	assert(SPECIAL.kind(GhostItemGenerator.create(data,292101,"normal")).is_empty())
	assert(SKILL.height_at(0.0)==0.0)
	assert(SKILL.height_at(0.48)>65.0)
	assert(absf(SKILL.height_at(SKILL.DURATION))<0.01)
	assert(SKILL.speed_at(0.60)>SKILL.speed_at(0.32))
	assert(SKILL.contact(Vector2(160,0),Vector2.RIGHT,true))
	assert(not SKILL.contact(Vector2(160,0),Vector2.RIGHT,false))
	assert(not SKILL.contact(Vector2(-80,0),Vector2.RIGHT,true))
	var frames: SpriteFrames = SpriteFrames.new()
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient=Gradient.new()
	for face in ["front","back","left","right"]:
		var source: String = "attack_unarmed_light_"+face
		frames.add_animation(source)
		for index in range(8):
			frames.add_frame(source,texture)
	MODELS.install(frames)
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames=frames
	AIR.install(sprite)
	for face in ["front","back","left","right"]:
		for clip in ["seraph_scythe_idle_"+face,"seraph_scythe_walk_"+face,"attack_seraph_scythe_light_"+face,"attack_seraph_scythe_heavy_"+face]:
			assert(frames.has_animation(clip))
			assert(frames.get_frame_count(clip)==8)
		assert(frames.has_animation(AIR.air_name("attack_seraph_scythe_heavy_"+face)))
	sprite.free()
	SETTINGS.loaded=true
	SETTINGS.preset=2
	PERF.profile=PERF.Profile.HIGH
	assert(GARDEN.particle_budget()==36)
	PERF.profile=PERF.Profile.LOW
	assert(GARDEN.particle_budget()==10)
	for key in ["garden","garden_arbor","garden_bridge","glasshouse"]:
		var scene: PackedScene = load("res://scenes/rooms/"+key+".tscn")
		var room: Node2D = scene.instantiate()
		var markers: Node2D = room.get_node("AtmosphereV292")
		assert(markers.get_child_count()>=5)
		for marker in markers.get_children():
			assert(marker is Marker2D)
		room.free()
	SETTINGS.preset=0
	assert(GARDEN.particle_budget()==0)
	print("v2.92 Seraph skill routes, reach, airborne aliases and garden markers PASS")
	quit(0)
