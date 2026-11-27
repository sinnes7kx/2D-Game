@tool
extends Node2D
const BOSS = preload("res://scripts/arena_boss_v279.gd")
@export_enum("iron","bell","astral") var boss_id: String = "iron"
var controller: Node

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("interactable")
		add_to_group("arena_challenge_v279")
		controller=get_node_or_null("../../ArenaController")

func prompt_text() -> String:
	return str(controller.call("prompt",boss_id)) if is_instance_valid(controller) else ""

func interact() -> String:
	return str(controller.call("interact_boss",boss_id)) if is_instance_valid(controller) else ""

func _draw() -> void:
	var ink: Color = BOSS.DATA[boss_id]["color"]
	_draw_contact_shadow()
	draw_colored_polygon(PackedVector2Array([Vector2(-42,10),Vector2(-31,-39),Vector2(0,-62),Vector2(31,-39),Vector2(42,10)]),Color("37303c"))
	draw_polyline(PackedVector2Array([Vector2(-42,10),Vector2(-31,-39),Vector2(0,-62),Vector2(31,-39),Vector2(42,10),Vector2(-42,10)]),ink,2.0,true)
	draw_texture_rect(BOSS.ART[boss_id],Rect2(-22,-55,44,48),false,Color.WHITE)
	var font: Font = ThemeDB.fallback_font
	var text: String = str(BOSS.DATA[boss_id]["title"])
	draw_string(font,Vector2(-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x*0.5,31),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)

func _draw_contact_shadow() -> void:
	draw_set_transform(Vector2(0,7),0.0,Vector2(1.0,0.28))
	draw_circle(Vector2.ZERO,49.0,Color(0.04,0.03,0.06,0.45))
	draw_set_transform(Vector2.ZERO)
