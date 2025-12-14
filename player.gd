extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0
const DAMAGE = 10 # Quanto male fai al boss

# Stati (utile per riferimento futuro, anche se ora usiamo is_attacking)
enum {IDLE, RUN, JUMP, FALL, ATTACK}

# Variabile per sapere se stiamo attaccando
var is_attacking = false

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var attacks_pivot = $AttacksPivot
@onready var sword_hitbox = $AttacksPivot/SwordHitbox

func _ready():
	# --- NUOVA PARTE: CONNESSIONE AL BOSS ---
	# Questo dice: "Quando qualcosa entra nell'area della spada,
	# chiama la funzione _on_sword_hit in questo script"
	if not sword_hitbox.body_entered.is_connected(_on_sword_hit):
		sword_hitbox.body_entered.connect(_on_sword_hit)

func _physics_process(delta):
	# 1. Gravità
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 2. Input Movimento (Sempre attivo, anche se attacchi!)
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
		# Giriamo lo sprite SOLO se non stiamo attaccando (Moonwalking style)
		if not is_attacking:
			if direction < 0:
				sprite.flip_h = true
				attacks_pivot.scale.x = -1 # Gira la hitbox a sinistra
			else:
				sprite.flip_h = false
				attacks_pivot.scale.x = 1  # Gira la hitbox a destra
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 3. Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 4. Input Attacco
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

	# 5. Gestione Animazioni
	update_animations()
	
	# 6. Fisica
	move_and_slide()

func start_attack():
	is_attacking = true
	anim.play("attack")
	# Non fermiamo il velocity.x, così scivola mentre colpisce

func update_animations():
	# Se attacchi, l'AnimationPlayer è occupato. Non interromperlo.
	if is_attacking:
		return 

	if not is_on_floor():
		if velocity.y < 0:
			anim.play("jump")
		else:
			anim.play("jump") # O "Fall" se l'hai creata
	elif velocity.x != 0:
		anim.play("run")
	else:
		anim.play("idle")

# --- FUNZIONI CHIAMATE DALL'ANIMATION PLAYER ---

# 1. Da mettere come "Call Method Track" alla fine dell'animazione Attack
func on_attack_finished():
	is_attacking = false

# --- NUOVA PARTE: LOGICA DEL DANNO ---

# 2. Questa viene chiamata automaticamente grazie al codice in _ready()
# quando la hitbox (Area2D) tocca un corpo fisico (CharacterBody2D)
func _on_sword_hit(body):
	# Evitiamo di colpire noi stessi o muri a caso
	if body == self:
		return
		
	# Controlliamo se è un nemico
	# (Assicurati che nello script del Boss tu abbia messo add_to_group("Enemy"))
	if body.is_in_group("Enemy"):
		print("Ho colpito: ", body.name)
		
		# Se il boss ha la funzione take_damage, usala
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE)
