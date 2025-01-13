extends CanvasLayer

@onready var main_menu: Control = $Menu
@onready var game_select: Control = $GameSelect
@onready var lobby_create: Control = $LobbyCreate
@onready var join_menu: Control = $JoinMenu


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
