@tool
extends Node2D
## Two optional, save-compatible spell discoveries; authored as scene nodes.
@export_enum("astral", "roses") var spell_kind: String = "astral"
@export var unlock_id: String = "v127_astral_rain_unlocked"
@export var key_hint: String = "V"
var learned: bool = false
var age: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v127_spell_reliquary")
        add_to_group("interactable")

func restore_from_inventory(inv: Node) -> void:
    learned = inv != null and inv.has_collected(unlock_id)

func _process(delta: float) -> void:
    age += delta
    queue_redraw()

func _draw() -> void:
    var tint: Color = Color("e4c0ff") if spell_kind == "astral" else Color("da9bbd")
    var glow: float = 0.5 + 0.5 * sin(age * 2.0)
    draw_circle(Vector2(0, -39), 42.0 + glow * 4.0, Color(tint.r, tint.g, tint.b, 0.035 if learned else 0.105))
    draw_rect(Rect2(-35, -12, 70, 30), Color("251b2e"), true)
    draw_rect(Rect2(-35, -12, 70, 30), Color("a38a9e"), false, 2.0)
    draw_arc(Vector2(0, -35), 29.0, age * 0.33, age * 0.33 + TAU * 0.87, 35, Color(tint.r, tint.g, tint.b, 0.28 if learned else 0.83), 2.0, true)
    for i in range(5):
        var p: Vector2 = Vector2(0, -39) + Vector2.from_angle(age * 0.42 + float(i) * TAU / 5.0) * 24.0
        if spell_kind == "astral":
            draw_line(p - Vector2(3, 0), p + Vector2(3, 0), tint, 1.2, true)
            draw_line(p - Vector2(0, 3), p + Vector2(0, 3), tint, 1.2, true)
        else:
            draw_circle(p, 2.7, Color(tint.r, tint.g, tint.b, 0.70))
    var title: String = "ASTRAL RAIN" if spell_kind == "astral" else "GRASPING ROSES"
    draw_string(ThemeDB.fallback_font, Vector2(-110, 40), title if learned else title + " RELIC", HORIZONTAL_ALIGNMENT_CENTER, 220, 12, Color("d8c6da"))
