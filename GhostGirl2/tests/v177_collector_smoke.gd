extends SceneTree
const LOOK = preload("res://scripts/collector_appearance_v177.gd")

func _initialize() -> void:
	var counts: Array[int] = [0, 0, 0, 0, 0, 0, 0]
	for ticket in range(10000):
		counts[LOOK.tier_for_ticket(ticket)] += 1
	if counts != LOOK.COUNTS:
		push_error("Collector rarity boundaries incorrect")
		quit(1)
		return
	var uid: String = "0123456789abcdef0123456789abcdef"
	var first: Dictionary = LOOK.roll(uid, 123)
	if first != LOOK.roll(uid, 999):
		push_error("Saved UID appearance changed with gameplay seed")
		quit(1)
		return
	if LOOK.roll("", 123) != LOOK.roll("", 123):
		push_error("Legacy appearance is not stable")
		quit(1)
		return
	var patterns: Dictionary = {}
	var pairs: Dictionary = {}
	for n in range(512):
		var look: Dictionary = LOOK.roll("%032x" % n, 1)
		patterns[look["pattern"]] = true
		pairs["%s:%s" % [look["material"], look["particle_tier"]]] = true
	if patterns.size() != 11 or pairs.size() < 5:
		push_error("Independent cosmetic channels do not vary")
		quit(1)
		return
	print("v1.77 PASS: exact rarity buckets, deterministic UID and legacy looks, independent channels")
	quit(0)
