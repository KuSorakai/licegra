extends CharacterBody2D

# Statystyki z GDD
@export var hp: int = 2
@export var speed: float = 150.0 # Połowa z 300 (prędkość gracza)

# Pobieramy referencje do naszych węzłów
@onready var damage_zone = $DamageZone
@onready var attack_timer = $AttackTimer
@export var gem_scene: PackedScene

func _physics_process(delta: float) -> void:
	# Szukamy gracza w scenie za pomocą grupy
	var player = get_tree().get_first_node_in_group("player")
	
	# Jeśli gracz istnieje, idziemy w jego stronę
	if player != null:
		# Obliczamy kierunek od przeciwnika do gracza
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
		move_and_slide()

# Funkcja wywoływana, gdy przeciwnik dostanie trafienie
func take_damage(amount: float) -> void:
	var final_damage: int = roundi(amount)
	hp -= amount
	if hp <= 0:
		spawn_gem()
		queue_free() # Ta funkcja trwale usuwa obiekt z gry (śmierć)
		

# Nowa funkcja odpowiadająca za tworzenie kryształu
func spawn_gem() -> void:
	if gem_scene != null:
		var gem = gem_scene.instantiate()
		# Kryształ pojawia się tam, gdzie zginął wróg
		gem.global_position = global_position
		# Bezpieczne dodanie obiektu do świata gry, gdy usuwamy wroga
		get_parent().call_deferred("add_child", gem)


# 1. Kiedy gracz WEJDZIE w przeciwnika
func _on_damage_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(1) # Pierwsze, natychmiastowe uderzenie
		attack_timer.start() # Uruchamiamy odliczanie (1 sekunda)

# 2. Kiedy gracz WYJDZIE z przeciwnika
func _on_damage_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		attack_timer.stop() # Gracz uciekł, wyłączamy stoper

# 3. Kiedy Timer odliczy 1 sekundę (i będzie robił to co sekundę)
func _on_attack_timer_timeout() -> void:
	# Upewniamy się, czy gracz nadal jest w środku strefy
	var bodies = damage_zone.get_overlapping_bodies()
	
	for b in bodies:
		if b.is_in_group("player"):
			b.take_damage(1) # Zadajemy kolejne obrażenia
