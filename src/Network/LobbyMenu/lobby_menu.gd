extends Control

@onready var lobby_title: Label = %LobbyTitle
@onready var player_list: VBoxContainer = %PlayerList
@onready var start_button: Button = %StartButton

var has_player_joined: Dictionary = {

}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func draw_lobby(players: Array[int], max_players: int) -> void:
	if multiplayer.get_unique_id() != 1:
		start_button.hide()

	lobby_title.text = "Players in Lobby (" + str(players.size()) + "/" + str(max_players) + "):"

	for idx in range(0, player_list.get_child_count()):
		var lobby_player: LobbyPlayer = player_list.get_child(idx)
		if players.size() <= idx:
			lobby_player.hide()
			continue

		var peer_id: int = players[idx]

		lobby_player.player_name = str(peer_id)
		if peer_id == 1 or not multiplayer.is_server():
			lobby_player.hide_kick()

		lobby_player.show()

func check_if_game_can_start() -> void:
	if multiplayer.is_server():
		start_button.disabled = has_player_joined.has(false)

@rpc("authority","call_remote","reliable")
func greet_peer(peer_amount: Array[int], max_players: int) -> void:
	Lobby.connected_peers = peer_amount
	Lobby.lobby_max = max_players

	draw_lobby(Lobby.connected_peers, Lobby.lobby_max)

	rpc_id(1,"peer_respond_back",multiplayer.get_unique_id())

@rpc("any_peer","call_remote","reliable")
func peer_respond_back(id: int) -> void:
	has_player_joined[id] = true

	check_if_game_can_start()

func _on_start_button_pressed() -> void:
	if multiplayer.is_server():
		Lobby.game_started()

func _on_peer_connected(id: int) -> void:
	if Lobby.connected_peers.size() == Lobby.lobby_max or Lobby.has_game_started:
		return

	if multiplayer.is_server():
		has_player_joined[id] = false
		rpc_id(id, "greet_peer", Lobby.connected_peers, Lobby.lobby_max)
		check_if_game_can_start()

	draw_lobby(Lobby.connected_peers, Lobby.lobby_max)

func _on_peer_disconnected(id: int) -> void:
	if not Lobby.has_game_started:
		draw_lobby(Lobby.connected_peers, Lobby.lobby_max)

	if multiplayer.is_server():
		has_player_joined.erase(id)
		check_if_game_can_start()

func _on_lobby_player_player_kicked(player_name: String) -> void:
	if multiplayer.is_server():
		Lobby.rpc_id(player_name.to_int(),"kick_peer", "Kicked", "You have been kicked from the lobby.")
