extends CharacterBody2D

# --- Referencias a nodos ---
@onready var visual: Sprite2D = $Visual
@onready var ray_cast_2d_up: RayCast2D = $RayCast2D_UP
@onready var ray_cast_2d_down: RayCast2D = $RayCast2D_DOWN
@onready var ray_cast_2d_left: RayCast2D = $RayCast2D_LEFT
@onready var ray_cast_2d_rigth: RayCast2D = $RayCast2D_RIGTH
@onready var hurtbox: Area2D = $Hurtbox
@onready var state_timer: Timer = $StateTimer

# --- Configuracion (ajustable desde el Inspector) ---
@export var SPEED: float = 40.0
@export var ROTATION_SPEED: float = 10.0  # que tan rapido "giran las aspas" mientras vuela
@export var FLY_TIME_MIN: float = 3.0     # segundos minimos volando
@export var FLY_TIME_MAX: float = 5.0     # segundos maximos volando
@export var LAND_TIME: float = 1.5        # segundos aterrizado y vulnerable
@export var MAX_HEALTH: int = 1

var health: int
var direction: Vector2 = Vector2.DOWN

var array_direction: Array = [
	Vector2.UP,
	Vector2.DOWN,
	Vector2.LEFT,
	Vector2.RIGHT
]

# Los dos estados posibles del Peahat
enum State { FLYING, LANDED }
var current_state: State = State.FLYING


func _ready() -> void:
	print("PEAHAT: _ready() empezo")
	health = MAX_HEALTH

	# Conectamos las señales por codigo (no hace falta tocar el editor)
	state_timer.timeout.connect(_on_state_timer_timeout)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	_enter_flying_state()
	print("PEAHAT: _ready() termino. Estado=", current_state, " Direccion=", direction)


func _physics_process(delta: float) -> void:
	print("PEAHAT: physics_process corriendo. Estado=", current_state, " Posicion=", global_position)
	match current_state:
		State.FLYING:
			_process_flying(delta)
		State.LANDED:
			_process_landed()


func _process_flying(delta: float) -> void:
	# Misma logica de movimiento y evasion de paredes que el Octorok
	velocity = direction * SPEED
	move_and_slide()

	if direction == Vector2.UP and ray_cast_2d_up.is_colliding():
		change_direction()
	elif direction == Vector2.DOWN and ray_cast_2d_down.is_colliding():
		change_direction()
	elif direction == Vector2.LEFT and ray_cast_2d_left.is_colliding():
		change_direction()
	elif direction == Vector2.RIGHT and ray_cast_2d_rigth.is_colliding():
		change_direction()

	# Efecto visual: el sprite "gira" mientras vuela (simula las aspas)
	visual.rotation += ROTATION_SPEED * delta


func _process_landed() -> void:
	# Aterrizado: se queda quieto
	velocity = Vector2.ZERO
	move_and_slide()


func change_direction() -> void:
	var available_directions: Array = []

	if not ray_cast_2d_up.is_colliding():
		available_directions.append(Vector2.UP)
	if not ray_cast_2d_down.is_colliding():
		available_directions.append(Vector2.DOWN)
	if not ray_cast_2d_left.is_colliding():
		available_directions.append(Vector2.LEFT)
	if not ray_cast_2d_rigth.is_colliding():
		available_directions.append(Vector2.RIGHT)

	if available_directions.is_empty():
		return

	direction = available_directions.pick_random()


func _enter_flying_state() -> void:
	current_state = State.FLYING
	hurtbox.monitoring = false          # invulnerable mientras vuela
	visual.modulate = Color(0.5, 0.8, 1.0)  # tinte azulado = "no le puedes pegar"
	direction = array_direction.pick_random()
	state_timer.wait_time = randf_range(FLY_TIME_MIN, FLY_TIME_MAX)
	state_timer.start()


func _enter_landed_state() -> void:
	current_state = State.LANDED
	hurtbox.monitoring = true           # vulnerable mientras esta aterrizado
	visual.modulate = Color(1, 1, 1)    # color normal = "ahora si le puedes pegar"
	visual.rotation = 0.0
	state_timer.wait_time = LAND_TIME
	state_timer.start()


func _on_state_timer_timeout() -> void:
	if current_state == State.FLYING:
		_enter_landed_state()
	else:
		_enter_flying_state()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if current_state != State.LANDED:
		return  # esta volando: ignoramos cualquier golpe

	if area.is_in_group("sword_hitbox"):
		take_damage(1)


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()


func die() -> void:
	queue_free()
