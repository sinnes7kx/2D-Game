@tool
extends Control
## Thin original engraved corner ornaments. No input, no layout changes.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

# Small cast-metal rosettes instead of sketched line ornaments.
static var relief_corner: Texture2D
static func _corner() -> Texture2D:
    if relief_corner!=null:
        return relief_corner
    var img: Image=Image.create(42,42,false,Image.FORMAT_RGBA8)
    for y in range(42):
        for x in range(42):
            var p: Vector2=Vector2(x-12,y-12)
            var r: float=p.length()
            var a: float=p.angle()
            var petal: float=12.0+3.2*cos(a*6.0)
            var arm: float=absf(float(x-y))
            if r>petal and not (minf(x,y)<7.0 and maxf(x,y)<38.0 and arm>8.0):
                continue
            var depth: float=clampf((petal-r)*0.28,0.0,1.0)
            var bevel: float=0.42+0.30*cos(a+0.8)+0.20*cos(r*1.05)
            var ink: Color=Color("463021").lerp(Color("d9b786"),clampf(bevel*depth+0.16,0.0,1.0))
            if r<3.6:
                ink=Color("754a55").lerp(Color("f0c1a8"),clampf(0.6-p.y*0.13,0.0,1.0))
            img.set_pixel(x,y,ink)
    relief_corner=ImageTexture.create_from_image(img)
    return relief_corner

func _draw() -> void:
    if size.x<60 or size.y<60:
        return
    var texture: Texture2D=_corner()
    for x in [-1.0,1.0]:
        for y in [-1.0,1.0]:
            var corner: Vector2=Vector2(3.0 if x>0 else size.x-3.0,3.0 if y>0 else size.y-3.0)
            draw_set_transform(corner,0.0,Vector2(x,y))
            draw_texture(texture,Vector2.ZERO)
    draw_set_transform(Vector2.ZERO)
