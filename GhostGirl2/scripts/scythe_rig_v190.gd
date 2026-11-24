extends Node2D
const SCYTHE = preload("res://scripts/scythe_art_v190.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const SURFACE = preload("res://scripts/weapon_surface_v190.gd")
var body: AnimatedSprite2D
var player: Node
var guides: Dictionary = {}
var look: Dictionary = {}
var profile: Dictionary = {}
var colors: Array[Color] = []
var key: String = ""
var phase: float = 0.0

func _ready() -> void:
	body = get_parent() as AnimatedSprite2D
	player = body.get_parent()
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/long_weapon_glow_axes_v143.json"))
	if raw is Dictionary:
		guides = raw

func _process(delta: float) -> void:
	phase += delta
	var world: Node = player.get("world") as Node
	var inventory: Node = world.get("inventory") as Node if world != null else null
	var item: GhostItemInstance = inventory.get_equipped("sword") if inventory != null else null
	visible = item != null and item.weapon_style() == "scythe" and SCYTHE.matches(str(body.animation))
	if not visible:
		return
	var next: String = SURFACE.key(item) + ":%d:%d:%d:%d" % [item.debug_color_mode, item.debug_glow_motif, item.debug_forge_guard, item.debug_forge_grip]
	if next != key:
		key = next
		look = item.collector_appearance()
		profile = ART.weapon_profile(look, item.definition.item_id)
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
	var points: PackedVector2Array = SCYTHE.span(name_now, body.frame, guides)
	if points.size() == 2:
		SCYTHE.draw_scythe(self, points[0], points[1], profile, look, colors, phase, -1.0 if name_now.ends_with("_left") else 1.0, true)
