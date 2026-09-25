class_name Player
extends CharacterBody2D

@export var SPEED : float = 60.0
var is_attaking: bool = false
var facing_direction := Vector2.DOWN

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: Area2D = $SwordHitbox

#Restringir el movimiento del jugador
var can_move: bool = true

#Que tan lejos del centro del jugador aparece la hitbox de la espada
const SWORD_OFFSET: float = 10.0

func _ready() -> void:
	pass
	
	
func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("ATAQUE"):
		attack()
		
	if is_attaking:
		return
	
	if not can_move:
		velocity = Vector2.ZERO
		return
	
	var direction = Input.get_vector(
	"IZQUIERDA",
	"DERECHA",
	"ARRIBA",
	"ABAJO")
	velocity = direction * SPEED
	
	if direction == Vector2.ZERO:
		if facing_direction == Vector2.UP:
			animated_sprite_2d.play("walk_up")
		elif facing_direction == Vector2.DOWN:
			animated_sprite_2d.play("walk_down")
		elif facing_direction == Vector2.LEFT:
			animated_sprite_2d.play("walk_left")
		elif facing_direction == Vector2.RIGHT:
			animated_sprite_2d.play("walk_right")
		animated_sprite_2d.pause()
		return
	
	if direction.x > 0:
		facing_direction = Vector2.RIGHT
		animated_sprite_2d.play("walk_right")
	elif direction.x < 0:
		facing_direction = Vector2.LEFT
		animated_sprite_2d.play("walk_left")
	elif direction.y > 0:
		facing_direction = Vector2.DOWN
		animated_sprite_2d.play("walk_down")
	elif direction.y < 0:
		facing_direction = Vector2.UP
		animated_sprite_2d.play("walk_up")
		
	move_and_slide()

func attack() -> void:
	is_attaking = true
	
	#Movemos la hitbox de la espada hacia donde mira el jugador
	sword_hitbox.position = facing_direction * SWORD_OFFSET
	sword_hitbox.monitoring = true
	
	if facing_direction == Vector2.UP:
		animated_sprite_2d.play("sword_up")
	elif facing_direction == Vector2.DOWN:
		animated_sprite_2d.play("sword_down")
	elif facing_direction == Vector2.LEFT:
		animated_sprite_2d.play("sword_left")
	elif facing_direction == Vector2.RIGHT:
		animated_sprite_2d.play("sword_right")
		
	await animated_sprite_2d.animation_finished
	
	#Apagamos la hitbox para que no siga haciendo daño fuera del golpe
	sword_hitbox.monitoring = false
	is_attaking = false
		

func move_transition_player(direction: Vector2, distance: float) -> void:
	can_move = false
	
	if direction.x > 0:
		animated_sprite_2d.play("walk_right")
	elif direction.x < 0:
		animated_sprite_2d.play("walk_left")
	elif direction.y > 0:
		animated_sprite_2d.play("walk_down")
	elif direction.y < 0:
		animated_sprite_2d.play("walk_up")
		
	var tween = create_tween()
	tween.tween_property(self, "position", position + direction * distance, 0.5)
	await tween.finished
