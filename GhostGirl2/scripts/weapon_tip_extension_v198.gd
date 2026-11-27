extends Node2D
## v1.98.1: small extensions to approved baked dagger/stiletto tips and
## Briarwake's haft in IDLE/WALK only. Existing atlas and hand pose stay intact.
## No collision, combat reach, hit counts, item/save writes or emitters.
const GUIDE_PATH: String = "res://resources/new_weapon_axes_v169.json"
const MODULAR = preload("res://scripts/modular_weapon_art_v178.gd")
const EXTRA_DAGGER: float = 18.0
const SHAFT_BACK: float = 26.0
var body: AnimatedSprite2D = null
var player: Node = null
var guides: Dictionary = {}
var previous_animation: String = ""
var previous_frame: int = -1
var previous_item_key: String = ""

static func dagger_extra_tip(grip: Vector2, tip: Vector2) -> Vector2:
    var heading: Vector2 = tip - grip
    return tip + heading.normalized() * EXTRA_DAGGER if heading.length_squared() > 1.0 else tip

static func trident_extra_tail(grip: Vector2, tip: Vector2) -> Vector2:
    var heading: Vector2 = tip - grip
    return grip - heading.normalized() * SHAFT_BACK if heading.length_squared() > 1.0 else grip

func _ready() -> void:
    body = get_parent() as AnimatedSprite2D
    player = body.get_parent() if body != null else null
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(GUIDE_PATH))
    if parsed is Dictionary:
        guides = parsed
    set_process(true)

func _process(_delta: float) -> void:
    if body == null:
        return
    var animation_now: String = str(body.animation)
    var item: GhostItemInstance = _equipped()
    var key: String = "%s:%s:%d" % [item.get_instance_id(), item.cosmetic_uid, item.gradient_version] if item != null else ""
    if key != previous_item_key or animation_now != previous_animation or body.frame != previous_frame:
        previous_item_key = key
        previous_animation = animation_now
        previous_frame = body.frame
        z_index = -2 if animation_now.ends_with("_back") else 6
        queue_redraw()
    MODULAR.apply_equipped_opacity(self, body)

func _equipped() -> GhostItemInstance:
    if player == null:
        return null
    var world: Node = player.get("world") as Node
    var inventory: Node = world.get("inventory") as Node if world != null else null
    return inventory.get_equipped("sword") if inventory != null else null

func _draw() -> void:
    if body == null or guides.is_empty():
        return
    var item: GhostItemInstance = _equipped()
    if item == null or item.definition == null:
        return
    var name: String = str(body.animation)
    var ident: String = str(item.definition.item_id)
    var dagger: bool = ident in ["roseglass_dagger_v169", "nocturne_stiletto_v171"] and (name.begins_with("dagger_idle_") or name.begins_with("dagger_walk_") or name.begins_with("nocturne_dagger_idle_") or name.begins_with("nocturne_dagger_walk_"))
    var trident: bool = ident == "briarwake_trident_v171" and (name.begins_with("briarwake_spear_idle_") or name.begins_with("briarwake_spear_walk_"))
    if not dagger and not trident:
        return
    var rows: Array = guides.get(name, [])
    if rows.is_empty():
        return
    var frame: int = 0 if name.contains("_idle_") else clampi(body.frame, 0, rows.size() - 1)
    var row: Array = rows[frame]
    if row.size() != 4:
        return
    var grip: Vector2 = Vector2(float(row[0]), float(row[1]))
    var tip: Vector2 = Vector2(float(row[2]), float(row[3]))
    if grip.distance_squared_to(tip) < 16.0:
        return
    var profile: Dictionary = MODULAR.equipped_profile(self, body)
    var shaft_color: Color = profile.get("grip", Color("70455c"))
    var blade_color: Color = profile.get("shade", Color("3f344e"))
    var edge_color: Color = profile.get("edge", Color("c8b8d3"))
    var direction: Vector2 = (tip - grip).normalized()
    var n: Vector2 = Vector2(-direction.y, direction.x)
    if trident:
        var old_tail: Vector2 = grip - direction * 18.0
        var new_tail: Vector2 = trident_extra_tail(grip, tip)
        draw_line(old_tail, new_tail, Color("2d1a2c"), 6.5, true)
        draw_line(old_tail, new_tail, shaft_color, 4.2, true)
        draw_line(old_tail - n * 0.6, new_tail, edge_color.darkened(0.34), 0.8, true)
        return
    # Extend the steel tip without changing the grip: the original decorated hilt,
    # blade faces and approved Ghost Girl body are not repainted.
    var extended: Vector2 = dagger_extra_tip(grip, tip)
    var root: Vector2 = tip - direction * 10.0
    draw_colored_polygon(PackedVector2Array([root - n * 1.5, root + n * 1.5, extended]), blade_color)
    draw_line(root - n * 0.35, extended, edge_color, 1.25, true)
