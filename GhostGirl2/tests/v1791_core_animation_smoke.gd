extends SceneTree
const CORE = preload("res://resources/ghost_girl_frames.tres")
const LIBRARY = preload("res://scripts/ghost_animation_library.gd")

func _initialize() -> void:
	var entries: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/ghost_extra_animations.json"))
	var prefixes: Array[String] = ["attack_light", "attack_heavy", "dodge", "hurt", "attack_sword", "hook_launch", "attack_light_alt", "attack_counter", "attack_unarmed_light", "attack_unarmed_heavy", "attack_sword_light", "attack_sword_heavy"]
	var checked: int = 0
	for entry in entries:
		var name: String = str(entry["name"])
		var prefix: String = name.get_slice("_", 0)
		# Strip only the final directional suffix.
		prefix = name.substr(0, name.rfind("_"))
		if prefix not in prefixes:
			continue
		checked += 1
		var paths: Array = entry["textures"]
		if not CORE.has_animation(name) or CORE.get_frame_count(name) != paths.size():
			push_error("Core animation missing before runtime initialization: " + name)
			quit(1)
			return
		for i in range(paths.size()):
			var tex: Texture2D = CORE.get_frame_texture(name, i)
			if tex == null or tex.resource_path != "res://" + str(paths[i]):
				push_error("Core animation artwork mismatch: " + name)
				quit(1)
				return
	if checked != 46:
		push_error("Unexpected core animation count: " + str(checked))
		quit(1)
		return
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = CORE
	LIBRARY.install(sprite)
	LIBRARY.install(sprite)
	for face in ["front", "back", "left", "right"]:
		for prefix in ["attack_light", "attack_heavy", "dodge", "hurt", "attack_sword", "attack_light_alt"]:
			var name: String = prefix + "_" + face
			if not sprite.sprite_frames.has_animation(name):
				push_error("Animation lost during repeated initialization: " + name)
				sprite.free()
				quit(1)
				return
	sprite.free()
	print("v1.79.1 PASS: 46 preloaded core clips, exact original artwork and repeatable installation")
	quit(0)
