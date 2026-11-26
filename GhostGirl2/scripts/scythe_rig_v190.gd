extends Node2D
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
		# The separate scythe aura must not linger when switching weapons.
		if is_instance_valid(scythe_glow):
			scythe_glow.call("clear_pose")
	if not visible:
		return
	var next: String = SURFACE.key(item) + ":%d:%d:%d:%d" % [item.debug_color_mode, item.debug_glow_motif, item.debug_forge_guard, item.debug_forge_grip]
	if next != key:
		key = next
		look = item.collector_appearance()
		profile = ART.weapon_profile(look, item.definition.item_id)
		ashglass = str(item.definition.item_id) == "ashglass_warmaul_v170"
		profile["heavy_head_span"] = float(look.get("heavy_head_span", 1.0))
		profile["heavy_head_flare"] = float(look.get("heavy_head_flare", 1.0))
		profile["scythe_span"] = float(look.get("scythe_span", 1.0))
		profile["scythe_curve"] = float(look.get("scythe_curve", 0.7))
		colors = item.glow_gradient_colors()
	self_modulate.a = item.weapon_opacity()
	show_behind_parent = str(body.animation).ends_with("_back")
	z_index = -2 if show_behind_parent else 5
	queue_redraw()

func _draw() -> void:
	if not visible or body == null or profile.is_empty():
		return
	var name_now: String = str(body.animation)
	var idle: bool = GENTLE.modular_idle(name_now)
	var index: int = 0 if idle else body.frame
	var points: PackedVector2Array = SCYTHE.span(name_now, index, guides) if style == "scythe" else HEAVY.span(name_now, index, guides)
	if idle:
		points = GENTLE.smooth(body, name_now, points)
	if points.size() == 2:
		var side: float = -1.0 if name_now.ends_with("_left") else 1.0
		if style == "scythe":
			SCYTHE.draw_scythe(self, points[0], points[1], profile, look, colors, phase, side, true)
			if is_instance_valid(scythe_glow):
				var world: Node = player.get("world") as Node
				var inv: Node = world.get("inventory") as Node if world != null else null
				scythe_glow.call("set_pose", inv.get_equipped("sword") if inv != null else null, points[0], points[1], profile, side)
		else:
			HEAVY.draw_heavy(self, points[0], points[1], profile, look, colors, phase, style, ashglass, side, true, active_item_id)
