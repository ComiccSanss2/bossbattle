extends CharacterBody2D

@export var max_health = 100
var current_health = 0

@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer

func _ready():
	current_health = max_health
	# Aggiungi il boss al gruppo "Enemy" così il player lo riconosce
	add_to_group("Enemy") 

func take_damage(amount):
	current_health -= amount
	print("Boss colpito! HP rimasti: ", current_health)
	
	# Feedback visivo (Lampeggia rosso)
	flash_red()
	
	if current_health <= 0:
		die()

func flash_red():
	# Semplice feedback: diventa rosso per 0.1 secondi
	sprite.modulate = Color(1, 0, 0) # Rosso puro
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1) # Torna normale

func die():
	print("BOSS SCONFITTO")
	anim.play("Death") # Assicurati di avere questa animazione!
	# Disabilita collisioni per non colpirlo da morto
	$CollisionShape2D.set_deferred("disabled", true)
	# await anim.animation_finished
	# queue_free() # Rimuove il boss (o mostra schermata vittoria)
