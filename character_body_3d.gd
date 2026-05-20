extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 7
#Variables que vamos a usar
@export var mouse_sensitivity = 0.2
var rot_x=0.0
var mouse_captured = true

#Funcion que llama cuando arranca
func _ready():
	#configuracion inicial del raton
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

#input se llama cada vez que hay un input
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		
		rot_x += - event.relative.y*mouse_sensitivity
		rot_x = clamp(rot_x,-90,90)
		
		$Camera3D.rotation_degrees.x=rot_x
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			mouse_captured = !mouse_captured
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				
			

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
