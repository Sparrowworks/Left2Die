class_name UsernameEnter extends Control

@onready var nick_edit: LineEdit = %NickEdit
@onready var desc: Label = $Panel/VBoxContainer/VBoxContainer2/Desc

func reset() -> void:
	desc.text = "To play multiplayer you need a username. enter it in the field below. The username cannot have more than 20 characters."

func is_username_correct() -> bool:
	var username: String = nick_edit.text.strip_edges()

	if username == "":
		desc.text = "Username can't be empty."
		return false

	return true

func _on_nick_edit_text_submitted(new_text: String) -> void:
	pass # Replace with function body.
