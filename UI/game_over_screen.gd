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
	get_tree().reload_current_scene() # Magia! Godot sam resetuje cały poziom
