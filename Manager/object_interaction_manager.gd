extends Node2D

# Список объектов, между которыми переключаемся. Заполняется в инспекторе.
@export var interactable_objects: Array[Node2D] = []
# Зона обзора в градусах.
@export var cone_angle_deg: float = 75.0
# Насколько важно, чтобы объект был ровно по направлению клавиши. 
# Чем больше, тем важнее в процентах
@export var angle_weight: float = 30.0
# Коэффициент «ничьи». Если два объекта одинаковы, выбор исходит из того где не был.
@export var tie_threshold_ratio: float = 0.1

# Текущий выбранный объект.
var currently_selected_object: Node2D = null
# Прошлый выбранный объект.
var previous_selected_object: Node2D = null

# Выполняется один раз при запуске сцены.
func _ready() -> void:
	# Для случая если список объектов пустой.
	if interactable_objects.is_empty():
		return
	# Выбор первого объекта из списка.
	currently_selected_object = interactable_objects[0]
	_bigger_object()

# Увеличивает размер выбранного объекта, остальные к обычному размеру.
func _bigger_object() -> void:
	for object in interactable_objects:
		if object == currently_selected_object:
			object.scale = Vector2(1.5, 1.5)
		else:
			object.scale = Vector2.ONE

# Выполняется при нажатии кнопок.
func _unhandled_input(event: InputEvent) -> void:
	# Пустое направление. Если ничего не нажато — таким и останется.
	var direction := Vector2.ZERO
	# Проверка нажатия конкретной клавиши, остальные игнорируем.
	if event.is_action_pressed("ui_left"):
		direction = Vector2.LEFT
	elif event.is_action_pressed("ui_right"):
		direction = Vector2.RIGHT
	elif event.is_action_pressed("ui_up"):
		direction = Vector2.UP
	elif event.is_action_pressed("ui_down"):
		direction = Vector2.DOWN
	
	# Поиск объекта при нажатии хоть одной клавиши.
	if direction != Vector2.ZERO:
		_selection(direction)

# Выбор объекта в заданном направлении
func _selection(direction: Vector2) -> void: 
	# Для случая если текущий выбранный объект был убран.
	if currently_selected_object == null or not is_instance_valid(currently_selected_object):
		return
	
	# Поиск лучшего объекта в заданном направлении.
	var best_candidate := _find_best(direction, cone_angle_deg)

	# Если ничего нет — оставляем выбор как был.
	if best_candidate == null:
		return

	# Запоминает, откуда ушли, (до того, как поменять текущий).
	previous_selected_object = currently_selected_object
	# Делает лучшего текущим.
	currently_selected_object = best_candidate
	_bigger_object()

# Ищет лучший объект в заданном направлении внутри зоны обзора.
func _find_best(direction: Vector2, angle_deg: float) -> Node2D:
	# Позиция текущего выбранного объекта — точка отсчёта.
	var current_position: Vector2 = currently_selected_object.global_position
	# Переводит угол в число для сравнения, 
	# если у кандидата «совпадение по направлению» меньше этого — он вне сектора.
	var minimum_alignment: float = cos(deg_to_rad(angle_deg))

	# Список для всех подходящих кандидатов с их оценками.
	var candidates: Array = []

	# Перебор всех кандитатов.
	for candidate in interactable_objects:
		# Пропуск текущего объекта.
		if candidate == currently_selected_object:
			continue
		# Если объект удалили со сцены — пропуск.
		if not is_instance_valid(candidate):
			continue
		
		# Стрелка от текущего объекта до кандидата.
		var vector_to_candidate: Vector2 = candidate.global_position - current_position
		# Длина этой стрелки = расстояние между ними.
		var distance_to_candidate: float = vector_to_candidate.length()
		# Пропуск другого объекта от текущего, который стоит там же.
		if distance_to_candidate < 0.001:
			continue

		# Проверка точно ли в той стороне находится кандидат?
		var alignment: float = vector_to_candidate.normalized().dot(direction)
		# Если кандидат вне зоны - пропуск.
		if alignment < minimum_alignment:
			continue

		# Перевод «совпадения» в угол (в радианах).
		var angle_offset: float = acos(clampf(alignment, -1.0, 1.0))
		# Оценка кандидата. На данный момент приоритет на направление клавиши.
		var candidate_score: float = distance_to_candidate + angle_offset * angle_weight
		# Добавить кандидата с оценкой в список
		candidates.append({"object": candidate, "score": candidate_score})

	# Если не кандидатов - не найдено.
	if candidates.is_empty():
		return null

	# Находит кандидата лучшего по оценке.
	var best_entry: Dictionary = candidates[0]
	for entry in candidates:
		# Если у кого-то оценка меньше - становится новым лучшим.
		if entry["score"] < best_entry["score"]:
			best_entry = entry

	# Если лучший — это тот, откуда мы пришли, и есть другие кандидаты...
	if best_entry["object"] == previous_selected_object and candidates.size() > 1:
		# Место для лучшего альтернативного кандидата.
		var alternative_entry: Dictionary = {}
		# Ищет лучшую альтернативу среди тех, где ещё не был.
		for entry in candidates:
			if entry["object"] == previous_selected_object:
				continue
			# Если это первый кандидат или он лучше текущей альтернативы — запоминает
			if alternative_entry.is_empty() or entry["score"] < alternative_entry["score"]:
				alternative_entry = entry

		# Насколько альтернатива хуже лучшего. 
		var difference: float = alternative_entry["score"] - best_entry["score"]
		# Порог «ничьи» — x% от оценки лучшего кандидата.
		var tie_threshold: float = best_entry["score"] * tie_threshold_ratio

		# Порог насколько альтернатива хуже лучшего.
		if difference < tie_threshold:
			# Берём альтернативу, чтобы не топтаться на месте.
			return alternative_entry["object"]

	return best_entry["object"]
