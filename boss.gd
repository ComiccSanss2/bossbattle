extends CharacterBody2D

@export var max_health = 100
var current_health = 0
var damage_amount = 20 # Quanto male fa l'ascia?

@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var axe_hitbox = $HitboxPivot/AxeHitbox # Assicurati il percorso sia giusto

func _ready():
	current_health = max_health
	add_to_group("Enemy")
	await get_tree().create_timer(2.0).timeout
	anim.play("attacking")
	# Colleghiamo la hitbox dell'ascia
	axe_hitbox.body_entered.connect(_on_axe_hit)

# --- LOGICA QUANDO IL BOSS VIENE COLPITO (L'hai già fatta) ---
func take_damage(amount):
	current_health -= amount
	flash_red()
	print("Boss HP: ", current_health)
	if current_health <= 0:
		die()

func flash_red():
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)

func die():
	anim.play("death") # Se ce l'hai, altrimenti queue_free()
	set_physics_process(false) # Smette di pensare

# --- NUOVA PARTE: QUANDO IL BOSS COLPISCE TE ---
func _on_axe_hit(body):
	if body.name == "Player": # O body.is_in_group("Player") se hai messo il gruppo
		print("Colpito!")
		# ### NUOVO ###
		if body.has_method("take_damage"):
			 # Passiamo il danno (es. 1) e LA POSIZIONE del boss (self.global_position)
			 # Così il player sa calcolare il knockback
			body.take_damage(1, self.global_position)
