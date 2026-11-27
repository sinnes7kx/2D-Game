extends Node2D
## Room-local ritual key. Never written to the inventory or save file.
@export var seal_name: String = "Left seal"
var awakened: bool = false

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("sepulchre_v266")

func prompt_text() -> String:
	return "SEAL AWAKENED" if awakened else "E  AWAKEN " + seal_name.to_upper()

func interact() -> String:
	if awakened:
		return ""
	var altar: Node = get_node_or_null("../SepulchreAltar")
	if altar == null or not bool(altar.call("can_awaken_seal")):
		return ""
	awakened = true
	altar.call("on_seal_awakened")
	queue_redraw()
	return seal_name.to_upper() + " · AWAKENED"

func _draw() -> void:
	var ink: Color = Color("e4b780") if awakened else Color("75677e")
	draw_circle(Vector2.ZERO, 34.0, Color("211b29"))
	draw_arc(Vector2.ZERO, 31.0, 0.0, TAU, 48, ink, 2.0, true)
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, ink.darkened(0.35), 1.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-19),Vector2(12,0),Vector2(0,19),Vector2(-12,0)]),ink.darkened(0.52))
	draw_line(Vector2(0,-16),Vector2(0,16),ink,1.8,true)
	draw_line(Vector2(-10,0),Vector2(10,0),ink,1.8,true)
	if awakened:
		draw_circle(Vector2.ZERO, 5.0, Color("f7dbad"))
