extends CanvasLayer

@onready var round_label = $Background/VBoxContainer/RoundLabel

func _ready() -> void:
	hide()

func trigger_victory() -> void:
	get_tree().paused = true # Zatrzymujemy grę
	if round_label != null:
		round_label.text = "Udało Ci się! Przetrwałeś 20 rund!"
	show()

# Pamiętaj, żeby w edytorze wejść w zakładkę Node->Signals i 
# podpiąć sygnał "pressed()" od Twojego przycisku Menu Głównego do tej funkcji:
func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
