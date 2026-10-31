extends Node3D
## IRA v0.5: CC0 imported GLB architecture, ambient props and layered urban silhouette.
## Geometry is original Kenney art, distributed as CC0; see docs/THIRD_PARTY_ASSETS.md.
const K = preload("res://scripts/ModelKit.gd")
const BASE := "res://assets/kenney/"
const FACADES := ["building-a","building-c","building-e","building-g"]
const TOWERS := ["building-skyscraper-a","building-skyscraper-c"]
var loaded: Dictionary = {}
var rng := RandomNumberGenerator.new()
var concrete: Material
var rust: Material
var red: Material
var asphalt: Material

func _ready() -> void:
    name = "Distrito_Modular_CC0"
    rng.seed = 20261031
    concrete = K.mat(Color("333945"), 0.10)
    rust = K.mat(Color("704349"), 0.16)
    red = K.mat(Color("f63b54"), 0.15, 2.1)
    asphalt = K.mat(Color("232830"), 0.05)
    _city_blocks()
    _vehicles_and_street_props()
    _architectural_details()

func _asset(pack: String, file_name: String) -> PackedScene:
    var key: String = BASE + pack + "/" + file_name + ".glb"
    if not loaded.has(key):
        loaded[key] = ResourceLoader.load(key, "PackedScene")
    return loaded[key] as PackedScene

func _place(pack: String, asset_name: String, at: Vector3, factor: float, direction: float = 0.0) -> Node3D:
    var resource: PackedScene = _asset(pack, asset_name)
    if resource == null:
        push_warning("GLB missing: " + pack + "/" + asset_name)
        return Node3D.new()
    var instance: Node3D = resource.instantiate() as Node3D
    instance.name = asset_name
    add_child(instance)
    instance.position = at
    instance.rotation.y = direction
    instance.scale = Vector3.ONE * factor
    return instance

func _invisible_collision(at: Vector3, size: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = at
    add_child(body)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)

func _city_blocks() -> void:
    # Detailed imported facade models at both sides, separated by walkable street.
    for i in range(9):
        var z: float = 14.0 - float(i)*10.8
        for side in [-1.0, 1.0]:
            var x: float = side * 12.2
            var index: int = (i + (0 if side < 0.0 else 2)) % FACADES.size()
            var model_name: String = FACADES[index]
            var factor: float = 10.5 + float(i%3)*0.45
            _place("city-kit-commercial", model_name, Vector3(x, -0.10, z), factor, 0.0 if side<0.0 else PI)
            _invisible_collision(Vector3(x, 6.5, z), Vector3(8.2,13.0,8.2))
            _ruin_front(x, z, side, i)
    # Multi-height city line, with real geometry rather than repeating flat boxes.
    for i in range(10):
        var side: float = -1.0 if i%2==0 else 1.0
        var model_name: String = TOWERS[i%2]
        var factor: float = 14.0+float(i%3)*2.8
        _place("city-kit-commercial", model_name, Vector3(side*31.0, -0.1, 13.0-float(i)*10.0), factor)
    for i in range(12):
        _place("city-kit-commercial", "low-detail-building-a",
            Vector3((-1.0 if i%2==0 else 1.0)*50.0, -1.0, 26.0 - float(i)*11.0),
            23.0 + float(i%3)*3.0)

func _ruin_front(x: float, z: float, side: float, idx: int) -> void:
    # Facade damage: uneven broken balconies, exposed piping and debris along kerbs.
    var at: Vector3 = Vector3(x - side*3.8, 2.4, z)
    for k in range(3):
        var p: Vector3 = at + Vector3(side*rng.randf_range(-1.0,1.0), float(k)*2.1, rng.randf_range(-2.0,2.0))
        var slab := K.box(self, Vector3(rng.randf_range(1.4,2.8),0.18,0.75),p,concrete)
        slab.rotation.z = rng.randf_range(-0.27,0.19)
    for k in range(4):
        var p: Vector3 = Vector3(side*rng.randf_range(6.9,7.6),0.12,z+rng.randf_range(-4.0,4.0))
        var stone := K.box(self, Vector3(rng.randf_range(0.35,0.95),rng.randf_range(0.16,0.41),rng.randf_range(0.3,0.8)),p,concrete)
        stone.rotation = Vector3(rng.randf_range(-0.2,0.2),rng.randf_range(-0.7,0.7),0)
    if idx%3==0:
        K.box(self,Vector3(0.14,3.5,0.14),Vector3(x-side*4.1,2.2,z+2.1),rust)
        var sign := K.box(self,Vector3(1.85,0.43,0.12),Vector3(x-side*4.35,4.1,z+2.1),red)
        sign.rotation.z = -side*0.12

func _vehicles_and_street_props() -> void:
    _place("car-kit","sedan",Vector3(-3.7,0.04,-19.0),1.85,0.33)
    _invisible_collision(Vector3(-3.7,0.78,-19.0),Vector3(2.6,1.6,4.8))
    _place("car-kit","police",Vector3(4.1,0.05,-48.0),1.78,-0.5)
    _invisible_collision(Vector3(4.1,0.8,-48.0),Vector3(2.7,1.6,4.7))
    for i in range(14):
        var side: float = -1.0 if i%2==0 else 1.0
        var z: float = 10.0 - float(i)*6.0
        if i%3==0:
            _place("city-kit-roads","construction-fence",Vector3(side*6.95,0,z),3.0,PI/2.0)
        elif i%3==1:
            _place("city-kit-roads","construction-barrier",Vector3(side*6.4,0,z),3.0,PI/2.0)
        else:
            _place("city-kit-roads","dumpster",Vector3(side*7.1,0,z),2.3,PI/2.0)
    for i in range(8):
        var z: float = 8.0-float(i)*12.0
        var side: float = -1.0 if i%2==0 else 1.0
        _place("city-kit-roads","light-curved",Vector3(side*7.75,0,z),3.6,PI if side>0.0 else 0.0)
        if i%2==0:
            _place("city-kit-roads","electricity-pole",Vector3(side*9.1,0,z-4.0),3.5)
    for i in range(6):
        _place("car-kit","debris-tire",
            Vector3(rng.randf_range(-5.0,5.0),0.0,-4.0-float(i)*12.0),1.5,float(i)*0.68)
    _place("city-kit-roads","traffic-light",Vector3(-7.8,0,-25.0),3.1,0.0)

func _architectural_details() -> void:
    # Collapsed steel pipes and broken concrete make the silhouettes less regular.
    for i in range(22):
        var p := Vector3(rng.randf_range(-6.9,6.9),0.10,rng.randf_range(-69.0,4.0))
        var metal := K.box(self,Vector3(rng.randf_range(0.15,0.34),0.11,rng.randf_range(0.7,2.2)),p,rust)
        metal.rotation.y = rng.randf_range(-1.55,1.55)
    for i in range(5):
        var z: float = -9.0 - float(i)*13.0
        var x: float = 7.1 if i%2==0 else -7.1
        K.sphere(self,Vector3(1.35,0.06,1.8),Vector3(x,0.035,z),red)
