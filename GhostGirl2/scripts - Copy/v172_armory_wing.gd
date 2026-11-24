@tool
extends Node2D
## v1.72.2: Original, editor-editable painted-style crypt side wing.
## Not a mirrored or recolored room texture. All architecture is drawn here.
## Local origin is the seam in the east side of Moonwake Crypt.
@export var room_right_edge: float = 3600.0
const WIDTH: float = 1310.0
const HEIGHT: float = 1590.0
const INK: Color = Color("171620")
const STONE: Color = Color("25222e")
const SILVER: Color = Color("6f6178")
const ROSE: Color = Color("b48b9c")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Solid walkable floor: never leave a transparent area behind the player.
	draw_rect(Rect2(-42, 0, WIDTH + 42.0, HEIGHT), Color("171722"))
	draw_rect(Rect2(0, 96, WIDTH, HEIGHT - 196.0), STONE)
	# Hand-composed stone irregularities; each slab has a separate subtle tone.
	for row in range(15):
		var y: float = 120.0 + float(row) * 91.0
		var offset: float = 36.0 if row % 2 == 1 else 0.0
		for col in range(11):
			var x: float = 30.0 + float(col) * 118.0 - offset
			var variation: float = 0.018 * sin(float(row * 13 + col * 7))
			var shade: Color = Color(0.135 + variation, 0.125 + variation, 0.172 + variation, 1.0)
			draw_rect(Rect2(x, y, 112, 85), shade, true)
			draw_line(Vector2(x, y), Vector2(x + 110.0, y), Color("37313f"), 1.2, true)
			draw_line(Vector2(x + 2.0, y + 85.0), Vector2(x + 110.0, y + 85.0), Color("191923"), 1.5, true)
	# A unique arch connecting the established crypt to its new wing.
	draw_rect(Rect2(-38, 72, 104, 690), Color("1c1a25"))
	for arch in range(5):
		var x: float = 5.0 + float(arch) * 11.0
		draw_arc(Vector2(x, 780.0), 340.0 + 5.0 * float(arch), -PI * 0.96, -PI * 0.04, 38, Color(0.38, 0.30, 0.38, 0.32), 2.0, true)
	# North panel with original rose tracery and cool fenestration.
	draw_rect(Rect2(0, 0, WIDTH, 137), Color("11121d"))
	draw_rect(Rect2(0, 128, WIDTH, 14), Color("453747"))
	draw_rect(Rect2(0, HEIGHT - 113.0, WIDTH, 113), Color("11111a"))
	draw_line(Vector2(0, HEIGHT - 112.0), Vector2(WIDTH, HEIGHT - 112.0), Color("574758"), 4.0)
	for col in range(6):
		var center: Vector2 = Vector2(170.0 + float(col) * 193.0, 112.0)
		draw_arc(center, 62.0, PI, TAU, 22, Color("756578"), 3.6, true)
		draw_line(center + Vector2(-62, 0), center + Vector2(-62, -70), Color("524657"), 3.0)
		draw_line(center + Vector2(62, 0), center + Vector2(62, -70), Color("524657"), 3.0)
		draw_arc(center + Vector2(0, -31), 16.0, 0, TAU, 24, Color("987787"), 2.0, true)
	# Two non-repeating gothic moon mosaics painted into the floor.
	for medallion in range(2):
		var center: Vector2 = Vector2(410.0 + float(medallion) * 540.0, 600.0 + float(medallion) * 230.0)
		draw_circle(center, 185.0, Color(0.105, 0.100, 0.145, 0.92))
		draw_arc(center, 174.0, 0.0, TAU, 76, Color("665163"), 4.0, true)
		draw_arc(center, 150.0, 0.0, TAU, 64, Color("383849"), 1.8, true)
		for petal in range(12):
			var angle: float = float(petal) * TAU / 12.0 + float(medallion) * 0.17
			var direction: Vector2 = Vector2(cos(angle), sin(angle))
			var sideways: Vector2 = Vector2(-direction.y, direction.x)
			var root: Vector2 = center + direction * 51.0
			var far: Vector2 = center + direction * 132.0
			draw_colored_polygon(PackedVector2Array([root - sideways * 13.0, far, root + sideways * 13.0]), Color(0.38, 0.27, 0.37, 0.48))
			draw_line(root, far, Color(0.67, 0.45, 0.55, 0.25), 1.0, true)
		draw_circle(center, 36.0, Color("322c40"))
		draw_arc(center + Vector2(9, -8), 31.0, 0.15, PI * 1.9, 32, Color("d0b4c5"), 2.2, true)
	# Eight floor setting rings under the armory equipment (non-colliding).
	for row in range(2):
		for col in range(4):
			var at: Vector2 = Vector2(250.0 + float(col) * 255.0, 865.0 + float(row) * 315.0)
			draw_circle(at + Vector2(0, 28), 67.0, Color(0.08, 0.065, 0.11, 0.45))
			draw_arc(at + Vector2(0, 28), 57.0, 0.0, TAU, 36, Color(0.59, 0.44, 0.56, 0.48), 2.0, true)
			draw_arc(at + Vector2(0, 28), 47.0, 0.1, PI * 1.95, 36, Color(0.86, 0.67, 0.75, 0.18), 0.9, true)
	# Delicate candlelight at the far eastern wall and a narrow rose border.
	draw_rect(Rect2(WIDTH - 77.0, 0, 77.0, HEIGHT), INK)
	for column in range(6):
		var y: float = 160.0 + float(column) * 235.0
		draw_rect(Rect2(WIDTH - 68.0, y, 53.0, 85.0), Color("3b303c"))
		draw_arc(Vector2(WIDTH - 42.0, y + 14.0), 25.0, PI, TAU, 20, SILVER, 2.0, true)
		draw_circle(Vector2(WIDTH - 42.0, y + 42.0), 5.2, ROSE)
	# Seam-to-wing walkway: a broad, actually traversable opening.
	draw_rect(Rect2(-16.0, 760.0, 48.0, 610.0), Color("26222e"))
	draw_line(Vector2(23.0, 765.0), Vector2(23.0, 1370.0), Color("5e4a5c"), 2.0, true)
