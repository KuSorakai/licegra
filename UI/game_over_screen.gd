extends CanvasLayer

@onready var round_label = $Background/VBoxContainer/RoundLabel

func _ready() -> void:
	hide() # Ukrywamy ekran na starcie

# Tę funkcję wywołamy, gdy gracz zginie
func trigger_game_over(round_reached: int) -> void:
	get_tree().paused = true # Zatrzymujemy świat gry
	show() # Wyświetlamy nasz ekran czerwonej śmierci
	round_label.text = "Przetrwałeś do rundy: " + str(round_reached)

# Pamiętaj o podłączeniu sygnału pressed() z przycisku do tej funkcji!
func _on_restart_button_pressed() -> void:
	get_tree().paused = false # Odpauzowujemy grę
	if FileAccess.file_exists("user://save_game.dat"):
		DirAccess.remove_absolute("user://save_game.dat")
	# Wczytanie gry od nowa
	get_tree().change_scene_to_file("res://Levels/world.tscn")
