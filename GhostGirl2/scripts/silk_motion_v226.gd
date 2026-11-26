extends RefCounted
## Tiny optional render-time secondary motion. No new textures, skeleton,
## collision, save fields or per-pixel CPU work. Geometric zones are a
## conservative prototype until authored per-frame hair/fabric masks exist.
static var enabled: bool = true
var lag: float = 0.0
var energy: float = 0.0
var phase: float = 0.0
var was_active: bool = false

static func supports(name: String) -> bool:
	for face in ["front", "back", "left", "right"]:
		# Do not deform baked blades, hook attacks or casting wrists.
		if name in ["idle_" + face, "walk_" + face, "wand_idle_" + face, "dual_sword_idle_" + face, "dual_dagger_idle_" + face]:
			return true
	return false

static func follow(current: float, target: float, delta: float, rate: float) -> float:
	return lerpf(current, target, 1.0 - exp(-maxf(0.0, delta) * rate))

func reset() -> void:
	lag = 0.0
	energy = 0.0
	phase = 0.0

func update(body: AnimatedSprite2D, velocity: Vector2, delta: float, freeze: bool) -> void:
	if body == null or not body.material is ShaderMaterial or body.sprite_frames == null:
		return
	var material: ShaderMaterial = body.material as ShaderMaterial
	var name: String = str(body.animation)
	var active: bool = enabled and supports(name) and body.centered and body.offset == Vector2.ZERO and not body.flip_h and not body.flip_v
	if active:
		var texture: Texture2D = body.sprite_frames.get_frame_texture(body.animation, body.frame)
		active = texture != null and texture.get_size() == Vector2(256, 220)
	if active != was_active:
		material.set_shader_parameter("silk_enabled", 1.0 if active else 0.0)
		was_active = active
	if not active:
		reset()
		return
	if not freeze:
		lag = follow(lag, clampf(-velocity.x / 240.0, -1.0, 1.0), delta, 5.0)
		energy = follow(energy, clampf(velocity.length() / 240.0, 0.0, 1.0), delta, 6.5)
		phase = fposmod(phase + delta * (1.7 + energy * 3.0), TAU * 100.0)
		material.set_shader_parameter("silk_phase", phase)
		material.set_shader_parameter("silk_lag", lag)
		material.set_shader_parameter("silk_energy", energy)
