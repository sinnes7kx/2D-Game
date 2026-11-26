extends RefCounted
## v2.03 original drawn blunt-weapon heads, sharing the existing MAUL
## hand/attack frame guides. Only geometry and FX vary; not damage or hitboxes.
const SURFACE = preload("res://scripts/living_metal_v187.gd")
const FX = preload("res://scripts/anomalous_steel_fx_v180.gd")
const FX_LEVEL = preload("res://scripts/fx_intensity_v1924.gd")

static func kind_from_id(item_id: String) -> String:
    match item_id:
        "v203_mournful_mace": return "mace"
        "v203_rosequartz_morningstar": return "morningstar"
        "v203_nightchain_flail": return "flail"
        _: return ""

# Full-head outline: long-running collector glow must describe the
# *actual* spiked or flanged shape, never a single line on one side.
static func _rim(canvas: Node2D, path: PackedVector2Array, gradient: Array[Color], look: Dictionary, time: float, strength: float) -> void:
    var ink: Color = FX.color_at(gradient, look, 0.56, time)
    var closed: PackedVector2Array = path.duplicate()
    if closed.size() < 3:
    	return
    closed.append(closed[0])
    canvas.draw_polyline(closed, Color(ink.r, ink.g, ink.b, FX_LEVEL.alpha(0.06)), 4.0, true)
    canvas.draw_polyline(closed, Color(ink.r, ink.g, ink.b, FX_LEVEL.alpha(0.14)), 1.6, true)
    FX.draw_edge(canvas, closed, gradient, look, time, strength)

# Forged, compact heads. The same outline drives opaque art and glow.
static func head_outline(center: Vector2, axis: Vector2, kind: String) -> PackedVector2Array:
    var n: Vector2 = axis.orthogonal()
    if kind == "mace":
        return PackedVector2Array([center-axis*12.0-n*4.0, center-axis*7.0-n*7.0, center+axis*8.0-n*7.0, center+axis*13.0-n*3.0, center+axis*13.0+n*3.0, center+axis*8.0+n*7.0, center-axis*7.0+n*7.0, center-axis*12.0+n*4.0])
    var result: PackedVector2Array = PackedVector2Array()
    var teeth: int = 6 if kind == "morningstar" else 5
    var radius: float = 9.0 if kind == "morningstar" else 7.0
    for i in range(teeth):
        var a: float = axis.angle() + TAU * float(i) / float(teeth)
        var d: Vector2 = Vector2.from_angle(a)
        result.append(center + Vector2.from_angle(a - 0.22) * radius)
        result.append(center + d * (15.0 if kind == "morningstar" else 12.0))
        result.append(center + Vector2.from_angle(a + 0.22) * radius)
    return result

static func draw_blunt(canvas: Node2D, grip: Vector2, head: Vector2, profile: Dictionary, look: Dictionary, gradient: Array[Color], time: float, kind: String, glow: bool) -> void:
    if grip.distance_squared_to(head) < 16.0 or profile.is_empty():
        return
    var axis: Vector2 = (head - grip).normalized()
    var n: Vector2 = axis.orthogonal()
    var steel: Color = SURFACE.surface_color(profile, 0.65, 0.62, time).lerp(Color("59606a"), 0.42)
    var shade: Color = steel.darkened(0.48)
    var edge: Color = steel.lightened(0.38)
    var ornament: Color = profile["ornament_ink"]
    var trim: Color = ornament.lerp(steel, 0.45)
    var shaft_tip: Vector2 = grip.lerp(head, 0.55) if kind == "flail" else head - axis * 5.0
    var heel: Vector2 = grip - axis * 18.0
    canvas.draw_line(heel, shaft_tip, Color("211d27"), 4.4, true)
    canvas.draw_line(heel, shaft_tip, profile["grip"], 2.9, true)
    canvas.draw_line(heel + n * 0.9, shaft_tip + n * 0.9, steel.darkened(0.15), 0.65, true)
    for i in range(4):
        var at: Vector2 = grip - axis * 7.0 + axis * float(i) * 4.0
        canvas.draw_line(at-n*1.6, at+n*1.6+axis, trim, 0.65, true)
    var center: Vector2 = head
    if kind == "flail":
        center += n * sin(time * 7.3) * 4.0
        var chain_axis: Vector2 = (center - shaft_tip).normalized()
        var chain_n: Vector2 = chain_axis.orthogonal()
        for i in range(6):
            var at: Vector2 = shaft_tip.lerp(center, (float(i) + 0.5) / 6.0)
            var link: PackedVector2Array = PackedVector2Array()
            for j in range(9):
                var angle: float = TAU * float(j) / 8.0
                link.append(at + chain_axis * cos(angle) * 2.8 + chain_n * sin(angle) * (1.4 if i % 2 == 0 else 0.7))
            canvas.draw_polyline(link, shade, 1.9, true)
            canvas.draw_polyline(link, edge, 0.7, true)
    var outline: PackedVector2Array = head_outline(center, axis, kind)
    canvas.draw_colored_polygon(outline, shade)
    # Triangular bevel facets provide forged-metal planes rather than a
    # flat cartoon circle and keep the spikes slim.
    for i in range(outline.size()):
        var a: Vector2 = outline[i]
        var b: Vector2 = outline[(i + 1) % outline.size()]
        var lit: float = clampf(0.5 + (a-center).normalized().dot(-n) * 0.36, 0.0, 1.0)
        canvas.draw_colored_polygon(PackedVector2Array([center, a, b]), shade.lerp(steel, lit))
    var closed: PackedVector2Array = outline.duplicate()
    closed.append(closed[0])
    canvas.draw_polyline(closed, edge, 0.75, true)
    if kind == "mace":
        for side in [-1.0, 1.0]:
            canvas.draw_line(center-axis*8.0+n*side*4.4, center+axis*8.0+n*side*4.4, edge, 1.0, true)
        canvas.draw_line(center-axis*10.0, center+axis*11.0, trim, 0.7, true)
    else:
        canvas.draw_line(center-axis*4.0, center+axis*4.0, trim, 0.85, true)
    if glow and FX_LEVEL.intensity > 0.0:
        _rim(canvas, outline, gradient, look, time, 0.32)
