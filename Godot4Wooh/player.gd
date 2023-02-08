extends CharacterBody2D
class_name MyPlayerWOO


enum {
	ABRUH
}

enum {
	Yoddlehee
}

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	print(new_pls())


func new_pls() -> MyPlayerWOO:
	return MyPlayerWOO.new()


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta * scale.y
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY * scale.y
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED * scale.x
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
#	velocity *= scale
	
	move_and_slide()
