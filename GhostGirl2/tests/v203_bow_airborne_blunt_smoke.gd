extends SceneTree
## v2.03: genuine player scene, 4-facing bow pivots with a cosmetic reroll,
## dedicated air attack clips, higher traversal arc and blunt item integrity.
const PLAYER: PackedScene = preload("res://scenes/player.tscn")
const BOW = preload("res://scripts/bow_palette_overlay_v139.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const AIR = preload("res://scripts/airborne_attacks_v203.gd")
const BLUNT = preload("res://scripts/blunt_weapon_family_v203.gd")
const GAME = preload("res://scripts/game.gd")

class FakeInventory extends Node:
    signal equipment_changed
    signal contents_changed
    var item: GhostItemInstance = null
    func get_equipped(slot: String) -> GhostItemInstance:
        return item if slot == "sword" else null
    func get_stat_total(_id: String) -> float:
        return 0.0

class FakeWorld extends Node:
    var inventory: Node = null

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var actor: CharacterBody2D = PLAYER.instantiate() as CharacterBody2D
    actor.set("equipment_preview_only", true)
    root.add_child(actor)
    var body: AnimatedSprite2D = actor.get_node("Ghost") as AnimatedSprite2D
    var mask: AnimatedSprite2D = body.get_node("BowPaletteV139") as AnimatedSprite2D
    var physical: AnimatedSprite2D = body.get_node("BowCarryV166") as AnimatedSprite2D
    var fx: Node2D = body.get_node("EquippedPrestigeFX") as Node2D
    if mask == null or physical == null or fx == null:
        _fail("Player loses its actual physical bow, mask, or child FX")
        return
    var fake: FakeInventory = FakeInventory.new()
    root.add_child(fake)
    for bow_id in ["thornrose_bow", "moonveil_bow"]:
        var base: GhostItemData = load("res://items/" + bow_id + ".tres") as GhostItemData
        fake.item = GhostItemGenerator.create(base, 203080, "rare")
        mask.call("bind_inventory", fake)
        fx.set("item", fake.item)
        fx.call("_sync_transform_parent")
        if fx.get_parent() != mask:
            _fail("Bow FX not parented to recolorable bow mask")
            return
        for face in ["front", "back", "left", "right"]:
            var pose: Dictionary = BOW.idle_hold_pose(face)
            var original: Vector2 = HAND.hand_anchor(face, 0, 0 if face == "left" else 1)
            if original == Vector2.INF:
                original = Vector2(34, 27)
            var correction: Vector2 = BOW.WRIST_CORRECTIONS_V203[face]
            if (pose["hand"] as Vector2).distance_to(original + correction) > 0.01:
                _fail("Calibrated physical bow hand off the authored wrist: " + face)
                return
            var handle: Vector2 = pose["position"] + (pose["source_handle"] as Vector2).rotated(deg_to_rad(float(pose["rotation_deg"])))
            if handle.distance_to(pose["hand"]) > 0.01:
                _fail("Actual bow handle is detached on " + face)
                return
            var animation: String = bow_id.trim_suffix("_bow") + "_idle_" + face
            if not bool(mask.call("_show_idle_bow", fake.item, animation)):
                _fail("Cannot display real original bow carrying artwork: " + animation)
                return
            var position_before: Vector2 = mask.position
            var rotation_before: float = mask.rotation_degrees
            fake.item.cosmetic_seed += 11
            mask.call("refresh")
            mask.call("_show_idle_bow", fake.item, animation)
            if mask.position.distance_to(position_before) > 0.01 or not is_equal_approx(rotation_before, mask.rotation_degrees):
                _fail("Cosmetic color reroll changed physical bow grip")
                return
            if mask.position.distance_to(physical.position) > 0.01 or mask.rotation_degrees != physical.rotation_degrees:
                _fail("Recolored mask and actual bow drift apart on " + face)
                return
            if fx.to_global(Vector2(7, -18)).distance_to(mask.to_global(Vector2(7, -18))) > 0.01:
                _fail("Weapon FX stopped inheriting the same bow grip/pivot")
                return
    # Four directions and all supported heavy weapon families have a distinct
    # eight-frame airborne animation without modifying approved ground poses.
    var families: Array[String] = [
        "sword", "scythe", "halberd", "dagger", "dual_dagger",
        "dual_sword", "spear", "maul", "ashglass_maul",
        "twinblade", "thornrose", "moonveil", "unarmed"
    ]
    for family in families:
        for face in ["front", "back", "left", "right"]:
            var found: bool = false
            for clip in body.sprite_frames.get_animation_names():
                var original: String = str(clip)
                if original.begins_with("attack_" + family + "_") and original.contains("_heavy_") and original.ends_with("_" + face) and not original.contains("_air_"):
                    var air: String = AIR.air_name(original)
                    if not body.sprite_frames.has_animation(air) or body.sprite_frames.get_frame_count(air) != 8:
                        _fail("Airborne clip missing or not eight frames: " + air)
                        return
                    if AIR.base_name(air) != original:
                        _fail("Airborne clip no longer maps to the source weapon's frame guide")
                        return
                    found = true
                    break
            if not found:
                _fail("No authored heavy attack to convert to airborne: " + family + "/" + face)
                return
    for style in ["thornrose", "moonveil"]:
        for face in ["front", "back", "left", "right"]:
            var airborne_light: String = AIR.air_name("attack_" + style + "_light_" + face)
            if not body.sprite_frames.has_animation(airborne_light):
                _fail("Short airborne bow shot has no dedicated animation: " + airborne_light)
                return
    var apex: Dictionary = AIR.airborne_pose(0.5, false, 1.0)
    var striking_apex: Dictionary = AIR.airborne_pose(0.5, true, 1.0)
    if float(apex["height"]) <= 30.0 or float(striking_apex["height"]) <= float(apex["height"]):
        _fail("Jump apex did not rise higher, or airborne windup lacks distinction")
        return
    # The jump pose comes from a shared, deterministic helper; do not use
    # object.get() for a GDScript const (constants are not live properties).
    for base_name in ["v203_mournful_mace", "v203_rosequartz_morningstar", "v203_nightchain_flail"]:
        var definition: GhostItemData = load("res://items/" + base_name + ".tres") as GhostItemData
        if definition == null or definition.icon == null or definition.weapon_style != "maul":
            _fail("Blunt base or inventory icon unavailable: " + base_name)
            return
        var item: GhostItemInstance = GhostItemGenerator.create(definition, 203051, "rare")
        if item.physical_damage_kind() != "blunt" or item.weapon_damage() <= 0.0 or BLUNT.kind_from_id(base_name).is_empty():
            _fail("Item lost proper blunt identity or real damage stats: " + base_name)
            return
        var saved_seed: int = item.item_seed
        var power: float = item.weapon_damage()
        item.cosmetic_seed = 123456
        if saved_seed != item.item_seed or not is_equal_approx(power, item.weapon_damage()):
            _fail("Changing appearance modified blunt damage or the original seed")
            return
    var old_maul: GhostItemInstance = GhostItemGenerator.create(load("res://items/gravebell_maul_v170.tres") as GhostItemData, 203011, "rare")
    if old_maul.physical_damage_kind() != "blunt" or not BLUNT.kind_from_id(old_maul.definition.item_id).is_empty():
        _fail("Original maul damage kind or silhouette changed")
        return
    # A bow aerial action cannot accidentally invoke a second, invisible
    # jump-melee strike while the genuine arrow is being drawn/released.
    var fake_world: FakeWorld = FakeWorld.new()
    fake_world.inventory = fake
    root.add_child(fake_world)
    actor.set("world", fake_world)
    actor.call("_begin_jump")
    if float(actor.get("jump_duration")) < 0.60:
        _fail("Jump duration was not raised")
        return
    actor.set("jump_time_left", 0.29)
    actor.set("jump_duration", 0.62)
    actor.set("jump_attack_active", true)
    actor.set("jump_attack_triggered", false)
    actor.call("_advance_jump", 0.04)
    if not bool(actor.get("jump_attack_triggered")) or bool(actor.get("attack_hit_done")):
        _fail("Aerial bow skipped its trigger policy or registered an invisible melee hit")
        return
    actor.set("world", null)
    fake_world.free()
    var game: Node2D = GAME.new() as Node2D
    var dropped: GhostItemData = game.call("_roll_sword_drop", load("res://items/dusk_needle.tres"), 41)
    if dropped == null or BLUNT.kind_from_id(dropped.item_id).is_empty():
        _fail("New ordinary monster drop lane cannot yield any blunt base")
        return
    var historical: GhostItemData = game.call("_roll_sword_drop", load("res://items/dusk_needle.tres"), 14) as GhostItemData
    var original_third: GhostItemData = load("res://items/vesper_rapier.tres") as GhostItemData
    if historical == null or original_third == null or historical.item_id != original_third.item_id:
        _fail("Existing 1/7 sword seed mapping was reindexed")
        return
    game.free()
    actor.free()
    fake.free()
    print("v2.03 PASS: calibrated 4-face bows across rerolls, parented FX, all airborne clips, higher jumps, authentic blunt loot and unchanged original seed/stat")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
