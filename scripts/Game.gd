extends Node2D
## IRA — El Purificador. Vertical slice 2D for Android, no plugins or online services.
## Fixed 1280x720 canvas; sprites are prepared from the original character sheets.

const W := 1280.0
const H := 720.0
const FLOOR := 574.0
const WORLD_END := 8400.0
const CHECKPOINTS := [0.0, 2100.0, 4400.0, 6550.0]
const PLAYER_SPEED := 295.0
const GRAVITY := 1640.0
const JUMP_FORCE := -680.0
const RED := Color("ff394c")
const AMBER := Color("ffbd6a")
const PALE := Color("e9eef7")
const DARK := Color("080b16")
const SAVE := preload("res://scripts/SaveSystem.gd")

var state := "MENU"
var previous_state := "PLAY"
var state_clock := 0.0
var world_clock := 0.0
var camera_x := 0.0
var hero_x := 105.0
var hero_y := FLOOR
var hero_vy := 0.0
var hero_facing := 1
var hero_hp := 100
var hero_invulnerable := 0.0
var hero_shot_cd := 0.0
var hero_slash_cd := 0.0
var hero_attack_time := 0.0
var hero_move_time := 0.0
var hero_grounded := true
var hero_lead_time := 0.0
var score := 0
var kills := 0
var weapon_level := 1
var checkpoint_index := 0
var stage_number := 1
var score_at_checkpoint := 0
var current_save: Dictionary = {}
var game_message := ""
var message_timer := 0.0
var boss_hp := 42.0
var boss_alive := true
var boss_attack_cd := 2.8
var boss_phase_time := 0.0
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var fx: Array[Dictionary] = []
var player_frames: Dictionary = {}
var enemy_frames: Dictionary = {}
var ally_frames: Dictionary = {}
var bg_seed := 391.0
var touch_map: Dictionary = {}
var last_input_jump := false
var last_input_fire := false
var last_input_slash := false
var has_real_sprites := false

const BUTTONS := {
	"left": Rect2(38, 595, 101, 92),
	"right": Rect2(153, 595, 101, 92),
	"jump": Rect2(850, 586, 103, 102),
	"fire": Rect2(968, 585, 103, 103),
	"slash": Rect2(1084, 582, 112, 109),
	"pause": Rect2(1218, 18, 49, 45)
}

func _ready() -> void:
	load_assets()
	current_save = SAVE.read_save()
	set_process(true)
	set_process_input(true)

func load_assets() -> void:
	for anim in {"idle":6,"run":8,"jump":6,"attack":6,"hurt":4,"lead":4}:
		var arr: Array[Texture2D] = []
		for i in range({"idle":6,"run":8,"jump":6,"attack":6,"hurt":4,"lead":4}[anim]):
			var path := "res://assets/sprites/hero_%s_%d.png" % [anim, i]
			if ResourceLoader.exists(path):
				arr.append(load(path))
		player_frames[anim] = arr
	for kind in ["sadness", "anger", "rage", "exhaustion", "anxiety", "burnout"]:
		var a: Array[Texture2D] = []
		for i in range(11):
			var path := "res://assets/sprites/enemy_%s_%d.png" % [kind, i]
			if ResourceLoader.exists(path):
				a.append(load(path))
		enemy_frames[kind] = a
	for kind in ["civilian", "mother", "student", "elder"]:
		var a: Array[Texture2D] = []
		for i in range(6):
			var path := "res://assets/sprites/ally_%s_walk_%d.png" % [kind, i]
			if ResourceLoader.exists(path):
				a.append(load(path))
		ally_frames[kind] = a
	has_real_sprites = player_frames["idle"].size() > 0

func _process(delta: float) -> void:
	var dt: float = minf(delta, 0.05)
	world_clock += dt
	state_clock += dt
	if state == "INTRO" and state_clock >= 3.8:
		change_state("PLAY")
	elif state == "VICTORY" and state_clock >= 3.7:
		change_state("STAGE2_INTRO")
	elif state == "STAGE2_INTRO" and state_clock >= 4.4:
		change_state("STAGE2")
	elif state == "PLAY":
		update_play(dt)
	if message_timer > 0:
		message_timer -= dt
	queue_redraw()

func change_state(next: String) -> void:
	state = next
	state_clock = 0.0
	touch_map.clear()

func new_game() -> void:
	SAVE.remove_save()
	score = 0
	kills = 0
	weapon_level = 1
	checkpoint_index = 0
	hero_hp = 100
	stage_number = 1
	boss_hp = 42
	boss_alive = true
	build_stage(0)
	save_checkpoint()
	change_state("INTRO")

func continue_game() -> void:
	if not SAVE.exists():
		new_game()
		return
	current_save = SAVE.read_save()
	stage_number = int(current_save.get("stage", 1))
	score = int(current_save.get("score", 0))
	kills = int(current_save.get("kills", 0))
	weapon_level = int(current_save.get("weapon_level", 1))
	hero_hp = int(current_save.get("hp", 100))
	checkpoint_index = int(current_save.get("checkpoint", 0))
	if stage_number >= 2 or bool(current_save.get("cleared", false)):
		change_state("STAGE2")
		return
	build_stage(checkpoint_index)
	change_state("PLAY")
	flash("Partida recuperada · Punto de control %d" % (checkpoint_index+1), 3)

func save_checkpoint() -> void:
	var data := {
		"version": 1, "stage": stage_number, "checkpoint": checkpoint_index,
		"score": score, "kills": kills, "hp": hero_hp,
		"weapon_level": weapon_level, "cleared": stage_number >= 2
	}
	if SAVE.write_save(data):
		current_save = SAVE.read_save()
		score_at_checkpoint = score

func build_stage(from_checkpoint: int) -> void:
	checkpoint_index = from_checkpoint
	hero_x = CHECKPOINTS[from_checkpoint] + 110.0
	hero_y = FLOOR
	hero_vy = 0.0
	hero_invulnerable = 1.5
	hero_shot_cd = 0.0
	hero_slash_cd = 0.0
	hero_attack_time = 0.0
	hero_grounded = true
	camera_x = clampf(hero_x - 310, 0.0, WORLD_END-W)
	boss_alive = true
	boss_hp = 42.0
	boss_attack_cd = 3.5
	boss_phase_time = 0
	bullets.clear()
	fx.clear()
	enemies.clear()
	for n in range(54):
		var x: float = 530.0 + n * 123.0 + float((n * 71) % 180)
		if x < CHECKPOINTS[from_checkpoint] + 50 or x > 7130:
			continue
		var kind := "runner" if n % 3 != 0 else "spitter"
		var archetypes := ["anger", "rage", "anxiety", "sadness", "exhaustion", "burnout"]
		enemies.append({"x":x, "kind":kind,"archetype":archetypes[n%6],"hp":3.0 if kind=="runner" else 2.0,"speed":195.0+float((n*31)%110) if kind=="runner" else 85.0,"cd":1.0+float(n%4)*0.33,"anim":float(n%7)*0.14,"hurt":0.0,"dead":false})

func flash(text: String, duration: float = 2.0) -> void:
	game_message = text
	message_timer = duration

func tapped(name: String) -> bool:
	for key in touch_map:
		if touch_map[key] == name:
			return true
	return false

func update_play(dt: float) -> void:
	hero_invulnerable = maxf(0.0,hero_invulnerable-dt)
	hero_shot_cd = maxf(0.0,hero_shot_cd-dt)
	hero_slash_cd = maxf(0.0,hero_slash_cd-dt)
	hero_attack_time = maxf(0.0,hero_attack_time-dt)
	hero_lead_time = maxf(0.0,hero_lead_time-dt)
	var left := tapped("left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right := tapped("right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var horizontal := int(right) - int(left)
	if horizontal != 0:
		hero_facing = horizontal
		hero_x = clampf(hero_x + horizontal * PLAYER_SPEED * dt, 70.0, 7640.0)
		hero_move_time += dt
	var jumping := tapped("jump") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	if jumping and not last_input_jump and hero_grounded:
		hero_vy = JUMP_FORCE
		hero_grounded = false
		spawn_fx(hero_x, FLOOR-3, AMBER, 6)
	last_input_jump = jumping
	if not hero_grounded:
		hero_vy += GRAVITY * dt
		hero_y += hero_vy * dt
		if hero_y >= FLOOR:
			hero_y = FLOOR
			hero_vy = 0.0
			hero_grounded = true
			spawn_fx(hero_x, FLOOR-5, Color("888a9e"), 4)
	var firing := tapped("fire") or Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_F)
	if firing and hero_shot_cd <= 0.0:
		fire_shot()
	var slashing := tapped("slash") or Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_G)
	if slashing and not last_input_slash and hero_slash_cd <= 0.0:
		melee_attack()
	last_input_fire = firing
	last_input_slash = slashing
	camera_x = lerpf(camera_x,clampf(hero_x-330.0,0.0,WORLD_END-W),minf(1.0,dt*5.2))
	update_enemies(dt)
	update_bullets(dt)
	update_boss(dt)
	update_effects(dt)
	for acid_x in [1050.0, 1860.0, 2960.0, 3890.0, 5120.0, 6030.0]:
		if absf(hero_x-acid_x) < 41.0 and hero_grounded and hero_invulnerable<=0.0:
			hurt_hero(5)
	for c in range(checkpoint_index+1,CHECKPOINTS.size()):
		if hero_x >= CHECKPOINTS[c]:
			checkpoint_index = c
			hero_hp = mini(100,hero_hp+30)
			save_checkpoint()
			flash("PUNTO DE CONTROL %d · PARTIDA GUARDADA"%(c+1),3.5)

func fire_shot() -> void:
	hero_shot_cd = 0.29 if weapon_level == 1 else 0.22
	hero_attack_time = 0.27
	bullets.append({"x":hero_x+hero_facing*55,"y":hero_y-113,"vx":float(hero_facing)*860,"vy":0.0,"source":"hero","damage":1.0+float(weapon_level-1)*0.55,"life":1.3})
	spawn_fx(hero_x+hero_facing*56,hero_y-111,RED,4)

func melee_attack() -> void:
	hero_slash_cd = 0.70
	hero_attack_time = 0.42
	spawn_fx(hero_x+hero_facing*112,hero_y-113,RED,8)
	for e in enemies:
		if bool(e["dead"]):continue
		var dx: float = float(e["x"])-hero_x
		if absf(dx) < 165.0 and dx*hero_facing > -30.0:
			e["hp"] = float(e["hp"]) - 2.5 - (weapon_level-1)*0.55
			e["hurt"] = 0.25
			spawn_fx(float(e["x"]),FLOOR-85,RED,9)
			if float(e["hp"]) <= 0: kill_enemy(e)
	if boss_alive and hero_x>7220 and hero_facing>0 and absf(hero_x-7530)<220:
		boss_hp -= 2.4
		spawn_fx(7520,FLOOR-135,AMBER,9)

func update_enemies(dt: float) -> void:
	for e in enemies:
		if bool(e["dead"]):continue
		var ex: float = float(e["x"])
		if ex > camera_x + 1470.0 or ex < camera_x - 470.0:continue
		e["cd"] = float(e["cd"])-dt
		e["hurt"] = maxf(0.0,float(e["hurt"])-dt)
		e["anim"] = float(e["anim"])+dt
		var dx: float = hero_x-ex
		if absf(dx) > 42.0:
			var speed: float = float(e["speed"])
			if e["kind"]=="spitter" and absf(dx)<340.0:
				speed *= 0.3
			e["x"] = ex + signf(dx)*speed*dt
		if absf(dx)<65.0 and hero_grounded and float(e["cd"])<=0.0:
			hurt_hero(13 if e["kind"]=="runner" else 8)
			e["cd"] = 1.15
		elif e["kind"]=="spitter" and absf(dx)<550.0 and float(e["cd"])<=0.0:
			var direction: float = signf(dx)
			bullets.append({"x":float(e["x"])+direction*28,"y":FLOOR-122,"vx":direction*380.0,"vy":-55.0,"source":"acid","damage":10.0,"life":2.2})
			e["cd"] = 2.5

func update_bullets(dt: float) -> void:
	for p in bullets:
		p["x"] = float(p["x"])+float(p["vx"])*dt
		p["y"] = float(p["y"])+float(p["vy"])*dt
		p["life"] = float(p["life"])-dt
		if p["source"]=="hero":
			for e in enemies:
				if bool(e["dead"]):continue
				if absf(float(p["x"])-float(e["x"]))<39.0 and absf(float(p["y"])-(FLOOR-105.0))<77.0:
					e["hp"] = float(e["hp"])-float(p["damage"])
					e["hurt"] = 0.15
					p["life"] = -1.0
					spawn_fx(float(e["x"]),float(p["y"]),RED,5)
					if float(e["hp"])<=0.0:kill_enemy(e)
					break
			if boss_alive and float(p["x"])>7470 and float(p["x"])<7610 and absf(float(p["y"])-(FLOOR-138))<93.0:
				boss_hp -= float(p["damage"])
				p["life"] = -1.0
				spawn_fx(float(p["x"]),float(p["y"]),RED,7)
		else:
			if absf(float(p["x"])-hero_x)<39.0 and absf(float(p["y"])-(hero_y-104))<90.0:
				p["life"] = -1.0
				hurt_hero(int(p["damage"]))
	var kept: Array[Dictionary] = []
	for p in bullets:
		if float(p["life"])>0.0:kept.append(p)
	bullets = kept

func kill_enemy(e: Dictionary) -> void:
	if bool(e["dead"]):return
	e["dead"] = true
	kills += 1
	score += 135 if e["kind"]=="spitter" else 85
	spawn_fx(float(e["x"]),FLOOR-94,AMBER,16)
	if score>=2400:
		weapon_level = 3
	elif score>=850:
		weapon_level = 2

func update_boss(dt: float) -> void:
	if not boss_alive or hero_x<7000:return
	boss_phase_time += dt
	boss_attack_cd -= dt
	if boss_hp<=0:
		boss_alive = false
		score += 2500
		stage_number = 2
		save_checkpoint()
		spawn_fx(7520,FLOOR-140,AMBER,60)
		change_state("VICTORY")
		return
	if boss_attack_cd<=0:
		boss_attack_cd = 2.0 if boss_hp<22 else 2.7
		for i in range(3 if boss_hp<22 else 2):
			bullets.append({"x":7460.0,"y":FLOOR-120.0+float(i)*41.0,"vx":-370.0-float(i)*66,"vy":-75.0+float(i)*65,"source":"vein","damage":14.0,"life":2.8})
	if absf(hero_x-7520)<150.0 and hero_invulnerable<=0.0 and hero_grounded:
		hurt_hero(16)

func update_effects(dt: float) -> void:
	for p in fx:
		p["x"] = float(p["x"])+float(p["vx"])*dt
		p["y"] = float(p["y"])+float(p["vy"])*dt
		p["vy"] = float(p["vy"])+310*dt
		p["time"] = float(p["time"])-dt
	var kept: Array[Dictionary] = []
	for p in fx:
		if float(p["time"])>0:kept.append(p)
	fx=kept

func spawn_fx(x:float,y:float,col:Color,count:int=7) -> void:
	for i in count:
		var rad:float = randf_range(0,TAU)
		var speed:float = randf_range(45,230)
		fx.append({"x":x,"y":y,"vx":cos(rad)*speed,"vy":sin(rad)*speed-100,"time":randf_range(0.23,0.72),"color":col})

func hurt_hero(amount:int) -> void:
	if hero_invulnerable>0:return
	hero_hp = maxi(0,hero_hp-amount)
	hero_invulnerable = 0.93
	spawn_fx(hero_x,hero_y-100,RED,11)
	if hero_hp<=0:
		change_state("GAME_OVER")

func restart_checkpoint() -> void:
	continue_game()
	if state == "PLAY":
		hero_hp = 100
		hero_invulnerable = 2.5
		flash("Regresas al último punto de control", 3)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			if state=="PLAY":
				previous_state="PLAY"
				change_state("PAUSE")
			elif state=="PAUSE":
				change_state("PLAY")
			get_viewport().set_input_as_handled()
		elif event.keycode==KEY_ENTER and state=="MENU":
			if SAVE.exists():
				continue_game()
			else:
				new_game()
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var position := touch.position
		if touch.pressed:
			if state=="PLAY":
				for action in BUTTONS.keys():
					if BUTTONS[action].has_point(position):
						if action=="pause":
							previous_state="PLAY"
							change_state("PAUSE")
						else:
							touch_map[touch.index]=action
						break
			else:
				handle_press(position)
		else:
			touch_map.erase(touch.index)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			if state=="PLAY":
				for action in BUTTONS.keys():
					if BUTTONS[action].has_point(event.position):
						if action=="pause":
							change_state("PAUSE")
						else:
							touch_map[999]=action
						break
			else:
				handle_press(event.position)
		else:
			touch_map.erase(999)

func handle_press(pos: Vector2) -> void:
	if state=="MENU":
		if Rect2(733,252,436,68).has_point(pos):
			if SAVE.exists():
				continue_game()
			else:
				new_game()
		elif Rect2(733,331,436,68).has_point(pos):
			if SAVE.exists():change_state("CONFIRM_NEW")
			else:new_game()
		elif Rect2(733,410,436,68).has_point(pos):
			change_state("ARMORY")
		elif Rect2(733,489,436,68).has_point(pos):
			get_tree().quit()
	elif state=="ARMORY":
		change_state("MENU")
	elif state=="CONFIRM_NEW":
		if Rect2(435,411,183,65).has_point(pos):new_game()
		elif Rect2(657,411,183,65).has_point(pos):change_state("MENU")
	elif state=="PAUSE":
		if Rect2(420,285,440,64).has_point(pos):change_state("PLAY")
		elif Rect2(420,366,440,64).has_point(pos):
			save_checkpoint()
			change_state("MENU")
	elif state=="GAME_OVER":
		if Rect2(415,420,450,70).has_point(pos):restart_checkpoint()
		elif Rect2(415,505,450,65).has_point(pos):change_state("MENU")
	elif state=="STAGE2":
		if Rect2(422,485,436,65).has_point(pos):change_state("MENU")

func _draw() -> void:
	if state in ["PLAY","PAUSE","GAME_OVER","MENU","ARMORY","CONFIRM_NEW"]:
		draw_world()
	if state=="MENU":draw_menu()
	elif state=="ARMORY":draw_armory()
	elif state=="CONFIRM_NEW":draw_confirm_new()
	elif state=="PLAY":
		draw_game_entities()
		draw_hud()
		draw_touch_ui()
	elif state=="PAUSE":
		draw_game_entities()
		draw_hud()
		draw_pause()
	elif state=="GAME_OVER":
		draw_game_entities()
		draw_game_over()
	elif state=="INTRO":draw_stage_card("STAGE 1", "Salvar a la humanidad está en tus manos.","EL COMIENZO DEL CAOS")
	elif state=="VICTORY":draw_stage_card("SUPERASTE EL STAGE 1.", "El Ojo ha caído. La esperanza sigue viva.","+2500 PUNTOS · PROGRESO GUARDADO")
	elif state=="STAGE2_INTRO":draw_stage_card("STAGE 2", "La primera cura", "PRÓXIMAMENTE")
	elif state=="STAGE2":draw_stage_two()

func label(x:float,y:float,message:String,size:int=26,color:Color=PALE,width:float=-1.0,align:HorizontalAlignment=HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ThemeDB.fallback_font,Vector2(x,y),message,align,width,size,color)

func rectangle(x:float,y:float,w:float,h:float,color:Color) -> void:
	draw_rect(Rect2(x,y,w,h),color)

func panel(x:float,y:float,w:float,h:float,fill:Color,border:Color=Color("53526b")) -> void:
	draw_rect(Rect2(x,y,w,h),fill)
	draw_rect(Rect2(x,y,w,h),border,false,2)

func button(x:float,y:float,w:float,h:float,text:String,accent:bool=false,small:String="") -> void:
	panel(x,y,w,h,Color("182030") if not accent else Color("7f1e34"),RED if accent else Color("435067"))
	rectangle(x,y,6,h,RED)
	label(x+20,y+43,text,25,PALE)
	if small!="":label(x+20,y+60,small,13,Color("a8aabd"))

func draw_world() -> void:
	# Horizon glow / smog gradient.
	for i in range(24):
		var t:=float(i)/24.0
		rectangle(0,i*26,W,27,Color(0.045+t*.18,0.05+t*.045,0.095+t*.025))
	for i in range(12):
		draw_circle(Vector2(935.0,395.0),290.0-i*17.0,Color(0.26,0.055,0.08,0.018))
	# Slow-moving skyline. Consistent pseudo-random silhouettes, broken roofs and windows.
	for layer in range(3):
		var factor:float = [0.18,0.40,0.71][layer]
		var baseline:float = [527,550,574][layer]
		var tint:Color = [Color("342b3b"),Color("211e31"),Color("111522")][layer]
		for b in range(-2,34):
			var wx:float = b*153.0 - camera_x*factor
			if wx < -235 or wx > W+170:continue
			var height:float = 130.0 + fposmod(sin(float(b)*27.17+float(layer)*9.0)*1000.0,205.0)
			var top:float=baseline-height
			var building:=PackedVector2Array([Vector2(wx,baseline),Vector2(wx,top+24),Vector2(wx+24,top+10),Vector2(wx+40,top+19),Vector2(wx+53,top),Vector2(wx+116,top+28),Vector2(wx+130,baseline)])
			draw_colored_polygon(building,tint)
			if layer>0:
				for row in range(5):
					for col in range(3):
						if (b*5+row*3+col)%4==0:continue
						var window_y:=top+53+row*39
						if window_y < baseline-16:
							rectangle(wx+17+col*29,window_y,9,18,Color(0.38,0.15,0.15,.44) if (b+row+col)%7==0 else Color("111420"))
	# Ash / smoke bands, moving bright red sky trails.
	for i in range(7):
		var sx:float=fposmod(i*269.0-world_clock*(5+i*2),1560.0)-150
		draw_line(Vector2(sx,128+i*48),Vector2(sx+190,121+i*47),Color(.7,.28,.33,.08),12)
	# Demolished highway in foreground.
	rectangle(0,FLOOR-1,W,146,Color("191b25"))
	rectangle(0,FLOOR,W,9,Color("55515d"))
	rectangle(0,FLOOR+8,W,16,Color("30303b"))
	for k in range(23):
		var x:float=k*101.0-fposmod(camera_x,101.0)
		rectangle(x,FLOOR+80,62,4,Color("6d5b5d"))
		draw_line(Vector2(x,FLOOR+17),Vector2(x-31,FLOOR+43),Color("0c0c15"),3)
	# Distant infected birds with lionlike tufted tails.
	for n in range(9):
		var bx:float=fposmod(n*191.0-world_clock*(23+n*4)-camera_x*.13,1450.0)-60.0
		var by:float=95+fposmod(n*46.0,165.0)+sin(world_clock*3+n)*7
		draw_line(Vector2(bx,by),Vector2(bx-19,by-9+sin(world_clock*6+n)*8),Color("0a0e19"),3)
		draw_line(Vector2(bx,by),Vector2(bx+19,by-9+cos(world_clock*6+n)*8),Color("0a0e19"),3)
		draw_line(Vector2(bx,by),Vector2(bx+13,by+14),Color("10131a"),2)
		draw_circle(Vector2(bx+13,by+14),3,Color("080e18"))
	for checkpoint_id in CHECKPOINTS.size():
		var cpos:float=CHECKPOINTS[checkpoint_id]-camera_x
		if cpos > -90 and cpos < W+90 and checkpoint_id>0:
			draw_line(Vector2(cpos,FLOOR-5),Vector2(cpos,FLOOR-227),Color("a8bac9"),4)
			draw_circle(Vector2(cpos,FLOOR-227),13,Color("43dfcb") if checkpoint_id<=checkpoint_index else RED)
			label(cpos-46,FLOOR-250,"CP %d"%(checkpoint_id+1),19,PALE)
	for acid_x in [1050.0,1860.0,2960.0,3890.0,5120.0,6030.0]:
		var ax:float=acid_x-camera_x
		if ax>-90 and ax<W+90:
			panel(ax-29,FLOOR-69,58,68,Color("3b3c3c"),Color("6d8795"))
			rectangle(ax-29,FLOOR-51,58,9,Color("aab9bd"))
			draw_circle(Vector2(ax,FLOOR-35),13,Color("b1fa4a"))
			label(ax-8,FLOOR-27,"!",21,Color("193e14"))
			for drop in range(3):
				var dx:float=ax+float(drop*9)-8
				var dy:float=FLOOR-68+fposmod(world_clock*(32+drop*11)+drop*17,73.0)
				draw_circle(Vector2(dx,dy),3,Color("aafa43"))

func draw_game_entities() -> void:
	for p in fx:
		var sx:float=float(p["x"])-camera_x
		if sx>-30 and sx<W+30:
			draw_circle(Vector2(sx,float(p["y"])),3.5,p["color"])
	for e in enemies:
		if bool(e["dead"]):continue
		var ex:float=float(e["x"])-camera_x
		if ex<-160 or ex>W+160:continue
		var ea:float=float(e["anim"])
		var frame:int=4+int(ea*7.0)%4
		if absf(hero_x-float(e["x"]))<135 and float(e["cd"])<.25:
			frame=8+int(ea*8.0)%3
		var a:Array=enemy_frames[e["archetype"]]
		if a.size()>0:
			var tex:Texture2D=a[mini(frame,a.size()-1)]
			var scale:float=1.06 if e["archetype"]=="rage" else 0.89
			draw_character(tex,Vector2(ex,FLOOR),scale,(-1 if float(e["x"])>hero_x else 1),Color(1,0.55,0.55) if float(e["hurt"])>0 else Color.WHITE)
		else:
			draw_dummy_human(ex,FLOOR, e["kind"]=="runner")
	for bullet in bullets:
		var bx:float=float(bullet["x"])-camera_x
		var by:float=float(bullet["y"])
		if bullet["source"]=="hero":
			draw_line(Vector2(bx-24,by),Vector2(bx+23,by),RED,10)
			draw_circle(Vector2(bx,by),10,AMBER)
		else:
			draw_circle(Vector2(bx,by),12,Color("c5fd49") if bullet["source"]=="acid" else RED)
			draw_line(Vector2(bx-23,by+4),Vector2(bx+20,by-5),Color("7aef47") if bullet["source"]=="acid" else AMBER,3)
	if boss_alive and hero_x>6700:
		draw_boss(7530.0-camera_x,FLOOR-128)
	var anim: String = "idle"
	if hero_attack_time>0:anim="attack"
	elif not hero_grounded:anim="jump"
	elif absf(float(int(tapped("right"))-int(tapped("left"))))>0 or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT):anim="run"
	var arr:Array = player_frames[anim]
	if arr.size()==0:arr=player_frames["idle"]
	var id:int=0
	if anim=="run":id=int(hero_move_time*13)%arr.size() if arr.size()>0 else 0
	elif anim=="attack":id=int((.42-hero_attack_time)*19)%arr.size() if arr.size()>0 else 0
	elif anim=="jump":id=clampi(int((hero_y-FLOOR)/-90.0),0,arr.size()-1) if arr.size()>0 else 0
	elif anim=="idle":id=int(world_clock*2.5)%arr.size() if arr.size()>0 else 0
	if arr.size()>0:
		var tone:Color=Color(1,0.6,0.6,.66) if hero_invulnerable>0 and fmod(world_clock,0.24)<0.12 else Color.WHITE
		draw_character(arr[id],Vector2(hero_x-camera_x,hero_y),1.14,hero_facing,tone)
	else:draw_dummy_hero(hero_x-camera_x,hero_y)
	if hero_attack_time>0.22:
		var hx:float=hero_x-camera_x+hero_facing*106
		draw_arc(Vector2(hx,hero_y-125),88,2.9,5.7,27,Color(1,.2,.25,.8),8)

func draw_character(tex:Texture2D,feet:Vector2,scale:float=1.0,facing:int=1,modulate:Color=Color.WHITE) -> void:
	var size:Vector2=tex.get_size()*scale
	# Character image is anchored by its feet (bottom of frame) and centered horizontally.
	if facing<0:
		draw_set_transform(Vector2(feet.x,feet.y),0.0,Vector2(-1,1))
		draw_texture_rect(tex,Rect2(-size.x/2,-size.y,size.x,size.y),false,modulate)
		draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
	else:
		draw_texture_rect(tex,Rect2(feet.x-size.x/2,feet.y-size.y,size.x,size.y),false,modulate)

func draw_dummy_human(x:float,y:float,fast:bool) -> void:
	draw_circle(Vector2(x,y-130),19,Color("888d9c"))
	draw_line(Vector2(x,y-110),Vector2(x,y-48),Color("413e4e"),29)
	draw_line(Vector2(x,y-55),Vector2(x-22,y),Color("413e4e"),16)
	draw_line(Vector2(x,y-55),Vector2(x+18,y),Color("413e4e"),16)
	draw_circle(Vector2(x+8,y-136),4,RED)

func draw_dummy_hero(x:float,y:float) -> void:
	draw_circle(Vector2(x,y-158),22,Color("dce1ea"))
	draw_line(Vector2(x,y-132),Vector2(x,y-58),Color("b9bec9"),40)
	draw_line(Vector2(x,y-68),Vector2(x-25,y),Color("9198ae"),23)
	draw_line(Vector2(x,y-68),Vector2(x+22,y),Color("a9b1c1"),23)
	draw_line(Vector2(x-25,y-120),Vector2(x-75,y-85),Color("c92945"),18)
	draw_circle(Vector2(x+7,y-162),5,RED)

func draw_boss(x:float,y:float) -> void:
	var pulse:float=sin(world_clock*3.0)*5.0
	for t in range(7):
		var ang:float=float(t)*TAU/7.0+sin(boss_phase_time*2+t)*.4
		var start:=Vector2(x+cos(ang)*87,y+sin(ang)*41)
		var end:=Vector2(x+cos(ang)*159,y+sin(ang)*84+sin(world_clock*4+t)*21)
		draw_line(start,end,Color("5b192d"),14)
		draw_line(start,end,RED,5)
		draw_circle(end,9,Color("c54f57"))
	# Shadow, mucous body, optic iris, slit pupil, pulsing red capillaries.
	draw_circle(Vector2(x,y+75),117,Color(0.08,.04,.07,.5))
	draw_circle(Vector2(x,y),105+pulse,Color("4c2234"))
	draw_circle(Vector2(x,y),89+pulse,Color("d7acb1"))
	draw_circle(Vector2(x,y),73+pulse,Color("f9e8c5"))
	draw_circle(Vector2(x+10,y+3),54,Color("a53047"))
	draw_circle(Vector2(x+10,y+3),42,Color("ff6b63"))
	draw_circle(Vector2(x+10,y+3),27,Color("14111d"))
	draw_circle(Vector2(x+19,y-14),8,Color("fff4e2"))
	for n in range(17):
		var a:float=n*TAU/17.0
		var inner:=Vector2(x+cos(a)*64,y+sin(a)*64)
		var outer:=Vector2(x+cos(a)*95,y+sin(a)*95)
		draw_line(inner,outer,Color("aa283e"),2)
	if state=="PLAY":
		panel(760,55,425,28,Color("241725"),RED)
		rectangle(766,60,maxf(0,413*boss_hp/42.0),18,RED)
		label(764,46,"EL OJO · NÚCLEO DE CORRUPCIÓN",19,PALE)

func draw_hud() -> void:
	panel(16,16,355,94,Color(0.025,0.037,0.08,.86),Color("40495d"))
	label(29,40,"IRA / EL PURIFICADOR",19,PALE)
	rectangle(29,59,270,20,Color("442334"))
	rectangle(29,59,270*hero_hp/100.0,20,RED)
	label(306,76,"%d%%"%hero_hp,17,PALE)
	label(29,103,"SCORE  %07d    STAGE %d"%[score,stage_number],19,AMBER)
	panel(395,18,350,58,Color(0.015,0.023,0.055,.73),Color("485068"))
	label(415,43,"ARMA / GARRA DE PURIFICACIÓN",15,PALE)
	label(415,65,"LV. %d · KILLS %d · CP %d"%[weapon_level,kills,checkpoint_index+1],17,AMBER)
	if message_timer>0:
		panel(275,116,730,52,Color(0.02,.04,.065,.86),Color("538185"))
		label(294,149,game_message,22,Color("d0ffe9"),690,HORIZONTAL_ALIGNMENT_CENTER)

func touch_button(name:String,text:String) -> void:
	var r:Rect2=BUTTONS[name]
	var active:=tapped(name)
	draw_rect(r,Color(.55,.11,.19,.66) if active else Color(.08,.13,.20,.71),true)
	draw_rect(r,RED if active else Color(.40,.49,.64,.80),false,3)
	label(r.position.x,r.position.y+r.size.y*.60,text,27,PALE,r.size.x,HORIZONTAL_ALIGNMENT_CENTER)

func draw_touch_ui() -> void:
	touch_button("left","◀")
	touch_button("right","▶")
	touch_button("jump","SALTO")
	touch_button("fire","PULSO")
	touch_button("slash","GARRA")
	touch_button("pause","II")

func dim_background(opacity:float=.85) -> void:
	rectangle(0,0,W,H,Color(0.01,.013,.025,opacity))

func draw_menu() -> void:
	# Menu camera slowly pans over the ruined city.
	camera_x = 110.0+sin(world_clock*.10)*40.0
	dim_background(.43)
	panel(669,76,534,568,Color(.023,.036,.065,.90),Color("5b3044"))
	rectangle(669,76,9,568,RED)
	label(718,135,"IRA",74,PALE)
	label(718,177,"EL PURIFICADOR",27,RED)
	label(719,207,"Un mundo caótico. Una última esperanza.",17,Color("9cabbc"))
	if has_real_sprites:
		var a:Array=player_frames["idle"]
		var tex:Texture2D=a[int(world_clock*2.2)%a.size()]
		draw_character(tex,Vector2(357,591),2.55,1)
	else:
		draw_dummy_hero(350,577)
	button(733,252,436,68,"CONTINUAR PARTIDA",true,"Desde el último punto de control" if SAVE.exists() else "Aún no existe una partida guardada")
	button(733,331,436,68,"NUEVA PARTIDA")
	button(733,410,436,68,"ARMAS Y PROGRESO")
	button(733,489,436,68,"SALIR")
	var stats:Dictionary = SAVE.read_save() if SAVE.exists() else SAVE.defaults()
	label(711,600,"SCORE  %07d     NIVEL  %d     ARMA  LV.%d"%[int(stats["score"]),int(stats["stage"]),int(stats["weapon_level"])],16,AMBER)
	label(28,686,"EDICIÓN ANDROID  ·  DEMO STAGE 1  ·  GUARDADO LOCAL",17,Color("a3aaba"))

func draw_armory() -> void:
	dim_background(.87)
	label(92,106,"ARSENAL Y PROGRESO",44,PALE)
	rectangle(91,128,1102,3,RED)
	var s:Dictionary=SAVE.read_save() if SAVE.exists() else SAVE.defaults()
	var unlocked:int=int(s["weapon_level"])
	for i in range(3):
		var x:float=93+i*372.0
		panel(x,176,339,337,Color("1c2232"),RED if unlocked>i else Color("4b5565"))
		label(x+24,221,["GARRA PRIMARIA","PULSO CONCENTRADO","NÚCLEO SUPREMO"][i],22,PALE)
		label(x+24,264,["Arma base / LV 1","850 puntos / LV 2","2400 puntos / LV 3"][i],17,Color("c4a5ae"))
		if i==0:
			draw_line(Vector2(x+85,375),Vector2(x+245,305),RED,19)
			draw_line(Vector2(x+104,405),Vector2(x+260,340),AMBER,5)
		else:
			draw_arc(Vector2(x+160,370),72,0,TAU,30,RED if unlocked>i else Color("555e6f"),9)
			label(x+110,382,"LV %d"%(i+1),25,PALE)
		label(x+23,481,"DESBLOQUEADA" if unlocked>i else "BLOQUEADA",20,Color("71f4cf") if unlocked>i else Color("8d91a1"))
	label(98,571,"Puntuación: %d     Eliminaciones: %d     Stage: %d"%[int(s["score"]),int(s["kills"]),int(s["stage"])],22,PALE)
	button(90,611,365,66,"VOLVER AL MENÚ",true)

func draw_confirm_new() -> void:
	dim_background(.92)
	label(0,240,"¿INICIAR UNA NUEVA PARTIDA?",37,PALE,W,HORIZONTAL_ALIGNMENT_CENTER)
	label(0,302,"Se reemplazará el guardado anterior y comenzarás desde cero.",21,Color("aebdcc"),W,HORIZONTAL_ALIGNMENT_CENTER)
	button(435,411,183,65,"SÍ, INICIAR",true)
	button(657,411,183,65,"CANCELAR")

func draw_pause() -> void:
	dim_background(.76)
	label(0,207,"PARTIDA EN PAUSA",54,PALE,W,HORIZONTAL_ALIGNMENT_CENTER)
	label(0,247,"Checkpoint %d  ·  Score %d"%[checkpoint_index+1,score],22,AMBER,W,HORIZONTAL_ALIGNMENT_CENTER)
	button(420,285,440,64,"REANUDAR",true)
	button(420,366,440,64,"GUARDAR Y SALIR")

func draw_game_over() -> void:
	dim_background(.85)
	label(0,234,"HAS SIDO INFECTADO",52,RED,W,HORIZONTAL_ALIGNMENT_CENTER)
	label(0,291,"La humanidad aún necesita al Purificador.",23,PALE,W,HORIZONTAL_ALIGNMENT_CENTER)
	label(0,337,"Continuarás desde tu último punto de control.",19,Color("b1b5c2"),W,HORIZONTAL_ALIGNMENT_CENTER)
	button(415,420,450,70,"REINTENTAR",true)
	button(415,505,450,65,"MENÚ PRINCIPAL")

func draw_stage_card(heading:String,description:String,footer:String) -> void:
	rectangle(0,0,W,H,Color.BLACK)
	var fade:float=clampf(state_clock/0.9,0.0,1.0)*clampf((4.0-state_clock)/.65,0.0,1.0)
	var alph:Color=Color(1,1,1,fade)
	rectangle(401,254,478,3,Color(1,.14,.2,fade))
	label(0,332,heading,56,Color(1,1,1,fade),W,HORIZONTAL_ALIGNMENT_CENTER)
	label(0,395,description,29,Color(.91,.85,.88,fade),W,HORIZONTAL_ALIGNMENT_CENTER)
	label(0,500,footer,18,Color(.92,.3,.36,fade),W,HORIZONTAL_ALIGNMENT_CENTER)

func draw_stage_two() -> void:
	rectangle(0,0,W,H,Color("07080d"))
	for i in range(12):
		draw_circle(Vector2(650,315),330-i*23,Color(.6,.1,.14,.016))
	label(0,225,"STAGE 2",65,PALE,W,HORIZONTAL_ALIGNMENT_CENTER)
	label(0,309,"LA PRIMERA CURA",40,RED,W,HORIZONTAL_ALIGNMENT_CENTER)
	label(0,382,"Próximo nivel en desarrollo",24,Color("b2b9c7"),W,HORIZONTAL_ALIGNMENT_CENTER)
	label(0,428,"El progreso de Stage 1 ya está guardado.",19,Color("8ea49e"),W,HORIZONTAL_ALIGNMENT_CENTER)
	button(422,485,436,65,"VOLVER AL MENÚ",true)
