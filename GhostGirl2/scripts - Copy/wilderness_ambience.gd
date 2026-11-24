@tool
extends Node2D
## Gentle outdoor motion: ambient fireflies, wind-borne petals and stream glints.
## Drawn in world space and separate from the painted 2D background.
@export_enum("woods", "brook") var style: String = "woods"
@export_range(1, 96, 1) var mote_count: int = 42
@export_range(0.0, 1.0, 0.05) var intensity: float = 0.55
var lifetime: float = 0.0
var seeds: Array[Vector4] = []

func _ready() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 231991 if style == "woods" else 551732
	for i in range(mote_count):
		seeds.append(Vector4(rng.randf_range(160,2910), rng.randf_range(220,1630), rng.randf_range(0,TAU), rng.randf_range(0.5,1.8)))

func _process(delta: float) -> void:
	lifetime += delta
	queue_redraw()

func _draw() -> void:
	if seeds.is_empty():
		return
	for i in range(seeds.size()):
		var seed: Vector4 = seeds[i]
		var dx: float = sin(lifetime * (0.34 + seed.w * 0.16) + seed.z) * (24 if style == "woods" else 8)
		var dy: float = -fposmod(lifetime * (5.0 + seed.w * 3.5) + float(i) * 27.0, 110.0)
		var pos: Vector2 = Vector2(seed.x + dx, seed.y + dy)
		var alpha: float = intensity * (0.22 + 0.13 * sin(lifetime * seed.w + seed.z))
		if style == "brook":
			# Sparse glints, never a flashing full-screen overlay.
			draw_line(pos, pos + Vector2(5,0), Color(0.70, 0.81, 1.0, alpha), 1.5, true)
		else:
			draw_circle(pos, 1.5 + 0.6 * sin(lifetime + seed.z), Color(0.93, 0.85, 1.0, alpha))
