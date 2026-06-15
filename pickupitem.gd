extends Area3D

@export_enum("battery", "ammo") var item_type: String = "battery"
@export var amount: int = 1

@export var rotation_speed: float = 1.2
@export var bob_height: float = 0.10
@export var bob_speed: float = 2.0

@export var near_light_energy: float = 5.0
@export var light_pulse_amount: float = 1.5
@export var pulse_speed: float = 4.0

@export var repeat_sound_delay: float = 1.2

@onready var detection_area := get_node_or_null("DetectionArea") as Area3D
@onready var glow_light := get_node_or_null("OmniLight3D") as OmniLight3D
@onready var near_sound := get_node_or_null("AudioStreamPlayer3D") as AudioStreamPlayer3D

var start_y: float = 0.0
var player_near_detection: bool = false


func _ready():
	start_y = position.y

	body_entered.connect(_on_pickup_body_entered)
	body_exited.connect(_on_pickup_body_exited)

	if detection_area != null:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
	else:
		print("Falta DetectionArea en ", name)

	if near_sound != null:
		near_sound.finished.connect(_on_near_sound_finished)

	set_highlight(false)


func _process(delta):
	rotate_y(rotation_speed * delta)
	position.y = start_y + sin(Time.get_ticks_msec() / 1000.0 * bob_speed) * bob_height

	if player_near_detection and glow_light != null:
		var t := Time.get_ticks_msec() / 1000.0
		glow_light.light_energy = near_light_energy + sin(t * pulse_speed) * light_pulse_amount


func _on_pickup_body_entered(body):
	if body.has_method("register_pickup"):
		body.register_pickup(self)


func _on_pickup_body_exited(body):
	if body.has_method("unregister_pickup"):
		body.unregister_pickup(self)


func _on_detection_body_entered(body):
	if body.has_method("register_pickup"):
		player_near_detection = true
		set_highlight(true)


func _on_detection_body_exited(body):
	if body.has_method("register_pickup"):
		player_near_detection = false
		set_highlight(false)


func set_highlight(active: bool):
	if glow_light != null:
		glow_light.visible = active

		if active:
			glow_light.light_energy = near_light_energy
		else:
			glow_light.light_energy = 0.0

	if near_sound != null:
		if active:
			if not near_sound.playing:
				near_sound.play()
		else:
			near_sound.stop()


func _on_near_sound_finished():
	if not player_near_detection:
		return

	await get_tree().create_timer(repeat_sound_delay).timeout

	if player_near_detection and near_sound != null:
		near_sound.play()


func pick_up(player):
	if player == null:
		return

	if player.has_method("add_pickup"):
		player.add_pickup(item_type, amount)

	queue_free()
