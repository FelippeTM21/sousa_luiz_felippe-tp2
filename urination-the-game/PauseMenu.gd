extends Control

signal resume_requested
signal restart_requested

@onready var btn_continue: Button = $Panel/VBoxContainer/Button_Continuer
@onready var btn_restart: Button  = $Panel/VBoxContainer/Button_Recommencer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS 
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)

func open() -> void:
	visible = true
	btn_continue.grab_focus()

func close() -> void:
	visible = false

func _on_continue_pressed() -> void:
	resume_requested.emit()

func _on_restart_pressed() -> void:
	restart_requested.emit()
