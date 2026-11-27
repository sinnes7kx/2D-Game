extends Node2D
## Room-owned, bounded atmospheric details. No extra screen texture copy.
const SETTINGS = preload("res://scripts/atmosphere_settings_v278.gd")
const PERF = preload("res://scripts/performance_profiles_v230.gd")
const VEIL = preload("res://assets/effects/lanternhaven_veil_v290.gdshader")
const RATE: int = 16000
const SECONDS: int = 12
static var cached_wind: AudioStreamWAV
var ambience: Node2D
var veil: ColorRect
var sound: AudioStreamPlayer
var clock: float = 0.0
var pending: float = 0.0
var old_revision: int = -1
var old_perf: int = -1

static func mote_budget() -> int:
	if SETTINGS.strength()<=0.0:
		return 0
	match PERF.profile:
		PERF.Profile.HIGH: return 48
		PERF.Profile.LOW: return 12
		_: return 30

static func wind_stream() -> AudioStreamWAV:
	if cached_wind!=null:
		return cached_wind
	var count: int = RATE*SECONDS
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count*2)
	# Integer harmonics over one loop keep the wind bed seamless.
	# Bell envelopes fade to zero well before the loop boundary.
	for i in range(count):
		var t: float = float(i)/float(RATE)
		var phase: float = TAU*t/float(SECONDS)
		var gust: float = 0.58+0.22*sin(phase*2.0)+0.12*sin(phase*5.0)
		var sample: float = (sin(phase*239.0+sin(phase*7.0))*0.028+sin(phase*383.0)*0.022+sin(phase*617.0+sin(phase*11.0))*0.013+sin(phase*1103.0)*0.007)*gust
		for strike in [3.0,6.8]:
			var elapsed: float = t-float(strike)
			if elapsed>=0.0 and elapsed<3.0:
				var envelope: float = minf(elapsed*45.0,1.0)*exp(-elapsed*2.5)*smoothstep(3.0,2.4,elapsed)
				sample+=envelope*(sin(TAU*196.0*elapsed)*0.030+sin(TAU*311.0*elapsed)*0.012+sin(TAU*489.0*elapsed)*0.005)
		bytes.encode_s16(i*2,roundi(clampf(sample,-1.0,1.0)*32767.0))
	cached_wind=AudioStreamWAV.new()
	cached_wind.format=AudioStreamWAV.FORMAT_16_BITS
	cached_wind.mix_rate=RATE
	cached_wind.data=bytes
	cached_wind.loop_mode=AudioStreamWAV.LOOP_FORWARD
	cached_wind.loop_begin=0
	cached_wind.loop_end=count
	return cached_wind

func _ready() -> void:
	z_as_relative=false
	z_index=34
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer=9
	add_child(layer)
	veil=ColorRect.new()
	veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader=VEIL
	veil.material=mat
	layer.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sound=AudioStreamPlayer.new()
	sound.bus="Master"
	sound.volume_db=-30.0
	add_child(sound)
	_refresh()

func _refresh() -> void:
	old_revision=SETTINGS.revision
	old_perf=PERF.revision
	var strength: float = SETTINGS.strength()
	veil.visible=strength>0.0
	(veil.material as ShaderMaterial).set_shader_parameter("strength",strength)
	if strength>0.0:
		if sound.stream==null:
			sound.stream=wind_stream()
		if not sound.playing:
			sound.play()
		sound.volume_db=-15.0+linear_to_db(strength)
	elif sound.playing:
		sound.stop()
	queue_redraw()

func _process(delta: float) -> void:
	clock+=delta
	pending+=delta
	if old_revision!=SETTINGS.revision or old_perf!=PERF.revision:
		_refresh()
	if PERF.due(pending,PERF.ambient_hz()):
		pending=PERF.remainder(pending,PERF.ambient_hz())
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(ambience):
		return
	var budget: int = mote_budget()
	if budget<=0:
		return
	var active: Array[PointLight2D] = []
	for lamp in ambience.get("lights"):
		if is_instance_valid(lamp) and lamp.enabled:
			active.append(lamp)
	if active.is_empty():
		return
	var strength: float = SETTINGS.strength()
	for i in range(budget):
		var lamp: PointLight2D = active[i%active.size()]
		var seed_phase: float = float(i)*2.399963
		var cycle: float = fposmod(clock*(0.075+float(i%5)*0.012)+float(i)*0.618,1.0)
		var fade: float = sin(PI*cycle)
		var radius: float = 22.0+float(i%9)*9.0
		var at: Vector2 = to_local(lamp.global_position)+Vector2(cos(seed_phase+clock*0.24)*radius,35.0-cycle*108.0+sin(clock*0.42+seed_phase)*12.0)
		var alpha: float = fade*strength*(0.18+0.07*sin(clock*1.3+seed_phase))
		var ink: Color = lamp.color.lerp(Color("ebd1b3"),0.48)
		draw_circle(at,2.5,Color(ink.r,ink.g,ink.b,alpha*0.23))
		draw_circle(at,0.85+float(i%3)*0.25,Color(ink.r,ink.g,ink.b,alpha))
