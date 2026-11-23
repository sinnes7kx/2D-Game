@tool
extends Node2D
## Distinct animated scene-only embellishments. No gameplay collision.
@export_enum("garden", "lily_pond", "glasshouse", "observatory") var area: String = "garden"
var elapsed: float = 0.0
var motes: Array[Vector2] = []
var phases: Array[float] = []

func _ready() -> void:
	var generator: RandomNumberGenerator = RandomNumberGenerator.new()
	generator.seed = 11572
	for i in range(28):
		motes.append(Vector2(generator.randf_range(270.0, 1190.0), generator.randf_range(315.0, 860.0)))
		phases.append(generator.randf_range(0.0, TAU))

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if area == "lily_pond":
		# Ripples follow the oval moonlit pool.
		for i in range(4):
			var radius: float = 60.0 + fposmod(elapsed * 15.0 + float(i) * 71.0, 245.0)
			var a: float = (1.0 - radius / 340.0) * 0.08
			draw_arc(Vector2(707, 570), radius, 0.17, PI - 0.17, 50, Color(0.73, 0.83, 1.0, a), 1.1, true)
		for i in range(motes.size()):
			var p: Vector2 = motes[i]
			var dx: float = (p.x - 707.0) / 280.0
			var dy: float = (p.y - 570.0) / 160.0
			if dx * dx + dy * dy > 1.0:
				continue
			var q: Vector2 = p + Vector2(sin(elapsed * 0.9 + phases[i]) * 5.0, cos(elapsed * 0.6 + phases[i]) * 3.0)
			draw_circle(q, 1.5 + sin(elapsed * 1.7 + phases[i]) * 0.55, Color(0.79, 0.82, 1.0, 0.42))
	elif area == "glasshouse":
		# Floating magical pollen over the central cherry blossoms.
		for i in range(motes.size()):
			var p: Vector2 = motes[i]
			var q: Vector2 = p + Vector2(sin(elapsed * 0.5 + phases[i]) * 24.0, -fposmod(elapsed * (9.0 + float(i % 5)) + float(i) * 21.0, 95.0))
			var tint: Color = Color(1.0, 0.81, 0.88, 0.30) if i % 2 == 0 else Color(0.79, 1.0, 0.87, 0.3)
			draw_circle(q, 2.0 + float(i % 3), tint)
	elif area == "observatory":
		# Tiny shooting-star trails that do not distract from the mirror beam.
		for i in range(motes.size()):
			var p: Vector2 = motes[i]
			var drift: float = fposmod(elapsed * (13.0 + float(i % 4) * 6.0) + float(i) * 17.0, 160.0)
			var q: Vector2 = p + Vector2(drift * 0.26, -drift)
			draw_line(q, q + Vector2(-4.0, 11.0), Color(0.80, 0.81, 1.0, 0.20), 1.5, true)
			draw_circle(q, 1.5, Color(0.95, 0.88, 1.0, 0.35))
