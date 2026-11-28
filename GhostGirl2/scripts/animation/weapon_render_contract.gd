extends RefCounted
## Physical attachment and rendering parameters shared by world rigs and Lens.
## A missing/occluded span is empty, never fabricated from the opposite hand.
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const LIGHT = preload("res://scripts/anomalous_steel_fx_v180.gd")
const CHOICES = preload("res://scripts/visual_choices_v216.gd")
const FX = preload("res://scripts/fx_intensity_v1924.gd")
const DIAGONAL = preload("res://scripts/ghost_diagonal_art_v247.gd")

static func equipped(body: AnimatedSprite2D) -> GhostItemInstance:
	if not is_instance_valid(body):
		return null
	var player: Node = body.get_parent()
	var world: Node = player.get("world") as Node if player!=null else null
	var inventory: Node = world.get("inventory") as Node if world!=null else null
	return inventory.get_equipped("sword") if inventory!=null else null

static func paired_layer(clip: String,hand: int) -> int:
	if not DIAGONAL.diagonal_name(clip).is_empty():
		return 6 if hand==DIAGONAL.near_hand(clip) else -2
	var back: bool = clip.ends_with("back")
	var left: bool = clip.ends_with("left")
	var right: bool = clip.ends_with("right")
	return -2 if back or (left and hand==1) or (right and hand==0) else 6

static func paired_spans(body: AnimatedSprite2D,style: String,clip: String,frame: int) -> Array:
	if not is_instance_valid(body):
		return []
	var name: String = "DualSwordsV174" if style=="dual_sword" else "DualDaggersV173"
	var rig: Node = body.get_node_or_null(name)
	return rig.call("get_blade_spans",clip,frame) if rig!=null and rig.has_method("get_blade_spans") else []

static func first_visible(spans: Array) -> PackedVector2Array:
	for span in spans:
		if span is PackedVector2Array and span.size()==2:
			return span
	return PackedVector2Array()

static func single_span(body: AnimatedSprite2D,clip: String,frame: int) -> PackedVector2Array:
	if not is_instance_valid(body):
		return PackedVector2Array()
	var rig: Node = body.get_node_or_null("WeaponPoseV172")
	return rig.call("get_weapon_span",clip,frame) if rig!=null and rig.has_method("get_weapon_span") else PackedVector2Array()

# Exact metal geometry measured from the actual physical rig. No hitbox data.
# The vector holds grip-start distance, blade-root distance, tip extension,
# grip width and blade width (named dictionary keeps these independent).
static func straight_geometry(style: String,span: PackedVector2Array,hand: int=0) -> Dictionary:
	if span.size()!=2 or span[0].distance_squared_to(span[1])<36.0:
		return {}
	var a: Vector2 = span[0]
	var b: Vector2 = span[1]
	var axis: Vector2 = (b-a).normalized()
	var start: float = -12.0
	var root: float = 10.0
	var extension: float = 0.0
	var grip_width: float = 3.0
	var width: float = 4.2
	match style:
		"dual_sword":
			start=-9.0
			root=15.0
			extension=2.0
			grip_width=5.1
			width=6.6 if hand==0 else 6.1
		"dual_dagger":
			start=-8.0
			root=12.0
			grip_width=3.5
			width=3.1
		"dagger":
			start=-5.0
			root=a.distance_to(b)*0.30
			grip_width=3.2
			width=3.2
		"forge_dagger":
			start=-7.0
			root=8.0
			grip_width=2.4
			width=2.8
		"blade":
			pass
		_:
			return {}
	return {"grip":a+axis*start,"root":a+axis*minf(root,a.distance_to(b)*0.90),"tip":b+axis*extension,"grip_width":grip_width,"width":width}

static func edge_paths(geometry: Dictionary,profile: Dictionary) -> Array[PackedVector2Array]:
	var paths: Array[PackedVector2Array] = []
	if geometry.is_empty() or profile.is_empty():
		return paths
	for side in [-1.0,1.0]:
		paths.append(ART.edge_points(geometry["root"],geometry["tip"],geometry["width"],profile,side))
	return paths

static func draw_straight(canvas: Node2D,geometry: Dictionary,profile: Dictionary,phase: float=0.0) -> void:
	if geometry.is_empty() or profile.is_empty():
		return
	ART.draw_grip(canvas,geometry["grip"],geometry["root"],geometry["grip_width"],profile)
	ART.draw_blade(canvas,geometry["root"],geometry["tip"],geometry["width"],profile,phase)

static func draw_light(canvas: Node2D,paths: Array[PackedVector2Array],colors: Array[Color],look: Dictionary,phase: float,scale: float) -> void:
	LIGHT.draw_blade_light(canvas,paths,colors,look,phase,scale)

static func effect_scale(item: GhostItemInstance,enabled: bool=true) -> float:
	return CHOICES.effect_scale(item) if item!=null and enabled else 0.0

# All renderers consume the same three independent bow lighting inputs.
static func bow_light(item: GhostItemInstance,enabled: bool=true) -> Vector3:
	var strength: float = effect_scale(item,enabled)*FX.intensity
	return Vector3(strength if CHOICES.bow_body_visible(item) else 0.0,strength if CHOICES.bow_string_visible(item) else 0.0,1.0 if enabled and CHOICES.bow_mode(item)==3 else 0.0)

static func draw_owned_light(canvas: Node2D,body: AnimatedSprite2D,geometry: Dictionary,profile: Dictionary,phase: float) -> void:
	var item: GhostItemInstance = equipped(body)
	if item==null or effect_scale(item)<=0.0 or FX.intensity<=0.0:
		return
	var key: String = "%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [item.get_instance_id(),item.cosmetic_uid,item.visual_seed(),item.gradient_version,item.origin_room,item.regional_rank,item.debug_collector_tier,item.debug_color_mode,item.debug_glow_motif,item.debug_surface_mode,item.effect_palette_channel()]
	if canvas.get_meta("shared_edge_key","")!=key:
		canvas.set_meta("shared_edge_key",key)
		canvas.set_meta("shared_edge_look",item.collector_appearance())
		canvas.set_meta("shared_edge_palette",item.glow_gradient_colors())
	var colors: Array[Color] = canvas.get_meta("shared_edge_palette",[])
	var look: Dictionary = canvas.get_meta("shared_edge_look",{})
	draw_light(canvas,edge_paths(geometry,profile),colors,look,phase,effect_scale(item))

static func preview_span(style: String,hand: int=0) -> PackedVector2Array:
	var x: float = (-17.0 if hand==0 else 17.0) if style in ["dual_sword","dual_dagger"] else 0.0
	match style:
		"dual_sword": return PackedVector2Array([Vector2(x,15),Vector2(x,-51)])
		"dual_dagger": return PackedVector2Array([Vector2(x,9),Vector2(x,-41)])
		"dagger": return PackedVector2Array([Vector2(0,5),Vector2(0,-49)])
		"forge_dagger": return PackedVector2Array([Vector2(0,14),Vector2(0,-40)])
		"blade": return PackedVector2Array([Vector2(0,10),Vector2(0,-50)])
	return PackedVector2Array()

static func owns_straight_core(body: AnimatedSprite2D,item: GhostItemInstance,clip: String) -> bool:
	if item==null or equipped(body)!=item:
		return false
	var style: String=item.weapon_style()
	if style in ["dual_sword","dual_dagger"]:
		return not first_visible(paired_spans(body,style,clip,body.frame)).is_empty()
	if style not in ["blade","dagger"]:
		return false
	var rig: Node=body.get_node_or_null("WeaponPoseV172")
	return rig!=null and rig.has_method("_is_equipped") and bool(rig.call("_is_equipped",clip)) and single_span(body,clip,body.frame).size()==2
