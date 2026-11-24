@tool
extends Node2D
## World loot must be picked up rather than directly entering inventory.
@export var item_data: GhostItemData
@export var loot_seed: int = 431
@export_enum("random", "normal", "magic", "rare", "set", "unique") var guaranteed_quality: String = "random"
@export var interaction_name: String = "Pick up treasure"
var time_counter: float = 0.0
var aura: Color = Color("c9a77c")
var spectral_color: Color = Color("d9b7e6")
var spectral_accent: Color = Color("c4d3f4")
var spectral_motif: int = 0
var spectral_trail: int = 0
var spectral_tier: int = -1
var spectral_label: String = ""
# v1.31: independently seeded floor heraldry is purely visual and
# only available to exceptional equipment. No rarity/drop roll is changed.
var rare_signature: int = -1
var display_title: String = "TREASURE"
var near_player: bool = false
# Ground-dropped gear keeps its original affixes, quality and socket contents.
var dropped_instance: GhostItemInstance = null
var persistent_drop_id: String = ""
var discovery_title: String = ""

func _ready() -> void:
    if not Engine.is_editor_hint():
        var sample: GhostItemInstance = dropped_instance
        if sample == null and item_data != null:
            var picked_quality: String = "" if guaranteed_quality == "random" else guaranteed_quality
            sample = GhostItemGenerator.create(item_data, loot_seed, picked_quality)
        if sample != null:
            aura = sample.quality_color()
            display_title = sample.display_name().to_upper()
            if dropped_instance != null and persistent_drop_id.is_empty():
                discovery_title = sample.discovery_label()
                if not discovery_title.is_empty():
                    var gradient: Array[Color] = sample.glow_gradient_colors()
                    spectral_color = gradient[0]
                    spectral_accent = gradient[1]
            # Floor loot reveals the item's rolled *cosmetic signature* before
            # pickup, but never changes rarity or its drop probability.
            if sample.get_slot() in ["sword", "wand"]:
                var appearance: Dictionary = sample.effect_rolls()
                spectral_tier = int(appearance["tier"])
                spectral_motif = int(appearance["motif"])
                spectral_trail = int(appearance["trail"])
                spectral_color = GhostWeaponFXLibrary.color(int(appearance["color"]))
                spectral_accent = GhostWeaponFXLibrary.color(int(appearance["accent"]))
                spectral_label = GhostWeaponFXLibrary.trail_name(spectral_trail)
                if sample.quality in ["set", "unique"] or (sample.quality == "rare" and GhostWeaponFXLibrary.prestige_variant(sample.item_seed, sample.quality) >= 0):
                    rare_signature = posmod(absi(sample.item_seed) * 7 + 131, 6)
        add_to_group("interactable")
        add_to_group("world_loot")

func _process(delta: float) -> void:
    time_counter += delta
    if not Engine.is_editor_hint():
        var girl: Node2D = get_tree().get_first_node_in_group("ghost_girl_player") as Node2D
        near_player = girl != null and girl.global_position.distance_to(global_position) <= 190.0
    queue_redraw()

func _draw() -> void:
    var flicker: float = 0.60 + sin(time_counter * 2.7) * 0.10
    draw_circle(Vector2(0, -12), 25.0, Color(aura.r, aura.g, aura.b, 0.12 * flicker))
    draw_line(Vector2(0, -9), Vector2(0, -68), Color(aura.r, aura.g, aura.b, 0.20 * flicker), 8.0, true)
    draw_circle(Vector2(0, -9), 8.0, aura)
    draw_arc(Vector2(0, -9), 13, 0, TAU, 24, Color(aura.r, aura.g, aura.b, flicker), 2.2, true)
    if spectral_tier >= 0:
        var count: int = 3 + spectral_tier * 2
        var radius: float = 13.0 + float(spectral_trail) * 1.7
        for i in range(count):
            var theta: float = time_counter * (0.45 + float(spectral_trail) * 0.13) + float(i) * TAU / float(count)
            var location: Vector2 = Vector2.from_angle(theta) * radius + Vector2(0, -12)
            var tint: Color = spectral_color if i % 2 == 0 else spectral_accent
            var opacity: float = (0.16 + 0.20 * sin(time_counter * 2.5 + float(i))) * (0.45 + 0.1 * float(spectral_tier))
            var ink: Color = Color(tint.r, tint.g, tint.b, maxf(0.06, opacity))
            if spectral_motif % 3 == 0:
                draw_circle(location, 1.9 + float(i % 2), ink)
            elif spectral_motif % 3 == 1:
                draw_line(location - Vector2(2, 0), location + Vector2(2, 0), ink, 1.2, true)
                draw_line(location - Vector2(0, 2), location + Vector2(0, 2), ink, 1.2, true)
            else:
                draw_arc(location, 2.5, 0.0, PI * 1.7, 9, ink, 1.2, true)
        if spectral_tier >= 2:
            draw_arc(Vector2(0, -10), 20.0 + sin(time_counter * 2.0) * 2.0, 0.0, TAU, 32, Color(spectral_accent.r, spectral_accent.g, spectral_accent.b, 0.22 + flicker * 0.12), 1.5, true)
    if rare_signature >= 0:
        # Six collectible-looking projections, reserved for rare prestige rolls.
        # These are animated linework only: no additional loot, light nodes,
        # damaging projectiles or collision objects.
        var center: Vector2 = Vector2(0, -15)
        var phase: float = time_counter * (0.52 + 0.08 * float(rare_signature))
        var primary: Color = Color(spectral_color.r, spectral_color.g, spectral_color.b, 0.54)
        var secondary: Color = Color(spectral_accent.r, spectral_accent.g, spectral_accent.b, 0.48)
        match rare_signature:
            0: # Double lunar wreath.
                draw_arc(center, 35.0, phase, phase + PI * 1.38, 40, primary, 2.0, true)
                draw_arc(center, 27.0, -phase, -phase + PI * 1.30, 38, secondary, 1.5, true)
            1: # Petal carousel.
                for j in range(9):
                    var a: float = phase + float(j) * TAU / 9.0
                    var v: Vector2 = Vector2.from_angle(a) * (32.0 + 4.0 * sin(phase * 2.0 + float(j)))
                    draw_circle(center + v, 2.8, primary if j % 2 == 0 else secondary)
            2: # Frost-lace spires.
                for j in range(6):
                    var a: float = phase * 0.45 + float(j) * TAU / 6.0
                    var v: Vector2 = Vector2.from_angle(a) * 31.0
                    draw_line(center + v * 0.60, center + v * 1.34, primary, 1.5, true)
                    draw_circle(center + v * 1.34, 2.2, secondary)
            3: # Prismatic cross-star.
                for j in range(4):
                    var a: float = phase + float(j) * PI * 0.5
                    var v: Vector2 = Vector2.from_angle(a) * (29.0 + 6.0 * sin(phase * 1.7))
                    draw_line(center, center + v, secondary, 1.3, true)
                    draw_circle(center + v, 2.6, primary)
            4: # Thorned constellation.
                var vertices: PackedVector2Array = PackedVector2Array()
                for j in range(7):
                    vertices.append(center + Vector2.from_angle(phase * 0.35 + float(j) * TAU / 7.0) * 35.0)
                vertices.append(vertices[0])
                draw_polyline(vertices, secondary, 1.4, true)
                for point in vertices:
                    draw_circle(point, 2.0, primary)
            _: # Eclipse halo.
                draw_arc(center, 36.0, phase, phase + PI * 1.70, 40, secondary, 2.6, true)
                draw_arc(center + Vector2(6, -5), 28.0, -phase * 0.68, -phase * 0.68 + PI * 1.25, 36, primary, 1.8, true)
    if not discovery_title.is_empty():
        var phase: float = time_counter * 0.48
        var ink: Color = spectral_color.lerp(spectral_accent, 0.5 + 0.5 * sin(phase))
        ink.a = 0.48
        draw_arc(Vector2(0,-16), 43.0, phase, phase + PI * 1.28, 40, ink, 1.6, true)
        for i in range(4):
            var p: Vector2 = Vector2(0,-16) + Vector2.from_angle(phase + float(i) * TAU / 4.0) * 43.0
            draw_line(p - Vector2(3,0), p + Vector2(3,0), ink, 1.1, true)
            draw_line(p - Vector2(0,3), p + Vector2(0,3), ink, 1.1, true)
        if near_player:
            draw_string(ThemeDB.fallback_font, Vector2(-140,-103), discovery_title, HORIZONTAL_ALIGNMENT_CENTER, 280.0, 11, Color("d5c0eb"))
    if near_player and not Engine.is_editor_hint():
        draw_string(ThemeDB.fallback_font, Vector2(-112, -83), display_title, HORIZONTAL_ALIGNMENT_CENTER, 224.0, 13, Color(aura.r, aura.g, aura.b, 0.82))
        if spectral_tier >= 2:
            draw_string(ThemeDB.fallback_font, Vector2(-112, -66), spectral_label, HORIZONTAL_ALIGNMENT_CENTER, 224.0, 10, spectral_accent)
