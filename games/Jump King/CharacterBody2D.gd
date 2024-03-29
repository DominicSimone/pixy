extends CharacterBody2D

@onready var NN = get_parent()
@onready var sprite = $Sprite2D

const WALK_SPEED = 100.0
const JUMP_SPEED = 120.0

const jump_range = Vector2(-80, -360)
const max_jump_time: float = 0.8
var current_jump_time: float = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * 0.8

var debug_position: Vector2

func _ready():
	debug_position = global_position

func reset():
	global_position = debug_position
	velocity = Vector2.ZERO
	current_jump_time = 0

func _physics_process(delta):
	
	if is_on_ceiling():
		velocity.x *= 0.5
	
	if is_on_wall():
		velocity.x = get_wall_normal().x * JUMP_SPEED * 0.3
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	
	else:
		if NN.frame_inputs["jump"]:
			sprite.frame = 1
			current_jump_time += delta
			velocity.x = move_toward(velocity.x, 0, JUMP_SPEED)
		else:
			sprite.frame = 0
			if current_jump_time > 0:
				var jump = max(lerp(jump_range.x, jump_range.y, current_jump_time / max_jump_time), jump_range.y)
				current_jump_time = 0
				velocity.y = jump
				velocity.x = (int(NN.frame_inputs["right"]) - int(NN.frame_inputs["left"])) * JUMP_SPEED
			else:
				var direction =  int(NN.frame_inputs["right"]) - int(NN.frame_inputs["left"])
				if direction:
					velocity.x = direction * WALK_SPEED
				else:
					velocity.x = move_toward(velocity.x, 0, WALK_SPEED)

	if Input.is_key_pressed(KEY_R):
		reset()

	move_and_slide()
	

