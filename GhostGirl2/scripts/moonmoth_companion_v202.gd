extends Node2D
## The Moonmoth: Ghost Girl's original, quiet traveling familiar.
## No hitboxes, autoplay chatter, player buffs, drops or item/save writes.
## An occasional brighter orbit hints that something nearby may be curious.
var time_alive: float = 0.0
var curiosity: float = 0.0
var target_hint: Vector2 = Vector2.ZERO
var check_time: float = 0.0
var actor: Node2D = null
var subdued: bool = false
const RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const ROLLS = preload("res://scripts/collector_appearance_v177.gd")
const FX = preload("res://scripts/fx_intensity_v1924.gd")
var look_key: String = ""
var look: Dictionary = {}
var colors: Array[Color] = []
var wing_colors: Array[Color] = []
var wing_shape: int = 0
var fx_profile: Dictionary = {}
var aura_colors: Array[Color] = []
var wake: Array[Vector2] = []
var wake_clock: float = 0.0
var familiar: GhostItemInstance = null

func _ready() -> void:
    actor = get_parent() as Node2D
    z_index = 28
    position = Vector2(-47.0, -121.0)
    subdued = actor == null or bool(actor.get("equipment_preview_only"))
    visible = false # No equipped familiar means no active companion.
    set_process(actor != null)

func _process(delta: float) -> void:
    if actor == null:
        return
    var world: Node = actor.get("world") as Node
    var inv: Node = world.get("inventory") as Node if world != null else null
    familiar = inv.get_equipped("companion") if inv != null else null
    visible = familiar != null
    if not visible:
        return
    if familiar != null:
        var key: String = "%s:%d:%d" % [familiar.cosmetic_uid, familiar.visual_seed(), familiar.gradient_version]
        if key != look_key:
            look_key = key
            look = ROLLS.roll(familiar.cosmetic_uid, familiar.visual_seed(), familiar.gradient_version)
            colors = RNG.gradient_for_channel(familiar.cosmetic_uid, familiar.visual_seed(), "companion-v239", familiar.gradient_version)
            wing_colors=RNG.gradient_for_channel(familiar.cosmetic_uid,familiar.visual_seed(),"familiar-wings-v272",familiar.gradient_version)
            wing_shape=posmod(hash("%s|%d|familiar-wing-v272" % [familiar.cosmetic_uid,familiar.visual_seed()]),4)
            fx_profile=profile_v273(familiar.cosmetic_uid,familiar.visual_seed())
            aura_colors=RNG.gradient_for_channel(familiar.cosmetic_uid,familiar.visual_seed(),"familiar-aura-v273",familiar.gradient_version)
            wake.clear()
    time_alive += delta
    var facing: String = str(actor.get("facing_name"))
    var side: float = 1.0 if facing == "left" else -1.0
    var normal: Vector2 = Vector2(side * 46.0, -116.0 + sin(time_alive * 1.7) * 8.0)
    check_time -= delta
    if check_time <= 0.0:
        check_time = 0.42
        if not subdued:
            _find_secret()
    if int(look.get("particle_tier",0))<6:
        var motion: int = int(fx_profile.get("motion",0))
        normal+=Vector2(sin(time_alive*(0.44+motion*0.09))*float(3+motion*2),cos(time_alive*0.8)*float(motion*2))
    var desired: Vector2 = normal + target_hint * curiosity
    position = position.lerp(desired, minf(1.0, delta * 4.4))
    wake_clock+=delta
    if wake_clock>=0.075:
        wake_clock=0.0
        if not wake.is_empty() and wake[0].distance_to(global_position)>100.0:
            wake.clear()
        wake.push_front(global_position)
        if wake.size()>9:
            wake.pop_back()
    queue_redraw()

func _find_secret() -> void:
    target_hint = Vector2.ZERO
    curiosity = move_toward(curiosity, 0.0, 0.14)
    if get_tree().current_scene == null:
        return
    for group in ["v201_cave_blocker", "v202_world_puzzle"]:
        for clue in get_tree().get_nodes_in_group(group):
            if not is_instance_valid(clue) or not clue is Node2D:
                continue
            var point: Vector2 = (clue as Node2D).global_position
            if actor.global_position.distance_squared_to(point) > 225.0 * 225.0:
                continue
            if clue.has_method("is_resolved") and clue.call("is_resolved"):
                continue
            if clue.is_in_group("v201_cave_blocker") and bool(clue.get("opened")):
                continue
            var delta: Vector2 = (point - actor.global_position).normalized()
            target_hint = delta * 23.0
            curiosity = minf(1.0, curiosity + 0.24)
            return

func _draw() -> void:
    if familiar != null and not colors.is_empty():
        _draw_equipped_wisp()
        return
    var lift: float = sin(time_alive * 2.1) * 2.0
    var bright: float = 0.68 + 0.18 * sin(time_alive * 1.6) + curiosity * 0.14
    var aura: Color = Color("b6d1ef")
    var body: Vector2 = Vector2(0, lift)
    draw_circle(body, 13.0, Color(aura.r, aura.g, aura.b, 0.034 * bright))
    var wing: float = 0.66 + 0.25 * sin(time_alive * 8.0)
    for side in [-1.0, 1.0]:
        var outer: Vector2 = body + Vector2(side * (9.0 + 4.0 * wing), -8.0)
        var lower: Vector2 = body + Vector2(side * 8.0, 6.0)
        draw_colored_polygon(PackedVector2Array([body, outer, lower]), Color(0.83, 0.71, 0.89, 0.35 * bright))
        draw_line(body, outer, Color("c8b8e1"), 0.85, true)
    draw_circle(body, 3.4, Color("8aa5cd"))
    draw_circle(body + Vector2(0, -1), 1.65, Color(0.98, 0.95, 1.0, bright))
    for i in range(3):
        var t: float = time_alive * (0.8 + i * 0.12) + i * 2.1
        var mote: Vector2 = body + Vector2(sin(t) * (9.0 + i * 3.0), cos(t * 1.1) * (9.0 + i * 3.0))
        draw_circle(mote, 0.9, Color(0.79, 0.79, 1.0, 0.28 * bright))

func _draw_equipped_wisp() -> void:
    var tier: int = int(look.get("particle_tier", 0))
    var motif: int = int(look.get("glow_motif", 0))
    if OS.is_debug_build() and familiar.debug_collector_tier >= 0:
        tier = familiar.debug_collector_tier
    if OS.is_debug_build() and familiar.debug_glow_motif >= 0:
        motif = familiar.debug_glow_motif
    var hue: Color = RNG.sample_palette(colors, 0.5 + 0.5 * sin(time_alive * 0.8))
    var accent: Color = RNG.sample_palette(colors, 0.8)
    var core: Vector2 = Vector2(0.0, sin(time_alive * 2.1) * 2.0)
    # A tiny elongated fairy, four articulated translucent wings. Keep
    # the existing independently rolled colors and wing-shape identity.
    var wing_ink: Color = RNG.sample_palette(wing_colors,0.43)
    var flap: float = 0.55+0.45*absf(sin(time_alive*11.0))
    var reach: float = (18.0+wing_shape*1.9)*flap
    var upper_height: float = 15.0+wing_shape*1.6
    var tail_height: float = 10.0+wing_shape*1.1
    for side in [-1.0,1.0]:
        var root: Vector2 = core+Vector2(side*1.5,-1)
        var upper: PackedVector2Array = wing_outline_v282(root,side,reach,upper_height,true)
        var lower: PackedVector2Array = wing_outline_v282(root,side,reach*0.64,tail_height,false)
        # Unique endpoints and a simple contour prevent Godot triangulation spam.
        _draw_valid_wing_v282(upper,Color(wing_ink.r,wing_ink.g,wing_ink.b,0.40))
        _draw_valid_wing_v282(lower,Color(wing_ink.r,wing_ink.g,wing_ink.b,0.31))
        var edge: Color = wing_ink.lerp(Color.WHITE,0.58)
        edge.a=0.76
        var upper_edge: PackedVector2Array = upper.duplicate()
        upper_edge.append(root)
        draw_polyline(upper_edge,edge,0.85,true)
        edge.a=0.54
        var lower_edge: PackedVector2Array = lower.duplicate()
        lower_edge.append(root)
        draw_polyline(lower_edge,edge,0.75,true)
        for vein in [5,8,11]:
            draw_line(root,upper[vein],Color(edge.r,edge.g,edge.b,0.24),0.65,true)
        draw_line(root,lower[8],Color(edge.r,edge.g,edge.b,0.28),0.65,true)
    # Head, slender body and pointed trailing dress. No large central orb.
    var light: Color = hue.lerp(Color.WHITE,0.54)
    draw_colored_polygon(PackedVector2Array([core+Vector2(-2.2,-2.0),core+Vector2(2.2,-2.0),core+Vector2(3.0,3.8),core+Vector2(0,7.5),core+Vector2(-3.0,3.8)]),light)
    draw_circle(core+Vector2(0,-4),2.1,hue.lerp(Color.WHITE,0.72))
    draw_line(core+Vector2(0,-1),core+Vector2(0,6),Color("fff3e9"),0.8,true)
    if FX.intensity <= 0.0:
        return
    if tier<6:
        _draw_seeded_layers_v273(core,hue,accent,tier)
        # Very local body bloom; the wings remain the dominant silhouette.
        draw_circle(core,5.5,Color(hue.r,hue.g,hue.b,FX.alpha(0.11)))
        return
    # Retain the protected top-tier decorative identity.
    draw_circle(core,13.0+tier,Color(hue.r,hue.g,hue.b,FX.alpha(0.12)))
    var count: int = 2+mini(tier,4)
    for i in range(count):
        var t: float = float(i) / float(count)
        var a: float = time_alive * (0.65 + tier * 0.08) + TAU * t
        var p: Vector2 = core + Vector2(cos(a) * (10.0 + tier), sin(a) * (6.0 + tier))
        var ink: Color = Color(accent.r, accent.g, accent.b, FX.alpha(0.62))
        if motif % 3 == 0:
            draw_circle(p, 1.5, ink)
        elif motif % 3 == 1:
            draw_line(p - Vector2(2, 0), p + Vector2(2, 0), ink, 0.8, true)
            draw_line(p - Vector2(0, 2), p + Vector2(0, 2), ink, 0.8, true)
        else:
            draw_arc(p, 2.5, a, a + PI, 8, ink, 1.1, true)
    if tier >= 3:
        var radius: float = 13.0+float(tier)*1.3
        var arc: float = time_alive*0.42
        draw_arc(core,radius,arc,arc+PI*0.84,24,Color(accent.r,accent.g,accent.b,FX.alpha(0.18)),0.9,true)
    if tier >= 4:
        for i in range(5):
            var t: float = float(i) / 5.0
            var a: float = time_alive * 0.85 - t * 2.8
            var p: Vector2 = core + Vector2(cos(a) * 19.0, sin(a) * 10.0)
            draw_circle(p, 2.4 * (1.0 - t), Color(hue.r, hue.g, hue.b, FX.alpha(0.7 * (1.0 - t))))

# Two monotonic boundaries meet only at root and tip. Never append a
# repeated closing vertex to a filled polygon.
static func wing_outline_v282(root: Vector2,side: float,reach: float,height: float,upper: bool) -> PackedVector2Array:
    var points: PackedVector2Array = PackedVector2Array([root])
    var sign_y: float = -1.0 if upper else 1.0
    var w: float = maxf(0.5,reach)
    var h: float = maxf(0.5,height)
    for i in range(1,9):
        var t: float = float(i)/8.0
        points.append(root+Vector2(side*w*t,sign_y*h*(t*0.75+0.38*sin(PI*t))))
    for i in range(7,0,-1):
        var t: float = float(i)/8.0
        points.append(root+Vector2(side*w*t,sign_y*h*(t*0.75-0.31*sin(PI*t))))
    return points

func _draw_valid_wing_v282(points: PackedVector2Array,ink: Color) -> void:
    if points.size()<3:
        return
    var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(points)
    if triangles.is_empty():
        return
    draw_colored_polygon(points,ink)

static func profile_v273(uid: String,seed: int) -> Dictionary:
    var key: String = "%s|%d|familiar-v273" % [uid,seed]
    return {"aura":posmod(hash(key+"|aura"),6),"orbit":posmod(hash(key+"|orbit"),5),"motif":posmod(hash(key+"|motif"),8),"trail":posmod(hash(key+"|trail"),4),"motion":posmod(hash(key+"|motion"),4)}

func _draw_seeded_layers_v273(core: Vector2,hue: Color,accent: Color,tier: int) -> void:
    var aura: Color = RNG.sample_palette(aura_colors,0.4) if not aura_colors.is_empty() else hue
    var strength: float = FX.alpha(0.30+float(tier)*0.07)
    var pulse: float = 0.70+0.30*sin(time_alive*1.1)
    var radius: float = 12.0+float(tier)*1.5
    var phase: float = time_alive*0.45
    var shape: int = int(fx_profile.get("aura",0))
    # All lower-tier effects are small wing-edge accents or drifting dust,
    # never a large enclosing orb/ring. Seed still selects the motif.
    for side in [-1.0,1.0]:
        var at: Vector2 = core+Vector2(side*(10.0+shape*1.4),-5.0+sin(time_alive*2.0+side)*2.0)
        var ink: Color = Color(aura.r,aura.g,aura.b,strength*pulse)
        match shape:
            0,1: draw_circle(at,1.5,ink)
            2,3:
                draw_line(at-Vector2(2,0),at+Vector2(2,0),ink,0.9,true)
                draw_line(at-Vector2(0,2),at+Vector2(0,2),ink,0.9,true)
            4: draw_arc(at,2.4,phase,phase+PI,10,ink,1.0,true)
            _: draw_line(at,at+Vector2(side*3,-4),ink,1.0,true)
    var orbit: int = int(fx_profile.get("orbit",0))
    var motif: int = int(fx_profile.get("motif",0))
    for j in range(2+mini(tier,3)):
        var a: float = phase*(1.0+float(orbit)*0.15)+float(j)*TAU/float(2+mini(tier,3))
        var p: Vector2 = core+Vector2(cos(a)*radius*0.78,8.0+absf(sin(a*(2.0 if orbit==2 else 1.0)))*radius*0.95)
        var c: Color = RNG.sample_palette(colors,float(j)*0.23+0.1)
        c.a=strength*pulse
        match motif:
            0,1: draw_circle(p,1.25,c)
            2,3:
                draw_line(p-Vector2(2.5,0),p+Vector2(2.5,0),c,0.8,true)
                draw_line(p-Vector2(0,2.5),p+Vector2(0,2.5),c,0.8,true)
            4: draw_arc(p,2.8,a,a+PI,9,c,0.9,true)
            5: draw_colored_polygon(PackedVector2Array([p+Vector2(0,-2.8),p+Vector2(1.8,0),p+Vector2(0,2.8),p+Vector2(-1.8,0)]),c)
            6: draw_line(p,p+Vector2.from_angle(a)*4.0,c,1.0,true)
            _: draw_circle(p,2.2,Color(c.r,c.g,c.b,c.a*0.4))
    if tier>=1:
        var trail_style: int = int(fx_profile.get("trail",0))
        for j in range(1,wake.size()):
            var p: Vector2 = to_local(wake[j])
            var a: float = strength*(1.0-float(j)/float(wake.size()))*0.62
            var c: Color = Color(accent.r,accent.g,accent.b,a)
            if trail_style==0:
                draw_line(to_local(wake[j-1]),p,c,1.8,true)
            elif trail_style==1:
                draw_circle(p,1.2,c)
            elif trail_style==2:
                draw_circle(p,3.0,Color(c.r,c.g,c.b,c.a*0.3))
            else:
                draw_line(p+Vector2(-2,0),p+Vector2(2,0),c,0.8,true)
