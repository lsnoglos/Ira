extends CanvasLayer
## Touch HUD owns two independent virtual sticks/zones; never blocks camera dragging.
var game: Node3D
var movement := Vector2.ZERO
var camera_delta := Vector2.ZERO
var jump_queued := false
var dodge_queued := false
var recenter_queued := false
var pause_queued := false
var joystick_finger := -1
var camera_finger := -1
var joystick_origin := Vector2.ZERO
var joystick_pos := Vector2.ZERO
var joystick_radius := 72.0
var camera_previous := Vector2.ZERO
var intro_seconds := 3.0
var paused := false
var checkpoint_name := "INICIO"
var message := ""
var message_time := 0.0
var hud_root: Control
var white := Color("e7eff7")
var cyan := Color("73e9ff")
var red := Color("ff3f5e")
var dark := Color(0.017, 0.026, 0.05, 0.79)

func _ready() -> void:
    hud_root = Control.new()
    hud_root.name = "TouchOverlay"
    hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
    hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_root.set_script(null)
    add_child(hud_root)
    hud_root.draw.connect(_draw_hud)

func _process(delta: float) -> void:
    intro_seconds = maxf(0.0, intro_seconds - delta)
    message_time = maxf(0.0, message_time - delta)
    if hud_root != null:
        hud_root.queue_redraw()

func announce(text_value: String, seconds: float = 2.6) -> void:
    message = text_value
    message_time = seconds

func consume_camera_delta() -> Vector2:
    var d := camera_delta
    camera_delta = Vector2.ZERO
    return d

func consume_jump() -> bool:
    var was := jump_queued
    jump_queued = false
    return was

func consume_dodge() -> bool:
    var was := dodge_queued
    dodge_queued = false
    return was

func consume_recenter() -> bool:
    var was := recenter_queued
    recenter_queued = false
    return was

func consume_pause() -> bool:
    var was := pause_queued
    pause_queued = false
    return was

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _press(event.index, event.position)
        else:
            _release(event.index)
    elif event is InputEventScreenDrag:
        _drag(event.index, event.position)
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _press(1000, event.position)
            else:
                _release(1000)
    elif event is InputEventMouseMotion:
        if joystick_finger == 1000:
            _drag(1000, event.position)
        elif camera_finger == 1000:
            _drag(1000, event.position)

func _press(finger: int, pos: Vector2) -> void:
    var s: Vector2 = get_viewport().get_visible_rect().size
    if pos.y < 112.0 and pos.x > s.x-118.0:
        pause_queued = true
        return
    if paused or intro_seconds > 0.0:
        if intro_seconds > 0.0:
            intro_seconds = 0.0
        elif paused:
            pause_queued = true
        return
    if pos.y > s.y-215.0 and pos.x < s.x*0.42 and joystick_finger == -1:
        joystick_finger = finger
        joystick_origin = Vector2(116, s.y - 122)
        joystick_pos = pos
        _set_joystick(pos)
    elif pos.y > s.y-245.0 and pos.x > s.x-150.0:
        jump_queued = true
    elif pos.y > s.y-245.0 and pos.x > s.x-282.0:
        dodge_queued = true
    elif pos.y > s.y-245.0 and pos.x > s.x-405.0:
        recenter_queued = true
    elif camera_finger == -1 and pos.x > s.x*0.32:
        camera_finger = finger
        camera_previous = pos

func _release(finger: int) -> void:
    if joystick_finger == finger:
        joystick_finger = -1
        movement = Vector2.ZERO
        joystick_pos = joystick_origin
    if camera_finger == finger:
        camera_finger = -1

func _drag(finger: int, pos: Vector2) -> void:
    if joystick_finger == finger:
        _set_joystick(pos)
    elif camera_finger == finger:
        camera_delta += (pos - camera_previous)
        camera_previous = pos

func _set_joystick(pos: Vector2) -> void:
    joystick_pos = joystick_origin + (pos - joystick_origin).limit_length(joystick_radius)
    movement = ((joystick_pos - joystick_origin)/joystick_radius).limit_length(1.0)

func _draw_hud() -> void:
    var s: Vector2 = get_viewport().get_visible_rect().size
    var font: Font = ThemeDB.fallback_font
    var ui_size: int = 18
    hud_root.draw_rect(Rect2(Vector2(0,0), Vector2(s.x, 86)), Color(0.012, 0.018, 0.032, 0.74))
    hud_root.draw_rect(Rect2(Vector2(19,16),Vector2(5,53)), red)
    hud_root.draw_string(font, Vector2(37,39), "IRA / EL PURIFICADOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, white)
    hud_root.draw_string(font, Vector2(37,64), "STAGE 1  ·  ZONA DE PRUEBA 3D", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, cyan)
    hud_root.draw_string(font, Vector2(s.x*0.48,36), "PROTOTIPO DE MOVIMIENTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("b5c9dd"))
    hud_root.draw_string(font, Vector2(s.x*0.48,60), "CP: " + checkpoint_name + "    ·    AUTOGUARDADO", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, white)
    _rounded_box(Vector2(s.x-70, 43), 38.0, red, "II", font, ui_size)
    if intro_seconds > 0.0:
        hud_root.draw_rect(Rect2(Vector2.ZERO,s), Color(0,0,0,minf(0.98,intro_seconds*0.5)))
        _center_text("STAGE 1", s/2.0 + Vector2(0,-20), 55, white)
        _center_text("SALVAR A LA HUMANIDAD ESTÁ EN TUS MANOS",s/2.0 + Vector2(0,37),23,cyan)
        return
    if paused:
        hud_root.draw_rect(Rect2(Vector2.ZERO,s),Color(0.015,0.025,0.04,0.78))
        _center_text("PAUSA",s/2.0 - Vector2(0,18),49,white)
        _center_text("TOCA LA PANTALLA PARA CONTINUAR",s/2.0 + Vector2(0,30),22,cyan)
        return
    var base := Vector2(116,s.y-122)
    hud_root.draw_circle(base,81,Color(0.03,0.10,0.19,0.58))
    hud_root.draw_arc(base,81,0,TAU,72,Color("4d7189"),3.5)
    var thumb: Vector2 = joystick_pos if joystick_finger != -1 else base
    hud_root.draw_circle(thumb,34,Color(0.35,0.78,0.92,0.42))
    hud_root.draw_arc(thumb,34,0,TAU,48,Color("a6eeff"),2.6)
    _rounded_box(Vector2(s.x-109,s.y-120),57.0,red,"SALTO",font,18)
    _rounded_box(Vector2(s.x-238,s.y-116),50.0,cyan,"DASH",font,17)
    _rounded_box(Vector2(s.x-357,s.y-116),43.0,Color("8ba4c9"),"CÁM",font,16)
    hud_root.draw_string(font,Vector2(s.x*0.41,s.y-36),"DESLIZA LA ZONA DERECHA PARA GIRAR LA CÁMARA",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("a9bdd1"))
    if message_time > 0.0:
        hud_root.draw_rect(Rect2(Vector2(s.x*0.24,s.y-250),Vector2(s.x*0.52,47)),Color(0.02,0.03,0.06,0.88))
        _center_text(message,Vector2(s.x*0.50,s.y-217),20,cyan)

func _rounded_box(center: Vector2, radius: float, outline: Color, contents: String, font: Font, size: int) -> void:
    hud_root.draw_circle(center,radius,dark)
    hud_root.draw_arc(center,radius,0,TAU,60,outline,3.0)
    var measured := font.get_string_size(contents,HORIZONTAL_ALIGNMENT_LEFT,-1,size)
    hud_root.draw_string(font, center+Vector2(-measured.x/2.0,measured.y/3.0),contents,HORIZONTAL_ALIGNMENT_LEFT,-1,size,white)

func _center_text(contents: String, center: Vector2, font_size: int, ink: Color) -> void:
    var font: Font = ThemeDB.fallback_font
    var w: float = font.get_string_size(contents,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
    hud_root.draw_string(font,center-Vector2(w/2.0,-font_size*0.33),contents,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)
