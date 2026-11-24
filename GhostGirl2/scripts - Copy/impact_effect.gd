extends Node2D
## A one-shot drawn sprite impact plus independent CPU particle shower.
@onready var bloom: AnimatedSprite2D = $Bloom
@onready var petals: CPUParticles2D = $PetalSparks

func _ready() -> void:
	bloom.play("impact")
	petals.restart()
	petals.emitting = true
	await get_tree().create_timer(0.85).timeout
	queue_free()
