extends CharacterBody3D

@export var attack_distance = 2
@export var attack_damage = 30
@export var attack_cooldown = 1.0
@export var movement_speed: float = 5.0
@export var target: Node3D
@export var jump_speed = 30
@export var jump_duration = 0.3

var jumping = false
var jump_direction = Vector3.ZERO
var preparing_attack = false
var is_dead = false

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var mesh = $Character_Monster
@onready var anim_player: AnimationPlayer = $Character_Monster/AnimationPlayer  # <-- NUEVO

var vidita_en = 100
var can_attack = true

func play_animation(anim_name: String):  # funcion para el cambio de animacion
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func take_damage(amount):
	vidita_en -= amount
	print("Enemy HP: ", vidita_en)
	if vidita_en <= 0:
		die()  # <-- cambiado

func die():  # funcion de muerte
	if is_dead:
		return
	is_dead = true
	play_animation("death/mixamo_com")
	# Esperamos que termine la animación antes de eliminar
	await get_tree().create_timer(anim_player.get_animation("death/mixamo_com").length).timeout
	queue_free()

func attack_player():
	if not can_attack:
		return
	can_attack = false
	target.take_damage(attack_damage)
	print("ENEMY ATTACK")
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func prepare_attack():
	if preparing_attack or jumping:
		return
	preparing_attack = true
	play_animation("idle/mixamo_com")  # <-- espera en idle antes de saltar
	await get_tree().create_timer(0.5).timeout
	jump_direction = global_position.direction_to(target.global_position)
	jumping = true
	preparing_attack = false
	await get_tree().create_timer(jump_duration).timeout
	jumping = false
	if global_position.distance_to(target.global_position) <= attack_distance:
		attack_player()

func rotate_to_direction(dir: Vector3, delta):
	if dir.length() > 0.1:
		var target_angle = atan2(dir.x, dir.z)
		mesh.rotation.y = lerp_angle(
			mesh.rotation.y,
			target_angle,
			5.0 * delta
		)

func _ready():
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.01
	play_animation("idle/mixamo_com")  # <-- empieza en idle

func _physics_process(delta):
	if is_dead or target == null:  # <-- chequeamos is_dead
		return

	if preparing_attack:
		play_animation("idle/mixamo_com")  # <-- quieto mientras prepara
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if jumping:
		play_animation("jump/mixamo_com")  # <-- animación de salto
		velocity = jump_direction * jump_speed
		rotate_to_direction(jump_direction, delta)
		move_and_slide()
		return

	navigation_agent.target_position = target.global_position

	if navigation_agent.is_navigation_finished():
		play_animation("idle/mixamo_com")  # <-- idle cuando llega
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var next_position = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	velocity = direction * movement_speed

	var distance_to_player = global_position.distance_to(target.global_position)

	if distance_to_player > 30:
		velocity *= 2
	elif distance_to_player > 20 and distance_to_player < 30:
		velocity *= 0.5
	elif distance_to_player <= 10:
		prepare_attack()
		return

	play_animation("run/mixamo_com")  # <-- corre hacia el player
	rotate_to_direction(direction, delta)
	move_and_slide()
