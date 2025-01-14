extends Control

@onready var lobby_title: Label = %LobbyTitle
@onready var player_list: VBoxContainer = %PlayerList
@onready var start_button: Button = %StartButton

func _ready() -> void:
	Lobby.lobby_redraw_needed.connect(
		func() -> void:
			draw_lobby(Lobby.connected_peers, Lobby.lobby_max)
	)

func draw_lobby(players: Array[int], max_players: int) -> void:
	if multiplayer.get_unique_id() != 1:
		start_button.hide()

	lobby_title.text = "Players in Lobby (" + str(players.size()) + "/" + str(max_players) + "):"

	for i in range(player_list.get_child_count()-1,-1,-1):
		player_list.get_child(i).queue_free()

	for player in players:
		var label: Label = Label.new()
		label.text = str(player)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		player_list.add_child(label)


func _on_start_button_pressed() -> void:
	if multiplayer.is_server():
		Lobby.game_started()
