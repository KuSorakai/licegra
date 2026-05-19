extends CharacterBody2D

var speed: float = 300.0
var dash_speed: float = 900.0 # Prędkość podczas uniku
var is_dashing: bool = false
var is_invincible: bool = false
var can_dash: bool = true
var hp: int = 5
var mana: float = 10.0
var base_max_mana: float = 10.0
var mana_regen: float = 3.0 # Odnawia 3 pkt many na sekundę
var current_exp: int = 0
var level: int = 1
var exp_to_next_level: int = 5 # Pierwszy próg z GDD
# --- EKWIPUNEK ---
# export pozwoli nam na szybkie dorzucenie przedmiotów w Inspektorze do testów
@export var starting_items: Array[ItemData] = [] 
var inventory: Array[ItemData] = []
# --- ZSUMOWANE STATYSTYKI Z PRZEDMIOTÓW ---
var total_bonus_damage_percent: float = 0.0
var total_bonus_strength: int = 0
var total_bonus_max_hp: int = 0    # NOWE
var total_bonus_max_mana: int = 0    # NOWE
var total_bonus_intelligence: int = 0
var total_apply_status: String = "" # Globalny status z przedmiotów (np. Fiolki)
var total_bonus_speed: float = 0.0 # NOWE
@onready var health_bar = $HealthBar
@onready var mana_bar = $ManaBar

var total_crit_chance: float = 0.0
var total_projectile_count: int = 0
var total_dash_count: int = 0

# Zmienna, do której podepniemy naszą scenę pocisku
@export var bullet_scene: PackedScene
# Zmienna na nasz plik z danymi broni (Resource)
@export var current_weapon: WeaponData 
# Stoper kontrolujący, jak często możemy strzelać
var shoot_timer: float = 0.0

# Pobieramy referencję do naszego nowego węzła obrotu broni
@onready var weapon_pivot = $WeaponPivot
# Pobieramy referencję do naszej lufy
@onready var muzzle = $WeaponPivot/WeaponMesh/Muzzle

func _ready() -> void:
	# Wrzucamy przedmioty startowe (z Inspektora) do właściwego plecaka
	inventory.append_array(starting_items)
	calculate_stats()

func _physics_process(delta: float) -> void:
	# Pobieramy kierunek tak jak wcześniej
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Sprawdzamy, czy wciśnięto spację, czy dash jest odnowiony i czy gracz w ogóle się rusza
	if Input.is_action_just_pressed("dash") and can_dash and direction != Vector2.ZERO:
		perform_dash()
	
	# Ustawiamy prędkość w zależności od tego, czy robimy unik, czy idziemy normalnie
	if is_dashing:
		velocity = direction * dash_speed
	else:
		velocity = direction * (speed + total_bonus_speed)
		
	move_and_slide()
	
	# --- REGENERACJA MANY ---
	var current_max_mana = base_max_mana + total_bonus_max_mana
	if mana < current_max_mana:
		mana += mana_regen * delta
		if mana > current_max_mana: mana = current_max_mana
		
	if mana_bar != null:
		mana_bar.max_value = current_max_mana
		mana_bar.value = mana
	
	# --- CELOWANIE ---
	# Jeśli broń ma tag "magic", szukamy wroga. Jak nie ma, strzelamy myszką.
	if current_weapon != null and "magic" in current_weapon.tags:
		var nearest = get_nearest_enemy()
		if nearest != null:
			weapon_pivot.look_at(nearest.global_position)
		else:
			weapon_pivot.look_at(get_global_mouse_position())
	else:
		weapon_pivot.look_at(get_global_mouse_position())
		
	# --- STRZELANIE Z UŻYCIEM DANYCH Z BRONI ---
	# Odliczamy czas stopera
	if shoot_timer > 0:
		shoot_timer -= delta
		
	# Input.is_action_pressed oznacza "dopóki trzymasz wciśnięty przycisk"
	if Input.is_action_pressed("shoot") and shoot_timer <= 0:
		# Upewniamy się, że gracz ma ubraną jakąś broń
		if current_weapon != null:
			shoot()
			# Ustawiamy stoper na nowy strzał (np. 1 / 2.5 = 0.4 sekundy przerwy)
			shoot_timer = 1.0 / current_weapon.attack_speed
		
	if Input.is_action_just_pressed("ui_focus_next"): # To jest domyślnie klawisz TAB
		add_exp(5) # Daje 5 EXP natychmiast
	
func shoot() -> void:
	# SPRAWDZAMY KOSZT MANY
	if current_weapon.mana_cost > 0:
		if mana >= current_weapon.mana_cost:
			mana -= current_weapon.mana_cost # Pobieramy manę
		else:
			return # Brak many = przerywamy strzał!
	# SPRAWDZAMY CZY BROŃ MA PRZYPISANĄ SCENĘ POCISKU
	if current_weapon.projectile_scene != null:
		var base_rot = muzzle.global_rotation
		var projectiles_to_fire = 1 + total_projectile_count
		var spread_angle = deg_to_rad(15.0) # Kąt rozrzutu pocisków (15 stopni)
		# --- OBLICZANIE WSPÓLNYCH OBRAŻEŃ ---
		var rarity_mult: float = 1.0
		match current_weapon.tier:
			0: rarity_mult = 1.0
			1: rarity_mult = 1.3
			2: rarity_mult = 1.6
			3: rarity_mult = 2.0
			
		var base_calculated_damage = current_weapon.base_attack * rarity_mult
		var final_damage = base_calculated_damage + (base_calculated_damage * total_bonus_damage_percent)
		var final_range = current_weapon.range * rarity_mult
		
		# --- PĘTLA STRZELAJĄCA WIELOMA POCISKAMI ---
		for i in range(projectiles_to_fire):
			var bullet = current_weapon.projectile_scene.instantiate()
			get_tree().root.add_child(bullet)
			bullet.global_position = muzzle.global_position
			if current_weapon.status_effect != "":
				bullet.status_effect = current_weapon.status_effect
			else:
				bullet.status_effect = total_apply_status
			
			# Magia trygonometrii: rozkładamy pociski równo w wachlarz
			var angle_offset = 0.0
			if projectiles_to_fire > 1:
				angle_offset = spread_angle * (i - (projectiles_to_fire - 1) / 2.0)
				
			bullet.global_rotation = base_rot + angle_offset
			
			# PRZEKAZANIE DANYCH DO POCISKU
			bullet.status_effect = current_weapon.status_effect
			bullet.damage = final_damage
			bullet.max_range = final_range
			bullet.max_pierce = current_weapon.piercing
		
# Nasza nowa funkcja wykonująca unik
func perform_dash() -> void:
	is_dashing = true
	can_dash = false # Blokujemy możliwość kolejnego uniku
	is_invincible = true # WŁĄCZAMY NIETYKALNOŚĆ
	modulate.a = 0.5 # Postać staje się półprzezroczysta jak duch!
	# "await" zatrzymuje wykonanie kodu w tej funkcji na podany czas.
	# To definiuje jak długo trwa sam "skok" gracza.
	await get_tree().create_timer(0.2).timeout
	is_dashing = false # Koniec uniku, wracamy do normalnej prędkości
	is_invincible = false # WYŁĄCZAMY NIETYKALNOŚĆ
	modulate.a = 1.0 # Wracamy do pełnych kolorów
	# Czas odnowienia: czekamy 2 sekundy, tak jak opisałeś w GDD
	await get_tree().create_timer(2.0).timeout
	can_dash = true # Dash znowu gotowy do użycia!
func take_damage(amount: int) -> void:
	if is_invincible:
		return
	hp -= amount
	if health_bar != null:
		health_bar.value = hp
	print("Aua! Otrzymałem obrażenia. Aktualne HP: ", hp)
	   
	if hp <= 0:
		print("Koniec Gry!")
		
		# Szukamy naszego menedżera, by zapytać go o numer rundy
		var gm = get_tree().get_first_node_in_group("game_manager")
		var current_round = 1
		if gm != null:
			current_round = gm.current_round
			
		# Odpalamy Ekran Przegranej
		var game_over_screen = get_node_or_null("../HUD/GameOverScreen")
		if game_over_screen != null:
			game_over_screen.trigger_game_over(current_round)
			
		# Trwale usuwamy postać gracza z planszy
		queue_free()

func add_exp(amount: int) -> void:
	current_exp += amount
	# Znajdujemy pasek w grupie i aktualizujemy jego wartości
	var exp_bar = get_tree().get_first_node_in_group("exp_bar")
	if exp_bar != null:
		exp_bar.max_value = exp_to_next_level
		exp_bar.value = current_exp
	print("EXP: ", current_exp, "/", exp_to_next_level)
	
	if current_exp >= exp_to_next_level:
		level_up()

func level_up() -> void:
	current_exp = 0 # Reset licznika zgodnie z GDD [cite: 29]
	level += 1
	
	# Obliczanie nowego progu zgodnie z GDD 
	if level <= 7:
		var thresholds = [5, 10, 20, 40, 60, 80, 100]
		exp_to_next_level = thresholds[level - 1]
	else:
		exp_to_next_level += 20 # Powyżej 8. poziomu: poprzedni + 20 [cite: 29]
		
	print("AWANS! Poziom: ", level, " Następny cel: ", exp_to_next_level)
	# Szukamy naszego ekranu na scenie i odpalamy jego funkcję
	var level_screen = get_node_or_null("../HUD/LevelUpScreen") # Upewnij się, że ścieżka się zgadza!
	if level_screen != null:
		level_screen.trigger_level_up()
	
	
func _on_magnet_area_area_entered(area: Area2D) -> void:
	# Sprawdzamy, czy obszar, w który wszedł nasz magnes to na pewno kryształ
	if area.is_in_group("gem"):
		# Mówimy kryształowi: "Hej, przypisz mnie jako swój cel do lotu!"
		area.target_player = self
		
# Tę funkcję wywołamy, gdy gracz zdobędzie przedmiot z Ekranu Awansu
func add_item(item: ItemData) -> void:
	inventory.append(item)
	calculate_stats()
	print("Dodano przedmiot: ", item.item_name)
	# --- NOWE: DODAJEMY IKONKĘ DO PASKA ---
	var items_container = get_node_or_null("../HUD/ItemsContainer")
	if items_container != null and item.icon != null:
		var new_icon = TextureRect.new() # Tworzymy nowy obrazek w locie
		new_icon.texture = item.icon
		new_icon.custom_minimum_size = Vector2(40, 40) # Rozmiar ikonki przedmiotu
		new_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		items_container.add_child(new_icon) # Wrzucamy do rzędu!

# Ta funkcja liczy wszystkie bonusy od zera
func calculate_stats() -> void:
	# 1. Resetujemy obecne bonusy
	total_bonus_damage_percent = 0.0
	total_bonus_strength = 0
	total_bonus_intelligence = 0
	total_bonus_max_hp = 0
	total_bonus_speed = 0.0
	total_crit_chance = 0.0
	total_apply_status = ""
	total_projectile_count = 0
	total_dash_count = 0
	
	# 2. Sumujemy statystyki
	for item in inventory:
		total_bonus_damage_percent += item.bonus_damage_percent
		total_bonus_strength += item.bonus_strength
		total_bonus_intelligence += item.bonus_intelligence
		total_bonus_max_hp += item.bonus_max_hp
		total_bonus_speed += item.bonus_speed
		total_crit_chance += item.bonus_crit_chance
		total_projectile_count += item.bonus_projectiles
		total_dash_count += item.bonus_dashes
		if item.apply_status != "":
			total_apply_status = item.apply_status
		
	# 3. Zastosowanie dodatkowego HP do paska nad głową
	# Nasze bazowe HP to 5. Zwiększamy "pojemność" paska.
	if health_bar != null:
		health_bar.max_value = 5 + total_bonus_max_hp
		# Opcjonalnie: uleczenie gracza przy zdobyciu max HP
		hp += total_bonus_max_hp 
		health_bar.value = hp
		
	print("Przeliczono! Speed: +", total_bonus_speed, " Max HP: +", total_bonus_max_hp)
	
func get_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest = null
	var min_dist = INF
	for e in enemies:
		var dist = global_position.distance_to(e.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = e
	return nearest
	# Używamy tej funkcji do zmiany broni, żeby od razu zaktualizować interfejs!
func equip_weapon(new_weapon: WeaponData) -> void:
	current_weapon = new_weapon
	
	# Szukamy naszego węzła z ikoną broni na ekranie
	var weapon_icon_rect = get_node_or_null("../HUD/WeaponIcon")
	if weapon_icon_rect != null and current_weapon.icon != null:
		weapon_icon_rect.texture = current_weapon.icon
