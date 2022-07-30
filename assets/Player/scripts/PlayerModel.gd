extends CollisionShape

onready var  _shield = preload("res://assets/Player/Props/Dome.tscn")
onready var _player = get_owner()

func _input(_event) -> void:
	if Input.is_action_just_pressed("ability") and _player.is_on_floor():
		add_child(_shield.instance())
