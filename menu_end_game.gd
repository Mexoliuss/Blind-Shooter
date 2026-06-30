extends Control

@onready var label_resultado = $CenterContainer/PanelContainer/VBoxContainer/TextoFin
@onready var label_time = $CenterContainer/PanelContainer/VBoxContainer/Time
@onready var label_kills = $CenterContainer/PanelContainer/VBoxContainer/Kills

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


	if Global.gano:
		label_resultado.text = "¡GANASTE!"
	else:
		label_resultado.text = "PERDISTE :( (Manco)"
		
	label_time.text = "Tiempo de Juego: " + Global.get_formatted_time()
	label_kills.text = "Enemigos matados: " + str(Global.kills)

func _on_volver_jugar_pressed():
	print("entra")
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_volver_menu_pressed():
	print("entra")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://MainMenu.tscn")
