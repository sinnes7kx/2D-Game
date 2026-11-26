extends SceneTree
## v2.14: keep the original scythe edge glow even when its separate
## silhouette aura legitimately rolls zero. Purely synthetic, no user:// writes.
const SCYTHE_AURA = preload("res://scripts/scythe_glow_layer_v211.gd")
const FX_LEVEL = preload("res://scripts/fx_intensity_v1924.gd")
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")
const LENS = preload("res://scripts/collector_lens_v179.gd")
const INV = preload("res://scripts/inventory.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var source_world: String = FileAccess.get_file_as_string("res://scripts/scythe_rig_v190.gd")
	var source_model: String = FileAccess.get_file_as_string("res://scripts/collector_lens_model_v179.gd")
	if not source_world.contains("var show_light: bool = equipped == null or equipped.glow_level_override != 0"):
		_fail("World scythe lost its independent curved-blade effects")
		return
	if not source_model.contains("glow_enabled and CHOICES_V216.effect_scale(item) > 0.0)"):
		_fail("Inspect scythe no longer follows Illumination setting")
		return
	var base: GhostItemData = load("res://items/rose_reaper_scythe.tres") as GhostItemData
	if base == null:
		_fail("Missing real scythe fixture")
		return
	var inv: Node = INV.new()
	var scythe: GhostItemInstance = GhostItemGenerator.create(base, 214018, "rare")
	scythe.apply_cosmetic_uid("abcdef0123456789abcdef0123456789")
	var before: Dictionary = inv._serialize_item(scythe, Vector2i.ZERO)
	var original_intensity: float = FX_LEVEL.intensity
	FX_LEVEL.set_intensity(1.0)
	var model: Node2D = MODEL.new()
	root.add_child(model)
	model.call("set_item", scythe)
	model.call("set_glow_preview_override", 0)
	await process_frame
	var aura: Node2D = model.get_node("ScytheGlowLayerV211") as Node2D
	if aura == null or aura.visible or int(aura.get("level")) != 0:
		_fail("Zero aura should stay invisible while separate blade rim is available")
		return
	model.call("set_glow_preview_override", 5)
	await process_frame
	if not aura.visible or int(aura.get("level")) != 5 or not is_equal_approx(SCYTHE_AURA.opacity(5), 0.5):
		_fail("50% inspection aura unavailable")
		return
	var old_rev: int = int(aura.get("last_fx_revision"))
	FX_LEVEL.set_intensity(0.5)
	aura.call("set_pose", scythe, aura.get("grip"), aura.get("head"), aura.get("profile"), aura.get("side"), 5)
	if int(aura.get("last_fx_revision")) == old_rev:
		_fail("Scythe aura did not respond to display intensity changes")
		return
	FX_LEVEL.set_intensity(original_intensity)
	var lens: Control = LENS.new()
	root.add_child(lens)
	lens.call("open_item", scythe)
	if not (lens.get("status") as Label).text.to_lower().contains("blade highlights"):
		_fail("Collector Lens must explain the two independent FX layers")
		return
	lens.call("close_lens")
	if inv._serialize_item(scythe, Vector2i.ZERO) != before:
		_fail("Display FX changed saved item stats or cosmetic identity")
		return
	lens.free()
	model.free()
	inv.free()
	print("v2.14 PASS: classic blade rim independent of optional aura, 0/50% preview, FX refresh and item unchanged")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
