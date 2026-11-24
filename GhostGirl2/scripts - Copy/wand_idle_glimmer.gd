extends Node2D
## v1.41 — wand-sized elongated glimmer, never a floating magic circle.
## A quiet material highlight runs along the wand shaft. Cosmetic only.
var inventory: Node = null
var visual_time: float = 0.0
var effect_color: Color = Color("c3b0e5")
var accent_color: Color = Color("efd1ed")
var trail_style: int = 0
var motif: int = 0
var rarity: int = 0
var enabled: bool = false

func bind_inventory(value: Node) -> void:
    inventory = value
    if inventory != null and not inventory.equipment_changed.is_connected(refresh):
        inventory.equipment_changed.connect(refresh)
    refresh()

func refresh() -> void:
    enabled = false
    if inventory == null:
        queue_redraw()
        return
    var wand: GhostItemInstance = inventory.get_equipped("wand")
    if wand == null:
        queue_redraw()
        return
    var rolls: Dictionary = wand.effect_rolls()
    rarity = GhostWeaponFXLibrary.tier(wand.quality)
    effect_color = GhostWeaponFXLibrary.color(int(rolls["color"]))
    accent_color = GhostWeaponFXLibrary.color(int(rolls["accent"]))
    motif = int(rolls["motif"])
    trail_style = int(rolls["trail"])
    enabled = rarity >= 2 and GhostWeaponFXLibrary.prestige_variant(wand.visual_seed(), wand.quality) >= 0
    queue_redraw()

func _process(delta: float) -> void:
    if not enabled:
        return
    visual_time += delta
    queue_redraw()

func _draw() -> void:
    if not enabled or inventory == null:
        return
    # If a melee weapon is out, let that blade own the visual silhouette.
    var carrying: GhostItemInstance = inventory.get_equipped("sword")
    var girl: Node = get_parent().get_parent()
    if carrying != null and float(girl.get("spell_time_left")) <= 0.0:
        return
    # A prestige wand is rendered already in Ghost's local coordinates.
    # Prevent a second, offset highlight from being drawn at the Hand marker.
    var prestige: Node = girl.get_node_or_null("Ghost/EquippedPrestigeFX")
    if prestige != null and prestige.get("item") == inventory.get_equipped("wand"):
        return
    var face: String = str(girl.get("facing_name"))
    var direction: Vector2 = Vector2(0.18, -1.0)
    match face:
        "left": direction = Vector2(-0.72, -0.70)
        "right": direction = Vector2(0.72, -0.70)
        "back": direction = Vector2(0.25, -0.97)
    direction = direction.normalized()
    var base: Vector2 = Vector2(1, -3)
    var tip: Vector2 = base + direction * 22.0
    var pulse: float = 0.5 + 0.5 * sin(visual_time * (1.2 + float(trail_style) * 0.12))
    var color: Color = effect_color.lerp(accent_color, pulse)
    color.a = 0.09 + 0.05 * pulse
    draw_line(base, tip, color, 3.0, true)
    color.a = 0.20 + 0.04 * pulse
    draw_line(base.lerp(tip, 0.25), tip, color, 1.0, true)
    var glint: Vector2 = base.lerp(tip, 0.18 + 0.66 * fposmod(visual_time * 0.16 + float(motif) * 0.13, 1.0))
    var across: Vector2 = Vector2(-direction.y, direction.x) * 1.4
    draw_line(glint - across, glint + across, Color(accent_color.r, accent_color.g, accent_color.b, 0.20), 1.0, true)
