extends Node2D
## Room-owned presentation. Existing editable lamp/shrine markers are the
## only sources. The nearest bounded pool lights actual world CanvasItems.
const SETTINGS = preload("res://scripts/atmosphere_settings_v278.gd")
const TEXTURES = preload("res://scripts/atmosphere_textures_v278.gd")
const PERF = preload("res://scripts/performance_profiles_v230.gd")
const MIST = preload("res://assets/effects/world_mist_v278.gdshader")
const MAX_LIGHTS: int = 8
const WET_ROOMS: Array[String] = ["hollow_veil_moor","weeping_brook","lily_pond","briar_hollow","moonthorn_woods"]
const WARM_ROOMS: Array[String] = ["lanternhaven","candle_reliquary","blackbrick_court","ashglass_vault","ashen_causeway","bellwether_court"]
var room_key: String = ""
var room_root: Node2D
var actor: Node2D
var anchors: Array[Dictionary] = []
var lights: Array[PointLight2D] = []
var far_mist: ColorRect
var near_mist: ColorRect
var clock: float = 0.0
var pending: float = 0.0
var revision: int = -1
var perf_revision: int = -1
var initialized: bool = false

static func profile(key: String) -> Dictionary:
	if key in WET_ROOMS:
		return {"ink":Color("85899f"),"far":0.115,"near":0.062,"drift":8.0}
	if key in WARM_ROOMS:
		return {"ink":Color("a68b8d"),"far":0.066,"near":0.029,"drift":3.0}
	return {"ink":Color("85809c"),"far":0.085,"near":0.036,"drift":4.5}

func setup(root: Node2D, player: Node2D, key: String) -> void:
	room_root=root
	actor=player
	room_key=key

func _ready() -> void:
	if not is_instance_valid(room_root):
		set_process(false)
		return
	SETTINGS.ensure_loaded()
	_collect_anchors()
	var bounds: Rect2 = _room_bounds()
	far_mist=_make_mist(bounds,-43,0.0,0.84)
	near_mist=_make_mist(bounds,38,4.0,0.56)
	for i in range(MAX_LIGHTS):
		var lamp: PointLight2D = PointLight2D.new()
		lamp.name="NearbyLight%02d"%i
		lamp.texture=TEXTURES.light()
		lamp.blend_mode=Light2D.BLEND_MODE_ADD
		lamp.shadow_enabled=false
		lamp.range_z_min=-50
		lamp.range_z_max=35
		lamp.range_layer_min=0
		lamp.range_layer_max=0
		lamp.enabled=false
		add_child(lamp)
		lights.append(lamp)
	initialized=true
	_refresh()

func _room_bounds() -> Rect2:
	var painted: Sprite2D = room_root.get_node_or_null("PaintedRoom") as Sprite2D
	var bounds: Rect2 = Rect2(Vector2.ZERO,Vector2(2389,1792))
	if painted!=null and painted.texture!=null:
		var r: Rect2 = painted.get_rect()
		bounds=Rect2(to_local(painted.to_global(r.position)),r.size*painted.global_scale.abs())
	var wing: Node = room_root.get_node_or_null("ArmoryWingV172")
	if wing!=null:
		bounds.size.x=maxf(bounds.size.x,float(wing.get("room_right_edge"))-bounds.position.x)
	return bounds

func _make_mist(bounds: Rect2, depth: int, phase: float, spatial: float) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rect.z_as_relative=false
	rect.z_index=depth
	rect.position=bounds.position
	rect.size=bounds.size
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader=MIST
	mat.set_shader_parameter("layer_phase",phase)
	mat.set_shader_parameter("spatial_scale",spatial)
	rect.material=mat
	add_child(rect)
	return rect

func _collect_anchors() -> void:
	anchors.clear()
	for node in room_root.find_children("*","Node2D",true,false):
		var source: Node2D = node as Node2D
		var script: Script = source.get_script() as Script
		if script==null:
			continue
		var path: String = script.resource_path.get_file()
		var offset: Vector2 = Vector2.ZERO
		var tint: Color = Color("ffc589")
		var diameter: float = 320.0
		var energy: float = 0.35
		match path:
			"hearth_light_v242.gd":
				var hearth: bool = str(source.get("kind"))=="hearth"
				offset=Vector2(0,-32) if hearth else Vector2.ZERO
				diameter=610.0 if hearth else 350.0
				energy=0.46 if hearth else 0.36
			"moor_lantern.gd":
				offset=Vector2(19,-47)
				tint=source.get("lamp_color")
				diameter=310.0
				energy=0.38*float(source.get("glow_strength"))
			"lantern_shrine.gd":
				offset=Vector2(0,-33)
				diameter=290.0
				energy=0.34
			_:
				continue # Existing flame PointLight2D nodes are not duplicated.
		anchors.append({"source":source,"offset":offset,"color":tint,"diameter":diameter,"energy":energy,"phase":float(anchors.size())*1.713})

func _process(delta: float) -> void:
	if not initialized:
		return
	clock+=delta
	pending+=delta
	var hz: float = PERF.ambient_hz()
	if revision!=SETTINGS.revision or perf_revision!=PERF.revision or PERF.due(pending,hz):
		pending=PERF.remainder(pending,hz)
		_refresh()

func _refresh() -> void:
	revision=SETTINGS.revision
	perf_revision=PERF.revision
	var strength: float = SETTINGS.strength()
	var p: Dictionary = profile(room_key)
	far_mist.visible=strength>0.0
	near_mist.visible=SETTINGS.foreground_fog()
	for rect in [far_mist,near_mist]:
		var mat: ShaderMaterial = rect.material as ShaderMaterial
		mat.set_shader_parameter("fog_ink",p["ink"])
		mat.set_shader_parameter("density",float(p["far"] if rect==far_mist else p["near"])*strength)
		mat.set_shader_parameter("drift",float(p["drift"])*(1.0 if rect==far_mist else 1.65))
	var budget: int = SETTINGS.light_budget()
	var candidates: Array[Dictionary] = []
	if budget>0 and is_instance_valid(actor):
		var camera: Camera2D = actor.get_node_or_null("Camera2D") as Camera2D
		var focus: Vector2 = camera.get_screen_center_position() if camera!=null else actor.global_position
		var half: Vector2 = get_viewport_rect().size*0.5
		if camera!=null:
			half/=camera.zoom
		for anchor in anchors:
			var source: Node2D = anchor["source"]
			if not is_instance_valid(source) or not source.is_visible_in_tree():
				continue
			var at: Vector2 = source.to_global(anchor["offset"])
			var radius: float = float(anchor["diameter"])*0.5
			var relative: Vector2 = (at-focus).abs()
			if relative.x>half.x+radius or relative.y>half.y+radius:
				continue
			var entry: Dictionary = anchor.duplicate()
			entry["at"]=at
			entry["distance"]=at.distance_squared_to(focus)
			candidates.append(entry)
	candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return float(a["distance"])<float(b["distance"]))
	for i in range(lights.size()):
		var lamp: PointLight2D = lights[i]
		var active: bool = i<budget and i<candidates.size()
		lamp.enabled=active
		if not active:
			continue
		var entry: Dictionary = candidates[i]
		var flicker: float = 0.94+0.045*sin(clock*2.7+float(entry["phase"]))+0.015*sin(clock*5.2+float(entry["phase"]))
		lamp.global_position=entry["at"]
		lamp.texture_scale=float(entry["diameter"])/128.0
		lamp.color=entry["color"]
		lamp.energy=float(entry["energy"])*strength*flicker
