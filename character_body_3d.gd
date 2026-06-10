extends CharacterBody3D

@onready var camera = $Camera3D #camara para tener a mano
@onready var gunshot = $Camera3D/Arma/AudioStreamPlayer3D #sonido de disparo
@onready var anim = $Camera3D/Arma/AnimationPlayer #animacion de disparo
@onready var muzzle_flash = $Camera3D/Arma/MuzzleFlash #flash de el disparo
@onready var visor = $Camera3D/SpotLight3D #Luz del visor
var vidita_ju = 100 #vida del jugador

# Variables de la mecánica del Visor
@export var max_battery: float = 100.0 #bateria total
var current_battery: float = 100.0 #cuanto le queda
@export var battery_drain_speed: float = 10.0  # Cuánta batería gasta por segundo
var visor_active: bool = false #si esta activo o no

# Barra de batería (Rutas corregidas de forma interna ya que están dentro del Player)
@onready var barra_bateria = $CanvasLayer/InterfaceBase/BarraBateria #esto es para el hud
@onready var efecto_visor = $CanvasLayer/InterfaceBase/EfectoVisor   # Referencia al filtro verde
@onready var ammo_hud = $CanvasLayer/InterfaceBase/Ammo   # Referencia al filtro verde
# Referencia al entorno para modificar la niebla (Mantenemos el grupo solo para el mapa)
@onready var world_env: WorldEnvironment = get_tree().get_first_node_in_group("entorno") 

@export var SPEED = 20.0 #velocidad de movimiento 
@export var JUMP_VELOCITY = 7 #de salto ?

# Variables de cámara
@export var mouse_sensitivity = 0.2 #sensibilidad del jugador
var rot_x = 0.0
var mouse_captured = true

#Variables de el arma
@export var arm_damage = 20
@export var ammo_current = 10
const ammo_mag = 10
@export var recharge_speed = 2

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ammo_hud.text=str(ammo_current) + "/" + str(ammo_mag)

func _process(delta):
	manage_battery(delta) #funcion para manejar toda la parte de la bateria

func activar_visor(): #todo esto es para activar el visor
	visor_active = true
	
	# Muestra el filtro verde
	if efecto_visor != null:
		efecto_visor.visible = true
	
	# despeja la niebla
	if world_env and world_env.environment:
		world_env.environment.fog_density = 0.005 #la baja mucho, en realidad

func desactivar_visor():
	visor_active = false
	
	# y esto, es lo contrario
	if efecto_visor != null:
		efecto_visor.visible = false
	
	# ¡VUELVE LA NIEBLA DE TERROR ORIGINAL!
	if world_env and world_env.environment:
		world_env.environment.fog_density = 1.0

func manage_battery(delta): #esto, es para el tema de la bateria
	if visor_active:
		current_battery -= battery_drain_speed * delta
		if current_battery <= 0:
			current_battery = 0
			desactivar_visor() # Apagón forzado si se agota
	elif current_battery<max_battery:
		current_battery += battery_drain_speed * delta * 0.1
	
	if barra_bateria != null:
		barra_bateria.value = current_battery

func _input(event):
	# CONTROL DEL VISOR: Detecta una sola pulsación limpia de la acción "Visor"
	if event.is_action_pressed("Visor"):
		if visor_active:
			desactivar_visor() # Si estaba puesto, se lo saca
		elif current_battery > 0.0:
			activar_visor()    # Si estaba sacado, se lo pone

	# Control del Mouse
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		rot_x += -event.relative.y * mouse_sensitivity
		rot_x = clamp(rot_x, -90, 90)
		$Camera3D.rotation_degrees.x = rot_x
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			mouse_captured = !mouse_captured
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
		ammo_hud.text=str(ammo_current) + "/" + str(ammo_mag)
		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func shoot():
	
	if ammo_current!=0:
		ammo_current-=1
		gunshot.play()
		anim.play("shoot")
		muzzle_flash.visible = true
		await get_tree().create_timer(0.05).timeout
		muzzle_flash.visible = false
		muzzle_flash.rotation.z = randf_range(-0.2, 0.2)
		
		var space_state = get_world_3d().direct_space_state
		var origin = camera.global_transform.origin
		var end = origin + -camera.global_transform.basis.z * 100
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		var result = space_state.intersect_ray(query)

		if result:
			print("DISPARO IMPACTÓ")
			if result.collider.has_method("take_damage"):
				result.collider.take_damage(arm_damage)
	else:
		anim.play("recarga")
		await get_tree().create_timer(recharge_speed).timeout
		ammo_current=ammo_mag

func take_damage(amount): #aca toma daño
	vidita_ju -= amount
	print("Player HP: ", vidita_ju)
	if vidita_ju <= 0:
		die()

func die():
	print("PLAYER DEAD") #esto es si se muere
