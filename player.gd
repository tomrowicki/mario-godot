extends CharacterBody2D


var is_firing_thong = false
var is_dying = false
var is_jumping = false
var is_big = false
var can_fire_thong = false
const SPEED = 300.0
const JUMP_VELOCITY = -600.0
var player_direction = 1

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var death_timer = $death_timer
@onready var thong_fire_timer = $ThongFireTimer

func _ready():
	add_to_group("Player")
	death_timer.connect("timeout", Callable(self, "_on_DeathTimer_timeout"))
	thong_fire_timer.connect("timeout", Callable(self, "_on_ThongFireTimer_timeout"))

func _physics_process(delta):
	if is_dying:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		is_jumping = false

	if Global.current_state == Global.PlayerState.THONG and Input.is_action_just_pressed("fire"):
		fire_thong()

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		player_direction = direction  # Update player_direction here
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	
	update_animation(direction)
	move_and_slide()

func update_animation(direction):
	if is_dying or is_firing_thong:  # Add the new flag here
		return
	
	match Global.current_state:
		Global.PlayerState.SMALL, Global.PlayerState.BIG:
			if is_jumping:
				animated_sprite_2d.play("jump")
			elif direction != 0:
				animated_sprite_2d.flip_h = (direction < 0)
				animated_sprite_2d.play("run")
			else:
				animated_sprite_2d.play("idle")
		Global.PlayerState.THONG:
			if is_jumping:
				animated_sprite_2d.play("thong_jump")
			elif direction != 0:
				animated_sprite_2d.flip_h = (direction < 0)
				animated_sprite_2d.play("thong_run")
			else:
				animated_sprite_2d.play("thong_idle")

func _on_hitbox_body_entered(body):
	if body.is_in_group("Enemy") and body.is_alive:
		match Global.current_state:
			Global.PlayerState.SMALL:
				die()
			Global.PlayerState.BIG:
				Global.current_state = Global.PlayerState.SMALL
			Global.PlayerState.THONG:
				Global.current_state = Global.PlayerState.BIG

func die():
	if is_dying:
		return

	is_dying = true
	animated_sprite_2d.play("die")
	await move_player_up_and_down()
	Global.player_lives -= 1

	if Global.player_lives > 0:
		print("Reloading scene")
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://gameover.tscn")

func move_player_up_and_down():
	var start_position = position
	var up_position = start_position + Vector2(0, -100)
	var down_position = start_position + Vector2(0, 600)

	while position.y > up_position.y:
		position.y -= 4
		await get_tree().create_timer(0.01).timeout

	while position.y < down_position.y:
		position.y += 4
		await get_tree().create_timer(0.01).timeout



func on_DeathTimer_timeout():
	get_tree().reload_current_scene()

func become_big():
	Global.current_state = Global.PlayerState.BIG
	self.scale = Vector2(1.5, 1.5)

func become_small():
	Global.current_state = Global.PlayerState.SMALL
	self.scale = Vector2(1, 1)

func got_thong():
	Global.current_state = Global.PlayerState.THONG

# Inside fire_thong function
func fire_thong():
	is_firing_thong = true
	print("firing thong")
	var thong = load("res://thong.tscn").instantiate()
	thong.global_position = Vector2(self.global_position.x, self.global_position.y - 15)

	thong.set("velocity", Vector2(500 * player_direction, 0))
	print("Thong fired")
	get_parent().add_child(thong)
	$AnimatedSprite2D.play("thong_fire")
	thong_fire_timer.start(1.0) 

func _on_ThongFireTimer_timeout():
	is_firing_thong = false
