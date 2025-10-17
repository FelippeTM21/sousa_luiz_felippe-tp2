extends CharacterBody2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var pee_particles: GPUParticles2D = $PeeParticles
@onready var cam: Camera2D = get_node_or_null("Camera2D")
@onready var pee_sound: AudioStreamPlayer2D = $PeeSound
@onready var drink_sound: AudioStreamPlayer2D = $DrinkSound 
@onready var boost_timer: Timer = $BoostTimer


const SPEED_BASE := 150.0
var speed := SPEED_BASE
var speed_boost := 1.15   
var boost_seconds := 60.0


@export var items_layer_path: NodePath
@onready var items_layer: TileMapLayer = get_tree().get_first_node_in_group("items_layer")

# le zoom
var zoom_default := Vector2(1.0, 1.0)
var zoom_peeing  := Vector2(1.4, 1.4)
var _zoom_tween: Tween
var direction_name := "bas"

func _ready() -> void:
	pee_particles.emitting = false
	if cam: cam.zoom = zoom_default

	if pee_particles.process_material == null:
		var new_mat := ParticleProcessMaterial.new()
		pee_particles.process_material = new_mat
	var mat := pee_particles.process_material as ParticleProcessMaterial
	mat.gravity = Vector3(0, 0, 0)
	mat.spread = 5.0
	mat.initial_velocity_min = 65.0
	mat.initial_velocity_max = 65.0

	boost_timer.one_shot = true
	boost_timer.timeout.connect(_on_boost_timeout)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("pee"):
		_set_zoom(true)
		_start_peeing()
	elif Input.is_action_just_released("pee"):
		_set_zoom(false)
		_stop_peeing()

func _set_zoom(zoom_in: bool) -> void:
	if not cam:
		return
	if _zoom_tween and _zoom_tween.is_running():
		_zoom_tween.kill()
	_zoom_tween = get_tree().create_tween()
	_zoom_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_property(cam, "zoom", zoom_peeing if zoom_in else zoom_default, 0.2)

func _start_peeing() -> void:
	pee_particles.emitting = true
	if pee_sound and not pee_sound.playing:
		pee_sound.play()

func _stop_peeing() -> void:
	pee_particles.emitting = false
	if pee_sound and pee_sound.playing:
		pee_sound.stop()

func _physics_process(delta: float) -> void:
	
	var direction = Vector2(Input.get_axis("gauche", "droite"), Input.get_axis("haut", "bas"))
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO

   
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			direction_name = "droite" if direction.x > 0 else "gauche"
		else:
			direction_name = "haut" if direction.y < 0 else "bas"

	# Animation
	if direction == Vector2.ZERO:
		animation.play("animation_idle_" + direction_name)
	else:
		animation.play("animation_" + direction_name)

	move_and_slide()

	
	var mat := pee_particles.process_material as ParticleProcessMaterial
	if pee_particles.emitting and mat:
		match direction_name:
			"haut": mat.direction = Vector3(0, -1, 0)
			"bas": mat.direction = Vector3(0, 1, 0)
			"gauche": mat.direction = Vector3(-1, 0, 0)
			"droite": mat.direction = Vector3(1, 0, 0)

	
	_check_drink_pickup()

func _check_drink_pickup() -> void:
	if not items_layer:
		return
	var map_pos: Vector2i = items_layer.local_to_map(items_layer.to_local(global_position))
	var tile_data := items_layer.get_cell_tile_data(map_pos)
	if tile_data:

		items_layer.erase_cell(map_pos)  
		_apply_speed_boost()

func _apply_speed_boost() -> void:
	if drink_sound:
		drink_sound.play()
	speed *= speed_boost   
	boost_timer.start(boost_seconds)

func _on_boost_timeout() -> void:
	speed = SPEED_BASE
