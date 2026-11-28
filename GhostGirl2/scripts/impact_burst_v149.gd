extends Node2D
const TEXTURES = preload("res://scripts/atmosphere_textures_v278.gd")
const PERF = preload("res://scripts/performance_profiles_v230.gd")
## Lightweight procedural impact debris, chips and rolling smoke. VISUAL ONLY.
## One node per event, no new textures, colliders, damage or timers in saves.
var effect_kind: String = "stone" # stone, wood, landing, slam, hurt, flesh, crate
var intensity: float = 1.0
var direction: Vector2 = Vector2.ZERO
var seed_value: int = 1
var age: float = 0.0
var lifetime: float = 1.18
var fragments: Array[Dictionary] = []
var clouds: Array[Dictionary] = []
var sparks: Array[Dictionary] = []

static func particle_budget(count: int, low: bool) -> int:
    return maxi(1,roundi(float(count)*0.60)) if low else count

static func spark_direction(heading: Vector2, variation: float) -> Vector2:
    if heading.length_squared()<0.01:
        return Vector2.from_angle(variation)
    return heading.normalized().rotated(variation*0.36)

func _ready() -> void:
    z_index = 16
    add_to_group("v149_impact_fx")
    intensity = clampf(intensity, 0.35, 2.4)
    lifetime = 1.50 if effect_kind in ["wood", "stone", "crate", "slam"] else (0.65 if effect_kind == "poise" else 0.88)
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = maxi(1, absi(seed_value) + absi(roundi(global_position.x * 13.0)) * 31 + absi(roundi(global_position.y * 7.0)) * 47)
    var debris_count: int = mini(20, roundi((10.0 if effect_kind in ["stone", "wood", "crate"] else 7.0) * intensity))
    var low: bool = PERF.profile==PERF.Profile.LOW
    for i in range(particle_budget(debris_count,low)):
        var spread: Vector2 = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 0.3)).normalized()
        var biased: Vector2 = spread + direction.normalized() * (0.24 if direction.length_squared() > 0.01 else 0.0)
        fragments.append({"origin": Vector2(rng.randf_range(-9.0, 9.0), rng.randf_range(-9.0, 9.0)), "speed": biased * rng.randf_range(55.0, 145.0) * intensity, "size": rng.randf_range(2.2, 5.5) * minf(intensity, 1.45), "rotation": rng.randf_range(-3.0, 3.0), "delay": rng.randf_range(0.0, 0.09), "life": rng.randf_range(0.42, 0.78)})
    var smoke_count: int = 1 if effect_kind == "poise" else (2 if effect_kind in ["hurt", "flesh"] else (5 if effect_kind in ["wood", "stone", "crate", "slam"] else 3))
    for i in range(particle_budget(smoke_count,low)):
        clouds.append({"origin": Vector2(rng.randf_range(-15.0, 15.0), rng.randf_range(-8.0, 8.0)), "rise": Vector2(rng.randf_range(-21.0, 21.0), rng.randf_range(-24.0, -12.0)), "size": rng.randf_range(12.0, 22.0) * intensity, "delay": rng.randf_range(0.0, 0.17)})
    for i in range(particle_budget(6,low)):
        sparks.append({"angle": rng.randf_range(-PI,PI), "distance": rng.randf_range(9.0,31.0)*intensity})

func _process(delta: float) -> void:
    age += delta
    if age >= lifetime:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    var wood: bool = effect_kind in ["wood", "crate"]
    var blood: bool = effect_kind in ["hurt", "flesh"]
    var dusty: bool = effect_kind in ["landing", "slam"]
    var particle_color: Color = Color("956e78") if wood else (Color("786e80") if not blood else Color("862c43"))
    if dusty:
        particle_color = Color("b1a5b5")
    if effect_kind == "poise":
        particle_color = Color("d9c0e3")
    var smoke_tint: Color = Color("80727c") if wood else (Color("9b94a5") if not blood else Color("77444f"))
    if dusty:
        smoke_tint = Color("c1b7c5")
    if effect_kind == "poise":
        smoke_tint = Color("c3a6d3")
    # Ground compression ring fades before the denser clouds disperse.
    var ring_fade: float = pow(maxf(0.0, 1.0 - age / 0.37), 1.6)
    if ring_fade > 0.01 and not blood:
        draw_arc(Vector2(0.0, 3.0), (7.0 + age * (125.0 if effect_kind == "slam" else 80.0)) * intensity, 0.0, TAU, 38, Color(0.95, 0.83, 0.82, ring_fade * (0.43 if effect_kind == "slam" else 0.20)), 2.8 if effect_kind == "slam" else 1.7, true)
    for cloud in clouds:
        var t: float = age - float(cloud["delay"])
        if t < 0.0:
            continue
        var p: float = clampf(t / lifetime, 0.0, 1.0)
        var opacity: float = pow(1.0 - p, 1.8) * (0.27 if not blood else 0.10)
        var smoke_pos: Vector2 = cloud["origin"] + cloud["rise"] * t
        var smoke_radius: float = float(cloud["size"]) * (0.57 + p * 1.5)
        # Soft layered dust rather than flat opaque circles.
        var extent: Vector2=Vector2(smoke_radius,smoke_radius*0.72)
        draw_texture_rect(TEXTURES.dust(),Rect2(smoke_pos-extent,extent*2.0),false,Color(smoke_tint.r,smoke_tint.g,smoke_tint.b,opacity*0.85))
        if PERF.profile!=PERF.Profile.LOW:
            var inner: Vector2=extent*0.66
            draw_texture_rect(TEXTURES.dust(),Rect2(smoke_pos-extent*0.12-inner,inner*2.0),false,Color(0.79,0.75,0.77,opacity*0.28))
    for frag in fragments:
        var t: float = age - float(frag["delay"])
        var duration: float = float(frag["life"])
        if t < 0.0 or t > duration:
            continue
        var fade: float = pow(1.0 - t / duration, 0.8)
        var at: Vector2 = frag["origin"] + frag["speed"] * t + Vector2(0.0, 95.0 * t * t)
        var sz: float = float(frag["size"]) * (1.0 - t * 0.37)
        var c: Color = Color(particle_color.r, particle_color.g, particle_color.b, 0.92 * fade)
        var angle: float = float(frag["rotation"]) * t
        var axis: Vector2 = Vector2.from_angle(angle)
        var ortho: Vector2 = axis.orthogonal()
        draw_colored_polygon(PackedVector2Array([at + axis * sz, at + ortho * sz * 0.42, at - axis * sz * 0.8, at - ortho * sz * 0.5]), c)
        if not blood:
            draw_line(at-axis*sz*0.55,at+ortho*sz*0.42,c.lightened(0.24),0.7,true)
    if effect_kind in ["slam", "stone", "wood", "poise"] and age < 0.22:
        var flare: float = 1.0 - age / 0.22
        for spark in sparks:
            var unit: Vector2 = spark_direction(direction if effect_kind=="poise" else Vector2.ZERO,float(spark["angle"]))
            var start: Vector2 = unit * float(spark["distance"]) * age * 1.4
            var end: Vector2=start+unit*(8.0+23.0*age)*intensity
            draw_line(start,end,Color(0.98,0.71,0.52,0.17*flare),3.0,true)
            draw_line(start,end,Color(1.0,0.91,0.80,0.72*flare),0.9,true)
