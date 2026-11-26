extends SceneTree
## v2.13 dual-weapon silhouette and original procedural foley regression.
## Uses synthetic data only. Does not read or alter user:// saves.
const DUAL = preload("res://scripts/v174_dual_swords.gd")
const JUICE = preload("res://scripts/combat_juice_v194.gd")
const INV = preload("res://scripts/inventory.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var definition: GhostItemData = load("res://items/gloamrose_dual_swords_v174.tres") as GhostItemData
	if definition == null:
		_fail("Missing paired-sword item")
		return
	var item: GhostItemInstance = GhostItemGenerator.create(definition, 213021, "rare")
	var initial: Dictionary = inv._serialize_item(item, Vector2i.ZERO)
	if DUAL.IDLE_BLADE_LENGTH_SCALE < 1.30 or DUAL.ATTACK_BLADE_LENGTH_SCALE < 1.10:
		_fail("World paired-sword length scale did not increase")
		return
	var checked: int = 0
	for facing in ["front", "back", "left", "right"]:
		for action in ["idle", "walk", "a", "b", "c", "heavy", "riposte"]:
			for frame in range(8):
				var blades: Array = DUAL.authored_blade_spans(facing, action, frame)
				if blades.size() != 2:
					_fail("Two sword poses missing")
					return
				for blade in blades:
					var span: PackedVector2Array = blade
					if span.size() != 2:
						_fail("Detached sword pose")
						return
					var length: float = span[0].distance_to(span[1])
					if length < 28.0 or length > 122.0:
						_fail("Sword pose length outside safe bounds")
						return
					if absf(span[1].x) > 123.0 or absf(span[1].y) > 118.0:
						_fail("Sword tip outside legacy frame bounds")
						return
					if action == "idle" and length < 65.0:
						_fail("Idle sword still too short at world scale")
						return
					checked += 1
	for cue in ["swing", "heavy_swing", "hit", "parry"]:
		var sample: AudioStreamWAV = JUICE._render(cue)
		if sample == null or sample.mix_rate != JUICE.RATE or sample.data.size() < 3000:
			_fail("New foley clip missing/too short: " + cue)
			return
		var max_value: int = 0
		var energy: float = 0.0
		for i in range(0, sample.data.size(), 2):
			var value: int = int(sample.data[i]) | (int(sample.data[i + 1]) << 8)
			if value >= 32768:
				value -= 65536
			max_value = maxi(max_value, absi(value))
			energy += absf(float(value))
		var average: float = energy / float(sample.data.size() / 2)
		if max_value >= 32760 or average < 30.0:
			_fail("Foley clipping/silence detected for: " + cue)
			return
	if inv._serialize_item(item, Vector2i.ZERO) != initial:
		_fail("Drawing/audio modified item's rarity, seed or stats")
		return
	inv.free()
	print("v2.13 PASS: ", checked, " bounded paired-sword spans, longer idle silhouettes, soft unclipped audio and item identity")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
