extends SceneTree
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const LOOK = preload("res://scripts/collector_appearance_v177.gd")

func _initialize() -> void:
	var shapes: Dictionary = {}
	var metals: Dictionary = {}
	var ornaments: Dictionary = {}
	var root: Vector2 = Vector2.ZERO
	var tip: Vector2 = Vector2(60, 0)
	for i in range(128):
		var uid: String = "%032x" % i
		var look: Dictionary = LOOK.roll(uid, 123)
		var p: Dictionary = ART.profile(look)
		if p != ART.profile(LOOK.roll(uid, 999)):
			push_error("Modular profile is not reproducible")
			quit(1)
			return
		shapes[p["shape"]] = true
		metals[p["metal"]] = true
		ornaments[p["ornament"]] = true
		var left: PackedVector2Array = ART.edge_points(root,tip,3.8,p,-1.0)
		var right: PackedVector2Array = ART.edge_points(root,tip,3.8,p,1.0)
		for segment in range(3):
			for bevel_side in [-1,1]:
				var strip: PackedVector2Array = ART.bevel_strip(left,right,segment,bevel_side)
				assert(strip.size() == 4)
				assert(strip[0] == (left[segment] if bevel_side < 0 else right[segment]))
				assert(strip[1] == (left[segment+1] if bevel_side < 0 else right[segment+1]))
				assert(absf(strip[3].y) <= absf(strip[0].y))
				if segment == 2:
					assert(strip[1] == tip and strip[2] == tip)
		for side in [-1.0, 1.0]:
			var edge: PackedVector2Array = ART.edge_points(root, tip, 3.8, p, side)
			if edge.size() != 4 or edge[3] != tip:
				push_error("Modular blade loses authored tip")
				quit(1)
				return
			for j in range(3):
				if absf(edge[j].y) > 5.0 or edge[j].y * side <= 0.0:
					push_error("Blade silhouette invalid or too broad")
					quit(1)
					return
	if shapes.size() != 5 or ornaments.size() != 9 or metals.size() < 100:
		push_error("Insufficient modular variation")
		quit(1)
		return
	print("v1.78 PASS: five shapes, nine ornaments, independent metal tones and stable pointed blade geometry")
	quit(0)
