class_name Bullet extends Area2D

const SPEED: float = 1000.0

var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	global_position += direction.rotated(rotation) * SPEED * delta

func _on_kill_timer_timeout() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Players"):
		return

	queue_free()
