extends SceneTree
const ART = preload("res://scripts/painted_relic_art_v287.gd")
const MODELS = preload("res://scripts/weapon_models_v283.gd")
const SPECIAL = preload("res://scripts/unique_specials_v261.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var present: int = 0
	for id in ART.IDS:
		var data: GhostItemData = load("res://items/"+id+".tres")
		assert(data!=null and data.item_id==id)
		assert(MODELS.MODELS.has(id))
		assert(ART.edge(id).size()>1)
		var rect: Rect2 = ART.held_rect(id)
		assert(rect.has_point(Vector2.ZERO))
		for p in ART.edge(id):
			assert(rect.has_point(p))
		var held: Texture2D = ART.texture(id,"held")
		var icon: Texture2D = ART.texture(id,"icon")
		assert((held==null)==(icon==null))
		if held!=null:
			present+=1
			assert(held.get_size()==rect.size*4.0)
			assert(held.get_image().detect_alpha()!=Image.ALPHA_NONE)
			assert(icon.get_image().detect_alpha()!=Image.ALPHA_NONE)
			assert(data.icon==icon)
		else:
			assert(data.icon!=null)
		var item: GhostItemInstance = GhostItemGenerator.create(data,287101,"unique")
		assert(not SPECIAL.label(item).is_empty())
	assert(present==0 or present==4)
	print("v2.87 painted relic resources and fallback checked. Installed: %d / 4"%present)
	quit(0)
