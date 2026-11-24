@tool
extends Node2D
## Tiny drifting motes. Visual-only, intentionally inexpensive on phones.
var particles: Array[Vector2] = []
var phases: Array[float] = []
var elapsed: float = 0.0

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 113
	for i in range(32):
		particles.append(Vector2(rng.randf_range(110.0, 1330.0), rng.randf_range(285.0, 890.0)))
		phases.append(rng.randf_range(0.0, TAU))

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	for i in range(particles.size()):
		var base: Vector2 = particles[i]
		var p := base + Vector2(sin(elapsed * 0.35 + phases[i]) * 13.0, -fmod(elapsed * (5.0 + float(i % 4) * 2.0), 115.0))
		var alpha := 0.12 + 0.12 * (0.5 + 0.5 * sin(elapsed * 1.6 + phases[i]))
		draw_circle(p, 1.5 + float(i % 3) * 0.55, Color(0.92, 0.78, 1.0, alpha))
