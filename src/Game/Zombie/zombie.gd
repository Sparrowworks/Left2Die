class_name Zombie extends Area2D

signal score_updated(id: int, value: int)
signal zombie_killed(id: int)

@onready var synchronizer: MultiplayerSynchronizer = $MovementSynchronizer
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var soft_collision: SoftCollision = $SoftCollision

@export var max_health: float = 25.0:
	set(val):
		health = max_health

@export var max_speed: float = 100.0:
	set(val):
		speed = max_speed

@export var hit_score: int = 10
@export var kill_score: int = 25

var health: float = 25.0
var speed: float = 100.0

var target_id: int = 0:
	set(val):
		target_id = val

		if target_id == 0:
			return

		target = get_target(target_id)

var direction: Vector2 = Vector2.RIGHT
var target: Player = null

@export var sync_pos: Vector2 = Vector2.ZERO
@export var sync_rot: float = 0
@export var sync_health: float = max_health

var game_manager: GameManager
var last_player_hit: int

func _ready() -> void:
	clean()

	game_manager = get_parent().get_parent().game_manager as GameManager
	game_manager.zombie_ready.connect(_on_zombie_ready)
	game_manager.zombie_dead.connect(_on_zombie_dead)

	game_manager.add_zombie(self.name, global_position)

	if multiplayer.get_unique_id() == 1:
		game_manager.add_spawned_zombie(self.name, 1)
	else:
		game_manager.rpc_id(1, "add_spawned_zombie", self.name, multiplayer.get_unique_id())

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		target_id = get_closest_target_id()

		sync_pos = global_position
		sync_rot = rotation_degrees

		sync_health = health
		if health <= 0:
			clean()
	else:
		global_position = global_position.lerp(sync_pos, synchronizer.replication_interval)
		rotation_degrees = lerpf(rotation_degrees, sync_rot, synchronizer.replication_interval)

		if sync_health <= health:
			health = sync_health

		if health <= 0:
			clean()

	if target == null:
		return

	look_at(target.global_position)

	if soft_collision.check_for_overlap():
		global_position += soft_collision.get_push_vector() * delta * 50.0

	if not global_position.distance_squared_to(target.global_position) < 350:
		global_position += direction.rotated(rotation) * speed * delta

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

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullets"):
		prints("ZOMBIE HIT",multiplayer.get_unique_id(), area.player_id)
		last_player_hit = area.player_id
		health -= 5.0

		score_updated.emit(last_player_hit, hit_score)

func _on_zombie_ready(zombie_name: String) -> void:
	if self.name == zombie_name:
		activate()

func _on_zombie_dead(zombie_name: String) -> void:
	if self.name == zombie_name:
		kill()

func activate() -> void:
	synchronizer.public_visibility = true

	show()
	set_physics_process(true)
	collision_shape_2d.set_deferred("disabled",false)

func clean() -> void:
	if game_manager:
		score_updated.emit(last_player_hit, kill_score)
		zombie_killed.emit(last_player_hit)

		if multiplayer.get_unique_id() == 1:
			game_manager.add_dead_zombie(self.name, 1)
		else:
			game_manager.rpc_id(1, "add_dead_zombie", self.name, multiplayer.get_unique_id())

	synchronizer.public_visibility = false

	collision_shape_2d.set_deferred("disabled",true)
	hide()
	set_physics_process(false)

func kill() -> void:
	queue_free()
