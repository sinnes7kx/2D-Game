extends Node2D
## Local, editable garden lighting landmarks. No new screen pass or physics.
const SETTINGS = preload("res://scripts/atmosphere_settings_v278.gd")
const PERF = preload("res://scripts/performance_profiles_v230.gd")
const SOFT = preload("res://scripts/atmosphere_textures_v278.gd")
var landmarks: Node2D
var actor: Node2D
var room_key: String = ""
var clock: float = 0.0
var pending: float = 0.0
var revision: int = -1
var perf_revision: int = -1

static func particle_budget() -> int:
	if SETTINGS.strength()<=0.0:
		return 0
	match PERF.profile:
		PERF.Profile.HIGH: return 36
		PERF.Profile.LOW: return 10
		_: return 22

func _ready() -> void:
	z_as_relative=false
	z_index=2
	var mat: CanvasItemMaterial = CanvasItemMaterial.new()
	mat.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material=mat
	queue_redraw()

func _process(delta: float) -> void:
	clock+=delta
	pending+=delta
	if revision!=SETTINGS.revision or perf_revision!=PERF.revision or PERF.due(pending,PERF.ambient_hz()):
		revision=SETTINGS.revision
		perf_revision=PERF.revision
		pending=PERF.remainder(pending,PERF.ambient_hz())
		queue_redraw()

func _visible_at(point: Vector2) -> bool:
	if not is_instance_valid(actor):
		return false
	var camera: Camera2D = actor.get_node_or_null("Camera2D") as Camera2D
	var focus: Vector2 = camera.get_screen_center_position() if camera!=null else actor.global_position
	var half: Vector2 = get_viewport_rect().size*0.5
	if camera!=null:
		half/=camera.zoom
	var d: Vector2 = (point-focus).abs()
	return d.x<half.x+340.0 and d.y<half.y+340.0

func _draw() -> void:
	var budget: int = particle_budget()
	if budget==0 or not is_instance_valid(landmarks):
		return
	var strength: float = SETTINGS.strength()
	var flowers: Array[Vector2] = []
	for child in landmarks.get_children():
		var marker: Marker2D = child as Marker2D
		if marker==null or not _visible_at(marker.global_position):
			continue
		var point: Vector2 = to_local(marker.global_position)
		var label: String = str(marker.name)
		if label.begins_with("MoonPool"):
			var size: Vector2 = Vector2(320,210) if room_key=="glasshouse" else Vector2(260,175)
			draw_texture_rect(SOFT.shadow(),Rect2(point-size*0.5,size),false,Color(0.75,0.82,1.0,0.095*strength))
			# Narrow, overlapping falloffs suggest moonlight filtering through
			# glass or foliage without a hard-edged cone across the screen.
			for i in range(2 if PERF.profile==PERF.Profile.LOW else 4):
				var beam: Vector2 = Vector2(52.0+float(i)*12.0,250.0)
				draw_set_transform(point+Vector2(-55.0+float(i)*27.0,-105.0),-0.28)
				draw_texture_rect(SOFT.shadow(),Rect2(-beam*0.5,beam),false,Color(0.76,0.84,1.0,0.045*strength))
				draw_set_transform(Vector2.ZERO)
		elif label.begins_with("Water"):
			for i in range(3):
				var phase: float = fposmod(clock*0.21+float(i)/3.0,1.0)
				var radius: float = 12.0+phase*47.0
				draw_set_transform(point,0.0,Vector2(1.0,0.43))
				draw_arc(Vector2.ZERO,radius,0.2,TAU-0.2,40,Color(0.75,0.88,1.0,sin(phase*PI)*0.18*strength),1.2,true)
				draw_set_transform(Vector2.ZERO)
		elif label.begins_with("Bloom"):
			flowers.append(point)
	if flowers.is_empty():
		return
	for i in range(budget):
		var origin: Vector2 = flowers[i%flowers.size()]
		var t: float = float(i)*2.399963
		var cycle: float = fposmod(clock*(0.07+float(i%4)*0.013)+float(i)*0.618,1.0)
		var fade: float = sin(cycle*PI)
		var at: Vector2 = origin+Vector2(cos(t+clock*0.22)*(30.0+float(i%7)*13.0),sin(t+clock*0.31)*40.0-60.0*cycle)
		if i%4==0:
			# Small drifting petals, not a rain-like full-screen effect.
			draw_set_transform(at,clock*0.5+t)
			draw_ellipse_texture(Vector2(5.5,2.4),Color(0.91,0.69,0.80,0.38*fade*strength))
			draw_set_transform(Vector2.ZERO)
		else:
			var blink: float = 0.25+0.75*pow(maxf(0.0,sin(clock*1.1+t)),2.0)
			var alpha: float = fade*blink*strength
			draw_texture_rect(SOFT.shadow(),Rect2(at-Vector2(6,6),Vector2(12,12)),false,Color(0.94,0.83,0.49,alpha*0.30))
			draw_circle(at,1.2,Color(1.0,0.94,0.70,alpha*0.82))

func draw_ellipse_texture(size: Vector2,ink: Color) -> void:
	draw_texture_rect(SOFT.shadow(),Rect2(-size*0.5,size),false,ink)
