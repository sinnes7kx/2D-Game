@tool
extends Node2D
## Editable Moonwake Crypt spell-discovery altar; unlock stored with inventory.
@export var discovery_id: String = "v125_moonfall_unlocked"
var learned: bool = false
var clock: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("moonfall_shrine")
        add_to_group("interactable")

func restore_from_inventory(inv: Node) -> void:
    learned = inv != null and inv.has_collected(discovery_id)

func _process(delta: float) -> void:
    clock += delta
    queue_redraw()

func _draw() -> void:
    var pearl: Color = Color("c7dbf5")
    var glow: float = 0.5 + 0.5 * sin(clock * 1.7)
    draw_circle(Vector2(0, -30), 43.0 + glow * 5.0, Color(0.60, 0.70, 1.0, 0.025 if learned else 0.09))
    draw_rect(Rect2(-37, -12, 74, 33), Color("282032"), true)
    draw_rect(Rect2(-37, -12, 74, 33), Color("ab94aa"), false, 2.5)
    draw_colored_polygon(PackedVector2Array([Vector2(-22,-49),Vector2(0,-79),Vector2(22,-49),Vector2(0,-19)]), Color(0.72,0.68,0.87,0.50 if learned else 0.9))
    draw_arc(Vector2(0,-50), 29.0, clock*0.33, clock*0.33+TAU*0.85, 28, Color(pearl.r,pearl.g,pearl.b,0.20 if learned else 0.70), 1.7, true)
    if not learned:
        for i in range(6):
            var p: Vector2 = Vector2.from_angle(clock*0.42+float(i)*TAU/6.0)*30.0+Vector2(0,-49)
            draw_circle(p, 2.3, Color("e3edff"))
    draw_string(ThemeDB.fallback_font, Vector2(-105,46), "MOONFALL" if learned else "FROST RELIQUARY", HORIZONTAL_ALIGNMENT_CENTER, 210, 13, Color("d7cfe7"))
