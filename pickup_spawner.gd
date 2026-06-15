extends Node3D

@export var battery_pickup_scene: PackedScene
@export var ammo_pickup_scene: PackedScene

@export var spawn_points_parent: NodePath

@export var initial_items: int = 10
@export var max_items_alive: int = 10
@export var respawn_time: float = 25.0

@export_range(0.0, 1.0, 0.01) var battery_chance: float = 0.5

var spawn_points: Array[Marker3D] = []
var alive_items: Array[Node3D] = []


func _ready():
	randomize()
	load_spawn_points()

	for i in range(initial_items):
		spawn_one()

	respawn_loop()


func load_spawn_points():
	spawn_points.clear()

	var parent := get_node_or_null(spawn_points_parent)

	if parent == null:
		print("No se encontró el nodo PickupSpawnPoints.")
		return

	for child in parent.get_children():
		if child is Marker3D:
			spawn_points.append(child)

	print("Puntos de spawn cargados: ", spawn_points.size())


func respawn_loop():
	while true:
		await get_tree().create_timer(respawn_time).timeout

		cleanup_alive_items()

		if alive_items.size() < max_items_alive:
			spawn_one()


func spawn_one():
	cleanup_alive_items()

	if spawn_points.is_empty():
		print("No hay puntos de spawn disponibles.")
		return

	var available_points: Array[Marker3D] = []

	for point in spawn_points:
		var used := false

		for item in alive_items:
			if is_instance_valid(item) and item.get_meta("spawn_point", null) == point:
				used = true
				break

		if not used:
			available_points.append(point)

	if available_points.is_empty():
		return

	var marker: Marker3D = available_points.pick_random() as Marker3D

	var chosen_scene: PackedScene = null

	if randf() <= battery_chance:
		chosen_scene = battery_pickup_scene
	else:
		chosen_scene = ammo_pickup_scene

	if chosen_scene == null:
		print("Falta asignar BatteryPickup o AmmoPickup en el Inspector.")
		return

	var item: Node3D = chosen_scene.instantiate() as Node3D

	add_child(item)
	item.global_transform = marker.global_transform
	item.set_meta("spawn_point", marker)

	alive_items.append(item)


func cleanup_alive_items():
	for i in range(alive_items.size() - 1, -1, -1):
		if not is_instance_valid(alive_items[i]):
			alive_items.remove_at(i)
