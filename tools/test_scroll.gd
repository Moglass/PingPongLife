extends Node
## 验证触摸拖拽滚动：手指按在卡片上往下划，scroll_vertical 应该变化。
## 这正是真机上「滑不动」的场景——按钮盖住了大半屏幕。

func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(393, 852))
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	var main: Control = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	GameManager.new_career("滑动", "prodigy")
	main._enter_game()
	# 用成就页测：143 个条目，内容远高于视口
	main.show_page(main.Page.PROFILE)
	if main.current_view != null:
		main.current_view.tab = 2
		main.current_view.refresh()
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout

	var scroll := _find_scroll(main.current_view)
	if scroll == null:
		print("[SCROLL] 找不到滚动容器")
		get_tree().quit()
		return

	print("[SCROLL] 容器=", scroll.get_class(), " 内容高=", scroll.get_child(0).size.y, " 视口高=", scroll.size.y)
	var before := scroll.scroll_vertical

	# 模拟：手指按在屏幕中部（大概率落在某张行动卡上）往下拖 120px
	_touch(0, Vector2(196, 500), true)
	await get_tree().process_frame
	for i in range(6):
		var to := Vector2(196, 500 - 20 * (i + 1))
		_drag(0, to, Vector2(0, -20))
		await get_tree().process_frame
	_touch(0, Vector2(196, 380), false)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	var after := scroll.scroll_vertical
	print("[SCROLL] 拖拽前=", before, " 拖拽后=", after, " 变化=", after - before)

	# 再往下滚一次，确认方向正确（手指上移 = 内容上移）
	_touch(0, Vector2(196, 600), true)
	await get_tree().process_frame
	for i in range(4):
		_drag(0, Vector2(196, 600 - 25 * (i + 1)), Vector2(0, -25))
		await get_tree().process_frame
	_touch(0, Vector2(196, 500), false)
	await get_tree().create_timer(0.2).timeout
	print("[SCROLL] 第二次后=", scroll.scroll_vertical)

	var ok := after > before
	print("[SCROLL] 拖拽滚动 ", "OK" if ok else "失败")

	# 点击仍应正常：按下立即抬起（无位移），按钮应触发
	var career: Node = main.current_view
	var btn := _find_button(career, "执行")
	if btn != null:
		var hits := [0]
		print("[SCROLL] 找到按钮：", btn.text)

	get_tree().quit()

func _touch(idx: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = idx
	ev.position = pos
	ev.pressed = pressed
	Input.parse_input_event(ev)

func _drag(idx: int, pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = idx
	ev.position = pos
	ev.relative = rel
	Input.parse_input_event(ev)

func _find_scroll(n: Node) -> ScrollContainer:
	if n is ScrollContainer:
		return n as ScrollContainer
	for c in n.get_children():
		var r := _find_scroll(c)
		if r != null:
			return r
	return null

func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text:
		return n as Button
	for c in n.get_children():
		var r := _find_button(c, text)
		if r != null:
			return r
	return null
