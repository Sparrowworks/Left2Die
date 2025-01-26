extends Node

signal player_kicked(error_title: String, error_content: String)

signal join_success()
signal join_failed(quiet: bool)

signal host_game_ready()
signal host_player_ready()

var peer: ENetMultiplayerPeer = null
var join_timer: Timer

var lobby_ip: String = ""
var lobby_port: int = 9999
var lobby_max: int = 4

var connected_peers: Array[int] = []

var has_game_started: bool = false

var is_host_game_ready: bool = false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	join_timer = Timer.new()
	join_timer.wait_time = 10
	join_timer.timeout.connect(func() -> void: join_failed.emit(false))
	add_child(join_timer)

func create_server(port: int, max_players: int) -> Error:
	lobby_port = port
	lobby_max = max_players

	peer = ENetMultiplayerPeer.new()

	var error: Error = peer.create_server(lobby_port, lobby_max)
	if error != OK:
		prints("Cannot host due to error",error)
		return error

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	connected_peers.append(1)
	return error

func create_client(ip: String, port: int) -> Error:
	lobby_ip = ip
	lobby_port = port

	peer = ENetMultiplayerPeer.new()

	var error: Error = peer.create_client(lobby_ip, lobby_port)
	if error != OK:
		prints("Cannot join due to error",error)
		return error

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer

	join_timer.start()

	return error

func clear_peer() -> void:
	connected_peers.clear()

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

	peer = null

@rpc("authority","call_remote","reliable")
func kick_peer(title: String, content: String) -> void:
	player_kicked.emit(title, content)
	join_failed.emit(true)

@rpc("authority","call_local","reliable")
func start_game() -> void:
	Composer.load_scene("res://src/Game/Game.tscn")

func game_started() -> void:
	if multiplayer.is_server():
		has_game_started = true

		rpc("start_game")

@rpc("authority","call_local","reliable")
func set_host_game_ready() -> void:
	prints(multiplayer.get_unique_id(), "set_host_game_ready DONE")
	is_host_game_ready = true
	host_game_ready.emit()

func _on_peer_connected(id: int) -> void:
	if connected_peers.size() == lobby_max:
		if multiplayer.is_server():
			rpc_id(id,"kick_peer","Lobby is full","You cannot join this game, because the lobby is full.")
		return

	if has_game_started:
		if multiplayer.is_server():
			rpc_id(id,"kick_peer","Game has started","You cannot join this game, because the game has already started.")
		return

	connected_peers.append(id)

	Messenger.message(str(id) + " Has connected")

func _on_peer_disconnected(id: int) -> void:
	connected_peers.erase(id)

	Messenger.message(str(id) + " Has disconnected")

### CLIENT SIGNALS

func _on_connected_to_server() -> void:
	if join_timer:
		join_timer.stop()

	Messenger.message("Connected to server")
	join_success.emit()

func _on_connection_failed() -> void:
	Messenger.message("Couldn't connect")

func _on_server_disconnected() -> void:
	player_kicked.emit("Host Left","The game has ended because host has left.")
