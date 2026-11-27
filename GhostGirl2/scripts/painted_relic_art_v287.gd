extends RefCounted
## High-resolution painted equipment. Fall back to the original art when
## the optional art bundle is not installed. No dependency on item instances.
const IDS: Array[String] = [
	"ivory_duelist_rapier_v286",
	"nightglass_rapier_v286",
	"rosehook_bearded_axe_v286",
	"ossuary_poleaxe_v286"
]
const ROOT: String = "res://assets/ui/weapons_v287/"
static var _textures: Dictionary = {}

static func texture(id: String, kind: String) -> Texture2D:
	if id not in IDS or kind not in ["held","icon"]:
		return null
	var key: String = id+"_"+kind
	if not _textures.has(key):
		var path: String = ROOT+key+".png"
		var loaded: Texture2D = null
		if ResourceLoader.exists(path,"Texture2D"):
			loaded=load(path) as Texture2D
		_textures[key]=loaded
	return _textures[key] as Texture2D

static func held_rect(id: String) -> Rect2:
	match id:
		"ivory_duelist_rapier_v286","nightglass_rapier_v286": return Rect2(-17,-23,108,46)
		"rosehook_bearded_axe_v286": return Rect2(-26,-32,118,64)
		"ossuary_poleaxe_v286": return Rect2(-27,-34,120,68)
	return Rect2()

static func edge(id: String) -> PackedVector2Array:
	match id:
		"ivory_duelist_rapier_v286": return PackedVector2Array([Vector2(19,0),Vector2(42,0),Vector2(83,0)])
		"nightglass_rapier_v286": return PackedVector2Array([Vector2(21,0),Vector2(45,0),Vector2(83,0)])
		"rosehook_bearded_axe_v286": return PackedVector2Array([Vector2(65.78,-18.17),Vector2(61.17,-20.67),Vector2(56.56,-22.58),Vector2(50.77,-23.18),Vector2(45.04,-22.26),Vector2(39.05,-19.88),Vector2(34.24,-16.00),Vector2(30.42,-11.79)])
		"ossuary_poleaxe_v286": return PackedVector2Array([Vector2(85.47,-11.36),Vector2(82.35,-16.50),Vector2(77.53,-21.64),Vector2(72.39,-24.75),Vector2(66.09,-26.15),Vector2(59.39,-25.22),Vector2(53.09,-21.25),Vector2(44.37,-14.95)])
	return PackedVector2Array()
