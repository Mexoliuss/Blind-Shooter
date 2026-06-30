extends Node

var gano: bool = false
var time_elapsed: float = 0
var timer_running: bool = false
var kills: int = 0

func _process(delta):
	if timer_running:
		time_elapsed += delta

func start_timer():
	time_elapsed = 0.0
	kills = 0
	timer_running = true

func stop_timer():
	timer_running = false

func register_kill():
	kills += 1

func get_formatted_time() -> String:
	var minutes = int(time_elapsed) / 60
	var seconds = int(time_elapsed) % 60
	var milliseconds = int((time_elapsed - int(time_elapsed)) * 100)
	return "%02d:%02d:%02d" % [minutes, seconds, milliseconds]

func reset():
	time_elapsed = 0.0
	kills = 0
	timer_running = false
