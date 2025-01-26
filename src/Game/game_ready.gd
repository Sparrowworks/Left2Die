class_name GameReady extends Node

signal game_ready()
signal players_ready()

var has_launched_game: Dictionary = {

}

var has_players_spawned: Dictionary = {

}

func _ready() -> void:
	if multiplayer.get_unique_id() == 1:
		for idx in Lobby.connected_peers:
			has_launched_game[idx] = false
			has_players_spawned[idx] = false

		add_launched_game(1)
	else:
		if not Lobby.is_host_game_ready:
			await Lobby.host_game_ready

		prints(multiplayer.get_unique_id(), "ALLOWED")

		rpc_id(1,"add_launched_game",multiplayer.get_unique_id())

@rpc("any_peer","call_remote","reliable",1)
func add_launched_game(idx: int) -> void:
	prints(multiplayer.get_unique_id(), str(idx), "SET LAUNCHED GAME")
	if idx == 1:
		Lobby.rpc("set_host_game_ready")

	has_launched_game[idx] = true
	print(has_launched_game)

	print(has_launched_game.values().has(false))
	if not has_launched_game.values().has(false):
		rpc("set_game_ready")

@rpc("authority","call_local","reliable",1)
func set_game_ready() -> void:
	game_ready.emit()

@rpc("any_peer","call_remote","reliable",1)
func add_players_spawned(idx: int) -> void:
	prints(multiplayer.get_unique_id(), str(idx), "SET PLAYERS SPAWNED")

	has_players_spawned[idx] = true
	print(has_players_spawned)

	print(has_players_spawned.values().has(false))
	if not has_players_spawned.values().has(false):
		rpc("set_player_ready")

@rpc("authority","call_local","reliable",1)
func set_player_ready() -> void:
	players_ready.emit()
