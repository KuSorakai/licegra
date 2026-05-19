extends Node

@export var enemy_scene: PackedScene
@export var triangle_scene: PackedScene # NASZ NOWY PRZECIWNIK
@export var boss_scene: PackedScene # NASZ NOWY BOSS
var boss_spawned_this_round: bool = false # Sprawdza, czy już go wypuściliśmy

# Pobieramy referencję do gracza
@onready var player = get_tree().get_first_node_in_group("player")
@onready var spawn_timer = $SpawnTimer
@onready var round_timer = $RoundTimer

@onready var top_label = $"../HUD/TopLabel"
@onready var time_label = $"../HUD/TimeLabel"

var current_round: int = 1

func _process(delta: float) -> void:
	if not round_timer.is_stopped():
		var time_left = int(round_timer.time_left)
		# Runda idzie do górnego napisu
		top_label.text = "Runda: " + str(current_round)
		# Sam czas idzie do nowego, wielkiego napisu
		time_label.text = str(time_left)

func _ready() -> void:
	print("Rozpoczynam RUNDĘ ", current_round)
	load_game() # ZAWSZE PRÓBUJEMY WCZYTAĆ NA STARCIE

# Wykonuje się co 1.5 sekundy (SpawnTimer)
func _on_spawn_timer_timeout() -> void:
	if player == null or enemy_scene == null:
		return
		
	# --- LOGIKA LOSOWANIA WROGA ---
	# Domyślnie zawsze szykujemy do wypuszczenia zwykłego Okręgu
	var enemy_to_spawn = enemy_scene 
	if current_round > 0 and current_round % 5 == 0 and not boss_spawned_this_round and boss_scene != null:
		enemy_to_spawn = boss_scene
		boss_spawned_this_round = true
	else:
		# Zwykłe losowanie, jeśli nie wysyłamy Bossa
		if current_round >= 2 and triangle_scene != null:
			if randf() < 0.30: 
				enemy_to_spawn = triangle_scene
	# Jeśli jesteśmy w 2 rundzie lub wyżej...
	if current_round >= 2 and triangle_scene != null:
		# Losujemy liczbę od 0.0 do 1.0. 
		# Jeśli wypadnie poniżej 0.3 (czyli 30% szans), podmieniamy wroga na Trójkąt!
		if randf() < 0.30: 
			enemy_to_spawn = triangle_scene
			
	# Tworzymy ostatecznie wybranego wroga
	var enemy = enemy_to_spawn.instantiate()
	# Losujemy losowy kierunek (kąt od 0 do 360 stopni)
	var random_direction = Vector2.RIGHT.rotated(randf() * TAU)
	
	# Ustawiamy odległość spawnu na 800 pikseli od gracza 
	# (to spełnia warunek "minimum 0.5 ekranu od gracza")
	var spawn_distance = 800.0
	
	# Obliczamy ostateczną pozycję
	enemy.global_position = player.global_position + (random_direction * spawn_distance)
	
	# Dodajemy wroga do świata gry (jako dziecko głównego węzła World)
	get_parent().add_child(enemy)

# Wykonuje się po 60 sekundach (RoundTimer)
func _on_round_timer_timeout() -> void:
	print("Koniec rundy ", current_round, "!")
	spawn_timer.stop() # Zatrzymujemy na ułamek sekundy, by nie zespawnować wroga w przejściu
	
	# Zgodnie z GDD gra trwa max 20 rund.
	if current_round >= 20:
		print("WYGRANA!")
		round_timer.stop()
		spawn_timer.stop()
		var gameplay_music = get_node_or_null("%GameplayMusic")
		if gameplay_music != null:
			gameplay_music.stop()
		# Opcjonalnie kasujemy zapis, bo gra została ukończona!
		if FileAccess.file_exists("user://save_game.dat"):
			DirAccess.remove_absolute("user://save_game.dat")
		
		var victory_screen = get_node_or_null("../HUD/VictoryScreen")
		if victory_screen != null:
			victory_screen.trigger_victory()
	else:
		# ZWIĘKSZAMY NUMER RUNDY!
		current_round += 1
		print("Rozpoczynam RUNDĘ ", current_round)
		boss_spawned_this_round = false # RESETUJEMY FLAGĘ NA POCZĄTKU RUNDY
		# Żeby było ciekawiej, skracamy czas między spawnami wrogów
		spawn_timer.wait_time = max(0.5, spawn_timer.wait_time - 0.05)
		save_game()
		# --- NAPRAWA: ODPALAMY ZEGARY NA NOWO! ---
		round_timer.start()
		spawn_timer.start()
		
# --- SYSTEM ZAPISU ---
func save_game() -> void:
	if player == null: return
	
	# Zbieramy ścieżki do wszystkich przedmiotów w plecaku
	var inv_paths = []
	for item in player.inventory:
		inv_paths.append(item.resource_path)
		
	# Tworzymy słownik z pełnymi danymi gry
	var save_data = {
		"current_round": current_round,
		"player_hp": player.hp,
		"player_level": player.level,
		"player_exp": player.current_exp,
		"player_exp_to_next": player.exp_to_next_level,
		"weapon_path": player.current_weapon.resource_path if player.current_weapon else "",
		"inventory_paths": inv_paths
	}
	
	# Zapisujemy słownik jako JSON na dysk gracza
	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("--> GRA ZAPISANA POMYŚLNIE! <--")

func load_game() -> void:
	if not FileAccess.file_exists("user://save_game.dat"):
		return # Brak pliku, gramy normalnie
		
	# Odczytujemy JSONa
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) == OK:
		var data = json.data
		
		# Odtwarzamy RUNDĘ
		current_round = data["current_round"]
		
		# Odtwarzamy Gracza
		if player != null:
			player.hp = data["player_hp"]
			player.level = data["player_level"]
			player.current_exp = data["player_exp"]
			player.exp_to_next_level = data["player_exp_to_next"]
			
			# Wczytujemy zapisaną broń
			var w_path = data["weapon_path"]
			if w_path != "":
				var loaded_weapon = load(w_path)
				player.equip_weapon(loaded_weapon)
				
			# Wczytujemy przedmioty (funkcja add_item sama odświeży UI i statystyki!)
			for i_path in data["inventory_paths"]:
				var loaded_item = load(i_path)
				player.add_item(loaded_item)
				
			# Aktualizacja Pasków HUD (HP i EXP)
			var exp_bar = get_tree().get_first_node_in_group("exp_bar")
			if exp_bar:
				exp_bar.max_value = player.exp_to_next_level
				exp_bar.value = player.current_exp
			if player.health_bar:
				player.health_bar.max_value = 5 + player.total_bonus_max_hp
				player.health_bar.value = player.hp
				
		print("--> GRA WCZYTANA POMYŚLNIE! <--")
