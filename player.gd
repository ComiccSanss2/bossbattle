extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0
const DAMAGE = 10 

# --- PARAMETRI GAME FEEL ---
const RECOIL_FORCE = 400.0 # Forza del rinculo quando colpisci
const KNOCKBACK_FORCE = 300.0 # Forza con cui voli via quando ti colpiscono
const RECOIL_DURATION = 0.2 # Durata del blocco input dopo aver colpito (0.2s è ottimo)

# Stati
enum {IDLE, RUN, JUMP, FALL, ATTACK, HURT} 
var state = IDLE
var is_attacking = false

# Vita e Invincibilità
var health = 5
var is_invincible = false

# Variabile per gestire il tempo di rinculo
var recoil_timer = 0.0

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var attacks_pivot = $AttacksPivot
@onready var sword_hitbox = $AttacksPivot/SwordHitbox

func _ready():
	# Collega il segnale della spada se non è già collegato nell'editor
	if not sword_hitbox.body_entered.is_connected(_on_sword_hit):
		sword_hitbox.body_entered.connect(_on_sword_hit)

func _physics_process(delta):
	# 1. Gravità (Sempre attiva)
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 2. GESTIONE RINCULO (Quando colpisci tu)
	# Se il timer è attivo, vieni spinto indietro e NON puoi muoverti.
	if recoil_timer > 0:
		recoil_timer -= delta
		# Applichiamo forte attrito per fermare lo scatto gradualmente
		velocity.x = move_toward(velocity.x, 0, 1000 * delta) 
		move_and_slide()
		return # <--- IMPORTANTE: Blocca l'esecuzione del resto (Input Lock)

	# 3. GESTIONE HURT (Quando vieni colpito tu)
	# Se sei ferito, non puoi controllare il personaggio
	if state == HURT:
		velocity.x = move_toward(velocity.x, 0, 500 * delta)
		move_and_slide()
		return 

	# 4. INPUT MOVIMENTO (Eseguito solo se non c'è rinculo e non sei ferito)
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
		# Giriamo lo sprite SOLO se non stiamo attaccando
		if not is_attacking:
			if direction < 0:
				sprite.flip_h = true
				attacks_pivot.scale.x = -1 
			else:
				sprite.flip_h = false
				attacks_pivot.scale.x = 1  
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 5. Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 6. Attacco
	# Nota: controlla che nella mappa degli input (Project Settings -> Input Map)
	# tu abbia creato un'azione chiamata "attack". Altrimenti usa "ui_select".
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

	update_animations()
	move_and_slide()

# --- COMBAT SYSTEM ---

func start_attack():
	is_attacking = true
	anim.play("attack") # Assicurati che nell'AnimationPlayer si chiami "attack" (minuscolo)

# Funzione per PRENDERE danno (chiamata dal Boss o nemici)
func take_damage(amount, source_position):
	if is_invincible: return
	$Camera2D.apply_shake(5.0) # Tremore forte
	health -= amount
	print("Ahia! HP Player: ", health)
	
	# Calcolo direzione Knockback (Opposta alla fonte del danno)
	var direction_to_damage = (source_position - global_position).normalized()
	var knockback_dir = -1 if direction_to_damage.x > 0 else 1
	
	# Applichiamo forza
	velocity.x = knockback_dir * KNOCKBACK_FORCE
	velocity.y = -200 # Saltino
	
	# Stati
	state = HURT
	is_attacking = false
	anim.play("jump") # O "hurt" se hai l'animazione
	sprite.modulate = Color(1, 0, 0) # Rosso
	is_invincible = true
	
	# Hitstop (Freeze frame drammatico)
	hit_stop(0.1) 
	
	# Tempo di stordimento (0.3s)
	await get_tree().create_timer(0.3).timeout
	state = IDLE
	sprite.modulate = Color(1, 1, 1) # Torna colore normale
	
	# Gestione Invincibilità (Lampeggio per 1.2s)
	var flash_timer = 0.0
	while flash_timer < 1.2:
		sprite.visible = !sprite.visible 
		await get_tree().create_timer(0.1).timeout
		flash_timer += 0.1
	
	sprite.visible = true
	is_invincible = false
	
	if health <= 0:
		die()

func die():
	print("GAME OVER")
	get_tree().reload_current_scene()

# Funzione per INFLIGGERE danno (quando la spada tocca qualcosa)
func _on_sword_hit(body):
	if body == self: return
	$Camera2D.apply_shake(2.0) # Tremore leggero
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE)
			
		# --- GESTIONE RINCULO (RECOIL) ---
		# 1. Calcola direzione (Opposta a dove guardi)
		var recoil_dir = -1 if attacks_pivot.scale.x > 0 else 1
		
		# 2. Applica velocità istantanea
		velocity.x = recoil_dir * RECOIL_FORCE
		
		# 3. ATTIVA IL BLOCCO INPUT (Il segreto del Game Feel)
		recoil_timer = RECOIL_DURATION 
		
		# 4. Hit Stop leggero
		hit_stop(0.05)

# Funzione per congelare il tempo brevemente
func hit_stop(time_scale_duration):
	Engine.time_scale = 0.05 # Rallenta tutto quasi a zero
	await get_tree().create_timer(time_scale_duration, true, false, true).timeout
	Engine.time_scale = 1.0 # Ripristina velocità normale

func update_animations():
	if is_attacking or state == HURT: return 

	if not is_on_floor():
		if velocity.y < 0: anim.play("jump")
		else: anim.play("jump") 
	elif velocity.x != 0:
		anim.play("walk") # Controlla se nell'AnimationPlayer è "walk" o "run" o "Run"
	else:
		anim.play("Idle") # Controlla maiuscole/minuscole

# Funzione chiamata dall'AnimationPlayer alla fine dell'animazione "attack"
func on_attack_finished():
	is_attacking = false
