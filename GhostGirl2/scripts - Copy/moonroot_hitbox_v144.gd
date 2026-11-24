extends StaticBody2D
## The actual physical collision forwards damage/ignition to the mechanism.
func receive_damage(amount: float, source: Vector2 = Vector2.ZERO) -> void:
    var lattice: Node = get_parent()
    if lattice != null and lattice.has_method("receive_damage"):
        lattice.call("receive_damage", amount, source)

func ignite_from_environment() -> void:
    var lattice: Node = get_parent()
    if lattice != null and lattice.has_method("ignite_from_environment"):
        lattice.call("ignite_from_environment")
