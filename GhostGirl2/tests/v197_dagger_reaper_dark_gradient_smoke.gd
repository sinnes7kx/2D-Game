extends SceneTree
## v1.97: presentation-only regressions; no item RNG/stat mutation.
const RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const STEADY = preload("res://scripts/steady_weapon_idles_v195.gd")
const SCYTHE = preload("res://scripts/scythe_art_v190.gd")
const INVENTORY = preload("res://scripts/inventory.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var uid: String = "1234567890abcdef1234567890abcdef"
    var seed: int = 197197
    var channel: String = "effect:0:0:0:0"
    var old: Array[Color] = RNG.gradient_for_channel(uid, seed, channel)
    if old != RNG.gradient_for_channel(uid, seed, channel, 1):
        _fail("Old palette algorithm changed")
        return
    var expanded: Array[Color] = RNG.gradient_for_channel(uid, seed, channel, 2)
    if expanded != RNG.gradient_for_channel(uid, seed, channel, 2) or expanded.size() < 3 or expanded.size() > 9:
        _fail("V2 dark gradients must be deterministic and complete")
        return
    var observed_black: bool = false
    var observed_dark: bool = false
    for i in range(128):
        var candidate: String = str(i).pad_zeros(32)
        var gradient: Array[Color] = RNG.gradient_for_channel(candidate, seed, channel, 2)
        for ink in gradient:
            observed_black = observed_black or ink.get_luminance() < 0.009
            observed_dark = observed_dark or ink.get_luminance() < 0.11
    if not observed_black or not observed_dark:
        _fail("Expanded spectrum cannot roll black/charcoal")
        return

    var definition: GhostItemData = load("res://items/rose_reaper_scythe.tres") as GhostItemData
    var item: GhostItemInstance = GhostItemGenerator.create(definition, seed, "rare")
    item.apply_cosmetic_uid(uid)
    var expected_legacy_glow: Array[Color] = RNG.gradient_for_channel(item.cosmetic_uid, item.visual_seed(), item.effect_palette_channel(), 1)
    if item.gradient_version != 1 or item.glow_gradient_colors() != expected_legacy_glow:
        _fail("Legacy object was not v1 by default")
        return
    var inv: Node = INVENTORY.new()
    var legacy: Dictionary = inv._serialize_item(item, Vector2i.ZERO)
    legacy.erase("gradient_version")
    var restored_legacy: GhostItemInstance = inv._deserialize_item(legacy)
    if restored_legacy == null or restored_legacy.gradient_version != 1 or restored_legacy.glow_gradient_colors() != expected_legacy_glow:
        _fail("Legacy save silently recolored")
        return
    item.gradient_version = 2
    var stats: Dictionary = item.all_stats()
    var item_seed: int = item.item_seed
    var cosmetic_snapshot: Dictionary = item.cosmetic_snapshot()
    if not cosmetic_snapshot.has("gradient_version"):
        _fail("Favorite look omitted gradient version")
        return
    if not item.save_cosmetic_look():
        _fail("Could not save dark look")
        return
    var saved_v2: Dictionary = inv._serialize_item(item, Vector2i.ZERO)
    var restored: GhostItemInstance = inv._deserialize_item(saved_v2)
    if restored == null or restored.gradient_version != 2 or restored.glow_gradient_colors() != item.glow_gradient_colors():
        _fail("New dark appearance failed save/load roundtrip")
        return
    if restored.item_seed != item_seed or restored.all_stats() != stats:
        _fail("Cosmetic version affected weapon stats")
        return
    restored.gradient_version = 1
    if not restored.restore_cosmetic_look(0) or restored.gradient_version != 2 or restored.glow_gradient_colors() != item.glow_gradient_colors():
        _fail("Saved cosmetic look failed to restore its gradient version")
        return

    # Reaper must glow visibly even when its seeded pigment is fully black.
    var dark_colors: Array[Color] = [Color.BLACK, Color.BLACK, Color.BLACK]
    var rim: Color = SCYTHE.reaper_edge_tint(dark_colors, {}, 0.0)
    if rim.get_luminance() < 0.18 or not SCYTHE.matches("scythe_idle_front"):
        _fail("Reaper edge illumination not visible for black pigment")
        return

    var fresh: GhostItemInstance = inv.generate_find(definition, seed + 1, "rare", "moonwake_crypt")
    if fresh == null or fresh.gradient_version != 2:
        _fail("New equipment drops do not opt into expanded gradients")
        return
    var actor: Node = (load("res://scenes/player.tscn") as PackedScene).instantiate()
    root.add_child(actor)
    var ghost: AnimatedSprite2D = actor.get_node("Ghost") as AnimatedSprite2D
    for family in ["dagger_idle_", "nocturne_dagger_idle_"]:
        for face in ["front", "back", "left", "right"]:
            var name: String = family + face
            if not STEADY.matches(name) or not ghost.sprite_frames.has_animation(name) or ghost.sprite_frames.get_frame_count(name) != 16:
                _fail("Dagger idle not stabilized: " + name)
                return
            if not is_equal_approx(16.0 / ghost.sprite_frames.get_animation_speed(name), STEADY.CYCLE_SECONDS):
                _fail("Dagger idle was not slowed: " + name)
                return
    actor.free()
    inv.free()
    print("v1.97 PASS: 8 smooth dagger idles, readable Reaper edge, black/dark deterministic v2, legacy and saved-look compatibility")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
