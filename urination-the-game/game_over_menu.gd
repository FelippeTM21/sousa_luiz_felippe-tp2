extends Control

signal respawn_requested

@onready var btn_respawn: Button = $Panel/VBoxContainer/Button_Respawn

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_respawn.pressed.connect(_on_respawn_pressed)

func open() -> void:
	visible = true
	btn_respawn.grab_focus()

func close() -> void:
	visible = false

func _on_respawn_pressed() -> void:
	respawn_requested.emit()
