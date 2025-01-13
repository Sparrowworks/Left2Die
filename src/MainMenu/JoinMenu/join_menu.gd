extends Control

@onready var ip_edit: LineEdit = %IpEdit
@onready var port_edit: LineEdit = %PortEdit


func _on_join_button_pressed() -> void:
	Lobby.create_client(ip_edit.text, int(port_edit.text))
