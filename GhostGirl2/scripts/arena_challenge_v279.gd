@tool
extends Node2D
const BOSS = preload("res://scripts/arena_boss_v279.gd")
@export_enum("iron","bell","astral") var boss_id: String = "iron"
var controller: Node
var displayed_mastery: int = -1

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("interactable")
		add_to_group("arena_challenge_v279")
		controller=get_node_or_null("../../ArenaController")

func prompt_text() -> String:
	return str(controller.call("prompt",boss_id)) if is_instance_valid(controller) else ""

func interact() -> String:
	return str(controller.call("interact_boss",boss_id,Input.is_physical_key_pressed(KEY_SHIFT))) if is_instance_valid(controller) else ""

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not is_instance_valid(controller):
		return
	var level: int = int(controller.call("mastery",boss_id))
	if level!=displayed_mastery:
		displayed_mastery=level
		queue_redraw()

func _draw() -> void:
	var ink: Color = BOSS.DATA[boss_id]["color"]
	_draw_contact_shadow()
	draw_colored_polygon(PackedVector2Array([Vector2(-42,10),Vector2(-31,-39),Vector2(0,-62),Vector2(31,-39),Vector2(42,10)]),Color("37303c"))
	draw_polyline(PackedVector2Array([Vector2(-42,10),Vector2(-31,-39),Vector2(0,-62),Vector2(31,-39),Vector2(42,10),Vector2(-42,10)]),ink,2.0,true)
	draw_texture_rect(BOSS.ART[boss_id],Rect2(-22,-55,44,48),false,Color.WHITE)
	for i in range(maxi(0,displayed_mastery)):
		var p: Vector2 = Vector2(float(i-1)*15.0,-73.0)
		var medal: Color = Color("a99bad") if i==0 else (Color("e9bd7d") if i==1 else Color("f6e5f8"))
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-6),p+Vector2(5,0),p+Vector2(0,6),p+Vector2(-5,0)]),medal)
	var font: Font = ThemeDB.fallback_font
	var text: String = str(BOSS.DATA[boss_id]["title"])
	draw_string(font,Vector2(-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x*0.5,31),text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,ink)

func _draw_contact_shadow() -> void:
	draw_set_transform(Vector2(0,7),0.0,Vector2(1.0,0.28))
	draw_circle(Vector2.ZERO,49.0,Color(0.04,0.03,0.06,0.45))
	draw_set_transform(Vector2.ZERO)
