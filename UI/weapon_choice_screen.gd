extends CanvasLayer

@onready var btn_1 = $Background/HBoxContainer/Weapon1
@onready var btn_2 = $Background/HBoxContainer/Weapon2
@onready var btn_3 = $Background/HBoxContainer/Weapon3
@onready var stats_label = $Background/StatsLabel

# Tu w Inspektorze wrzucisz wszystkie bronie, jakie masz w grze
@export var weapon_pool: Array[WeaponData] = []
var offered_weapons: Array[WeaponData] = []
var player: CharacterBody2D

func _ready() -> void:
	# BŁYSKAWICZNIE ZATRZYMUJEMY GRĘ NA SAMYM STARCIE
	get_tree().paused = true 
	player = get_tree().get_first_node_in_group("player")
	update_stats_display()
	if player != null:
		var st = "--- TWOJE STATYSTYKI ---\n"
		st += "Zdrowie: " + str(player.hp) + " / " + str(5 + player.total_bonus_max_hp) + "\n"
		st += "Mana: " + str(int(player.mana)) + " / " + str(int(player.base_max_mana + player.total_bonus_max_mana)) + "\n"
		st += "Dodatkowe DMG: +" + str(player.total_bonus_damage_percent * 100) + "%\n"
		st += "Prędkość Ruchu: " + str(player.speed + player.total_bonus_speed)
		stats_label.text = st
	
	# Tasujemy całą pulę broni jak talię kart i bierzemy 3 pierwsze!
	var pool_copy = weapon_pool.duplicate()
	pool_copy.shuffle()
	offered_weapons = pool_copy.slice(0, 3)
	
	# Nakładamy nazwy broni na przyciski
	if offered_weapons.size() >= 3:
		# Karta 1
		btn_1.text = offered_weapons[0].weapon_name
		btn_1.icon = offered_weapons[0].icon
		btn_1.expand_icon = true
		btn_1.tooltip_text = build_weapon_tooltip(offered_weapons[0])
		# Karta 2
		btn_2.text = offered_weapons[1].weapon_name
		btn_2.icon = offered_weapons[1].icon
		btn_2.expand_icon = true
		btn_2.tooltip_text = build_weapon_tooltip(offered_weapons[1])
		# Karta 3
		btn_3.text = offered_weapons[2].weapon_name
		btn_3.icon = offered_weapons[2].icon
		btn_3.expand_icon = true
		btn_3.tooltip_text = build_weapon_tooltip(offered_weapons[2])

func select_weapon(index: int) -> void:
	if player != null and offered_weapons.size() > index:
		# Przekazujemy broń do ręki gracza
		player.equip_weapon(offered_weapons[index])
		
	# Odpauzowujemy grę i chowamy ten ekran na zawsze
	get_tree().paused = false
	queue_free() # Usuwamy scenę, bo wybieramy broń tylko raz na start

func _on_weapon_1_pressed() -> void:
	select_weapon(0)


func _on_weapon_2_pressed() -> void:
	select_weapon(1)


func _on_weapon_3_pressed() -> void:
	select_weapon(2)

func build_weapon_tooltip(w: WeaponData) -> String:
	var t = "== " + w.weapon_name.to_upper() + " ==\n"
	t += "Obrażenia: " + str(w.base_attack) + "\n"
	t += "Zasięg: " + str(w.range) + "\n"
	if w.mana_cost > 0:
		t += "Koszt Many: " + str(w.mana_cost) + "\n"
	if w.status_effect != "":
		t += "Status: " + w.status_effect + "\n"
	return t

func update_stats_display() -> void:
	if player == null: return
	
	var st = "=== STATYSTYKI GRACZA ===\n"
	st += "HP: " + str(player.hp) + " / " + str(5 + player.total_bonus_max_hp) + "\n"
	st += "Mana: " + str(int(player.mana)) + " / " + str(int(player.base_max_mana + player.total_bonus_max_mana)) + "\n"
	st += "Obrażenia: +" + str(player.total_bonus_damage_percent * 100) + "%\n"
	st += "Szansa na Kryt: " + str((0.05 + player.total_crit_chance) * 100) + "%\n"
	st += "Dodatkowe Pociski: +" + str(player.total_projectile_count) + "\n"
	st += "Dodatkowe Dashe: +" + str(player.total_dash_count) + "\n"
	st += "Prędkość: " + str(player.speed + player.total_bonus_speed) + "\n"
	
	# Dodanie tagów posiadanych przedmiotów (dla orientacji)
	var all_tags = []
	for item in player.inventory:
		for tag in item.tags:
			if not tag in all_tags: all_tags.append(tag)
	st += "Tagi: " + str(all_tags)
	
	stats_label.text = st
