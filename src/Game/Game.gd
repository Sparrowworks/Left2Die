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

@onready var game_ready_node: GameReady = $GameReady

var player_sprites: Array = [
	preload("res://assets/images/player1.png"),
	preload("res://assets/images/player2.png"),
	preload("res://assets/images/player3.png"),
	preload("res://assets/images/player4.png")
]

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	await game_ready_node.game_ready

	print(multiplayer.get_unique_id()," Game is ready")

	spawn_players()

	await game_ready_node.players_ready

	start_game()

func spawn_players() -> void:
	for idx in range(0, Lobby.connected_peers.size()):
		var player: Player = PLAYER.instantiate()
		player.name = str(Lobby.connected_peers[idx])
		player.global_position = player_pos.get_child(idx).global_position
		player.sync_pos = player_pos.get_child(idx).global_position
		players.add_child(player)

		player.sprite.texture = player_sprites[idx]
		player.set_multiplayer_authority(Lobby.connected_peers[idx])

		if not is_instance_valid(player):
			await player.ready

		if multiplayer.is_server() && Lobby.connected_peers[idx] == 1:
			player.spawn_enabled.connect(_on_spawn_enabled)

	if multiplayer.get_unique_id() != 1:
		game_ready_node.rpc_id(1,"add_players_spawned",multiplayer.get_unique_id())
	else:
		game_ready_node.add_players_spawned(1)

func start_game() -> void:
	for plr: Player in players.get_children():
		plr.synchronizer.public_visibility = true

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

	Lobby.connected_peers.erase(id)

func _on_server_disconnected() -> void:
	process_mode = PROCESS_MODE_DISABLED
	var popup: MessagePopup = Messenger.create_popup("Host Left", "Host has left the game.")
	popup.ok_pressed.connect(
		func() -> void:
			Lobby.clear_peer()
			Composer.load_scene("res://src/MainMenu/MainMenu.tscn")
	)
	ui.add_child(popup)
