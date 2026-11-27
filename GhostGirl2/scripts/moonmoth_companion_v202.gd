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
    time_alive += delta
    var facing: String = str(actor.get("facing_name"))
    var side: float = 1.0 if facing == "left" else -1.0
    var normal: Vector2 = Vector2(side * 46.0, -116.0 + sin(time_alive * 1.7) * 8.0)
    check_time -= delta
    if check_time <= 0.0:
        check_time = 0.42
        if not subdued:
            _find_secret()
    var desired: Vector2 = normal + target_hint * curiosity
    position = position.lerp(desired, minf(1.0, delta * 4.4))
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
    # Seeded wing geometry and independent wing color channel. Cosmetic only.
    var shape_seed: int = wing_shape
    var wing_ink: Color = RNG.sample_palette(wing_colors,0.43)
    var flap: float = 0.76+0.22*sin(time_alive*5.1)
    for side in [-1.0,1.0]:
        var root: Vector2 = core+Vector2(side*2.0,0)
        var upper: Vector2 = core+Vector2(side*(10.0+shape_seed*1.6)*flap,-8.0-shape_seed*1.2)
        var outer: Vector2 = core+Vector2(side*(14.0+shape_seed)*flap,-1.0)
        var lower: Vector2 = core+Vector2(side*(7.0+shape_seed*1.4)*flap,6.0+shape_seed)
        draw_colored_polygon(PackedVector2Array([root,upper,outer,lower]),Color(wing_ink.r,wing_ink.g,wing_ink.b,0.46))
        draw_polyline(PackedVector2Array([root,upper,outer,lower,root]),wing_ink.lightened(0.28),0.85,true)
        draw_line(root,outer,wing_ink.darkened(0.24),0.65,true)
        if shape_seed>=2:
            draw_line(outer,lower+Vector2(side*2.0,5.0),wing_ink.lightened(0.2),0.9,true)
    draw_circle(core, 4.0, hue.lerp(Color.WHITE, 0.28))
    draw_circle(core + Vector2(-1, -1), 1.6, Color("fff5ff"))
    if FX.intensity <= 0.0:
        return
    draw_circle(core, 13.0 + tier, Color(hue.r, hue.g, hue.b, FX.alpha(0.12)))
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
