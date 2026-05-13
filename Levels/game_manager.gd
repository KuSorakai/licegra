extends Node

@export var enemy_scene: PackedScene
@export var triangle_scene: PackedScene # NASZ NOWY PRZECIWNIK

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

# Wykonuje się co 1.5 sekundy (SpawnTimer)
func _on_spawn_timer_timeout() -> void:
	if player == null or enemy_scene == null:
		return
		
	# --- LOGIKA LOSOWANIA WROGA ---
	# Domyślnie zawsze szykujemy do wypuszczenia zwykłego Okręgu
	var enemy_to_spawn = enemy_scene 
	
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
		top_label.text = "WYGRANA!"
	else:
		# ZWIĘKSZAMY NUMER RUNDY!
		current_round += 1
		print("Rozpoczynam RUNDĘ ", current_round)
		
		# Żeby było ciekawiej, skracamy czas między spawnami wrogów
		spawn_timer.wait_time = max(0.5, spawn_timer.wait_time - 0.05)
		
		# --- NAPRAWA: ODPALAMY ZEGARY NA NOWO! ---
		round_timer.start()
		spawn_timer.start()
