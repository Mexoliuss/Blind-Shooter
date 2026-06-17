extends CharacterBody3D

@onready var camera = $Camera3D
@onready var gunshot = $Camera3D/Arma/AudioStreamPlayer3D
@onready var anim = $Camera3D/Arma/AnimationPlayer
@onready var muzzle_flash = $Camera3D/Arma/MuzzleFlash
@onready var visor = $Camera3D/SpotLight3D

@export var max_health: float = 100.0
var vidita_ju: float = 100.0

@export var health_regen_delay: float = 8.0 # segundos que tienen que pasar sin recibir daño
@export var health_regen_speed: float = 2.0 # cuánta vida recupera por segundo

var time_since_last_damage: float = 0.0
var is_dead: bool = false


# -------------------------
# VISOR / BATERÍA
# -------------------------

@export var max_battery: float = 100.0
var current_battery: float = 100.0

@export var battery_drain_speed: float = 10.0
@export var battery_pack_charge: float = 50.0

var visor_active: bool = false
var batteries_inventory: int = 0


# -------------------------
# HUD
# -------------------------

@onready var barra_bateria = get_node_or_null("CanvasLayer/InterfaceBase/BarraBateria")
@onready var efecto_visor = get_node_or_null("CanvasLayer/InterfaceBase/EfectoVisor")
@onready var ammo_hud = get_node_or_null("CanvasLayer/InterfaceBase/Ammo")
@onready var battery_hud = get_node_or_null("CanvasLayer/InterfaceBase/Baterias")
@onready var barra_vida = get_node_or_null("CanvasLayer/InterfaceBase/BarraVida")
@onready var efecto_danio = get_node_or_null("CanvasLayer/EfectoDanio")

@onready var world_env := get_tree().get_first_node_in_group("entorno") as WorldEnvironment


# -------------------------
# MOVIMIENTO
# -------------------------

@export var SPEED = 20.0
@export var JUMP_VELOCITY = 7.0

@export var mouse_sensitivity = 0.2
var rot_x = 0.0
var mouse_captured = true


# -------------------------
# ARMA
# -------------------------

@export var arm_damage = 20
@export var ammo_current = 10
const ammo_mag = 10

@export var recharge_speed = 2.0

var magazines_inventory: int = 0
var is_reloading: bool = false


# -------------------------
# PICKUPS CERCANOS
# -------------------------

var nearby_pickups: Array[Node3D] = []


func _ready():
	vidita_ju = max_health
	update_health_hud()

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	ammo_current = clamp(ammo_current, 0, ammo_mag)

	update_hud()


func _process(delta):
	manage_battery(delta)
	manage_health_regeneration(delta)


func _input(event):
	if event.is_action_pressed("Visor"):
		if visor_active:
			desactivar_visor()
		elif current_battery > 0.0:
			activar_visor()

	if event.is_action_pressed("interact"):
		try_pickup_closest()

	if event.is_action_pressed("reload_weapon"):
		reload_weapon()

	if event.is_action_pressed("reload_visor"):
		recharge_visor()

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


# -------------------------
# VISOR
# -------------------------

func activar_visor():
	if current_battery <= 0.0:
		return

	visor_active = true

	if efecto_visor != null:
		efecto_visor.visible = true

	if world_env and world_env.environment:
		world_env.environment.fog_density = 0.005


func desactivar_visor():
	visor_active = false

	if efecto_visor != null:
		efecto_visor.visible = false

	if world_env and world_env.environment:
		world_env.environment.fog_density = 0.3


func manage_battery(delta):
	if visor_active:
		current_battery -= battery_drain_speed * delta

		if current_battery <= 0:
			current_battery = 0
			desactivar_visor()

	if barra_bateria != null:
		barra_bateria.value = current_battery


func recharge_visor():
	if current_battery >= max_battery:
		print("La batería del visor ya está llena.")
		return

	if batteries_inventory <= 0:
		print("No tenés baterías para recargar el visor.")
		return

	batteries_inventory -= 1
	current_battery = min(max_battery, current_battery + battery_pack_charge)

	print("Visor recargado. Baterías restantes: ", batteries_inventory)
	update_hud()


# -------------------------
# ARMA
# -------------------------

func shoot():
	if is_reloading:
		return

	if ammo_current <= 0:
		print("Sin balas. Presioná R para recargar si tenés cargadores.")
		return

	ammo_current -= 1
	update_hud()

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


func reload_weapon():
	if is_reloading:
		return

	if ammo_current >= ammo_mag:
		print("El arma ya tiene el cargador lleno.")
		return

	if magazines_inventory <= 0:
		print("No tenés cargadores.")
		return

	is_reloading = true

	anim.play("recarga")
	await get_tree().create_timer(recharge_speed).timeout

	magazines_inventory -= 1
	ammo_current = ammo_mag
	is_reloading = false

	print("Arma recargada. Cargadores restantes: ", magazines_inventory)
	update_hud()


# -------------------------
# PICKUPS
# -------------------------

func register_pickup(pickup: Node3D):
	if not nearby_pickups.has(pickup):
		nearby_pickups.append(pickup)


func unregister_pickup(pickup: Node3D):
	nearby_pickups.erase(pickup)


func try_pickup_closest():
	cleanup_nearby_pickups()

	if nearby_pickups.is_empty():
		return

	var closest: Node3D = null
	var best_distance: float = 999999.0

	for item in nearby_pickups:
		if not is_instance_valid(item):
			continue

		var distance := global_position.distance_squared_to(item.global_position)

		if distance < best_distance:
			best_distance = distance
			closest = item

	if closest != null and closest.has_method("pick_up"):
		closest.pick_up(self)
		nearby_pickups.erase(closest)


func cleanup_nearby_pickups():
	for i in range(nearby_pickups.size() - 1, -1, -1):
		if not is_instance_valid(nearby_pickups[i]):
			nearby_pickups.remove_at(i)


func add_pickup(item_type: String, amount: int):
	match item_type:
		"battery":
			batteries_inventory += amount
			print("Agarraste batería. Total: ", batteries_inventory)

		"ammo":
			magazines_inventory += amount
			print("Agarraste cargador. Total: ", magazines_inventory)

	update_hud()


# -------------------------
# HUD
# -------------------------

func update_hud():
	if ammo_hud != null:
		ammo_hud.text = str(ammo_current) + "/" + str(ammo_mag) + " | Carg: " + str(magazines_inventory)

	if battery_hud != null:
		battery_hud.text = "Bat: " + str(batteries_inventory)

	if barra_bateria != null:
		barra_bateria.value = current_battery


# -------------------------
# DAÑO / MUERTE
# -------------------------

func take_damage(amount):
	if is_dead:
		return

	vidita_ju -= float(amount)
	vidita_ju = clamp(vidita_ju, 0.0, max_health)

	time_since_last_damage = 0.0

	print("Player HP: ", int(vidita_ju))

	update_health_hud()
	damage_flash()

	if vidita_ju <= 0:
		die()


func die():
	if is_dead:
		return

	is_dead = true
	print("PLAYER DEAD")


func update_health_hud():
	if barra_vida != null:
		barra_vida.max_value = max_health
		barra_vida.value = vidita_ju

	if efecto_danio != null:
		var health_percent: float = vidita_ju / max_health
		var red_intensity: float = 1.0 - health_percent

		var alpha: float = clamp(red_intensity * 0.45, 0.0, 0.65)

		efecto_danio.color = Color(1.0, 0.0, 0.0, alpha)


func damage_flash():
	if efecto_danio == null:
		return

	var health_percent: float = vidita_ju / max_health
	var base_red: float = 1.0 - health_percent
	var base_alpha: float = clamp(base_red * 0.45, 0.0, 0.65)

	efecto_danio.color = Color(1.0, 0.0, 0.0, 0.85)

	var tween = create_tween()
	tween.tween_property(
		efecto_danio,
		"color",
		Color(1.0, 0.0, 0.0, base_alpha),
		0.35
	)


func manage_health_regeneration(delta):
	if is_dead:
		return

	if vidita_ju >= max_health:
		vidita_ju = max_health
		update_health_hud()
		return

	time_since_last_damage += delta

	if time_since_last_damage >= health_regen_delay:
		vidita_ju += health_regen_speed * delta
		vidita_ju = clamp(vidita_ju, 0.0, max_health)

		update_health_hud()
