@tool
extends Node2D
## Editor-owned treasure cache. Each chest can drop a reproducible roll once.
@export var interaction_name: String = "Open the forgotten coffer"
@export var chest_id: String = ""
@export var loot_data: GhostItemData
@export var loot_seed: int = 101
@export_enum("random", "normal", "magic", "rare", "set", "unique") var guaranteed_quality: String = "random"
@export var opened: bool = false
var elapsed: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("interactable")
		add_to_group("treasure_chest")

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var base: Color = Color("4a344f")
	var gold: Color = Color("bd9b80") if not opened else Color("9b8196")
	draw_circle(Vector2(0, -8), 39.0 + sin(elapsed * 2.0) * 2.0, Color(0.77, 0.58, 0.92, 0.045 if opened else 0.16))
	draw_rect(Rect2(-29, -21, 58, 41), base, true)
	draw_rect(Rect2(-29, -21, 58, 41), gold, false, 3)
	draw_line(Vector2(-29, -5), Vector2(29, -5), gold, 3)
	draw_line(Vector2(-9, -21), Vector2(-9, 20), gold, 2)
	draw_line(Vector2(9, -21), Vector2(9, 20), gold, 2)
	if opened:
		draw_line(Vector2(-28, -20), Vector2(29, -38), gold, 5)
	else:
		draw_circle(Vector2.ZERO, 4.0, Color("e6c0a4"))
