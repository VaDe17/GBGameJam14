extends Node2D

# Радиус шестерёнки в пикселях. Нужен, чтобы понимать, с кем она сцеплена.
@export var radius: float = 25.0

@export var animated_sprite: AnimatedSprite2D = null

@export var spin_animation_name: String = "spin"

# Крутится ли сейчас. Управляется менеджером.
var is_driven: bool = false

# Направление вращения: 1 — вперёд, -1 — назад.
var spin_direction: int = 1

func set_driven(driven: bool, direction: int = 1) -> void:
	if animated_sprite == null:
		return

	is_driven = driven
	spin_direction = direction

	if not driven:
		animated_sprite.pause()
		return

	animated_sprite.play(spin_animation_name)
	animated_sprite.speed_scale = spin_direction
