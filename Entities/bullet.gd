extends Area2D

@export var speed: float = 1000.0
var damage: float = 1.0 # Zmienna gotowa na przyjęcie ułamkowych danych z broni
var status_effect: String = "" # Pusty string = brak statusu
var max_range: float = 400.0 # Maksymalny zasięg z GDD
var distance_traveled: float = 0.0 # Licznik przebytego dystansu
# NOWE ZMIENNE DO PRZEBICIA
var max_pierce: int = 1
var pierced_count: int = 0
var hit_enemies: Array = [] # Lista wrogów, którzy już dostali

func _physics_process(delta: float) -> void:
	# Obliczamy wektor ruchu w tej klatce
	var movement = transform.x * speed * delta
	position += movement
	# Zwiększamy licznik przebytego dystansu
	distance_traveled += movement.length()
	# Jeśli pocisk przeleciał swój maksymalny zasięg, po prostu znika
	if distance_traveled >= max_range:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and not body in hit_enemies:
		hit_enemies.append(body) # Zapisujemy "Ten już dostał!"
		# PRZEKAZUJEMY STATUS DO WROGA!
		body.take_damage(damage, status_effect)
		
		pierced_count += 1
		# Jeśli przebiliśmy maksymalną liczbę wrogów, pocisk znika
		if pierced_count >= max_pierce:
			queue_free()
