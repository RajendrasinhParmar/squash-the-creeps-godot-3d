extends CharacterBody3D

# Emitted when the player was hit by a mob
signal hit

# How fast the player moves in meters per second
@export var speed = 14

# The downward acceleration when in the air, in meters per second squared
@export var fall_acceleration = 75

# Vertical impulse applied to the character upon jumping in meters per seconds
@export var jump_impulse = 20

# Vertical impulse applied to the character upon bouncing over a mob in meters per second
@export var bounce_impulse = 16

var target_velocity = Vector3.ZERO

func _physics_process(delta):
	# We create a local variable to store the input direction
	var direction = Vector3.ZERO
	
	# We check for each move input and update the direction accordingly
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		# Notice how we are working on vector's x and z axes
		# In 3D, the XZ plan is a ground plane.
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$Pivot.look_at(position + direction, Vector3.UP)
		$AnimationPlayer.speed_scale = 4
	else:
		$AnimationPlayer.speed_scale = 1
	
	# Ground velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	# Vertical velocity
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	
	# Moving the character
	velocity = target_velocity
	
	# Jumping
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse
	
	# Iterate through all collisions that occurred this frame
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)
		
		# If the collision is with ground
		if (collision.get_collider() == null):
			continue
		
		# If the collision is with a mob
		if collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			
			# We check that we are hitting it from above or not?
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				mob.squash()
				target_velocity.y = bounce_impulse
	move_and_slide()
	$Pivot.rotation.x = PI / 6 * velocity.y / jump_impulse

func die():
	hit.emit()
	queue_free()

func _on_mob_detector_body_entered(body):
	die()
