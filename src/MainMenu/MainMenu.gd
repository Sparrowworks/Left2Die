extends CanvasLayer

@onready var main_menu: Control = $Menu
@onready var game_select: Control = $GameSelect
@onready var lobby_create: Control = $LobbyCreate
@onready var join_menu: Control = $JoinMenu
@onready var lobby_menu: Control = $LobbyMenu

func _ready() -> void:
	Lobby.game_joined.connect(_on_game_created)

func _on_multi_button_pressed() -> void:
	main_menu.hide()
	game_select.show()


func _on_host_create_button_pressed() -> void:
	game_select.hide()
	lobby_create.show()

func _on_menu_button_pressed() -> void:
	game_select.hide()
	main_menu.show()

func _on_back_button_pressed() -> void:
	lobby_create.hide()
	join_menu.hide()
	game_select.show()


func _on_join_game_button_pressed() -> void:
	game_select.hide()
	join_menu.show()


func _on_leave_button_pressed() -> void:
	Lobby.clear_peer()

	main_menu.show()
	lobby_menu.hide()


func _on_game_created() -> void:
	lobby_create.hide()
	join_menu.hide()

	lobby_menu.show()

	lobby_menu.draw_lobby(Lobby.connected_peers, Lobby.lobby_max)
