extends CharacterBody3D

@export var attack_distance = 2.0
@export var attack_damage = 10
@export var attack_cooldown = 1.0
var can_attack = true

@export var movement_speed: float = 3.0
@export var target: Node3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var mesh = $Character_Monster

var speed: float = 0.1
var vidita_en = 100

#Funcion de daño al enemigo
func take_damage(amount):

	vidita_en -= amount

	print("Enemy HP: ", vidita_en)

	if vidita_en <= 0:
		queue_free()

#Funcion para que ataque al player
func attack_player():
	# Si todavía está en cooldown
	if not can_attack:
		return
	
	# Bloqueamos ataque
	can_attack = false

	# HACER DAÑO AL PLAYER
	target.take_damage(attack_damage)
	print("ENEMY ATTACK")
	# Esperar cooldown
	await get_tree().create_timer(attack_cooldown).timeout

	# Puede volver a atacar
	can_attack = true

func rotate_to_player():
	var direccion = (target.global_position - global_transform.origin).normalized()
	
	if direccion.length() > 0.1:
		var angulo = atan2(direccion.x, direccion.z)
		mesh.rotation.y = angulo
	


func _ready():
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.01


func _physics_process(delta):
	if target == null:
		return

	# Actualiza el destino al player
	navigation_agent.target_position = target.global_position

	# Si ya llegó, no se mueve
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Siguiente punto del path
	var next_position = navigation_agent.get_next_path_position()

	# Dirección hacia ese punto
	var direction = global_position.direction_to(next_position)
	
	velocity = direction * movement_speed
	
	
	# Distancia al jugador
	var distance_to_player = global_position.distance_to(target.global_position)

	# SI ESTÁ CERCA → ATACAR
	if distance_to_player <= attack_distance:

		velocity = Vector3.ZERO

		attack_player()

		move_and_slide()

		return
	#var direccion = Vector3(target.global_position) - Vector3(position)
	#var norm_dir = direccion.normalized()
	
	#var angulo = acos(norm_dir.dot(Vector3(0, 0, 1)))
	#print(norm_dir)
	#rotation.y = -angulo
	#look_follow(delta, target.global_position)
	rotate_to_player()
	
	
	move_and_slide()
