extends Camera2D

var shake_strength = 0.0
var shake_decay = 5.0 # Quanto velocemente smette di tremare
@export var tilemap: TileMap # O TileMap se usi Godot < 4.3


func _ready():
	if tilemap:
		setup_camera_limits()

func setup_camera_limits():
	# Ottiene il rettangolo usato dai tiles (in coordinate tiles)
	var map_rect = tilemap.get_used_rect()
	# Ottiene la grandezza di un tile (es. 64px)
	var tile_size = tilemap.tile_set.tile_size.x * tilemap.scale.x
	
	# Calcola i limiti in pixel
	limit_left = map_rect.position.x * tile_size
	limit_top = map_rect.position.y * tile_size
	limit_right = (map_rect.position.x + map_rect.size.x) * tile_size
	limit_bottom = (map_rect.position.y + map_rect.size.y) * tile_size
	
	
func _process(delta):
	if shake_strength > 0:
		shake_strength = move_toward(shake_strength, 0, shake_decay * delta)
		# Sposta la camera a caso
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)

# Chiama questa funzione dal Player quando colpisci: camera.apply_shake(10)
func apply_shake(strength):
	shake_strength = strength
