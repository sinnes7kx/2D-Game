extends RefCounted
## v2.03 original drawn blunt-weapon heads, sharing the existing MAUL
## hand/attack frame guides. Only geometry and FX vary; not damage or hitboxes.
const SURFACE = preload("res://scripts/living_metal_v187.gd")
const FX = preload("res://scripts/anomalous_steel_fx_v180.gd")

static func kind_from_id(item_id: String) -> String:
    match item_id:
        "v203_mournful_mace": return "mace"
        "v203_rosequartz_morningstar": return "morningstar"
        "v203_nightchain_flail": return "flail"
        _: return ""

static func draw_blunt(canvas: Node2D, grip: Vector2, head: Vector2, profile: Dictionary, look: Dictionary, gradient: Array[Color], time: float, kind: String, glow: bool) -> void:
    if grip.distance_squared_to(head) < 16.0 or profile.is_empty():
        return
    var along: Vector2 = (head - grip).normalized()
    var normal: Vector2 = Vector2(-along.y, along.x)
    var metal: Color = SURFACE.surface_color(profile, 0.65, 0.62, time)
    var shade: Color = profile["shade"]
    var edge: Color = profile["edge"]
    var accent: Color = profile["ornament_ink"]
    var shaft_tip: Vector2 = head
    if kind == "flail":
        shaft_tip = grip.lerp(head, 0.57)
    var heel: Vector2 = grip - along * 14.0
    canvas.draw_line(heel, shaft_tip, Color("241d2a"), 6.3, true)
    canvas.draw_line(heel, shaft_tip, profile["grip"], 3.75, true)
    canvas.draw_line(grip - along * 8.0, grip + along * 8.0, accent, 1.45, true)
    if kind == "flail":
        # A short chain trails in a pendulum on the attack clock; no additional
        # collision probes, physics bodies, independent strikes or damage.
        var wiggle: float = sin(time * 7.3) * 6.0
        var ball: Vector2 = head + normal * wiggle
        for link in range(5):
            var v: float = float(link) / 5.0
            var a: Vector2 = shaft_tip.lerp(ball, v)
            var b: Vector2 = shaft_tip.lerp(ball, v + 0.16)
            var lateral: Vector2 = normal * (2.1 if link % 2 == 0 else -2.1)
            canvas.draw_line(a + lateral, b - lateral, edge.darkened(0.21), 2.6, true)
            canvas.draw_circle(a, 1.75, accent)
        canvas.draw_circle(ball, 14.8, shade)
        canvas.draw_circle(ball - normal * 1.8, 11.2, metal)
        canvas.draw_arc(ball, 13.0, -PI * 0.7, PI * 0.7, 22, edge, 2.2, true)
        for i in range(8):
            var ang: float = float(i) * TAU / 8.0
            var direction: Vector2 = Vector2(cos(ang), sin(ang))
            var base: Vector2 = ball + direction * 10.8
            var tip: Vector2 = ball + direction * 18.2
            canvas.draw_colored_polygon(PackedVector2Array([base + direction.orthogonal() * 3.7, tip, base - direction.orthogonal() * 3.7]), metal)
        if glow:
            FX.draw_edge(canvas, PackedVector2Array([ball - normal * 10, ball + normal * 10]), gradient, look, time, 0.46)
        return
    if kind == "mace":
        # Flanged blunt head, not a cutting edge.
        var mid: Vector2 = head - along * 6.0
        canvas.draw_line(mid - along * 14.0, head + along * 12.0, shade, 19.0, true)
        canvas.draw_line(mid - along * 11.0, head + along * 10.0, metal, 12.5, true)
        for side in [-1.0, 1.0]:
            var spine: Vector2 = head + normal * side * 8.0
            canvas.draw_line(spine - along * 13.0, spine + along * 10.0, edge, 2.4, true)
            canvas.draw_circle(spine + along * 10.0, 2.2, accent)
        canvas.draw_line(head - along * 15.0, head + along * 14.0, accent, 1.0, true)
        if glow:
            FX.draw_edge(canvas, PackedVector2Array([head - along * 13.0 + normal * 9.0, head + along * 11.0 + normal * 9.0]), gradient, look, time, 0.38)
        return
    # Morningstar: heavy round ball plus eight inward-braced spikes.
    canvas.draw_circle(head, 17.0, shade)
    canvas.draw_circle(head - normal * 2.0, 14.0, metal)
    canvas.draw_circle(head - normal * 4.0 - along * 3.0, 5.4, metal.lightened(0.17))
    for i in range(8):
        var angle: float = TAU * float(i) / 8.0
        var axis: Vector2 = Vector2(cos(angle), sin(angle))
        var origin: Vector2 = head + axis * 13.8
        var spike: Vector2 = head + axis * (26.0 if i % 2 == 0 else 21.0)
        canvas.draw_colored_polygon(PackedVector2Array([origin + axis.orthogonal() * 4.6, spike, origin - axis.orthogonal() * 4.6]), edge)
    canvas.draw_arc(head, 16.0, 0.18, PI * 1.42, 24, accent, 1.45, true)
    if glow:
        FX.draw_edge(canvas, PackedVector2Array([head - normal * 14.0, head + along * 16.0]), gradient, look, time, 0.45)
