extends RefCounted
## Pure item-specific tuning, independent of rolled stats and cosmetic seed.
const TUNING: Dictionary = {
	"briar_hatchet_v283":{"time":0.86,"reach":0.88,"poise":0.82,"arc":-0.03},
	"gravecleaver_axe_v283":{"time":1.0,"reach":1.0,"poise":1.0,"arc":0.0},
	"gallows_greataxe_v283":{"time":1.14,"reach":1.12,"poise":1.12,"arc":-0.08},
	"rosehook_bearded_axe_v286":{"time":0.94,"reach":0.97,"poise":1.04,"arc":-0.10},
	"ossuary_poleaxe_v286":{"time":1.20,"reach":1.19,"poise":1.20,"arc":0.20},
	"ivory_duelist_rapier_v286":{"time":0.91,"reach":0.96,"poise":0.90,"arc":0.0},
	"nightglass_rapier_v286":{"time":1.04,"reach":1.10,"poise":1.0,"arc":0.0}
}

static func tuning(id: String) -> Dictionary:
	return TUNING.get(id,{"time":1.0,"reach":1.0,"poise":1.0,"arc":0.0})

# A narrow forward corridor prevents a long rapier from acting like a
# wide sword slash. The existing range/LOS gates remain authoritative.
static func thrust_contact(offset: Vector2,axis: Vector2,reach: float,heavy: bool) -> bool:
	if axis.is_zero_approx():
		return false
	var forward: Vector2 = axis.normalized()
	var along: float = offset.dot(forward)
	var width: float = 32.0 if heavy else 24.0
	return along>0.0 and offset.length_squared()<=reach*reach and absf(offset.cross(forward))<=width
