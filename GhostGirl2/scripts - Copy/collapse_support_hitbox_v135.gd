extends StaticBody2D
## Forwards thrown crates/physical impacts to the authored support parent.
func receive_damage(amount: float, _attacker_position: Vector2 = Vector2.ZERO) -> void:
    var support: Node = get_parent()
    if support != null and support.has_method("receive_damage"):
        support.call("receive_damage", amount)
