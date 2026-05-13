extends Resource
class_name ItemData

@export var item_name: String = "Nowy Przedmiot"
@export var icon: Texture2D # Zmienna na ikonę przedmiotu
@export_multiline var description: String = "" # export_multiline daje duże pole tekstowe
@export var tags: Array[String] = [] # np. ["magic", "melee", "ALL"]

# --- BONUSY BAZOWE ---
@export var bonus_strength: int = 0
@export var bonus_dexterity: int = 0
@export var bonus_intelligence: int = 0

# --- NOWE STATYSTYKI ---
@export var bonus_max_hp: int = 0     # Zwiększa maksymalne zdrowie
@export var bonus_max_mana: int = 0     # Zwiększa maksymalne zdrowie
@export var bonus_speed: float = 0.0  # Zwiększa prędkość poruszania się

# --- BONUSY ZAAWANSOWANE ---
@export var bonus_projectiles: int = 0
@export var bonus_damage_percent: float = 0.0 # np. 0.3 dla +30% Osełki
@export var bonus_crit_chance: float = 0.0
@export var apply_status: String = "" # np. "Poison" z Fiolki Trucizny
