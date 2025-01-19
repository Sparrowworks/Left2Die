class_name Game extends Node2D

const PLAYER = preload("res://src/Game/Player/Player.tscn")
const ZOMBIE = preload("res://src/Game/Zombie/Zombie.tscn")

@onready var player_pos: Node = $PlayerPos
@onready var players: Node = $Players
@onready var zombies: Node = $Zombies
@onready var bullets: Node = $Bullets
@onready var ui: CanvasLayer = $UI

@onready var zombie_spawn_point: PathFollow2D = %ZombieSpawnPoint
@onready var zombie_spawn_timer: Timer = $ZombieSpawnTimer

var player_sprites: Array = [
	preload("res://assets/images/player1.png"),
	preload("res://assets/images/player2.png"),
	preload("res://assets/images/player3.png"),
	preload("res://assets/images/player4.png")
]

var have_players_spawned: Dictionary = {

}

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	if multiplayer.is_server():
		for peer in Lobby.connected_peers:
			have_players_spawned[peer] = false

	spawn_players()

@rpc("any_peer","call_remote","reliable",1)
func player_spawned(id: int) -> void:
	have_players_spawned[id] = true

	check_if_game_is_ready()

@rpc("authority","call_local","reliable",1)
func start_game() -> void:
	for player in players.get_children():
		player.process_mode = Node.PROCESS_MODE_INHERIT

func spawn_players() -> void:
	for idx in range(0, Lobby.connected_peers.size()):
		var player: Player = PLAYER.instantiate()
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.name = str(Lobby.connected_peers[idx])
		player.global_position = player_pos.get_child(idx).global_position
		player.sync_pos = player_pos.get_child(idx).global_position
		players.add_child(player)
		player.sprite.texture = player_sprites[idx]
		player.set_multiplayer_authority(Lobby.connected_peers[idx])

		if multiplayer.is_server() && Lobby.connected_peers[idx] == 1:
			player.spawn_enabled.connect(_on_spawn_enabled)

	if multiplayer.is_server():
		have_players_spawned[1] = true
		check_if_game_is_ready()
	else:
		rpc_id(1,"player_spawned",multiplayer.get_unique_id())

func check_if_game_is_ready() -> void:
	if not have_players_spawned.has(false):
		rpc("start_game")

@rpc("call_local","authority","reliable",1)
func spawn_zombie(z_pos: Vector2) -> void:
	var zombie: Zombie = ZOMBIE.instantiate()
	zombie.hide()
	zombie.global_position = z_pos
	zombie.sync_pos = z_pos
	zombies.add_child(zombie, true)
	zombie.set_multiplayer_authority(1)
	zombie.show()

func _on_spawn_enabled() -> void:
	zombie_spawn_timer.start()

func _on_zombie_spawn_timer_timeout() -> void:
	zombie_spawn_point.progress_ratio = randf()
	rpc("spawn_zombie", zombie_spawn_point.global_position)

func _on_player_disconnected(id: int) -> void:
	for player in players.get_children():
		if player.name == str(id):
			player.queue_free()
			break

	have_players_spawned.erase(id)
	Lobby.connected_peers.erase(id)
	check_if_game_is_ready()

func _on_server_disconnected() -> void:
	process_mode = PROCESS_MODE_DISABLED
	var popup: MessagePopup = Messenger.create_popup("Host Left", "Host has left the game.")
	popup.ok_pressed.connect(
		func() -> void:
			Lobby.clear_peer()
			Composer.load_scene("res://src/MainMenu/MainMenu.tscn")
	)
	ui.add_child(popup)
