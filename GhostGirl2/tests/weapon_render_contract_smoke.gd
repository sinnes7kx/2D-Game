extends SceneTree
const RENDER = preload("res://scripts/animation/weapon_render_contract.gd")
const DIR = preload("res://scripts/direction_controller_v245.gd")
const DIAGONAL = preload("res://scripts/ghost_diagonal_art_v247.gd")
const FX = preload("res://scripts/fx_intensity_v1924.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const WAND = preload("res://scripts/wand_anchors_v216.gd")
const WAND_LIGHT=preload("res://scripts/animation/wand_held_light.gd")

func _initialize() -> void:
	var profile: Dictionary = {"width_scale":1.0,"shape":0,"shoulder":1.0,"taper":1.0}
	var expected: Dictionary = {"blade":[10.0,4.2,0.0],"dagger":[16.2,3.2,0.0],"forge_dagger":[8.0,2.8,0.0],"dual_sword":[15.0,6.6,2.0],"dual_dagger":[12.0,3.1,0.0]}
	for style in expected:
		var preview: PackedVector2Array=RENDER.preview_span(style)
		var values: Array=expected[style]
		for i in range(8):
			var heading: Vector2=DIR.heading(i)
			var origin: Vector2=Vector2(12,-7)
			var span: PackedVector2Array=PackedVector2Array([origin,origin+heading*preview[0].distance_to(preview[1])])
			var geo: Dictionary=RENDER.straight_geometry(style,span,0)
			assert((geo["root"] as Vector2).is_equal_approx(origin+heading*float(values[0])))
			assert((geo["tip"] as Vector2).is_equal_approx(span[1]+heading*float(values[2])))
			assert(is_equal_approx(float(geo["width"]),float(values[1])))
			var edges: Array[PackedVector2Array]=RENDER.edge_paths(geo,profile)
			assert(edges.size()==2)
			for edge in edges:
				assert(edge.size()==4 and edge[-1].is_equal_approx(geo["tip"]))
				assert((edge[0]-origin).dot(heading)>0.0)
		var missing: Dictionary=RENDER.straight_geometry(style,PackedVector2Array())
		assert(missing.is_empty() and RENDER.edge_paths(missing,profile).is_empty())
	for face in DIAGONAL.DIRECTIONS:
		var clip: String="dual_sword_idle_"+face
		for hand in range(2):
			assert(RENDER.paired_layer(clip,hand)==(6 if hand==DIAGONAL.near_hand(clip) else -2))
	var visible: PackedVector2Array=PackedVector2Array([Vector2.ZERO,Vector2.RIGHT*54])
	assert(RENDER.first_visible([PackedVector2Array(),visible])==visible)
	assert(RENDER.first_visible([PackedVector2Array(),PackedVector2Array()]).is_empty())
	assert(RENDER.paired_spans(null,"dual_dagger","",0).is_empty())
	for i in range(8):
		var heading: Vector2=DIR.heading(i)
		var grip: Vector2=Vector2(12,-7)
		var tip: Vector2=grip+heading*80.0
		var span: PackedVector2Array=PackedVector2Array([grip,tip])
		var spear: Array=RENDER.polearm_heads(span,false)
		var trident: Array=RENDER.polearm_heads(span,true)
		assert(spear.size()==1 and trident.size()==3)
		assert((spear[0]["root"] as Vector2).is_equal_approx(tip-heading*24.0))
		assert((trident[2]["root"] as Vector2).is_equal_approx(tip-heading*25.0))
		assert((trident[2]["tip"] as Vector2).is_equal_approx(tip))
		for prong in trident:
			assert(RENDER.edge_paths(prong,profile).size()==2)
		assert(((trident[0]["tip"] as Vector2)+(trident[1]["tip"] as Vector2)).is_equal_approx((tip-heading*2.0)*2.0))
	assert(RENDER.polearm_heads(PackedVector2Array(),true).is_empty())
	for seed in [-4,-1,0,1,2,3,2001]:
		var texture: AtlasTexture=WAND.preview_texture(seed)
		assert(texture!=null and texture.atlas==WAND.POSE_ATLASES[WAND.atlas_index(seed)])
		assert(texture.region.size==WAND.CELL)
	var wand: GhostItemInstance=GhostItemGenerator.create(load("res://items/briar_wand.tres") as GhostItemData,192301,"rare")
	var wand_stats: Dictionary=wand.all_stats()
	var wand_snapshot: Dictionary=wand.cosmetic_snapshot()
	assert(WAND.preview_texture(wand.visual_seed())!=null)
	assert(wand.all_stats()==wand_stats and wand.cosmetic_snapshot()==wand_snapshot)
	var bow: GhostItemInstance=GhostItemGenerator.create(load("res://items/thornrose_bow.tres") as GhostItemData,192301,"rare")
	var stats: Dictionary=bow.all_stats()
	var initial: float=FX.intensity
	FX.set_intensity(1.0)
	bow.glow_level_override=5
	for mode in [-1,0,1,2,3]:
		bow.bow_glow_mode_override=mode
		var light: Vector3=RENDER.bow_light(bow)
		assert(is_equal_approx(light.x,0.0 if mode==0 else 0.5))
		assert(is_equal_approx(light.y,0.5 if mode in [-1,2,3] else 0.0))
		assert(light.z==(1.0 if mode==3 else 0.0))
		assert(RENDER.bow_light(bow,false)==Vector3.ZERO)
		var snapshot: Dictionary=bow.cosmetic_snapshot()
		RENDER.bow_light(bow)
		assert(bow.cosmetic_snapshot()==snapshot and bow.all_stats()==stats)
	bow.glow_level_override=0
	assert(RENDER.bow_light(bow).x==0.0 and RENDER.bow_light(bow).y==0.0)
	assert(RENDER.melee_model_glow(bow)==0.0)
	var light_node: Node2D=WAND_LIGHT.new()
	root.add_child(light_node)
	wand.glow_level_override=4
	light_node.call("set_pose",wand,visible,false,0.1)
	assert(light_node.visible and is_equal_approx(float(light_node.get("strength")),0.4))
	wand.glow_level_override=0
	light_node.call("set_pose",wand,visible,false,0.1)
	assert(not light_node.visible)
	light_node.free()
	# Rehaul preserves stat seed, suppresses ordinary hue motion, and saves purchased skin separately.
	var palette_fx = preload("res://scripts/anomalous_steel_fx_v180.gd")
	var colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]
	var regular: Dictionary = {"color_mode": 6, "material": 6, "particle_tier": 6, "signature": 0}
	assert(palette_fx.color_at(colors,regular,0.35,0.0)==palette_fx.color_at(colors,regular,0.35,4.0))
	var prism: Dictionary = {"prism": true, "palette_speed": 0.2}
	assert(palette_fx.color_at(colors,prism,0.35,0.0)!=palette_fx.color_at(colors,prism,0.35,1.0))
	bow.rainbow_skin = true
	assert(bow.glow_gradient_colors().size()==6 and bool(bow.collector_appearance()["prism"]))
	assert(bow.all_stats()==stats)
	var inv: Node = preload("res://scripts/inventory.gd").new()
	var record: Dictionary = inv.call("_serialize_item",bow,Vector2i.ZERO)
	var restored: GhostItemInstance = inv.call("_deserialize_item",record)
	assert(restored.rainbow_skin and restored.glow_gradient_colors()==bow.glow_gradient_colors())
	assert(restored.all_stats()==bow.all_stats())
	record.erase("rainbow_skin")
	var legacy: GhostItemInstance = inv.call("_deserialize_item",record)
	assert(not legacy.rainbow_skin)
	inv.free()
	FX.set_intensity(initial)
	print("Weapon render contract: straight and polearm geometry, wand atlas identity, 8 headings and glow inputs PASS")
	quit(0)
