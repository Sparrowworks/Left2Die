extends Node

const MESSAGE_POPUP = preload("res://src/Network/MessagePopup/MessagePopup.tscn")

func message(content: String) -> void:
	prints("(", multiplayer.get_unique_id(), "): ", content)

func create_popup(title: String, content: String) -> MessagePopup:
	var popup: MessagePopup = MESSAGE_POPUP.instantiate()

	popup.message_title = title
	popup.message_content = content

	return popup
