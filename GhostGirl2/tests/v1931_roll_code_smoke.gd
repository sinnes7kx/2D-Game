extends SceneTree
const JOURNAL = preload("res://scripts/codex_discoveries.gd")
const CODE = preload("res://scripts/collector_roll_code_v1931.gd")
const LOOK = preload("res://scripts/collector_appearance_v177.gd")
const SURFACE = preload("res://scripts/living_metal_v187.gd")
const INV = preload("res://scripts/inventory.gd")
const MARKUP = preload("res://scripts/item_rich_text.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var counts: Array[int] = [0,0,0,0,0,0,0]
	var surface_counts: Array[int] = [0,0,0,0,0,0,0]
	for ticket in range(10000):
		var tier: int = LOOK.tier_for_ticket(ticket)
		counts[tier] += 1
		for material in range(7):
			var mode: int = SURFACE.surface_for_ticket(ticket,material)
			surface_counts[mode] += 1
			if mode > mini(material+1,6):
				_fail("Surface rarity gate changed")
				return
	if counts != LOOK.COUNTS or not CODE.valid_code("00000-----") or CODE.valid_code("0000000000") or CODE.valid_code("0123"):
		_fail("Tier boundaries or versioned leading-zero validation failed")
		return
	var inv: Node = INV.new()
	var base: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	var item: GhostItemInstance = inv.generate_find(base,193101,"rare","moonwake_crypt")
	var born: String = item.birth_roll_code_v1
	var uid: String = item.birth_roll_uid_v1
	var journal: Array = []
	JOURNAL.add_find(journal,item)
	JOURNAL.add_find(journal,item)
	assert(journal.size()==1 and journal[0]["code"]==born)
	assert(JOURNAL.rank("09999-----") < JOURNAL.rank("19999-----"))
	var stats: Dictionary = item.all_stats()
	var original: Dictionary = item.cosmetic_snapshot()
	if not CODE.valid_code(born) or CODE.current(item) != born or uid != item.cosmetic_uid or not MARKUP.item_info(item,true).contains(born):
		_fail("Newly generated item did not record or show the original code")
		return
	item.debug_collector_tier = 6
	item.debug_visual_override = 5
	item.debug_surface_mode = 6
	if CODE.current(item) != born or item.birth_roll_code_v1 != born or item.cosmetic_snapshot() != original:
		_fail("Debug testing changed genuine rarity fingerprint")
		return
	if OS.is_debug_build() and not MARKUP.item_info(item,true).contains("TEST FX active"):
		_fail("Debug tooltip missing test notice")
		return
	item.debug_collector_tier = -1
	item.debug_visual_override = -1
	item.debug_surface_mode = -1
	item.collector_favorite = true
	item.collector_locked = true
	if not item.save_cosmetic_look():
		_fail("Could not save original appearance")
		return
	item.apply_cosmetic_uid("fedcba9876543210fedcba9876543210")
	var current: String = CODE.current(item)
	JOURNAL.add_find(journal,item)
	assert(journal.size()==1 and journal[0]["code"]==born)
	assert(JOURNAL.restore(JSON.parse_string(JSON.stringify(journal)))==journal)
	if not CODE.valid_code(current) or item.birth_roll_code_v1 != born or item.birth_roll_uid_v1 != uid or item.all_stats() != stats:
		_fail("Reroll changed original code or combat stats")
		return
	var serialized: Dictionary = inv._serialize_item(item,Vector2i.ZERO)
	var restored: GhostItemInstance = inv._deserialize_item(JSON.parse_string(JSON.stringify(serialized)))
	if restored == null or restored.birth_roll_code_v1 != born or CODE.current(restored) != current or restored.all_stats()!=stats or not restored.collector_locked or not restored.collector_favorite:
		_fail("Serialization lost code, stats or collector flags")
		return
	if not restored.restore_cosmetic_look(0) or CODE.current(restored)!=born or restored.birth_roll_code_v1!=born:
		_fail("Saved look did not reproduce original code")
		return
	inv.contents.append(restored)
	inv.grid_positions.append(Vector2i.ZERO)
	if not inv.vault_store(0,false) or not inv.set_exhibition(restored,0,false) or not inv.vault_withdraw(0,false) or inv.contents[0]!=restored or restored.birth_roll_code_v1!=born:
		_fail("Stash or exhibition transfer changed item identity")
		return
	serialized.erase("birth_roll_code_v1")
	serialized.erase("birth_roll_uid_v1")
	var legacy: GhostItemInstance = inv._deserialize_item(serialized)
	if legacy == null or not legacy.birth_roll_code_v1.is_empty() or CODE.current(legacy)!=current or not MARKUP.item_info(legacy,true).contains("unknown (legacy)"):
		_fail("Legacy item invented birth history or changed current roll")
		return
	if not CODE.share(restored).contains("birth="+born):
		_fail("Copyable rarity fingerprint missing birth code")
		return
	inv.free()
	print("v1.93.1 PASS: rarity boundaries, leading zeros, original/current/debug separation, legacy, saved looks and stash round-trip")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
