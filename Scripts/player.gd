extends CharacterBody3D

# ---------- VARIABLES ---------- #

@export_category("Player Properties")
@export var move_speed : float = 6
@export var jump_force : float = 5
@export var follow_lerp_factor : float = 4
@export var jump_limit : int = 2

@export_group("Game Juice")
@export var jumpStretchSize := Vector3(0.8, 1.2, 0.8)

var is_grounded = false
var can_double_jump = false

@onready var model = $gobot
@onready var animation = $gobot.find_child("AnimationPlayer", true, false)
@onready var spring_arm = %Gimbal
@onready var particle_trail = $ParticleTrail
@onready var footsteps = $Footsteps

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2


# ---------- FUNCTIONS ---------- #

func _ready():
	# ซ่อนเมาส์ตั้งแต่เริ่มเกม
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	# สำหรับ HTML5 ต้องคลิกก่อนถึงจะซ่อนเมาส์
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# กด ESC (ผ่าน Action ui_cancel) → แสดงเมาส์กลับมา
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _process(delta):
	player_animations()
	get_input(delta)
	spring_arm.position = lerp(spring_arm.position, position, delta * follow_lerp_factor)
	
	if is_moving():
		var look_direction = Vector2(velocity.z, velocity.x)
		model.rotation.y = lerp_angle(model.rotation.y, look_direction.angle(), delta * 12)
	
	is_grounded = is_on_floor()
	if is_grounded:
		can_double_jump = true
	
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			perform_jump()
		elif can_double_jump and is_moving():
			perform_flip_jump()
	
	velocity.y -= gravity * delta


func perform_jump():
	AudioManager.jump_sfx.play()
	AudioManager.jump_sfx.pitch_scale = 1.12
	jumpTween()
	play_animation_by_name("Jump")
	velocity.y = jump_force


func perform_flip_jump():
	AudioManager.jump_sfx.play()
	AudioManager.jump_sfx.pitch_scale = 0.8
	play_animation_by_name("Flip")
	velocity.y = jump_force
	if animation != null:
		await animation.animation_finished
	can_double_jump = false
	play_animation_by_name("Jump")


func is_moving():
	return abs(velocity.z) > 0 or abs(velocity.x) > 0


func jumpTween():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", jumpStretchSize, 0.1)
	tween.tween_property(self, "scale", Vector3(1,1,1), 0.1)


func get_input(_delta):
	var move_direction := Vector3.ZERO
	move_direction.x = Input.get_axis("move_left", "move_right")
	move_direction.z = Input.get_axis("move_forward", "move_back")
	move_direction = move_direction.rotated(Vector3.UP, spring_arm.rotation.y).normalized()
	velocity = Vector3(move_direction.x * move_speed, velocity.y, move_direction.z * move_speed)
	move_and_slide()


func player_animations():
	particle_trail.emitting = false
	footsteps.stream_paused = true
	if is_on_floor():
		if is_moving():
			play_animation_by_name("Run")
			particle_trail.emitting = true
			footsteps.stream_paused = false
		else:
			play_animation_by_name("Idle")


func play_animation_by_name(animation_name):
	if animation == null:
		return
	var animation_list = animation.get_animation_list()
	var target_animation = ""
	for anim_name in animation_list:
		if anim_name == animation_name:
			target_animation = anim_name
			break
	if target_animation == "":
		for anim_name in animation_list:
			if anim_name.to_lower().contains(animation_name.to_lower()):
				target_animation = anim_name
				break
	if target_animation == "" and animation_name == "Flip":
		for anim_name in animation_list:
			if anim_name.to_lower().contains("jump"):
				target_animation = anim_name
				break
	if target_animation != "" and animation.current_animation != target_animation:
		animation.play(target_animation, 0.5)


func _on_portal_2_body_entered(body: Node3D) -> void:
	pass


func _on_portal_body_entered(body: Node3D) -> void:
	pass
