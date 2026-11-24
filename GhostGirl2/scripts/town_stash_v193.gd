@tool
extends Node2D
## A physical access point to the existing inventory vault. No items stored here.
@export var interaction_name: String = "Open town stash"
func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("interactable")
		add_to_group("town_stash")

func _draw() -> void:
	draw_ellipse_shadow()
	draw_rect(Rect2(-42,-39,84,52),Color("48363b"))
	draw_colored_polygon(PackedVector2Array([Vector2(-42,-39),Vector2(-35,-61),Vector2(35,-61),Vector2(42,-39)]),Color("826352"))
	draw_rect(Rect2(-42,-39,84,52),Color("af9777"),false,2.0)
	for x in [-28.0,28.0]:
		draw_rect(Rect2(x-3,-58,6,70),Color("b99b71"))
	draw_rect(Rect2(-6,-36,12,17),Color("d5b789"))
	draw_circle(Vector2(0,-29),2.0,Color("30242d"))
	draw_string(ThemeDB.fallback_font,Vector2(-45,35),"STASH",HORIZONTAL_ALIGNMENT_CENTER,90,14,Color("e5cfad"))

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0,12),0.0,Vector2(1.0,0.42))
	draw_circle(Vector2.ZERO,55,Color(0.04,0.03,0.06,0.55))
	draw_set_transform(Vector2.ZERO)
