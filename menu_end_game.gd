extends Control

@onready var label_resultado = $CenterContainer/VBoxContainer/Label

func _ready():
	#process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	#$CenterContainer/VBoxContainer/RePLAY.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	#$CenterContainer/VBoxContainer/MenuBack.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


	if Global.gano:
		label_resultado.text = "¡GANASTE!"
	else:
		label_resultado.text = "PERDISTE :( (Manco)"

func _on_volver_jugar_pressed():
	print("entra")
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_volver_menu_pressed():
	print("entra")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://MainMenu.tscn")
