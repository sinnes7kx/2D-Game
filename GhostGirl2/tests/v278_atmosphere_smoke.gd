extends SceneTree
const ROOM_FX = preload("res://scripts/room_atmosphere_v278.gd")
const SETTINGS = preload("res://scripts/atmosphere_settings_v278.gd")
const TEXTURES = preload("res://scripts/atmosphere_textures_v278.gd")
const PERF = preload("res://scripts/performance_profiles_v230.gd")
const LANTERN = preload("res://scripts/moor_lantern.gd")
const SHADOW = preload("res://scripts/shadow.gd")
const IMPACT = preload("res://scripts/impact_spawner_v149.gd")
const BURST = preload("res://scripts/impact_burst_v149.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	# Session-only test overrides: never persist test presets to user config.
	SETTINGS.loaded=true
	SETTINGS.preset=2
	SETTINGS.revision+=1
	PERF.profile=PERF.Profile.HIGH
	PERF.revision+=1
	assert(SETTINGS.light_budget()==8)
	assert(ROOM_FX.profile("hollow_veil_moor")["far"]>ROOM_FX.profile("lanternhaven")["far"])
	assert(ROOM_FX.profile("observatory")["ink"]!=ROOM_FX.profile("lanternhaven")["ink"])
	assert(ROOM_FX.profile("westwood_road")["far"]>ROOM_FX.profile("colosseum")["far"])
	assert(ROOM_FX.profile("colosseum")["near"]<0.02)
	assert(TEXTURES.light()==TEXTURES.light())
	assert(TEXTURES.shadow()==TEXTURES.shadow())
	assert(TEXTURES.light().width==128)
	assert(TEXTURES.shadow().width==64)
	assert(TEXTURES.dust()==TEXTURES.dust() and TEXTURES.dust().width==64)
	assert(ROOM_FX.readability_radius("colosseum")>ROOM_FX.readability_radius("lanternhaven"))
	var room: Node2D = Node2D.new()
	root.add_child(room)
	var painted: Sprite2D = Sprite2D.new()
	painted.name="PaintedRoom"
	painted.centered=false
	painted.texture=TEXTURES.light()
	room.add_child(painted)
	var player: Node2D = Node2D.new()
	root.add_child(player)
	player.position=Vector2(80,80)
	for i in range(12):
		var marker: Node2D = LANTERN.new()
		marker.position=Vector2(40+float(i)*9.0,100)
		room.add_child(marker)
	var atmosphere: Node2D = ROOM_FX.new()
	atmosphere.call("setup",room,player,"hollow_veil_moor")
	room.add_child(atmosphere)
	assert(atmosphere.get("anchors").size()==12)
	assert(atmosphere.get("lights").size()==8)
	assert(atmosphere.get("halos").size()==8)
	assert(atmosphere.get("far_mist").z_index==-43)
	assert(atmosphere.get("near_mist").z_index==38)
	assert(atmosphere.get("near_mist").mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert(atmosphere.get("far_mist").size==Vector2(128,128))
	assert(atmosphere.get("far_mist").visible)
	assert(atmosphere.get("near_mist").visible)
	assert(_enabled_count(atmosphere)==8)
	var near: ShaderMaterial=atmosphere.get("near_mist").material as ShaderMaterial
	var far: ShaderMaterial=atmosphere.get("far_mist").material as ShaderMaterial
	assert(is_equal_approx(float(near.get_shader_parameter("clear_strength")),0.72))
	assert(is_zero_approx(float(far.get_shader_parameter("clear_strength"))))
	player.position=Vector2(96,112)
	atmosphere.call("_update_readability")
	assert(near.get_shader_parameter("clear_center")==player.global_position)
	assert(near.get_shader_parameter("clear_radius")==170.0)
	assert(BURST.particle_budget(10,true)==6 and BURST.particle_budget(10,false)==10)
	for heading in [Vector2.RIGHT,Vector2.UP,Vector2.LEFT,Vector2.DOWN]:
		assert(BURST.spark_direction(heading,0.0).is_equal_approx(heading))
		assert(BURST.spark_direction(heading,PI).dot(heading)>0.0)
	var fx_parent: Node2D=Node2D.new()
	fx_parent.position=Vector2(200,100)
	room.add_child(fx_parent)
	for i in range(32):
		IMPACT.burst(fx_parent,Vector2(300+i,220),"poise",1.0,Vector2.RIGHT,33)
	var live: int=0
	for effect in fx_parent.get_children():
		if not effect.is_queued_for_deletion():
			live+=1
	assert(live==IMPACT.MAX_BURSTS)
	var newest: Node2D=fx_parent.get_child(fx_parent.get_child_count()-1)
	assert(newest.global_position==Vector2(331,220))
	assert(newest.get("fragments").size()==7)
	IMPACT.burst(fx_parent,Vector2(331,220),"poise",1.0,Vector2.RIGHT,33)
	var repeat: Node2D=fx_parent.get_child(fx_parent.get_child_count()-1)
	assert(repeat.get("fragments")==newest.get("fragments"))
	IMPACT.burst(fx_parent,Vector2(332,220),"poise",1.0,Vector2.RIGHT,33)
	var moved: Node2D=fx_parent.get_child(fx_parent.get_child_count()-1)
	assert(moved.get("fragments")!=repeat.get("fragments"))
	PERF.profile=PERF.Profile.LOW
	PERF.revision+=1
	atmosphere.call("_refresh")
	assert(SETTINGS.light_budget()==3)
	assert(_enabled_count(atmosphere)==3)
	assert(not atmosphere.get("near_mist").visible)
	SETTINGS.preset=0
	SETTINGS.revision+=1
	atmosphere.call("_refresh")
	assert(_enabled_count(atmosphere)==0)
	assert(not atmosphere.get("far_mist").visible)
	assert(not atmosphere.get("near_mist").visible)
	var shadow: Node2D = SHADOW.new()
	player.add_child(shadow)
	assert(shadow.get("width")==23.0)
	room.free()
	assert(not is_instance_valid(atmosphere))
	player.free()
	print("v2.78 atmosphere pool, shader resources, quality presets and room lifetime PASS")
	quit(0)

func _enabled_count(atmosphere: Node) -> int:
	var count: int = 0
	for light in atmosphere.get("lights"):
		if light.enabled:
			count+=1
	return count
