extends CharacterBody2D

# === Nodes ===
@onready var trees_tilemap = get_node("/root/Game/Map/TileMapLayer2")
@onready var main_bar = get_node("/root/Game/UI/MainBar")
@onready var win_label = get_node("/root/Game/UI/WinLabel")

@onready var animation = $AnimatedSprite2D
@onready var camera = $Camera2D
@onready var pee_prompt = get_node("/root/Game/UI/PeePrompt")
@onready var pee_bar = get_node("/root/Game/UI/PeeBar")
@onready var pee_sound = $PeeSound if has_node("PeeSound") else null

# === Movement ===
const SPEED = 300
var direction_name = "bas"

# === Pee logic ===
var can_pee = false
var peeing = false
var pee_timer = 0.0
var pee_time = 2.0
var total_pees = 0
var pee_position = Vector2.ZERO

# === Ready ===
func _ready():
	if pee_prompt:
		pee_prompt.visible = false
	if pee_bar:
		pee_bar.visible = false
	if win_label:
		win_label.visible = false
	if main_bar:
		main_bar.value = 0

# === Physics ===
func _physics_process(delta):
	if not peeing:
		_handle_movement(delta)

	_check_near_tree()

	if can_pee and Input.is_action_just_pressed("pee") and not peeing:
		start_peeing()

	if peeing:
		pee_timer += delta
		if pee_bar:
			pee_bar.value = clamp((pee_timer / pee_time) * 100, 0, 100)
		if pee_timer >= pee_time:
			finish_peeing()

# === Movement ===
func _handle_movement(delta):
	var input_dir = Vector2(
		Input.get_axis("gauche", "droite"),
		Input.get_axis("haut", "bas")
	)

	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * SPEED
		if abs(input_dir.x) > abs(input_dir.y):
			direction_name = "droite" if input_dir.x > 0 else "gauche"
		else:
			direction_name = "haut" if input_dir.y < 0 else "bas"
		if animation:
			animation.play("animation_" + direction_name)
	else:
		velocity = Vector2.ZERO
		if animation:
			if direction_name == "haut":
				animation.play("animation_idle")
			else:
				animation.play("animation_" + direction_name)

	move_and_slide()

# === Check nearby tree ===
func _check_near_tree():
	can_pee = false
	if trees_tilemap == null:
		return
	var player_tile = trees_tilemap.world_to_map(global_position)

	# Check 3x3 tiles
	for x in range(-1, 2):
		for y in range(-1, 2):
			var tile = trees_tilemap.get_cell(player_tile.x + x, player_tile.y + y)
			if tile != -1:
				can_pee = true
				pee_position = trees_tilemap.map_to_world(player_tile + Vector2(x, y)) + trees_tilemap.cell_size / 2
				break

	if pee_prompt:
		pee_prompt.visible = can_pee

# === Start peeing ===
func start_peeing():
	peeing = true
	velocity = Vector2.ZERO
	if pee_prompt:
		pee_prompt.visible = false
	pee_timer = 0.0
	if pee_bar:
		pee_bar.value = 0
		pee_bar.visible = true
	if pee_sound:
		pee_sound.play()
	if camera:
		camera.global_position = pee_position
		camera.zoom = Vector2(0.5, 0.5)

# === Finish peeing ===
func finish_peeing():
	peeing = false
	if pee_bar:
		pee_bar.visible = false
	if pee_sound:
		pee_sound.stop()
	if camera:
		camera.zoom = Vector2(1, 1)
	total_pees += 1
	if main_bar:
		main_bar.value = clamp((total_pees / 5) * 100, 0, 100)

	if total_pees >= 5:
		show_win_message()
		reset_game()

# === Show win ===
func show_win_message():
	if win_label:
		win_label.visible = true
		await get_tree().create_timer(2.0).timeout
		win_label.visible = false

# === Reset ===
func reset_game():
	global_position = Vector2(100, 100)
	total_pees = 0
	if main_bar:
		main_bar.value = 0
