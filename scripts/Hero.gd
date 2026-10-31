extends CharacterBody3D
## Keyboard and virtual joystick. Forward always relative to camera yaw.
const K = preload("res://scripts/ModelKit.gd")
const WALK_SPEED := 5.3
const SPRINT_SPEED := 8.6
const JUMP_VELOCITY := 7.9
const GRAVITY := 22.0
const DASH_SPEED := 15.0
var move_input := Vector2.ZERO
var camera_yaw := 0.0
var sprint_requested := false
var jump_requested := false
var dash_requested := false
var dash_time := 0.0
var dash_cooldown := 0.0
var coyote_time := 0.0
var jump_buffer := 0.0
var controls_enabled := true
var locomotion_time := 0.0
var model: Node3D
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var visor: MeshInstance3D
var claw_glow: MeshInstance3D
var health := 100
var invulnerability := 0.0
var attack_timer := 0.0

func _ready() -> void:
    name = "IRA_El_Purificador"
    var shape := CapsuleShape3D.new()
    shape.radius = 0.37
    shape.height = 2.1
    var collider := CollisionShape3D.new()
    collider.position.y = 1.06
    collider.shape = shape
    add_child(collider)
    floor_snap_length = 0.22
    _build_model()

func _build_model() -> void:
    var silver := K.mat(Color("bec6d4"), 0.45, 0.0, 0.24)
    var white := K.mat(Color("e1e8eb"), 0.28, 0.0, 0.33)
    var dark := K.mat(Color("171b27"), 0.55, 0.0, 0.36)
    var graphite := K.mat(Color("48515f"), 0.62, 0.0, 0.28)
    var red := K.mat(Color("ff304e"), 0.12, 2.4, 0.2)
    var red_dark := K.mat(Color("872239"), 0.3, 0.9, 0.25)
    model = Node3D.new()
    model.name = "ArticulatedArmor"
    add_child(model)
    K.sphere(model, Vector3(1.15, 0.95, 0.65), Vector3(0, 1.47, 0), silver)
    K.box(model, Vector3(0.9, 0.19, 0.7), Vector3(0, 1.87, 0), white)
    K.sphere(model, Vector3(0.81, 0.42, 0.65), Vector3(0, 1.05, 0.05), dark)
    K.box(model, Vector3(0.14, 0.52, 0.03), Vector3(-0.28, 1.52, -0.325), red_dark)
    K.box(model, Vector3(0.14, 0.52, 0.03), Vector3(0.28, 1.52, -0.325), red_dark)
    K.sphere(model, Vector3(0.46, 0.52, 0.50), Vector3(0, 2.28, -0.035), white)
    K.box(model, Vector3(0.48, 0.11, 0.09), Vector3(0, 2.32, -0.275), red)
    K.box(model, Vector3(0.36, 0.10, 0.24), Vector3(0, 2.13, -0.13), graphite)
    K.box(model, Vector3(0.16, 0.3, 0.23), Vector3(0, 2.51, 0.04), white)
    K.sphere(model, Vector3(0.76, 0.22, 0.22), Vector3(0, 1.98, 0.01), graphite)
    K.box(model, Vector3(0.27, 0.13, 0.12), Vector3(0, 1.55, -0.40), red)
    leg_l = _make_limb("LegLeft", Vector3(-0.28, 0.98, 0), silver, dark)
    leg_r = _make_limb("LegRight", Vector3(0.28, 0.98, 0), silver, dark)
    arm_l = _make_arm("ArmLeft", -0.69, silver, graphite, false)
    arm_r = _make_arm("ArmClaw", 0.69, silver, graphite, true)
    # Extra armor panels, collar and dorsal organic spines move with the character.
    for side in [-1.0,1.0]:
        var chest: MeshInstance3D = K.sphere(model,Vector3(0.50,0.35,0.23),Vector3(side*0.27,1.66,-0.30),white)
        chest.rotation.z = side*0.18
        var pauldron: MeshInstance3D = K.sphere(model,Vector3(0.45,0.22,0.50),Vector3(side*0.73,1.94,0.03),silver)
        pauldron.rotation.z = side*0.30
        K.box(model,Vector3(0.13,0.42,0.08),Vector3(side*0.43,1.52,-0.35),graphite)
        K.sphere(model,Vector3(0.35,0.17,0.28),Vector3(side*0.30,0.91,-0.14),silver)
        var knee: MeshInstance3D = K.box(model,Vector3(0.27,0.28,0.19),Vector3(side*0.28,0.52,-0.24),white)
        knee.rotation.x = -0.18
    for i in range(5):
        var yy: float = 1.85-float(i)*0.29
        var fin := K.cylinder(model,0.17,0.48+float(i)*0.16,Vector3(0.25,yy,0.54),red_dark,0.0)
        fin.rotation.x = -0.72
    for i in range(3):
        K.box(model, Vector3(0.13, 0.22, 0.42), Vector3(0.07 + float(i)*0.12, 1.24, 0.40), graphite)

func _make_limb(limb_name: String, pos: Vector3, armor: Material, dark: Material) -> Node3D:
    var joint := Node3D.new()
    joint.name = limb_name
    joint.position = pos
    model.add_child(joint)
    K.sphere(joint, Vector3(0.38, 0.66, 0.44), Vector3(0, -0.29, 0), armor)
    K.sphere(joint, Vector3(0.29, 0.30, 0.3), Vector3(0, -0.66, 0.015), dark)
    K.sphere(joint, Vector3(0.35, 0.56, 0.38), Vector3(0, -0.80, -0.04), armor)
    K.box(joint, Vector3(0.35, 0.20, 0.63), Vector3(0, -0.92, -0.20), dark)
    return joint

func _make_arm(limb_name: String, x: float, armor: Material, metal: Material, is_claw: bool) -> Node3D:
    var joint := Node3D.new()
    joint.name = limb_name
    joint.position = Vector3(x, 1.79, 0)
    model.add_child(joint)
    K.sphere(joint, Vector3(0.5, 0.52, 0.48), Vector3(0, -0.06, 0), armor)
    K.sphere(joint, Vector3(0.34, 0.65, 0.36), Vector3(0, -0.49, 0), armor)
    K.sphere(joint, Vector3(0.29, 0.36, 0.30), Vector3(0, -0.87, -0.03), metal)
    if is_claw:
        var red := K.mat(Color("ff334b"), 0.18, 3.0, 0.2)
        var black := K.mat(Color("24212e"), 0.6, 0.0, 0.23)
        K.box(joint, Vector3(0.35, 0.52, 0.44), Vector3(0.01, -0.98, -0.13), black)
        for blade in range(3):
            var xx: float = (float(blade)-1.0)*0.16
            var spike := K.cylinder(joint, 0.09, 0.90 + float(blade) * 0.17, Vector3(xx, -1.32, -0.31), red, 0.0)
            spike.rotation.x = -0.43
        claw_glow = K.sphere(joint, Vector3(0.39, 0.12, 0.39), Vector3(0, -1.03, -0.42), red)
    else:
        K.sphere(joint, Vector3(0.38, 0.28, 0.40), Vector3(0, -1.04, -0.04), metal)
    return joint

func set_controls(stick: Vector2, yaw: float, sprint: bool, jump: bool, dash: bool, enabled: bool) -> void:
    move_input = stick.limit_length(1.0)
    camera_yaw = yaw
    sprint_requested = sprint
    controls_enabled = enabled
    if jump:
        jump_buffer = 0.15
    if dash:
        dash_requested = true

func _physics_process(delta: float) -> void:
    invulnerability = maxf(0.0, invulnerability-delta)
    attack_timer = maxf(0.0,attack_timer-delta)
    jump_buffer = maxf(jump_buffer-delta, 0.0)
    dash_cooldown = maxf(dash_cooldown-delta, 0.0)
    dash_time = maxf(dash_time-delta, 0.0)
    if is_on_floor():
        coyote_time = 0.12
    else:
        coyote_time = maxf(0.0, coyote_time-delta)
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    if controls_enabled and jump_buffer > 0.0 and coyote_time > 0.0:
        velocity.y = JUMP_VELOCITY
        coyote_time = 0.0
        jump_buffer = 0.0
    var movement := Vector3.ZERO
    if controls_enabled and move_input.length() > 0.1:
        movement = Vector3(move_input.x, 0, move_input.y).rotated(Vector3.UP, camera_yaw).normalized()
        var target_angle: float = atan2(-movement.x, -movement.z)
        model.rotation.y = lerp_angle(model.rotation.y, target_angle, minf(1.0, delta * 12.0))
    if dash_requested and dash_cooldown <= 0.0 and controls_enabled:
        dash_cooldown = 1.6
        dash_time = 0.18
    dash_requested = false
    var speed: float = SPRINT_SPEED if sprint_requested else WALK_SPEED
    if dash_time > 0.0:
        speed = DASH_SPEED
    var target := movement * speed
    var smooth: float = 13.0 if is_on_floor() else 4.0
    velocity.x = move_toward(velocity.x, target.x, smooth * delta)
    velocity.z = move_toward(velocity.z, target.z, smooth * delta)
    move_and_slide()
    if global_position.y < -8.0:
        global_position = Vector3(0, 1, 8)
        velocity = Vector3.ZERO
    _animate_model(delta, movement.length())

func _animate_model(delta: float, activity: float) -> void:
    locomotion_time += delta * (14.0 if sprint_requested else 9.0) * (activity if controls_enabled else 0.0)
    var amount := minf(1.0, Vector2(velocity.x, velocity.z).length() / 5.0)
    if not is_on_floor():
        amount = 0.0
    var swing := sin(locomotion_time) * amount * 0.55
    leg_l.rotation.x = lerpf(leg_l.rotation.x, swing, delta * 12.0)
    leg_r.rotation.x = lerpf(leg_r.rotation.x, -swing, delta * 12.0)
    arm_l.rotation.x = lerpf(arm_l.rotation.x, -swing * 0.65, delta * 9.0)
    arm_r.rotation.x = lerpf(arm_r.rotation.x, swing * 0.50, delta * 9.0)
    model.position.y = sin(float(Time.get_ticks_msec()) / 460.0) * 0.012 + absf(sin(locomotion_time))*amount*0.025
    if attack_timer>0.0:
        arm_r.rotation.x = -1.20 + sin(attack_timer*25.0)*0.65
        arm_r.rotation.z = -0.55
    else:
        arm_r.rotation.z = lerpf(arm_r.rotation.z,0.0,minf(1.0,delta*9.0))
    model.scale = Vector3.ONE * (1.035 if invulnerability>0.0 else 1.0)
    if not is_on_floor():
        leg_l.rotation.x = lerpf(leg_l.rotation.x, -0.36, delta * 6)
        leg_r.rotation.x = lerpf(leg_r.rotation.x, 0.32, delta * 6)

func face_forward() -> Vector3:
    return Vector3.FORWARD.rotated(Vector3.UP,model.rotation.y).normalized()

func claw_attack() -> void:
    attack_timer = 0.30

func receive_hit(damage: int) -> void:
    if invulnerability > 0.0 or health <= 0:
        return
    health = maxi(0,health-damage)
    invulnerability = 0.85
    if health == 0:
        health = 100
        global_position = Vector3(0,0.5,8.0)
        velocity = Vector3.ZERO
