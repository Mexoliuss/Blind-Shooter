extends Node3D

var mouse_suelto = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Al presionar Esc, el mouse se vuelve a liberar y mostrar
	if !mouse_suelto and event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_suelto = true
	else:
		if event.is_action_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED	
			mouse_suelto = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func game_over(gano: bool):
	get_tree().paused = false

	# Guardamos el resultado en una variable global simple
	Global.gano = gano

	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	get_tree().change_scene_to_file("res://MenuEndGame.tscn")


func _on_personaje_died() -> void:
	game_over(false)
	
func _on_meta_reached_goal():
	game_over(true)
