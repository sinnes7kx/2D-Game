@tool
extends "res://scripts/treasure_chest.gd"
## Optional early-world reward, uncovered by a separate falling support.
## Reuses the existing treasure chest ID and collected flag on reload.
@export var revealed: bool = false
var uncover_seconds: float = -1.0

func _ready() -> void:
    super._ready()
    if not Engine.is_editor_hint() and not revealed:
        hide()
        remove_from_group("interactable")

func reveal_from_collapse(restoring: bool = false) -> void:
    if revealed:
        return
    if restoring:
        _uncover()
    else:
        uncover_seconds = 0.85

func _uncover() -> void:
    revealed = true
    uncover_seconds = -1.0
    show()
    if not Engine.is_editor_hint() and not opened:
        add_to_group("interactable")
    queue_redraw()

func _process(delta: float) -> void:
    if uncover_seconds > 0.0:
        uncover_seconds -= delta
        if uncover_seconds <= 0.0:
            _uncover()
    if visible:
        super._process(delta)

func _draw() -> void:
    if not revealed:
        return
    super._draw()
    draw_arc(Vector2.ZERO, 43.0, 0.0, TAU, 36, Color(0.72, 0.6, 0.75, 0.28), 2.0, true)
