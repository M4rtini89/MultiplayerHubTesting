extends KinematicBody2D

puppet var slave_position = Vector2()
puppet var slave_movement = Vector2()

var movement = Vector2()
var speed = 200

var health = 100

func _ready():
    $HealthBar.value = health
    if not is_network_master():
        set_process_unhandled_input(false)

func _unhandled_input(event):
    if event.is_action_pressed("up"):
        movement.y -= 1
    if event.is_action_released("up"):
        movement.y +=1
    if event.is_action_pressed("down"):
        movement.y += 1
    if event.is_action_released("down"):
        movement.y -=1

    if event.is_action_pressed("left"):
        movement.x -= 1
    if event.is_action_released("left"):
        movement.x +=1
    if event.is_action_pressed("right"):
        movement.x += 1
    if event.is_action_released("right"):
        movement.x -=1
    
    if event.is_action_pressed("shoot"):
        rpc("shoot", get_global_mouse_position())
        #shoot()


func _process(delta):
    if is_network_master():
        rset_unreliable("slave_position", position)
        rset("slave_movement", movement)  
    else:
        position= slave_position
        movement = slave_movement

func _physics_process(delta):
    move_and_slide(movement.normalized() * speed)


func damage(value):
    health -= value
    $HealthBar.value = health
    if health <= 0:
        die()


func die():
#    queue_free()
    health = 100
    $HealthBar.value = health


sync func shoot(target):
    var bullet = preload("res://Player/weapons/bullet/bullet.tscn").instance()
    bullet.position = position
    var mouse_direction = target - position
    var angle = mouse_direction.angle()
    bullet.direction = Vector2.RIGHT.rotated(angle)
    add_child(bullet)
    
    
    