extends RefCounted
## Local discovery journal. Original cosmetic roll only; never ownership proof.
const ROLL = preload("res://scripts/collector_roll_code_v1931.gd")
const LIMIT: int = 100

# Rank by rarest recorded channel, then other channels in ascending order.
# This is an ordinal comparison, not a joint probability or global ranking.
static func rank(code: String) -> String:
	if not ROLL.valid_code(code):
		return "99999"
	var digits: Array[String] = []
	for i in range(5):
		var digit: String = code.substr(i,1)
		digits.append("9" if digit == "-" else digit)
	digits.sort()
	return "".join(digits)

static func add_find(records: Array, item: GhostItemInstance) -> void:
	if item == null or item.definition == null or item.origin_room.is_empty() or item.birth_roll_uid_v1.is_empty() or not ROLL.valid_code(item.birth_roll_code_v1):
		return
	if ROLL.debug_active(item):
		return
	for entry in records:
		if entry is Dictionary and str(entry.get("uid","")) == item.birth_roll_uid_v1:
			return
	records.append({"uid":item.birth_roll_uid_v1,"code":item.birth_roll_code_v1,"name":item.display_name(),"origin":item.origin_room,"resource":item.definition.resource_path})
	records.sort_custom(earlier)
	if records.size() > LIMIT:
		records.resize(LIMIT)

static func earlier(a: Dictionary,b: Dictionary) -> bool:
	var left: String = rank(str(a.get("code","")))
	var right: String = rank(str(b.get("code","")))
	return str(a.get("uid","")) < str(b.get("uid","")) if left == right else left < right

static func restore(raw: Variant) -> Array:
	var result: Array = []
	if not raw is Array:
		return result
	for entry in raw:
		if entry is Dictionary and ROLL.valid_code(str(entry.get("code",""))) and not str(entry.get("uid","")).is_empty():
			result.append(entry.duplicate(true))
	result.sort_custom(earlier)
	if result.size() > LIMIT:
		result.resize(LIMIT)
	return result
