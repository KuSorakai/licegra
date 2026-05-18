extends CharacterBody2D

# Statystyki z GDD
@export var hp: int = 2
@export var speed: float = 150.0 # Połowa z 300 (prędkość gracza)
@onready var base_speed: float = speed

# Pobieramy referencje do naszych węzłów
@onready var damage_zone = $DamageZone
@onready var attack_timer = $AttackTimer
@export var gem_scene: PackedScene
@export var gem_drop_count: int = 1 # Zwykły wróg wyrzuca 1. Boss wyrzuci np. 30!

# --- NOWE ZMIENNE DO EFEKTÓW ---
@onready var sprite = $Sprite2D
@onready var original_color = sprite.modulate

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
func take_damage(amount: float, status: String = "") -> void:
	var final_damage: int = roundi(amount)
	hp -= final_damage
	# --- NOWY KOD: EFEKT MIGANIA NA BIAŁO ---
	if sprite != null:
		# Tworzymy nowego Tweena
		var tween = create_tween()
		# Krok 1: Zmień kolor na biały w ciągu 0.1 sekundy
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		# Krok 2: Wróć do oryginalnego koloru w ciągu 0.1 sekundy
		tween.tween_property(sprite, "modulate", original_color, 0.1)
	# ----------------------------------------
	# --- SPRAWDZANIE STATUSÓW ---
	if status == "Fire":
		apply_burn()
	elif status == "Freeze":
		apply_freeze()
	elif status == "Shock":
		apply_shock(final_damage)
	if hp <= 0:
		spawn_gem()
		queue_free() # Ta funkcja trwale usuwa obiekt z gry (śmierć)
		

# --- MECHANIKI STATUSÓW ---
func apply_burn() -> void:
	for i in range(3):
		await get_tree().create_timer(0.5).timeout
		if not is_inside_tree(): return # Zabezpieczenie, jeśli wróg umrze w międzyczasie!
		hp -= 1
		sprite.modulate = Color(1.0, 0.5, 0.0) # Mignięcie na pomarańczowo
		if hp <= 0:
			spawn_gem()
			queue_free()
			break

func apply_freeze() -> void:
	speed = 0.0 # Zatrzymanie
	sprite.modulate = Color(0.3, 0.8, 1.0) # Kolor lodu
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		speed = base_speed # Odmrożenie
		sprite.modulate = original_color

func apply_shock(base_dmg: int) -> void:
	var shock_dmg = max(1.0, base_dmg / 2.0) # 50% obrażeń, minimum 1
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		# Jeśli wróg jest inny niż cel i jest blisko (zasięg rażenia 150 pikseli)
		if e != self and e.global_position.distance_to(global_position) < 150.0:
			# Rażąc prądem nie podajemy statusu, by wrogowie nie raziły się w nieskończoność
			e.take_damage(shock_dmg, "")
# Nowa funkcja odpowiadająca za tworzenie kryształu
func spawn_gem() -> void:
	if gem_scene != null:
		# Pętla wykonuje się tyle razy, ile gemów ma wypaść
		for i in range(gem_drop_count):
			var gem = gem_scene.instantiate()
			
			# Tworzymy lekki rozrzut (od -40 do 40 pikseli wokół wroga)
			var random_offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
			gem.global_position = global_position + random_offset
			
			# call_deferred upewnia się, że silnik bezpiecznie doda gemy tuż po śmierci wroga
			get_tree().root.call_deferred("add_child", gem)


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
