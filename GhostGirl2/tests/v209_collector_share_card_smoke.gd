extends SceneTree
## v2.09 offline share-card smoke. Synthetic in-memory items only.
const CARD = preload("res://scripts/v209_collector_share_card.gd")
const INV = preload("res://scripts/inventory.gd")
const LENS = preload("res://scripts/collector_lens_v179.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var weapon: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	var accessory: GhostItemData = load("res://items/v202_luminous_eyes.tres") as GhostItemData
	if weapon == null or accessory == null:
		_fail("Missing known equipment definitions")
		return
	var item: GhostItemInstance = inv.generate_find(weapon, 209017, "rare", "moonwake_crypt")
	item.collector_favorite = true
	item.collector_locked = true
	var previous: Dictionary = inv._serialize_item(item, Vector2i.ZERO)
	var card: String = CARD.compose(item)
	if not card.contains(item.display_name()) or not card.contains(item.definition.item_id):
		_fail("Card lost actual collectible identity")
		return
	if not card.contains("Found in: ") or not card.contains(item.origin_label()):
		_fail("Card dropped source location")
		return
	if not card.contains("Current appearance roll: ") or not card.contains("Original appearance roll: "):
		_fail("Card does not separate current and birth rolls")
		return
	if not card.contains("not verified ownership or rarity") or card.contains("1 of 1"):
		_fail("Card exaggerates offline rarity or ownership")
		return
	if inv._serialize_item(item, Vector2i.ZERO) != previous:
		_fail("Building a card modified the saved item")
		return
	var eyes: GhostItemInstance = GhostItemGenerator.create(accessory, 209018, "magic")
	eyes.birth_roll_code_v1 = ""
	var eye_record: Dictionary = inv._serialize_item(eyes, Vector2i(1,0))
	var eye_card: String = CARD.compose(eyes)
	if eye_card.is_empty() or not eye_card.contains("Family: Wings") or eye_card.contains("Current appearance roll: "):
		_fail("Accessory card invented unsupported weapon roll")
		return
	if inv._serialize_item(eyes, Vector2i(1,0)) != eye_record:
		_fail("Creating accessory card changed collectible")
		return
	item.debug_visual_override = 5
	if OS.is_debug_build() and not CARD.compose(item).contains("TEST EFFECTS ACTIVE"):
		_fail("Debug appearance was not disclosed")
		return
	var lens: Control = LENS.new()
	root.add_child(lens)
	lens.open_item(item)
	if not lens.visible or not lens.has_method("_copy_card"):
		_fail("Collector's Lens did not expose the card action")
		return
	lens.close_lens()
	lens.free()
	inv.free()
	print("v2.09 PASS: readable offline collector card, original/current roll, accessory, provenance, debug warning and no mutation")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
