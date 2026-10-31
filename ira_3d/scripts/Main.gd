extends Node3D
## 3D movement vertical slice: mobile controls, basic checkpoint, no combat yet.
const HERO = preload("res://scripts/Hero.gd")
const CAMERA = preload("res://scripts/FollowCamera.gd")
const CITY = preload("res://scripts/RuinedDistrict.gd")
const HUD = preload("res://scripts/TouchHUD.gd")
const SAVE_FILE := "user://ira3d_checkpoint_v1.json"
var hero
var rig
var hud
var checkpoint_reached := false
var paused := false
var _previous_jump := false
var _previous_dash := false
var _previous_pause := false

func _ready() -> void:
    var city := CITY.new()
    add_child(city)
    hero = HERO.new()
    hero.position = Vector3(0,0.06,8.0)
    add_child(hero)
    rig = CAMERA.new()
    rig.target = hero
    add_child(rig)
    rig.global_position = hero.global_position+Vector3(0,1.7,0)
    hud = HUD.new()
    hud.game = self
    add_child(hud)
    _load_checkpoint()

func _process(_delta: float) -> void:
    if Input.is_key_pressed(KEY_ESCAPE) and not _previous_pause:
        paused = not paused
    _previous_pause = Input.is_key_pressed(KEY_ESCAPE)
    if hud.consume_pause():
        paused = not paused
    hud.paused = paused
    var look: Vector2 = hud.consume_camera_delta()
    if not paused and hud.intro_seconds <= 0.0:
        rig.orbit(look)
    if hud.consume_recenter():
        rig.recenter()
    var stick: Vector2 = hud.movement
    var x: float = (1.0 if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) else 0.0)
    var y: float = (1.0 if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) else 0.0)
    if Vector2(x,y).length() > 0.0:
        stick = Vector2(x,y).normalized()
    var jump_key: bool = Input.is_key_pressed(KEY_SPACE)
    var dash_key: bool = Input.is_key_pressed(KEY_SHIFT)
    var jump: bool = (jump_key and not _previous_jump) or hud.consume_jump()
    var dodge: bool = (dash_key and not _previous_dash) or hud.consume_dodge()
    _previous_jump = jump_key
    _previous_dash = dash_key
    var active: bool = not paused and hud.intro_seconds <= 0.0
    var sprint: bool = stick.length() > 0.89 and (hud.joystick_finger != -1)
    hero.set_controls(stick,rig.yaw,sprint,jump,dodge,active)
    if active and not checkpoint_reached and hero.global_position.distance_to(Vector3(0,0,-27)) < 2.5:
        checkpoint_reached = true
        hud.checkpoint_name = "BALIZA ALFA"
        hud.announce("PUNTO DE CONTROL GUARDADO")
        _save_checkpoint()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not paused:
        rig.orbit(event.relative)

func _save_checkpoint() -> void:
    var data := {"schema":1,"sector":1,"checkpoint":"alpha","position":[0.0,0.06,-27.0]}
    var file := FileAccess.open(SAVE_FILE,FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))
        file.close()

func _load_checkpoint() -> void:
    if not FileAccess.file_exists(SAVE_FILE):
        return
    var file := FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return
    var json := JSON.new()
    var parse_status: Error = json.parse(file.get_as_text())
    file.close()
    if parse_status != OK or not json.data is Dictionary:
        return
    var loaded: Dictionary = json.data
    if int(loaded.get("schema",0)) != 1 or str(loaded.get("checkpoint","")) != "alpha":
        return
    # Load from canonical safe spawn instead of trusting tampered coordinates.
    hero.global_position = Vector3(0,0.10,-25.0)
    checkpoint_reached = true
    hud.checkpoint_name = "BALIZA ALFA"
    hud.announce("PARTIDA REANUDADA DESDE CP ALFA",3.2)
