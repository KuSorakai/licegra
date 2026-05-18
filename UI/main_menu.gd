extends Control

# Referencje do nowych elementów UI
@onready var continue_button = $VBoxContainer/ContinueButton
@onready var credits_panel = $CreditsPanel

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
