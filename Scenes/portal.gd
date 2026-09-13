extends Area3D

@export var connect_portal: Area3D
@export var exit_distance: float = 2.0

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("มีวัตถุเข้า Portal: ", body.name)

	if body.name != "Player":
		return

	if connect_portal == null:
		print("ERROR: ยังไม่ได้เชื่อม Connect Portal")
		return

	if body.has_meta("portal_cooldown"):
		return

	body.set_meta("portal_cooldown", true)

	print("เจอ Player!")
	print("Portal ปลายทาง: ", connect_portal.name)

	# ตำแหน่ง Portal ปลายทางใน World
	var target_position = connect_portal.global_position

	# ให้ Player อยู่สูงกว่า Portal เล็กน้อย
	target_position.y += 1.0

	# วาง Player หน้า Portal
	target_position.z += exit_distance

	body.global_position = target_position

	body.velocity = Vector3.ZERO

	print("วาร์ปสำเร็จ")

	await get_tree().create_timer(0.5).timeout

	if is_instance_valid(body):
		body.remove_meta("portal_cooldown")
