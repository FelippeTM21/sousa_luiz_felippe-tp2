extends CharacterBody2D

var speed = 400.0;
 
#func _process(delta: float) -> void:
 
 
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
 
const SPEED = 300.0
 
var directionName = "bas";
 
func _physics_process(_delta: float) -> void:
 
	var direction = Vector2(
		Input.get_axis("gauche", "droite"),
		Input.get_axis("haut", "bas")
	)
 
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * SPEED
	else:
		velocity = Vector2.ZERO
 
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				directionName = "droite";
			else:
				directionName = "gauche";
		else:
			if direction.y < 0:
				directionName = "haut";
			else:
				directionName = "bas";
	if direction == Vector2.ZERO:
		if directionName == "haut":
			animation.play("animation_idle");
	else:
		animation.play("animation_" + directionName);
 
	move_and_slide()
