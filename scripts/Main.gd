extends Node3D
## 3D movement vertical slice: mobile controls, basic checkpoint, no combat yet.
const HERO = preload("res://scripts/Hero.gd")
const CAMERA = preload("res://scripts/FollowCamera.gd")
const CITY = preload("res://scripts/RuinedDistrict.gd")
const HUD = preload("res://scripts/TouchHUD.gd")
const ENEMY = preload("res://scripts/Infected.gd")
const PULSE = preload("res://scripts/EnergyPulse.gd")
const K = preload("res://scripts/ModelKit.gd")
const SAVE_FILE := "user://ira3d_checkpoint_v1.json"
var hero
var rig
var hud
var checkpoint_reached := false
var paused := false
var _previous_jump := false
var _previous_dash := false
var _previous_pause := false
var enemies: Array[Node3D] = []
var score := 0
var kills := 0
var claw_cooldown := 0.0
var pulse_cooldown := 0.0

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
    _spawn_infected()

func _process(_delta: float) -> void:
    claw_cooldown = maxf(0.0,claw_cooldown-_delta)
    pulse_cooldown = maxf(0.0,pulse_cooldown-_delta)
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
    hud.life = hero.health
    hud.score = score
    hud.kills = kills
    if active and (hud.consume_claw() or Input.is_key_pressed(KEY_F)) and claw_cooldown<=0.0:
        _claw()
    if active and (hud.consume_pulse() or Input.is_key_pressed(KEY_Q)) and pulse_cooldown<=0.0:
        _pulse()
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

func _spawn_infected() -> void:
    for pos in [Vector3(-1.0,0.06,-8.0),Vector3(3.3,0.06,-27.0),Vector3(-1.8,0.06,-45.0),Vector3(1.7,0.06,-59.0)]:
        var enemy: CharacterBody3D = ENEMY.new()
        enemy.position = pos
        enemy.target = hero
        add_child(enemy)
        enemy.defeated.connect(_on_defeated)
        enemies.append(enemy)

func _on_defeated(points: int) -> void:
    score += points
    kills += 1
    hud.announce("INFECTADO PURIFICADO +%d" % points,1.7)

func _claw() -> void:
    claw_cooldown = 0.67
    hero.claw_attack()
    var forward: Vector3 = hero.face_forward()
    for enemy in enemies:
        if not is_instance_valid(enemy):
            continue
        var toward: Vector3 = enemy.global_position - hero.global_position
        toward.y = 0.0
        if toward.length() < 3.05 and forward.dot(toward.normalized()) > 0.05:
            enemy.call("receive_damage",3,hero.global_position)
            _impact(enemy.global_position+Vector3(0,1.4,0))
    _impact(hero.global_position+Vector3.UP*1.25+forward*1.4)

func _pulse() -> void:
    pulse_cooldown = 0.9
    var shot: Node3D = PULSE.new()
    shot.travel = hero.face_forward()
    shot.targets = enemies
    add_child(shot)
    shot.global_position = hero.global_position+Vector3(0,1.24,0)+hero.face_forward()*0.95

func _impact(p: Vector3) -> void:
    var material: StandardMaterial3D = K.mat(Color("ff4059"),0.0,3.2,0.12)
    var flash: MeshInstance3D = K.sphere(self,Vector3(0.33,0.33,0.33),p,material)
    var tween := create_tween()
    tween.tween_property(flash,"scale",Vector3.ONE*0.02,0.22)
    tween.tween_callback(flash.queue_free)
