extends Control

# Referencje do nowych elementów UI
@onready var continue_button = $VBoxContainer/ContinueButton
@onready var credits_panel = $CreditsPanel
@onready var settings_panel = $SettingsPanel
@onready var fullscreen_toggle = $SettingsPanel/VBoxContainer/HBoxContainer/FullscreenToggle
@onready var volume_slider = $SettingsPanel/VBoxContainer/HBoxContainer2/VolumeSlider

# Ścieżka do pliku zapisu (zgodnie z mechaniką zapisu z GDD)
const SAVE_PATH = "user://save_game.dat"

func _ready() -> void:
	get_tree().paused = false
	
	# --- LOGIKA PRZYCISKU KONTYNUUJ ---
	# Sprawdzamy, czy na dysku gracza istnieje plik zapisu.
	# Jeśli nie ma, przycisk "Kontynuuj" staje się nieaktywny (szary) i nie da się go kliknąć!
	if FileAccess.file_exists(SAVE_PATH):
		continue_button.disabled = false
	else:
		continue_button.disabled = true
	# Odczytujemy czy gra już jest w Fullscreenie
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	# Odczytujemy obecną głośność i konwertujemy z decybeli na ułamek (0.0 do 1.0)
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))

# Wywoływane po kliknięciu "Rozpocznij Grę" (Nowa gra)
func _on_start_button_pressed() -> void:
	# Jeśli gracz zaczyna nową grę, możemy opcjonalnie usunąć stary zapis,
	# lub po prostu załadować czystą scenę.
	# Jeśli istnieje stary zapis, kasujemy go, by zacząć czystą grę!
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	get_tree().change_scene_to_file("res://Levels/world.tscn")

# Wywoływane po kliknięciu "Kontynuuj"
func _on_continue_button_pressed() -> void:
	# Informujemy GameManager lub Player, że gra ma się wczytać.
	# Na tym etapie przełączamy scenę, a w nowej scenie skrypt wczyta dane z SAVE_PATH.
	get_tree().change_scene_to_file("res://Levels/world.tscn")
	# (Wskazówka: W world.tscn dodamy flagę "should_load = true" w kolejnym kroku systemów zapisu)

# Wywoływane po kliknięciu "Twórcy"
func _on_credits_button_pressed() -> void:
	credits_panel.show() # Pokazujemy okienko z napisami

# Wywoływane po kliknięciu "Powrót" w oknie twórców
func _on_close_credits_button_pressed() -> void:
	credits_panel.hide() # Chowamy okienko twórców

# Wywoływane po kliknięciu "Wyjście"
func _on_quit_button_pressed() -> void:
	get_tree().quit()

# --- USTAWIENIA ---
func _on_settings_button_pressed() -> void:
	settings_panel.show()

func _on_close_settings_button_pressed() -> void:
	settings_panel.hide()

# Funkcja wywoływana, gdy przełączymy suwak "Pełny ekran"
func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Funkcja wywoływana, gdy ruszymy suwakiem głośności
func _on_volume_slider_value_changed(value: float) -> void:
	# Szukamy naszego głównego kanału "Master"
	var bus_idx = AudioServer.get_bus_index("Master")
	# Konwertujemy nasz ułamek (0.0 - 1.0) na decybele (np. 1.0 to 0dB, a 0.5 to ok. -6dB)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	# Jeśli zjedziemy na zero, całkowicie wyciszamy grę
	AudioServer.set_bus_mute(bus_idx, value <= 0.01)
