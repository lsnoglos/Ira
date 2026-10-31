extends Node3D
## A low-cost, original, procedural art blockout of a ruined dystopian city.
const K = preload("res://scripts/ModelKit.gd")
const URBAN = preload("res://scripts/UrbanAssets.gd")
var rng := RandomNumberGenerator.new()
var charcoal: Material
var roadway: Material
var wall_a: Material
var wall_b: Material
var wall_c: Material
var rust: Material
var metal: Material
var hazard: Material
var crimson: Material
var cyan: Material
var amber: Material
var window: Material
var toxic: Material
var neon: Material
var animated_beacon: Node3D
var beacon_phase := 0.0

func _ready() -> void:
    rng.seed = 342186
    name = "Distrito_de_las_Cenizas"
    _make_materials()
    _build_light_environment()
    _build_floor()
    var architecture := URBAN.new()
    add_child(architecture)
    _build_props()
    _build_checkpoint()

func _make_materials() -> void:
    charcoal = K.mat(Color("101522"),0.18)
    roadway = K.mat(Color("232b35"),0.12)
    wall_a = K.mat(Color("313b4b"),0.05)
    wall_b = K.mat(Color("444456"),0.06)
    wall_c = K.mat(Color("38313e"),0.05)
    rust = K.mat(Color("6d3838"),0.22)
    metal = K.mat(Color("6e7581"),0.7,0.0,0.22)
    hazard = K.mat(Color("ff944e"),0.12,1.4)
    crimson = K.mat(Color("df3157"),0.15,1.7)
    cyan = K.mat(Color("74e4f4"),0.15,2.4)
    amber = K.mat(Color("ffc681"),0.06,1.4)
    window = K.mat(Color("131925"),0.0)
    toxic = K.mat(Color("6cf5a9"),0.03,2.8)
    neon = K.mat(Color("b33853"),0.15,0.8)

func _build_light_environment() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color("121e2e")
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color("7590b4")
    environment.ambient_light_energy = 0.80
    environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
    environment.fog_enabled = true
    environment.fog_light_color = Color("243345")
    environment.fog_density = 0.007
    world.environment = environment
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-42, 28, 12)
    sun.light_color = Color("ffb48f")
    sun.light_energy = 1.30
    sun.shadow_enabled = true
    add_child(sun)
    var cold := DirectionalLight3D.new()
    cold.rotation_degrees = Vector3(-20, -130, 0)
    cold.light_color = Color("729dcc")
    cold.light_energy = 0.58
    add_child(cold)

func _build_floor() -> void:
    K.collision_box(self, Vector3(100,1,190),Vector3(0,-0.54,-44),roadway)
    # Mapped street with curbs, broken concrete and glowing traffic lane lines.
    for side in [-1.0,1.0]:
        var x: float = side * 7.7
        K.collision_box(self,Vector3(2.4,0.42,122),Vector3(x,-0.1,-35),charcoal)
        K.box(self,Vector3(0.22,0.24,128),Vector3(side*6.42,0.02,-35),metal)
    for i in range(43):
        var z: float = 11.0-float(i)*2.0
        K.box(self,Vector3(0.12,0.02,0.91),Vector3(0,0.028,z),amber)
    for i in range(24):
        var z: float = 10.0-float(i)*3.2
        var x: float = rng.randf_range(-5.8,5.8)
        var crack := K.box(self,Vector3(rng.randf_range(0.65,2.2),0.016,0.035),Vector3(x,0.035,z),charcoal)
        crack.rotation.y = rng.randf_range(-1.1,1.1)
    # A safe, visible end-of-prototype blocker.
    K.collision_box(self,Vector3(13,2.8,1.1),Vector3(0,1.2,-75),wall_a)
    for j in range(5):
        K.box(self,Vector3(1.8,1.5,0.2),Vector3(-4.8+float(j)*2.4,2.35,-74.3),neon)

func _build_city() -> void:
    for i in range(17):
        var z: float = 12.0-float(i)*5.1
        for side in [-1.0,1.0]:
            var width: float = rng.randf_range(4.4,7.9)
            var height: float = rng.randf_range(6.5,22.0)
            var depth: float = rng.randf_range(4.2,7.6)
            var x: float = side*(12.5+rng.randf_range(0.0,2.2))
            var mat: Material = [wall_a,wall_b,wall_c][rng.randi_range(0,2)]
            _building(Vector3(x,height*0.5-0.18,z),Vector3(width,height,depth),mat,i)
    for i in range(18):
        var x: float = rng.randf_range(-42,42)
        var z: float = -30.0-rng.randf_range(28.0,110.0)
        var h: float = rng.randf_range(12,40)
        K.box(self,Vector3(rng.randf_range(3,8),h,rng.randf_range(3,7)),Vector3(x,h*0.5-0.15,z),ColorMaterial_for_background(i))

func ColorMaterial_for_background(i: int) -> Material:
    return wall_b if i % 2 == 0 else wall_c

func _building(center: Vector3, size: Vector3, material: Material, index: int) -> void:
    var block := K.collision_box(self,size,center,material)
    block.name = "RuinBuilding_%02d"%index
    # Broken roof silhouette, balconies, ribs, and shattered dark windows.
    for j in range(rng.randi_range(1,3)):
        var rx: float = -size.x*0.38+float(j)*size.x*0.24
        K.box(self,Vector3(size.x*0.2,0.5+float(j)*0.65,0.95),center+Vector3(rx,size.y*0.5+0.12,-size.z*0.25),rust)
    for floor_n in range(1,int(size.y/2.6)):
        var y: float = center.y-size.y*0.5+float(floor_n)*2.5
        for col in range(2):
            var wx: float = center.x+(float(col)-0.5)*size.x*0.39
            var window_front: float = center.z-size.z*0.5-0.032
            var win_material: Material = hazard if (index+floor_n+col)%9 == 0 else window
            K.box(self,Vector3(0.72,1.10,0.055),Vector3(wx,y,window_front),win_material)
    for band in range(2):
        var yy: float = center.y-size.y*0.5 + size.y*(float(band)+1.0)/3.0
        K.box(self,Vector3(size.x+0.15,0.16,size.z+0.15),Vector3(center.x,yy,center.z),rust)
    if index%3 == 0:
        var pipe := K.cylinder(self,0.11,size.y*0.7,center+Vector3(-size.x*0.4,-size.y*0.15,-size.z*0.48),metal)
        pipe.rotation.z = 0.04

func _build_props() -> void:
    for i in range(23):
        var z: float = 6.0-float(i)*3.4
        var side: float = -1.0 if i%2 == 0 else 1.0
        var x: float = side*rng.randf_range(5.2,6.8)
        if i % 4 == 0:
            _acid_barrel(Vector3(x,0,z))
        elif i % 4 == 1:
            _rubble(Vector3(x,0,z))
        elif i % 4 == 2:
            _street_lamp(Vector3(x,0,z))
        else:
            _road_barrier(Vector3(x,0,z))
    for j in range(8):
        var zz: float = -2.0-float(j)*9.5
        _rubble(Vector3(rng.randf_range(-4.9,4.9),0,zz))
    # Distant circular beacon where the future boss encounter will happen.
    _distant_eye_monument(Vector3(0,5.2,-71))

func _acid_barrel(p: Vector3) -> void:
    var barrel := StaticBody3D.new()
    barrel.position = p+Vector3(0,0.63,0)
    add_child(barrel)
    K.cylinder(barrel,0.47,1.24,Vector3.ZERO,rust)
    for yy in [-0.45,0.45]:
        K.cylinder(barrel,0.5,0.11,Vector3(0,yy,0),metal)
    K.sphere(barrel,Vector3(0.4,0.06,0.4),Vector3(0,0.69,0),toxic)
    var collision := CollisionShape3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = 0.47
    shape.height = 1.25
    collision.shape = shape
    barrel.add_child(collision)

func _rubble(p: Vector3) -> void:
    for k in range(rng.randi_range(3,6)):
        var offset := Vector3(rng.randf_range(-0.8,0.8),rng.randf_range(0.1,0.28),rng.randf_range(-0.55,0.55))
        var rock := K.box(self,Vector3(rng.randf_range(0.2,0.75),rng.randf_range(0.15,0.5),rng.randf_range(0.2,0.75)),p+offset,wall_b)
        rock.rotation = Vector3(rng.randf_range(-0.2,0.2),rng.randf_range(0,6.2),rng.randf_range(-0.3,0.3))

func _street_lamp(p: Vector3) -> void:
    K.cylinder(self,0.11,5.4,p+Vector3(0,2.7,0),metal)
    K.box(self,Vector3(1.4,0.14,0.16),p+Vector3(-0.55,5.37,0),metal)
    K.box(self,Vector3(0.64,0.12,0.44),p+Vector3(-1.1,5.28,0),amber)
    if p.z > -18.0 or p.z < -62.0:
        var light := OmniLight3D.new()
        light.position = p+Vector3(-1.1,5.0,0)
        light.light_color = Color("ff8e67")
        light.light_energy = 1.8
        light.omni_range = 8.0
        add_child(light)

func _road_barrier(p: Vector3) -> void:
    K.box(self,Vector3(2.0,0.85,0.32),p+Vector3(0,0.39,0),rust)
    for k in range(3):
        var band := K.box(self,Vector3(0.24,0.87,0.06),p+Vector3((float(k)-1.0)*0.61,0.45,-0.19),amber)
        band.rotation.z = -0.38

func _damaged_car(p: Vector3, turn: float) -> void:
    var car := Node3D.new()
    car.position = p
    car.rotation.y = turn
    add_child(car)
    K.box(car,Vector3(1.9,0.6,3.6),Vector3(0,0.70,0),rust)
    K.box(car,Vector3(1.7,0.75,2.0),Vector3(0,1.29,0.2),wall_c)
    for x in [-0.9,0.9]:
        for z in [-1.2,1.2]:
            var wheel := K.cylinder(car,0.36,0.22,Vector3(x,0.36,z),charcoal)
            wheel.rotation.z = PI*0.5
    for x in [-0.6,0.6]:
        K.box(car,Vector3(0.38,0.17,0.03),Vector3(x,0.83,-1.81),amber)

func _distant_eye_monument(p: Vector3) -> void:
    # Environment art only, NOT a boss implementation in this milestone.
    K.sphere(self,Vector3(5.1,5.1,2.2),p,wall_c)
    K.sphere(self,Vector3(3.1,3.1,0.33),p+Vector3(0,0,-1.11),crimson)
    K.sphere(self,Vector3(1.44,1.44,0.36),p+Vector3(0,0,-1.3),charcoal)
    K.sphere(self,Vector3(0.5,0.5,0.36),p+Vector3(0.12,0.11,-1.47),amber)
    for i in range(8):
        var a: float = TAU*float(i)/8.0
        var blade := K.cylinder(self,0.35,4.2,p+Vector3(cos(a)*3.45,sin(a)*3.2,0.4),rust,0.0)
        blade.rotation.z = -cos(a)*0.9
        blade.rotation.x = sin(a)*0.8

func _build_checkpoint() -> void:
    animated_beacon = Node3D.new()
    animated_beacon.position = Vector3(0,0,-27)
    animated_beacon.name = "Checkpoint_Alpha"
    add_child(animated_beacon)
    K.cylinder(animated_beacon,1.05,0.20,Vector3(0,0.12,0),metal)
    K.cylinder(animated_beacon,0.88,0.06,Vector3(0,0.23,0),cyan)
    K.cylinder(animated_beacon,0.14,2.35,Vector3(0,1.34,0),cyan,0.0)
    K.sphere(animated_beacon,Vector3(0.4,0.4,0.4),Vector3(0,2.47,0),amber)
    var blue_light := OmniLight3D.new()
    blue_light.light_color = Color("64efff")
    blue_light.light_energy = 1.1
    blue_light.omni_range = 5.0
    blue_light.position = Vector3(0,1.6,0)
    animated_beacon.add_child(blue_light)

func _process(delta: float) -> void:
    beacon_phase += delta
    if animated_beacon != null:
        animated_beacon.rotation.y = sin(beacon_phase*0.5)*0.08
