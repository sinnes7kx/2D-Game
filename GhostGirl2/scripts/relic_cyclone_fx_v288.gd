extends Node2D
const PERF = preload("res://scripts/performance_profiles_v230.gd")
const MECHANICS = preload("res://scripts/relic_mechanics_v288.gd")
var echoes: Array[Sprite2D] = []
var sample_clock: float = 0.0
var sample_index: int = 0
var history: Array[Dictionary] = []
var actor: CharacterBody2D
var mode: String = "spin"
var ink: Color = Color("e1bedf")
func _ready() -> void:
	z_index=16
	for i in range(4):
		var echo: Sprite2D = Sprite2D.new()
		echo.z_as_relative=false
		echo.z_index=-1
		echo.visible=false
		add_child(echo)
		echoes.append(echo)
func _process(delta: float) -> void:
	if not is_instance_valid(actor) or str(actor.get("relic_channel_v288"))!=mode:
		queue_free()
		return
	var body: AnimatedSprite2D = actor.get("body_art") as AnimatedSprite2D
	if body!=null and body.sprite_frames!=null and body.sprite_frames.has_animation(body.animation):
		sample_clock+=delta
		if sample_clock>=0.045 or history.is_empty():
			sample_clock=0.0
			var tex: Texture2D = body.sprite_frames.get_frame_texture(body.animation,body.frame)
			if tex!=null:
				history.push_front({"texture":tex,"at":body.global_position,"scale":body.global_scale,"offset":body.offset,"centered":body.centered,"flip":body.flip_h})
				if history.size()>4:
					history.pop_back()
		var budget: int = 2 if PERF.profile==PERF.Profile.LOW else (4 if PERF.profile==PERF.Profile.HIGH else 3)
		var a: float = float(actor.get("relic_spin_angle_v288"))
		var age: float = float(actor.get("relic_channel_age_v288"))
		var strength: float = lerpf(0.55,1.0,clampf(age/0.85,0.0,1.0))
		for i in range(echoes.size()):
			var echo: Sprite2D = echoes[i]
			echo.visible=i<budget and i<history.size()
			if not echo.visible:
				continue
			var frame: Dictionary = history[i]
			echo.texture=frame["texture"]
			echo.offset=frame["offset"]
			echo.centered=frame["centered"]
			echo.flip_h=frame["flip"]
			echo.global_position=frame["at"]+Vector2(cos(a-float(i)*0.85)*float(7+i*3),sin(a-float(i)*0.85)*3.0)
			echo.global_scale=Vector2(frame["scale"])*Vector2(1.09+0.035*float(i),0.99)
			echo.material=body.material
			echo.modulate=Color(1.0,0.88,0.97,0.23*strength*(1.0-float(i)*0.18))
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(actor):
		return
	var angle: float = float(actor.get("relic_spin_angle_v288"))
	var age: float = float(actor.get("relic_channel_age_v288"))
	if mode=="hybrid":
		for i in range(2):
			var a: float = angle+PI*float(i)
			draw_arc(Vector2(0,-26),91.0,a-1.10,a,28,Color(ink.r,ink.g,ink.b,0.22),9.0,true)
			draw_arc(Vector2(0,-26),91.0,a-0.80,a,22,Color(ink.r,ink.g,ink.b,0.87),2.1,true)
	var build: float = MECHANICS.bloom_v290(age) if mode=="hybrid" else clampf(age/0.85,0.0,1.0)
	if build<=0.0:
		return
	var size_factor: float = (MECHANICS.hybrid_radius_v290(age)/145.0) if mode=="hybrid" else 1.0
	for layer in range(5):
		var h: float = float(layer)/4.0
		var radius: float = lerpf(47.0,145.0,1.0-h*0.56)*lerpf(0.65,1.0,build)*size_factor
		var center: Vector2 = Vector2(0,-12.0-h*91.0)
		for strand in range(2):
			var phase: float = angle*(0.78+h*0.40)+h*2.7+PI*float(strand)
			var points: PackedVector2Array = PackedVector2Array()
			for i in range(30):
				var t: float = float(i)/29.0
				var a: float = phase-t*2.5
				points.append(center+Vector2(cos(a)*radius,sin(a)*radius*0.36+t*14.0))
			draw_polyline(points,Color(ink.r,ink.g,ink.b,(0.14+build*0.12)*build),8.0-3.0*h,true)
			draw_polyline(points,Color(ink.r,ink.g,ink.b,(0.55+build*0.23)*build),1.7,true)
