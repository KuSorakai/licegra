extends CanvasLayer

@onready var volume_slider = $Background/VBoxContainer/VolumeContainer/VolumeSlider

func _ready() -> void:
	hide() # Na starcie gry menu pauzy jest niewidoczne
	
	# Ustawiamy suwak głośności na aktualną wartość z systemu
	if volume_slider != null:
		var bus_idx = AudioServer.get_bus_index("Master")
		volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))

func _process(_delta: float) -> void:
	# Domyślnie w Godocie klawisz ESC jest przypisany pod "ui_cancel"
	if Input.is_action_just_pressed("ui_cancel"):
		if visible:
			# Jeśli menu pauzy już jest otwarte -> zamykamy je i wznawiamy grę
			resume_game()
		elif not get_tree().paused:
			# ZABEZPIECZENIE: Włączamy pauzę TYLKO jeśli gra nie jest już zapauzowana 
			# przez inny ekran (np. Level Up lub Wybór Broni)
			pause_game()

func pause_game() -> void:
	show()
	get_tree().paused = true # Zamrażamy świat gry (wrogów, pociski, gracza)

func resume_game() -> void:
	hide()
	get_tree().paused = false # Odmrażamy świat gry

# --- OBSŁUGA SYGNAŁÓW PRZYCISKÓW ---

func _on_resume_button_pressed() -> void:
	resume_game()

func _on_volume_slider_value_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	AudioServer.set_bus_mute(bus_idx, value <= 0.01)

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false # KRYTYCZNE: Musimy odmrozić grę PRZED zmianą sceny, inaczej menu główne też będzie zapauzowane!
	get_tree().change_scene_to_file("res://UI/main_menu.tscn")
