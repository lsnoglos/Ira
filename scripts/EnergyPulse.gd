extends Node3D
## IRA energy projectile for v0.5 prototype. Uses cheap distance hit checks.
const K = preload("res://scripts/ModelKit.gd")
var travel: Vector3 = Vector3.FORWARD
var speed := 20.0
var distance_left := 17.0
var targets: Array = []

func _ready() -> void:
    name = "Pulso_De_Purificacion"
    var energy: Material = K.mat(Color("ff4356"),0.0,3.4,0.15)
    K.sphere(self,Vector3(0.42,0.42,0.72),Vector3.ZERO,energy)
    K.sphere(self,Vector3(0.17,0.17,0.95),Vector3(0,0,0.37),K.mat(Color("e3ecff"),0.0,2.0))
    var light := OmniLight3D.new()
    light.light_color = Color("ff5569")
    light.omni_range = 3.7
    light.light_energy = 0.85
    add_child(light)

func _physics_process(delta: float) -> void:
    var step: float = minf(distance_left,speed*delta)
    global_position += travel.normalized()*step
    distance_left -= step
    for entity in targets:
        if is_instance_valid(entity) and global_position.distance_to(entity.global_position+Vector3(0,1.1,0))<1.45:
            entity.call("receive_damage",2,global_position)
            queue_free()
            return
    if distance_left <= 0.0:
        queue_free()
