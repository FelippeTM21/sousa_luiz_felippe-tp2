extends Control

signal respawn_requested
signal next_requested

@onready var btn_respawn: Button = $Panel/VBoxContainer/Button_Respawn
@onready var btn_next: Button = $Panel/VBoxContainer/Button_Next

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

func _on_next_pressed() -> void:
	next_requested.emit()
