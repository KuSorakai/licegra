extends Area2D

var speed: float = 1000.0
var damage: float = 1.0 # Zmienna gotowa na przyjęcie ułamkowych danych z broni
var max_range: float = 400.0 # Maksymalny zasięg z GDD
var distance_traveled: float = 0.0 # Licznik przebytego dystansu

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
	if body.is_in_group("enemy"):
		# Przekazujemy nasze obrażenia (float) do przeciwnika
		body.take_damage(damage)
		queue_free()
