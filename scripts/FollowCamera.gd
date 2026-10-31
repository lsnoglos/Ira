extends Node3D
## Third-person camera. Orbit drag, shoulder-friendly framing and camera obstruction.
var target: Node3D
var yaw := 0.0
var pitch := -0.25
var distance := 5.7
var camera: Camera3D
var arm: SpringArm3D
var follow_speed := 9.0

func _ready() -> void:
    name = "ThirdPersonCameraRig"
    arm = SpringArm3D.new()
    arm.name = "CollisionAwareSpringArm"
    arm.spring_length = distance
    arm.margin = 0.12
    add_child(arm)
    camera = Camera3D.new()
    camera.name = "Camera3D"
    camera.current = true
    camera.fov = 72.0
    camera.near = 0.12
    camera.far = 165.0
    arm.add_child(camera)
    camera.position = Vector3.ZERO

func orbit(drag: Vector2) -> void:
    yaw -= drag.x * 0.006
    pitch = clampf(pitch - drag.y * 0.0045, -0.83, 0.25)

func recenter() -> void:
    if target == null:
        return
    yaw = lerp_angle(yaw, target.get_node("ArticulatedArmor").rotation.y, 0.8)
    pitch = -0.25

func _process(delta: float) -> void:
    if target == null:
        return
    var follow_point: Vector3 = target.global_position + Vector3(0.0, 1.70, 0.0)
    if global_position.distance_to(follow_point) > 17.0:
        global_position = follow_point
    else:
        global_position = global_position.lerp(follow_point, minf(delta * follow_speed, 1.0))
    rotation.y = yaw
    arm.rotation.x = pitch
