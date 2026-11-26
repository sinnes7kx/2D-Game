@tool
extends Control
## Thin original engraved corner ornaments. No input, no layout changes.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

func _draw() -> void:
    if size.x < 60 or size.y < 60:
        return
    var brass: Color = Color("a88b67")
    var silver: Color = Color("d3bd9e")
    for x in [-1.0, 1.0]:
        for y in [-1.0, 1.0]:
            var corner: Vector2 = Vector2(7.0 if x > 0 else size.x-7.0,7.0 if y > 0 else size.y-7.0)
            draw_set_transform(corner,0.0,Vector2(x,y))
            draw_polyline(PackedVector2Array([Vector2(0,30),Vector2(0,9),Vector2(9,0),Vector2(30,0)]),brass,1.0,true)
            draw_polyline(PackedVector2Array([Vector2(5,24),Vector2(5,12),Vector2(12,5),Vector2(24,5)]),Color(0.65,0.47,0.41,0.65),1.0,true)
            draw_arc(Vector2(12,12),7.0,PI,TAU*0.75,16,silver,1.0,true)
            draw_colored_polygon(PackedVector2Array([Vector2(8,8),Vector2(12,5),Vector2(16,8),Vector2(12,12)]),brass)
    draw_set_transform(Vector2.ZERO)
