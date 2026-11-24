extends RefCounted
## Regional origin is immutable provenance, independent of combat quality.
## A regional imprint is rolled once on acquisition, not when equipping.
const LOOK = preload("res://scripts/collector_appearance_v177.gd")
const REGIONS = {
	"moonwake_crypt": ["Moonwake Crypt", "Spectral Steel", "b3c9e5", "796fae", 4],
	"hollow_veil_moor": ["Hollow Veil Moor", "Mistweave", "a1c9c5", "647d91", 7],
	"ashglass_vault": ["Ashglass Vault", "Emberglass", "f4a570", "58334c", 3],
	"briar_hollow": ["Briar Hollow", "Living Briar", "c8d9a3", "a55b82", 2],
	"observatory": ["Starfall Observatory", "Astral Filigree", "d7c1ff", "5667b4", 6],
	"lily_pond": ["Lily Mirror Pool", "Iridescent Waterglass", "a2e3e7", "cba2de", 5]
}
# 20% regional imprint; 4% of all eligible drops have a deeper imprint,
# 0.5% have a radiant imprint. These are independent of existing rarity.
static func rank_for_ticket(ticket: int) -> int:
	if ticket >= 9950:
		return 3
	if ticket >= 9600:
		return 2
	if ticket >= 8000:
		return 1
	return 0

static func roll_rank(room: String, uid: String, seed: int) -> int:
	if not REGIONS.has(room):
		return 0
	return rank_for_ticket(LOOK.ticket(uid, seed, "v183-origin:" + room))

static func origin_label(room: String) -> String:
	return str(REGIONS[room][0]) if REGIONS.has(room) else room.replace("_", " ").capitalize()

static func imprint_label(room: String, rank: int) -> String:
	if rank <= 0 or not REGIONS.has(room):
		return ""
	return ["", "", "Deep ", "Radiant "][clampi(rank, 0, 3)] + str(REGIONS[room][1])

static func apply(look: Dictionary, room: String, rank: int) -> Dictionary:
	if rank <= 0 or not REGIONS.has(room):
		return look
	var data: Array = REGIONS[room]
	look["region"] = room
	look["region_rank"] = clampi(rank, 1, 3)
	look["region_color"] = Color(str(data[2]))
	look["region_shadow"] = Color(str(data[3]))
	look["region_motif"] = int(data[4])
	var metals: Array[Color] = []
	var accents: Array[Color] = []
	var original_metals: Array = look.get("metal_colors", [])
	var original_accents: Array = look.get("accent_colors", [])
	var weight: float = 0.25 + 0.12 * float(rank)
	for i in range(original_metals.size()):
		var original: Color = original_metals[i]
		metals.append(original.lerp(Color(str(data[2 if i != 1 else 3])), weight))
	for i in range(original_accents.size()):
		var original: Color = original_accents[i]
		accents.append(original.lerp(Color(str(data[2 if i != 1 else 3])), weight * 0.8))
	look["metal_colors"] = metals
	look["accent_colors"] = accents
	return look
