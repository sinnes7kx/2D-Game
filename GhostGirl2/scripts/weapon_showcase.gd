@tool
extends Node2D
## An editor-placeable weapon pedestal in the starter room. Always visually
## present, but a specific seeded item can only be claimed once per save.
@export var item_data: GhostItemData
@export var pickup_id: String = ""
@export var item_seed: int = 230001
@export var ground_display: bool = false
@export_enum("normal", "magic", "rare", "set", "unique") var guaranteed_quality: String = "rare"
var claimed: bool = false
var pulse: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("weapon_rack")
		add_to_group("interactable")

func restore_from_inventory(inventory: Node) -> void:
	if inventory == null:
		return
	claimed = inventory.has_collected(pickup_id)
	if claimed:
		remove_from_group("interactable")
	else:
		add_to_group("interactable")

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	# v1.72: armory weapons appear on the crypt floor rather than on another
	# pedestal. The previous showcase look is unchanged unless enabled.
	if ground_display:
		if claimed:
			return
		var breath: float = 0.82 + 0.18 * sin(pulse * 1.6)
		draw_circle(Vector2(0, 7), 33.0, Color(0.06, 0.04, 0.09, 0.32))
		draw_arc(Vector2(0, 7), 27.0 + sin(pulse * 1.4), 0.14 * PI, 1.86 * PI, 30, Color(0.76, 0.59, 0.85, 0.20 * breath), 1.1, true)
		if item_data != null and item_data.icon != null:
			draw_texture_rect(item_data.icon, Rect2(-26, -45, 52, 52), false, Color(0.95, 0.88, 1.0, 0.94))
		var ground_name: String = item_data.display_name if item_data != null else "Weapon"
		draw_string(ThemeDB.fallback_font, Vector2(-80, 38), ground_name, HORIZONTAL_ALIGNMENT_CENTER, 160, 11, Color("dec9dc"))
		return
	var gold: Color = Color("b99c89") if not claimed else Color("77717e")
	draw_circle(Vector2(0, 2), 47, Color(0.26, 0.15, 0.29, 0.28))
	draw_rect(Rect2(-47, -14, 94, 44), Color("201a29"), true)
	draw_rect(Rect2(-47, -14, 94, 44), gold, false, 2.6)
	draw_line(Vector2(-41, -8), Vector2(41, -8), Color("4b3848"), 1.6, true)
	draw_circle(Vector2(0, -35), 39 + 3.0 * sin(pulse * 1.6), Color(0.86, 0.66, 0.97, 0.0 if claimed else 0.11))
	if item_data != null and item_data.icon != null:
		draw_texture_rect(item_data.icon, Rect2(-31, -77, 62, 62), false, Color(0.69, 0.66, 0.73, 0.8) if claimed else Color.WHITE)
	if Engine.is_editor_hint() or not claimed:
		draw_arc(Vector2(0, -38), 38, pulse * 0.5, pulse * 0.5 + PI * 1.7, 32, Color(0.88, 0.70, 0.95, 0.48), 1.8, true)
	var heading: String = item_data.display_name if item_data != null else "WEAPON"
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(-62, 45), heading, HORIZONTAL_ALIGNMENT_CENTER, 124, 12, Color("d2bed0") if claimed else Color("eacde1"))
	if not claimed and guaranteed_quality in ["set", "unique"]:
		draw_circle(Vector2(0, 13), 3.7 + 1.3 * sin(pulse * 3.0), Color("ead9a6"))
