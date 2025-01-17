class_name Game extends Node2D

const PLAYER = preload("res://src/Game/Player/Player.tscn")
const ZOMBIE = preload("res://src/Game/Zombie/Zombie.tscn")

@onready var player_pos: Node = $PlayerPos
@onready var zombies: Node = $Zombies
@onready var bullets: Node = $Bullets

@onready var zombie_spawn_point: PathFollow2D = %ZombieSpawnPoint
@onready var zombie_spawn_timer: Timer = $ZombieSpawnTimer

var player_sprites: Array = [
	preload("res://assets/images/player1.png"),
	preload("res://assets/images/player2.png"),
	preload("res://assets/images/player3.png"),
	preload("res://assets/images/player4.png")
]

func _ready() -> void:
	spawn_players()

	if multiplayer.is_server():
		zombie_spawn_timer.start()

func spawn_players() -> void:
	for idx in range(0, Lobby.connected_peers.size()):
		var player: Player = PLAYER.instantiate()
		player.name = str(Lobby.connected_peers[idx])
		add_child(player)
		player.sprite.texture = player_sprites[idx]
		player.global_position = player_pos.get_child(idx).global_position
		player.set_multiplayer_authority(Lobby.connected_peers[idx])

@rpc("call_local","authority","reliable")
func spawn_zombie(z_pos: Vector2) -> void:
	var zombie: Zombie = ZOMBIE.instantiate()
	zombies.add_child(zombie, true)
	zombie.global_position = z_pos
	zombie.set_multiplayer_authority(1)

func _on_zombie_spawn_timer_timeout() -> void:
	zombie_spawn_point.progress_ratio = randf()
	rpc("spawn_zombie", zombie_spawn_point.global_position)
