extends CharacterBody3D
## Original IRA infected prototype: patrol, pursuit, infected melee attack, hit and death feedback.
## A separate mesh from its physics capsule makes future GLB replacement straightforward.
signal defeated(points: int)
const K = preload("res://scripts/ModelKit.gd")
const GRAVITY := 22.0
var target: Node3D
var health := 5
var alert_distance := 16.0
var attack_distance := 1.7
var attack_cooldown := 0.0
var hit_flash := 0.0
var stride := 0.0
var model: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var moving := false

func _ready() -> void:
    name = "Infectado_Corredor"
    add_to_group("ira_infected")
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.39
    capsule.height = 1.95
    collider.shape = capsule
    collider.position.y = 0.99
    add_child(collider)
    floor_snap_length = 0.18
    _build_model()

func _build_model() -> void:
    var skin := K.mat(Color("746c75"),0.0,0.0,0.85)
    var ribs := K.mat(Color("40333c"),0.0,0.0,0.90)
    var infected := K.mat(Color("ab3547"),0.08,0.6,0.42)
    var eye := K.mat(Color("f33a44"),0.03,3.0,0.20)
    model = Node3D.new()
    model.name = "CorruptedSkin"
    add_child(model)
    var torso := K.sphere(model,Vector3(0.85,1.12,0.50),Vector3(0,1.36,0.15),skin)
    torso.rotation.x = -0.22
    K.sphere(model,Vector3(0.47,0.48,0.53),Vector3(0,2.12,-0.12),skin)
    K.sphere(model,Vector3(0.17,0.10,0.12),Vector3(-0.13,2.19,-0.40),eye)
    K.sphere(model,Vector3(0.17,0.10,0.12),Vector3(0.13,2.19,-0.40),eye)
    K.box(model,Vector3(0.48,0.09,0.13),Vector3(0,1.97,-0.35),ribs)
    for i in range(4):
        var y := 1.66-float(i)*0.19
        var bone := K.box(model,Vector3(0.70-float(i)*0.06,0.08,0.56),Vector3(0,y,-0.14),ribs)
        bone.rotation.z = -0.07*float(i)
        K.sphere(model,Vector3(0.18,0.20,0.11),Vector3(0.32,y,-0.32),infected)
    for i in range(5):
        var spike := K.cylinder(model,0.11,0.45+float(i)*0.08,Vector3(0.0,1.84-float(i)*0.17,0.38),infected,0.0)
        spike.rotation.x = -0.8
    left_leg = _limb(-0.22,0.93,skin,ribs,false)
    right_leg = _limb(0.22,0.93,skin,ribs,false)
    left_arm = _limb(-0.52,1.78,skin,infected,true)
    right_arm = _limb(0.52,1.78,skin,infected,true)

func _limb(x: float,y:float,skin:Material,trim:Material,arm:bool) -> Node3D:
    var pivot := Node3D.new()
    pivot.position = Vector3(x,y,0)
    model.add_child(pivot)
    var length: float = 0.77 if arm else 0.83
    K.sphere(pivot,Vector3(0.26,length,0.26),Vector3(0,-length*0.42,0),skin)
    K.sphere(pivot,Vector3(0.22,0.23,0.23),Vector3(0,-length*0.75,-0.07),trim)
    if arm:
        var nail := K.cylinder(pivot,0.12,0.52,Vector3(0,-1.02,-0.21),trim,0.0)
        nail.rotation.x = -0.85
    else:
        K.box(pivot,Vector3(0.29,0.18,0.51),Vector3(0,-0.89,-0.15),trim)
    return pivot

func _physics_process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown-delta)
    hit_flash = maxf(0.0, hit_flash-delta)
    if not is_on_floor():
        velocity.y -= GRAVITY*delta
    var desired := Vector3.ZERO
    moving = false
    if is_instance_valid(target):
        var offset: Vector3 = target.global_position - global_position
        offset.y = 0.0
        var distance: float = offset.length()
        if distance < alert_distance and distance > attack_distance:
            desired = offset.normalized()
            moving = true
            model.rotation.y = lerp_angle(model.rotation.y,atan2(-desired.x,-desired.z),minf(1.0,delta*7.0))
        elif distance <= attack_distance and attack_cooldown <= 0.0:
            attack_cooldown = 1.6
            target.call("receive_hit",11)
    velocity.x = move_toward(velocity.x,desired.x*3.35,delta*10.0)
    velocity.z = move_toward(velocity.z,desired.z*3.35,delta*10.0)
    move_and_slide()
    stride += delta*8.0*float(moving)
    var swing: float = sin(stride)*0.45 if moving else 0.0
    left_leg.rotation.x = lerpf(left_leg.rotation.x,swing,minf(1.0,delta*11.0))
    right_leg.rotation.x = lerpf(right_leg.rotation.x,-swing,minf(1.0,delta*11.0))
    left_arm.rotation.x = lerpf(left_arm.rotation.x,-0.45-swing*0.35,minf(1.0,delta*10.0))
    right_arm.rotation.x = lerpf(right_arm.rotation.x,-0.4+swing*0.35,minf(1.0,delta*10.0))
    model.scale = Vector3.ONE * (1.12 if hit_flash>0.0 else 1.0)

func receive_damage(amount: int, source: Vector3) -> void:
    if health <= 0:
        return
    health -= amount
    hit_flash = 0.16
    var push: Vector3 = global_position-source
    push.y = 0.0
    if push.length_squared()>0.01:
        velocity += push.normalized()*4.0
    if health <= 0:
        defeated.emit(100)
        queue_free()
