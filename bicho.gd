extends CharacterBody3D

var movement_speed: float = 5.0
var movement_target_position: Vector3 = Vector3(-100.0,0.0,2.0)

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var default_3d_map_rid: RID = get_world_3d().get_navigation_map()

var movement_delta: float
var path_point_margin: float = 0.5

var current_path_index: int = 0
var current_path_point: Vector3
var current_path: PackedVector3Array

func set_movement_target(target_position:Vector3):
	var start_position:Vector3 = global_transform.origin
	
	current_path = NavigationServer3D.map_get_path(
		default_3d_map_rid,
		start_position,
		target_position,
		true
	)

	if not current_path.is_empty():
		current_path_index = 0
		current_path_point = current_path[0]
		
	navigation_agent.set_target_position(target_position)
	
func _ready():
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

	# Make sure to not await during _ready.
	actor_setup.call_deferred()

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	# Now that the navigation map is no longer empty, set the movement target.
	set_movement_target(movement_target_position)

	

func _physics_process(delta):
	if navigation_agent.is_navigation_finished():
		return

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	velocity = current_agent_position.direction_to(next_path_position) * movement_speed
	move_and_slide()
	
	if current_path.is_empty():
		return

	movement_delta = movement_speed * delta

	if global_transform.origin.distance_to(current_path_point) <= path_point_margin:
		current_path_index += 1
		if current_path_index >= current_path.size():
			current_path = []
			current_path_index = 0
			current_path_point = global_transform.origin
			return

	current_path_point = current_path[current_path_index]

	var new_velocity: Vector3 = global_transform.origin.direction_to(current_path_point) * movement_delta

	global_transform.origin = global_transform.origin.move_toward(global_transform.origin + new_velocity, movement_delta)
	
