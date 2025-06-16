class_name SoftCollision extends Area2D

var overlapping_areas: Array[Area2D] = []

# This script prevents zombies from overlapping with each other
# Detailed explanation of this script and how it works can be found here: https://www.youtube.com/watch?v=2LBuO7lbeAE


func check_for_overlap() -> bool:
	overlapping_areas = get_overlapping_areas()
	return overlapping_areas.size() > 0


func get_push_vector() -> Vector2:
	if overlapping_areas.size() > 0:
		var direction: int = -1 if randf() < 0.5 else 1
		return (
			overlapping_areas[0]
			. global_position
			. direction_to(global_position)
			. rotated(direction * PI / 4)
			. normalized()
		)

	return Vector2.ZERO
