extends RefCounted
## Shared generated soft falloffs: no external textures or per-light allocations.
static var _light: GradientTexture2D
static var _shadow: GradientTexture2D
static var _dust: GradientTexture2D

static func light() -> GradientTexture2D:
	if _light==null:
		_light=_make(PackedFloat32Array([0.0,0.20,0.48,0.76,1.0]),PackedColorArray([Color(1,1,1,1),Color(0.82,0.82,0.82,1),Color(0.30,0.30,0.30,1),Color(0.065,0.065,0.065,1),Color(0,0,0,1)]),128)
	return _light

static func shadow() -> GradientTexture2D:
	if _shadow==null:
		_shadow=_make(PackedFloat32Array([0.0,0.28,0.58,0.82,1.0]),PackedColorArray([Color(1,1,1,1),Color(1,1,1,0.94),Color(1,1,1,0.52),Color(1,1,1,0.12),Color(1,1,1,0)]),64)
	return _shadow

# Shared soft particulate texture, not a screen blur or an added light.
static func dust() -> GradientTexture2D:
	if _dust==null:
		_dust=_make(PackedFloat32Array([0.0,0.22,0.50,0.76,1.0]),PackedColorArray([Color(1,1,1,0.92),Color(1,1,1,0.70),Color(1,1,1,0.34),Color(1,1,1,0.08),Color(1,1,1,0)]),64)
	return _dust

static func _make(offsets: PackedFloat32Array, colors: PackedColorArray, resolution: int) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets=offsets
	gradient.colors=colors
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient=gradient
	texture.width=resolution
	texture.height=resolution
	texture.fill=GradientTexture2D.FILL_RADIAL
	texture.fill_from=Vector2(0.5,0.5)
	texture.fill_to=Vector2(1.0,0.5)
	return texture
