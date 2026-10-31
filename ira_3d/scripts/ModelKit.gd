extends RefCounted
## Constructs efficient primitive 3D meshes and materials. No external licensed assets.

static func mat(color: Color, metallic: float = 0.0, emission: float = 0.0, roughness: float = 0.72) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    if emission > 0.0:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = emission
    return m

static func box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.material_override = material
    item.position = pos
    item.rotation = rot
    parent.add_child(item)
    return item

static func sphere(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.radial_segments = 16
    mesh.rings = 8
    item.mesh = mesh
    item.scale = size
    item.material_override = material
    item.position = pos
    parent.add_child(item)
    return item

static func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material, top_radius: float = -1.0) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.bottom_radius = radius
    mesh.top_radius = radius if top_radius < 0.0 else top_radius
    mesh.height = height
    mesh.radial_segments = 12
    item.mesh = mesh
    item.material_override = material
    item.position = pos
    parent.add_child(item)
    return item

static func collision_box(parent: Node3D, size: Vector3, pos: Vector3, material: Material) -> StaticBody3D:
    var body := StaticBody3D.new()
    body.position = pos
    parent.add_child(body)
    box(body, size, Vector3.ZERO, material)
    var shape := BoxShape3D.new()
    shape.size = size
    var collision := CollisionShape3D.new()
    collision.shape = shape
    body.add_child(collision)
    return body
