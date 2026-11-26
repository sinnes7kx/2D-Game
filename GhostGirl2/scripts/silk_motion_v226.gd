extends RefCounted
## Tiny optional render-time secondary motion. No new textures, skeleton,
## collision, save fields or per-pixel CPU work. Geometric zones are a
## conservative prototype until authored per-frame hair/fabric masks exist.
static var enabled: bool = true
var hair_lag: Vector2 = Vector2.ZERO
var cloth_lag: Vector2 = Vector2.ZERO
var energy: float = 0.0
var phase: float = 0.0
var fade: float = 0.0
var was_active: bool = false
var last_material_id: int = 0
var needs_upload: bool = true

static func supports(name: String) -> bool:
	for face in ["front", "back", "left", "right"]:
		# Do not deform baked blades, hook attacks or casting wrists.
		if name in ["idle_" + face, "walk_" + face, "wand_idle_" + face, "wand_walk_" + face, "dual_sword_idle_" + face, "dual_sword_walk_" + face, "dual_dagger_idle_" + face, "dual_dagger_walk_" + face]:
			return true
	return false

static func follow(current: float, target: float, delta: float, rate: float) -> float:
	return lerpf(current, target, 1.0 - exp(-maxf(0.0, delta) * rate))

static func follow_vector(current: Vector2, target: Vector2, delta: float, rate: float) -> Vector2:
	return current.lerp(target, 1.0 - exp(-maxf(0.0, delta) * rate))

func reset() -> void:
	hair_lag = Vector2.ZERO
	cloth_lag = Vector2.ZERO
	energy = 0.0
	phase = 0.0
	fade = 0.0
	needs_upload = true

func update(body: AnimatedSprite2D, velocity: Vector2, delta: float, freeze: bool) -> void:
	if body == null or not body.material is ShaderMaterial or body.sprite_frames == null:
		return
	var material: ShaderMaterial = body.material as ShaderMaterial
	var name: String = str(body.animation)
	var active: bool = enabled and supports(name) and body.centered and body.offset == Vector2.ZERO and not body.flip_h and not body.flip_v
	if active:
		var texture: Texture2D = body.sprite_frames.get_frame_texture(body.animation, body.frame)
		active = texture != null and texture.get_size() == Vector2(256, 220)
	var changed_material: bool = material.get_instance_id() != last_material_id
	if active != was_active or changed_material:
		material.set_shader_parameter("silk_enabled", 1.0 if active else 0.0)
		was_active = active
		last_material_id = material.get_instance_id()
	if not enabled:
		reset()
		return
	# Keep inertia through short unsupported clips (blink, attacks, hook).
	# Their pixels stay untouched; only the hidden response continues.
	# A teleport or explicit Off still resets the entire motion state.
	if not freeze:
		# Hair follows quickly; heavier fabric trails longer. Both axes are
		# bounded, and a zero target settles naturally after stopping.
		var target: Vector2 = (-velocity / 240.0).limit_length(1.0)
		hair_lag = follow_vector(hair_lag, target, delta, 7.5)
		cloth_lag = follow_vector(cloth_lag, target, delta, 3.7)
		energy = follow(energy, clampf(velocity.length() / 240.0, 0.0, 1.0), delta, 6.5)
		fade = follow(fade, 1.0 if active else 0.0, delta, 10.0)
		phase = fposmod(phase + delta * (1.7 + energy * 3.0), TAU * 100.0)
	if not active:
		needs_upload = true
		return
	if not freeze or changed_material or needs_upload:
		needs_upload = false
		# Pack the response into two vector uniforms instead of independent
		# scalar uploads. Freeze keeps the last visual pose during hitstop.
		material.set_shader_parameter("silk_flow", Vector4(hair_lag.x, hair_lag.y, cloth_lag.x, cloth_lag.y))
		material.set_shader_parameter("silk_state", Vector3(phase, energy, fade))
