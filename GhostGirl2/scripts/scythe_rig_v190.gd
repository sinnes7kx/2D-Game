extends Node2D
const RENDER = preload("res://scripts/animation/weapon_render_contract.gd")
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const HEAVY = preload("res://scripts/heavy_weapon_art_v192.gd")
const SCYTHE = preload("res://scripts/scythe_art_v190.gd")
const SCYTHE_GLOW = preload("res://scripts/scythe_glow_layer_v211.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const SURFACE = preload("res://scripts/weapon_surface_v190.gd")
var body: AnimatedSprite2D
var player: Node
var guides: Dictionary = {}
var look: Dictionary = {}
var profile: Dictionary = {}
var colors: Array[Color] = []
var key: String = ""
var style: String = ""
var active_item_id: String = ""
var ashglass: bool = false
var phase: float = 0.0
var scythe_glow: Node2D

func _ready() -> void:
	scythe_glow = SCYTHE_GLOW.new() as Node2D
	scythe_glow.name = "WorldScytheGlowV211"
	scythe_glow.z_index = 1
	add_child(scythe_glow)
	body = get_parent() as AnimatedSprite2D
	player = body.get_parent()
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/long_weapon_glow_axes_v143.json"))
	if raw is Dictionary:
		guides = raw
	var maul_guides: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/new_weapon_axes_v170.json"))
	if maul_guides is Dictionary:
		guides.merge(maul_guides, false)

func _process(delta: float) -> void:
	phase += delta
	var world: Node = player.get("world") as Node
	var inventory: Node = world.get("inventory") as Node if world != null else null
	var item: GhostItemInstance = inventory.get_equipped("sword") if inventory != null else null
	style = item.weapon_style() if item != null else ""
	active_item_id = str(item.definition.item_id) if item != null and item.definition != null else ""
	visible = item != null and ((style == "scythe" and SCYTHE.matches(str(body.animation))) or (style in ["halberd", "maul"] and HEAVY.matches(str(body.animation))))
	if not visible or style != "scythe":
		if is_instance_valid(scythe_glow):
			scythe_glow.call("clear_pose")
	if not visible:
		return
	var next: String = SURFACE.key(item) + ":%d:%d:%d:%d" % [item.debug_color_mode, item.debug_glow_motif, item.debug_forge_guard, item.debug_forge_grip]
	if next != key:
		key = next
		look = item.collector_appearance()
		profile = RENDER.heavy_profile(ART.weapon_profile(look, item.definition.item_id),look)
		ashglass = str(item.definition.item_id) == "ashglass_warmaul_v170"
		colors = item.glow_gradient_colors()
	self_modulate.a = item.weapon_opacity()
	var diagonal_face: String = preload("res://scripts/ghost_diagonal_art_v247.gd").diagonal_name(str(body.animation))
	show_behind_parent = str(body.animation).ends_with("_back") or diagonal_face.begins_with("back")
	z_index = -2 if show_behind_parent else 5
	queue_redraw()

func _draw() -> void:
	if not visible or body == null or profile.is_empty():
		return
	var name_now: String = str(body.animation)
	var idle: bool = GENTLE.modular_idle(name_now)
	var diagonal: bool = not preload("res://scripts/ghost_diagonal_art_v247.gd").diagonal_name(name_now).is_empty()
	var index: int = 0 if idle and not diagonal else body.frame
	var points: PackedVector2Array = SCYTHE.span(name_now, index, guides) if style == "scythe" else HEAVY.span(name_now, index, guides)
	if idle:
		points = GENTLE.smooth(body, name_now, points)
	if points.size() == 2:
		var side: float = -1.0 if name_now.ends_with("_left") else 1.0
		var world: Node = player.get("world") as Node
		var inv: Node = world.get("inventory") as Node if world != null else null
		var equipped: GhostItemInstance = inv.get_equipped("sword") if inv != null else null
		var glow_scale: float = RENDER.effect_scale(equipped)
		var show_light: bool = glow_scale>0.0
		if style == "scythe":
			SCYTHE.draw_scythe(self, points[0], points[1], profile, look, colors, phase, side, show_light,glow_scale)
			if is_instance_valid(scythe_glow):
				scythe_glow.call("set_pose", equipped, points[0], points[1], profile, side)
		else:
			HEAVY.draw_heavy(self, points[0], points[1], profile, look, colors, phase, style, ashglass, side, show_light, active_item_id,glow_scale)
