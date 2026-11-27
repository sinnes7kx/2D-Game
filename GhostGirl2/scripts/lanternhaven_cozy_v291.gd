extends Node2D
## Warm reflected light and a localized fireplace sound. No gameplay collision,
## global audio changes, screen copies or new PointLight2D allocations.
const SETTINGS = preload("res://scripts/atmosphere_settings_v278.gd")
const TEXTURES = preload("res://scripts/atmosphere_textures_v278.gd")
const PERF = preload("res://scripts/performance_profiles_v230.gd")
const RATE: int = 16000
const DURATION: int = 8
static var cached_fire: AudioStreamWAV
var ambience: Node2D
var hearth: Node2D
var fire: AudioStreamPlayer2D
var shade: CanvasModulate
var bench_shadows: Array[Sprite2D] = []
var clock: float = 0.0
var pending: float = 0.0
var revision: int = -1

static func ambient_color(strength: float) -> Color:
	return Color.WHITE.lerp(Color("b9aabe"),clampf(strength,0.0,1.0)*0.66)

static func fire_stream() -> AudioStreamWAV:
	if cached_fire!=null:
		return cached_fire
	var count: int = RATE*DURATION
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(count*2)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed=291242
	var low: float = 0.0
	var pop: float = 0.0
	for i in range(count):
		var n: float = rng.randf_range(-1.0,1.0)
		low=lerpf(low,n,0.034)
		if rng.randf()<0.0007:
			pop=rng.randf_range(0.055,0.16)
		pop*=0.986
		var edge: float = minf(1.0,float(i)/640.0)*minf(1.0,float(count-1-i)/640.0)
		var t: float = float(i)/float(RATE)
		var sample: float = (low*0.32+n*0.014+pop*n)*(0.76+0.24*sin(TAU*t/4.0))*edge
		pcm.encode_s16(i*2,roundi(clampf(sample,-1.0,1.0)*32767.0))
	cached_fire=AudioStreamWAV.new()
	cached_fire.format=AudioStreamWAV.FORMAT_16_BITS
	cached_fire.mix_rate=RATE
	cached_fire.data=pcm
	cached_fire.loop_mode=AudioStreamWAV.LOOP_FORWARD
	cached_fire.loop_begin=0
	cached_fire.loop_end=count
	return cached_fire

func _ready() -> void:
	z_as_relative=false
	z_index=-44
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material=mat
	# CanvasModulate is shared within a canvas. Never compete with a scene
	# that already supplies one; this node owns only its own modulator.
	var canvas: RID = get_canvas()
	var existing: bool = false
	for node in get_tree().root.find_children("*","CanvasModulate",true,false):
		var other: CanvasModulate = node as CanvasModulate
		if other!=null and other.get_canvas()==canvas and other.is_visible_in_tree():
			existing=true
			break
	if not existing:
		shade=CanvasModulate.new()
		shade.name="TownDusk"
		add_child(shade)
	for entry in ambience.get("anchors"):
		var source: Node2D = entry["source"]
		if is_instance_valid(source) and source.name=="GatheringHearth":
			hearth=source
			break
	if is_instance_valid(hearth):
		fire=AudioStreamPlayer2D.new()
		fire.name="HearthCrackle"
		fire.volume_db=-17.0
		fire.max_distance=680.0
		fire.attenuation=1.65
		add_child(fire)
		fire.global_position=hearth.global_position
	var room: Node2D = ambience.get("room_root") as Node2D
	if room!=null:
		for bench_name in ["HearthBenchWest","HearthBenchEast"]:
			var bench: Node2D = room.get_node_or_null("Gameplay/"+bench_name) as Node2D
			if bench==null:
				continue
			var shadow: Sprite2D = Sprite2D.new()
			shadow.texture=TEXTURES.shadow()
			shadow.z_as_relative=false
			shadow.z_index=-43
			var shadow_mat: CanvasItemMaterial = CanvasItemMaterial.new()
			shadow_mat.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
			shadow.material=shadow_mat
			shadow.scale=Vector2(2.9,0.92)
			add_child(shadow)
			shadow.global_position=bench.global_position+Vector2(0,10)
			bench_shadows.append(shadow)
	_refresh()

func _refresh() -> void:
	revision=SETTINGS.revision
	var strength: float = SETTINGS.strength()
	for shadow in bench_shadows:
		shadow.visible=strength>0.0
		shadow.modulate=Color(0.13,0.08,0.12,0.30*strength)
	if is_instance_valid(shade):
		shade.color=ambient_color(strength)
		shade.visible=strength>0.0
	if is_instance_valid(fire):
		if strength>0.0:
			if fire.stream==null:
				fire.stream=fire_stream()
			fire.volume_db=-17.0+linear_to_db(strength)
			if not fire.playing:
				fire.play()
		elif fire.playing:
			fire.stop()
	queue_redraw()

func _process(delta: float) -> void:
	clock+=delta
	pending+=delta
	if revision!=SETTINGS.revision:
		_refresh()
	if PERF.due(pending,PERF.ambient_hz()):
		pending=PERF.remainder(pending,PERF.ambient_hz())
		queue_redraw()

func _draw() -> void:
	var strength: float = SETTINGS.strength()
	if strength<=0.0 or not is_instance_valid(ambience):
		return
	# Broad, flat warm pools on the ground, below furniture/characters.
	for lamp in ambience.get("lights"):
		if not is_instance_valid(lamp) or not lamp.enabled:
			continue
		var at: Vector2 = to_local(lamp.global_position)+Vector2(0,38)
		var size: Vector2 = Vector2(260,112)*clampf(lamp.texture_scale/3.0,0.65,1.6)
		var ink: Color = lamp.color.lerp(Color("e5a56e"),0.25)
		draw_texture_rect(TEXTURES.shadow(),Rect2(at-size*0.5,size),false,Color(ink.r,ink.g,ink.b,0.11*strength))
	if is_instance_valid(hearth):
		var at: Vector2 = to_local(hearth.global_position)+Vector2(0,30)
		var breath: float = 0.92+0.06*sin(clock*2.7)+0.02*sin(clock*6.0)
		draw_texture_rect(TEXTURES.shadow(),Rect2(at-Vector2(285,145),Vector2(570,290)),false,Color(1.0,0.53,0.26,0.18*strength*breath))
