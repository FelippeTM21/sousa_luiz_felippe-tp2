extends Node

@onready var pause_menu: Control = $CanvasLayer/PauseMenu

func _ready() -> void:
	
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.restart_requested.connect(_restart_game)

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
