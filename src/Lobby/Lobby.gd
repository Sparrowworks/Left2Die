extends Node

const PORT = 9999

var peer: ENetMultiplayerPeer = null
var ip: String = ""

var connected_peers: Array = []

func create_server() -> Error:
	peer = ENetMultiplayerPeer.new()

	return peer.create_server(PORT, 4)

func create_client() -> Error:
	peer = ENetMultiplayerPeer.new()

	return peer.create_client(ip, PORT)
