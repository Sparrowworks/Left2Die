extends Node

signal game_joined()
signal lobby_redraw_needed()

var peer: ENetMultiplayerPeer = null

var lobby_ip: String = ""
var lobby_port: int = 9999
var lobby_max: int = 4

var connected_peers: Array[int] = []

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

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
	return error

func clear_peer() -> void:
	connected_peers.clear()

	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	peer = null

@rpc("authority","call_remote","reliable")
func greet_peer(peer_amount: Array[int], max_players: int) -> void:
	connected_peers = peer_amount
	lobby_max = max_players

	lobby_redraw_needed.emit()

func _on_peer_connected(id: int) -> void:
	if multiplayer.get_unique_id() == 1:
		connected_peers.append(id)
		lobby_redraw_needed.emit()
		rpc_id(id,"greet_peer",connected_peers,lobby_max)

	prints("(",multiplayer.get_unique_id(),"): ",str(id),"Has connected")

func _on_peer_disconnected(id: int) -> void:
	if multiplayer.get_unique_id() == 1:
		connected_peers.erase(id)
		lobby_redraw_needed.emit()

	prints("(",multiplayer.get_unique_id(),"): ",str(id),"Has disconnected")
### CLIENT SIGNALS

func _on_connected_to_server() -> void:
	prints("(",multiplayer.get_unique_id(),"): ","Connected to server")
	game_joined.emit()

func _on_connection_failed() -> void:
	prints("(",multiplayer.get_unique_id(),"): ","Couldn't connect")
