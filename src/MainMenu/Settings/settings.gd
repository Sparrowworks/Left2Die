extends Control

@onready var master_text: Label = %MasterText
@onready var master_slider: HSlider = %MasterSlider
@onready var music_text: Label = %MusicText
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_text: Label = %SfxText
@onready var sfx_slider: HSlider = %SfxSlider
@onready var nick_edit: LineEdit = %NickEdit


func _ready() -> void:
	update()


func update() -> void:
	nick_edit.text = Lobby.player_username

	update_text()
	update_sliders()
	update_buses()


func update_text() -> void:
	master_text.text = "Master Volume: " + str(Lobby.master_volume)
	music_text.text = "Music Volume: " + str(Lobby.music_volume)
	sfx_text.text = "SFX Volume: " + str(Lobby.sfx_volume)


func update_sliders() -> void:
	master_slider.value = Lobby.master_volume
	music_slider.value = Lobby.music_volume
	sfx_slider.value = Lobby.sfx_volume


func update_buses() -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"), linear_to_db(Lobby.master_volume / 100.0)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), linear_to_db(Lobby.music_volume / 100.0)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"), linear_to_db(Lobby.sfx_volume / 100.0)
	)


func _on_master_slider_value_changed(value: float) -> void:
	Lobby.master_volume = value
	update()


func _on_music_slider_value_changed(value: float) -> void:
	Lobby.music_volume = value
	update()


func _on_sfx_slider_value_changed(value: float) -> void:
	Lobby.sfx_volume = value
	update()


func _on_nick_edit_text_changed(new_text: String) -> void:
	Lobby.player_username = new_text
