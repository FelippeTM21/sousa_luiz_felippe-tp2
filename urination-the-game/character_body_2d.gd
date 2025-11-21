extends CharacterBody2D

signal pee_amount_changed(amount: float)
signal score_changed(score: int)
signal toilet_finished

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var pee_particles: GPUParticles2D = $PeeParticles
@onready var cam: Camera2D = get_node_or_null("Camera2D")
@onready var pee_sound: AudioStreamPlayer2D = $PeeSound
@onready var drink_sound: AudioStreamPlayer2D = $DrinkSound
@onready var boost_timer: Timer = $BoostTimer
@onready var poop_sound: AudioStreamPlayer2D = $PoopSound
@onready var toilet_timer: Timer = $ToiletTimer

const SPEED_BASE := 150.0
var speed := SPEED_BASE
var speed_boost := 1.15
var boost_seconds := 60.0

# jauge
const PEE_MAX := 100.0
var pee_amount := 50.0
var pee_drain_rate := 20.0
var pee_gain_per_drink := 30.0

# vitesse piss
var pee_speed_scale_base := 1.0
var pee_speed_scale_boost := 1.6


@export var items_layer_path: NodePath
@onready var items_layer: TileMapLayer = get_tree().get_first_node_in_group("items_layer")
@onready var trees_layer: TileMapLayer = get_tree().get_first_node_in_group("trees_layer")
@onready var toilets_layer: TileMapLayer = get_tree().get_first_node_in_group("toilet_layer")

# zoom
var zoom_default := Vector2(1.0, 1.0)
var zoom_peeing  := Vector2(1.4, 1.4)
var _zoom_tween: Tween
var direction_name := "bas"


var score: int = 0


var _pee_hit_accum := 0.0
var _points_per_chunk := 1
var _seconds_per_point := 0.30
var _hit_distance := 18.0


var using_toilet := false

func _ready() -> void:
	pee_particles.emitting = false
	pee_particles.speed_scale = pee_speed_scale_base
	if cam:
		cam.zoom = zoom_default

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

	toilet_timer.one_shot = true
	toilet_timer.timeout.connect(_on_toilet_timeout)

	pee_amount_changed.emit(pee_amount)
	score_changed.emit(score)

func _unhandled_input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("use_toilet"):
		_try_use_toilet()
		if using_toilet:
			return

	
	if using_toilet:
		return

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
	if pee_amount <= 0.0:
		return
	pee_particles.emitting = true
	if pee_sound and not pee_sound.playing:
		pee_sound.play()

func _stop_peeing() -> void:
	pee_particles.emitting = false
	if pee_sound and pee_sound.playing:
		pee_sound.stop()

func _physics_process(delta: float) -> void:

	if using_toilet:
		velocity = Vector2.ZERO
		animation.play("animation_idle_" + direction_name)
		move_and_slide()
		return

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

	
	if direction == Vector2.ZERO:
		animation.play("animation_idle_" + direction_name)
	else:
		animation.play("animation_" + direction_name)

	move_and_slide()


	var mat := pee_particles.process_material as ParticleProcessMaterial
	if pee_particles.emitting and mat:
		match direction_name:
			"haut":
				mat.direction = Vector3(0, -1, 0)
			"bas":
				mat.direction = Vector3(0, 1, 0)
			"gauche":
				mat.direction = Vector3(-1, 0, 0)
			"droite":
				mat.direction = Vector3(1, 0, 0)

	
	if pee_particles.emitting:
		var old := pee_amount
		pee_amount = clamp(pee_amount - pee_drain_rate * delta, 0.0, PEE_MAX)
		if pee_amount != old:
			pee_amount_changed.emit(pee_amount)
		if pee_amount <= 0.0:
			_set_zoom(false)
			_stop_peeing()


	_check_tree_peeing(delta)


	_check_drink_pickup()

func _front_point() -> Vector2:
	var dir: Vector2
	match direction_name:
		"haut":
			dir = Vector2(0, -1)
		"bas":
			dir = Vector2(0, 1)
		"gauche":
			dir = Vector2(-1, 0)
		"droite":
			dir = Vector2(1, 0)
		_:
			dir = Vector2(0, 1)
	return global_position + dir * _hit_distance

func _check_tree_peeing(delta: float) -> void:
	if not pee_particles.emitting:
		_pee_hit_accum = 0.0
		return
	if trees_layer == null:
		return
	var p := _front_point()
	var map_pos: Vector2i = trees_layer.local_to_map(trees_layer.to_local(p))
	var tile_data := trees_layer.get_cell_tile_data(map_pos)
	if tile_data:
		_pee_hit_accum += delta * pee_particles.speed_scale
		if _pee_hit_accum >= _seconds_per_point:
			score += _points_per_chunk
			score_changed.emit(score)
			_pee_hit_accum = 0.0
	else:
		_pee_hit_accum = 0.0

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
	
	pee_particles.speed_scale = pee_speed_scale_boost
	
	var old := pee_amount
	pee_amount = clamp(pee_amount + pee_gain_per_drink, 0.0, PEE_MAX)
	if pee_amount != old:
		pee_amount_changed.emit(pee_amount)
	
	boost_timer.start(boost_seconds)

func _on_boost_timeout() -> void:
	speed = SPEED_BASE
	pee_particles.speed_scale = pee_speed_scale_base



func _try_use_toilet() -> void:
	if using_toilet:
		return
	if toilets_layer == null:
		return
	# check if standing on a toilet tile
	var map_pos: Vector2i = toilets_layer.local_to_map(toilets_layer.to_local(global_position))
	var tile_data := toilets_layer.get_cell_tile_data(map_pos)
	if tile_data == null:
		return

	
	var local_pos: Vector2 = toilets_layer.map_to_local(map_pos)
	global_position = toilets_layer.to_global(local_pos)

	
	using_toilet = true
	velocity = Vector2.ZERO
	_stop_peeing()
	_set_zoom(false)

	if poop_sound:
		poop_sound.play()

	toilet_timer.start(3.0) 

func _on_toilet_timeout() -> void:
	using_toilet = false
	toilet_finished.emit()
