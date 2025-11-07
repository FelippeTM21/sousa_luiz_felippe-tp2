extends Node

@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var game_over_menu: Control = $CanvasLayer/GameOverMenu

var game_timer: Timer

func _ready() -> void:
	# Pause menu signals
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.restart_requested.connect(_restart_game)

	# Game Over menu signals
	game_over_menu.respawn_requested.connect(_restart_game)
	game_over_menu.next_requested.connect(_on_next_level_requested)

	# 1-minute game timer
	game_timer = Timer.new()
	game_timer.one_shot = true
	game_timer.wait_time = 60.0
	add_child(game_timer)
	game_timer.timeout.connect(_on_game_over_timeout)
	game_timer.start()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()

func _pause_game() -> void:
	get_tree().paused = true
	pause_menu.open()

func _resume_game() -> void:
	pause_menu.close()
	get_tree().paused = false

func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_game_over_timeout() -> void:
	get_tree().paused = true
	game_over_menu.open()

func _on_next_level_requested() -> void:
	# Placeholder: not implemented yet
	pass
