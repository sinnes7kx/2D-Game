@tool
extends Node2D
## v1.42: compact, repeatable archery testing for charged/airborne arrows.
## Uses the existing ONE physical swept arrow; never grants loot or deals damage.
## No persistent flags: each shot can be tested again with different bow seeds.
@export var interaction_name: String = "Fletcher's practice vane"
@export_range(18.0, 85.0, 1.0) var trigger_radius: float = 45.0
@export var require_full_draw: bool = false
@export var require_airborne: bool = false
var flash_left: float = 0.0
var last_ink: Color = Color("dfc0d9")
var test_hits: int = 0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("v139_elemental_world")
	queue_redraw()

func on_elemental_arrow_hit(element: int, formation: int, charged: bool, airborne: bool) -> bool:
	if Engine.is_editor_hint():
		return false
	if (require_full_draw and not charged) or (require_airborne and not airborne):
		_announce("HOLD RIGHT-CLICK TO DRAW, JUMP WITH C, THEN RELEASE")
		return false
	test_hits += 1
	flash_left = 0.85
	match element:
		1: last_ink = Color("e6a183")
		2: last_ink = Color("a4d9ee")
		3: last_ink = Color("f4dfa9")
		_: last_ink = Color("d8bdde")
	var name: String = str(["SILVER", "EMBERFIRE", "FROSTGLASS", "LUMINOUS"][clampi(element, 0, 3)])
	var extras: String = (" / TRIUNE" if formation == 1 else "") + (" / CHARGED" if charged else "") + (" / AIRBORNE" if airborne else "")
	_announce(name + extras + " — TARGET STRUCK")
	queue_redraw()
	return true

func _announce(message: String) -> void:
	var root: Node = get_tree().current_scene
	if root != null and root.has_node("HUD"):
		root.get_node("HUD").call("show_pickup", message, last_ink)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	if flash_left > 0.0:
		flash_left = maxf(0.0, flash_left - delta)
		queue_redraw()

func _draw() -> void:
	var stone: Color = Color("695c70")
	var silver: Color = Color("c6b5c9")
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(0, -34), Vector2(18, -17), Vector2(18, 20),
		Vector2(0, 37), Vector2(-18, 20), Vector2(-18, -17)
	])
	draw_colored_polygon(points, Color(stone.r, stone.g, stone.b, 0.66))
	draw_polyline(PackedVector2Array([
		Vector2(0, -34), Vector2(18, -17), Vector2(18, 20),
		Vector2(0, 37), Vector2(-18, 20), Vector2(-18, -17), Vector2(0, -34)
	]), Color(silver.r, silver.g, silver.b, 0.48), 1.5, true)
	draw_line(Vector2(0, -25), Vector2(0, 24), Color("9d8d9f"), 2.0, true)
	draw_line(Vector2(-9, 0), Vector2(9, 0), Color("b5a0b1"), 1.2, true)
	if require_airborne:
		draw_line(Vector2(-8, 14), Vector2(0, 4), Color("b6aadd"), 1.5, true)
		draw_line(Vector2(0, 4), Vector2(8, 14), Color("b6aadd"), 1.5, true)
	if flash_left > 0.0:
		var c: Color = last_ink
		draw_line(Vector2(0, -29), Vector2(0, 30), Color(c.r, c.g, c.b, flash_left * 0.68), 2.4, true)
		draw_line(Vector2(-10, -4), Vector2(10, 4), Color(c.r, c.g, c.b, flash_left * 0.48), 1.4, true)
