class_name GameManager extends Node

signal game_ready()
signal players_ready()
signal zombie_ready(zombie_name: String)
signal zombie_dead(zombie_name: String)

var has_launched_game: Dictionary = {

}

var has_players_spawned: Dictionary = {

}

var is_game_ready: bool = false
var are_players_ready: bool = false

var is_zombie_spawned: Dictionary = {}
var is_zombie_dead: Dictionary = {}

var game: Game

func _ready() -> void:
	game = get_parent()

	# Track which players have launched and which are still loading.
	if multiplayer.get_unique_id() == 1:
		for idx: int in Lobby.connected_peers.keys():
			has_launched_game[idx] = false
			has_players_spawned[idx] = false

		add_launched_game(1)
	else:
		# If a client loaded in faster than the host, wait till the host loads then send a message
		if not Lobby.is_host_game_ready:
			await Lobby.host_game_ready

		rpc_id(1,"add_launched_game",multiplayer.get_unique_id())

func add_zombie(zombie_name: String, z_pos: Vector2, health: float, speed: float) -> void:
	is_zombie_spawned[zombie_name] = {}
	is_zombie_dead[zombie_name] = {}

	# Keep a list if a zombie spawned/despawned for each client
	if multiplayer.get_unique_id() == 1:
		for idx: int in Lobby.connected_peers.keys():
			is_zombie_spawned[zombie_name][idx] = false
			is_zombie_dead[zombie_name][idx] = false

		# Spawn the zombie for everyone
		game.rpc("spawn_zombie", z_pos, health, speed)

@rpc("any_peer","call_remote","reliable",1)
func add_spawned_zombie(zombie_name: String, idx: int = 0) -> void:
	# Check if a zombie has spawned for every client
	if idx > 0:
		is_zombie_spawned[zombie_name][idx] = true

	# If he has, then activate him
	if not is_zombie_spawned[zombie_name].values().has(false):
		rpc("set_zombie_ready", zombie_name)

@rpc("authority","call_local","reliable",1)
func set_zombie_ready(zombie_name: String) -> void:
	# Activate the zombie
	if multiplayer.get_unique_id() == 1:
		is_zombie_spawned.erase(zombie_name)

	zombie_ready.emit(zombie_name)

@rpc("any_peer","call_remote","reliable",1)
func add_dead_zombie(zombie_name: String, idx: int = 0) -> void:
	# Check if a zombie has despawned for every client
	if idx > 0:
		is_zombie_dead[zombie_name][idx] = true

	# If he has, then delete him
	if not is_zombie_dead[zombie_name].values().has(false):
		rpc("set_zombie_dead", zombie_name)

@rpc("authority","call_local","reliable",1)
func set_zombie_dead(zombie_name: String) -> void:
	# Delete the zombie
	if multiplayer.get_unique_id() == 1:
		is_zombie_dead.erase(zombie_name)

	zombie_dead.emit(zombie_name)

@rpc("any_peer","call_remote","reliable",1)
func add_launched_game(idx: int = 0) -> void:
	# Check if the game has launched for every client
	if idx > 0:
		if idx == 1:
			# If it launched for the host, notify the clients that the host can receive messages
			Lobby.rpc("set_host_game_ready")

		has_launched_game[idx] = true

	# If it did, then start spawning the players
	if not has_launched_game.values().has(false):
		rpc("set_game_ready")

@rpc("authority","call_local","reliable",1)
func set_game_ready() -> void:
	is_game_ready = true
	game_ready.emit()

@rpc("any_peer","call_remote","reliable",1)
func add_players_spawned(idx: int = 0) -> void:
	# Check if the players have spawned for every client
	if idx > 0:
		has_players_spawned[idx] = true

	# If they did, then the game can finally start
	if not has_players_spawned.values().has(false):
		rpc("set_player_ready")

@rpc("authority","call_local","reliable",1)
func set_player_ready() -> void:
	are_players_ready = true
	players_ready.emit()

func clear_peer(id: int) -> void:
	# When a peer leaves during the game, remove all mention of him
	has_launched_game.erase(id)
	if not is_game_ready:
		add_launched_game()

	has_players_spawned.erase(id)
	if not are_players_ready:
		add_players_spawned()

	for key: String in is_zombie_spawned.keys():
		is_zombie_spawned[key].erase(id)
		add_spawned_zombie(key)

		is_zombie_dead[key].erase(id)
		add_dead_zombie(key)
