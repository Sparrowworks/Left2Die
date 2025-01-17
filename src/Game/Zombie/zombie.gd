class_name Zombie extends Area2D

const SPEED: float = 150.0

@export var health: float = 25.0
@export var target_id: int = 0:
	set(val):
		target_id = val

		if target_id == 0:
			return

		target = get_target(target_id)

var direction: Vector2 = Vector2.RIGHT
var target: Player = null

func get_closest_target_id() -> int:
	var players: Array[Node] = get_tree().get_nodes_in_group("Players")
	var player_amount: int = players.size()

	if player_amount == 0:
		return 0

	if player_amount == 1:
		var player: Player = players[0]
		if player.is_dead:
			return 0
		else:
			return player.name.to_int()

	var closest_target: Player = target

	for player: Player in players:
		if player.is_dead:
			continue

		if closest_target:
			if global_position.distance_squared_to(player.global_position) < global_position.distance_squared_to(closest_target.global_position):
				closest_target = player
		else:
			closest_target = player

	return closest_target.name.to_int()

func get_target(id: int) -> Player:
	var players: Array[Node] = get_tree().get_nodes_in_group("Players")

	for player: Player in players:
		if player.name.to_int() == id:
			return player

	return null

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		target_id = get_closest_target_id()

	if target == null:
		return

	look_at(target.global_position)
	global_position += direction.rotated(rotation) * SPEED * delta
