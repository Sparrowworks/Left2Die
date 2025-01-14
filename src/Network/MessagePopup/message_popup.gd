class_name MessagePopup extends Control

signal ok_pressed()

@onready var title: Label = %Title
@onready var content: Label = %Content
@onready var ok_button: Button = %OkButton

@export var message_title: String = "Alert":
	set(val):
		if title == null:
			await ready

		title.text = val

@export var message_content: String = "An error has occured":
	set(val):
		if content == null:
			await ready

		content.text = val

func _ready() -> void:
	ok_button.pressed.connect(default_ok)

func default_ok() -> void:
	ok_pressed.emit()
	self.queue_free()
