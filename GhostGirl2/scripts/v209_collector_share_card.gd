extends RefCounted
## Offline-only textual item showcase. No save writes or ownership claims.
## This is a snapshot of the current, non-debug collectible appearance.
const ROLL = preload("res://scripts/collector_roll_code_v1931.gd")

static func compose(item: GhostItemInstance) -> String:
	if item == null or item.definition == null:
		return ""
	var lines: Array[String] = [
		"GHOST GIRL · COLLECTOR CARD",
		item.display_name(),
		"Quality: %s · Family: %s" % [item.quality.capitalize(), item.get_slot().replace("_", " ").capitalize()],
		"Material: " + item.collector_material_label()
	]
	if not item.origin_label().is_empty():
		lines.append("Found in: " + item.origin_label())
	if item.item_level > 0:
		lines.append("Item level: %d" % item.item_level)
	var roll: String = ROLL.current(item)
	if not roll.is_empty():
		lines.append("Current appearance roll: " + roll)
		lines.append("Original appearance roll: " + (item.birth_roll_code_v1 if ROLL.valid_code(item.birth_roll_code_v1) else "unknown (legacy)"))
	var appearance: String = item.cosmetic_uid if not item.cosmetic_uid.is_empty() else "legacy-%d" % item.visual_seed()
	lines.append("Appearance: GG1:%s:%s" % [item.definition.item_id, appearance])
	if item.sockets > 0:
		lines.append("Sockets: %d/%d" % [item.socketed.size(), item.sockets])
	if item.ethereal:
		lines.append("Ethereal: " + ("broken" if item.is_broken() else "%d/%d durability" % [item.durability, item.max_durability]))
	if item.collector_favorite:
		lines.append("Marked as a favorite")
	if ROLL.debug_active(item):
		lines.append("WARNING: TEST EFFECTS ACTIVE (not a genuine rare discovery)")
	lines.append("Offline collection snapshot · self-reported, not verified ownership or rarity.")
	return "\n".join(lines)
