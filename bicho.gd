extends CharacterBody3D

@export var movement_speed: float = 3.0
@export var target: Node3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var mesh = $Character_Monster

var speed: float = 0.1

func rotate_to_player():
	var direccion = (target.global_position - global_transform.origin).normalized()
	
	if direccion.length() > 0.1:
		var angulo = atan2(direccion.x, direccion.z)
		mesh.rotation.y = angulo
	


func look_follow(delta: float, target_position: Vector3) -> void:
	var direccion = (target_position - global_transform.origin).normalized()
	
	var mirar = Basis.looking_at(direccion, Vector3.UP).orthonormalized()
	
	global_transform.basis = global_transform.basis.slerp(mirar, speed*delta)


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
	#var direccion = Vector3(target.global_position) - Vector3(position)
	#var norm_dir = direccion.normalized()
	
	#var angulo = acos(norm_dir.dot(Vector3(0, 0, 1)))
	#print(norm_dir)
	#rotation.y = -angulo
	#look_follow(delta, target.global_position)
	rotate_to_player()
	
	
	move_and_slide()
