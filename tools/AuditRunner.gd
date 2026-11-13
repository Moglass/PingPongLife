extends Node
## UI 越界审计：把每个页面都建出来，逐个控件比对视口矩形。
## 目的不是好看，而是找出「被挤出屏幕、点不到」的控件。
## 用法：godot --headless tools/Audit.tscn（竖屏）/ 加 -- 参数跑横屏

var vw := 0.0
var vh := 0.0
var problems: Array[String] = []

func _ready() -> void:
	var portrait := true
	for a in OS.get_cmdline_user_args():
		if a == "landscape":
			portrait = false

	if portrait:
		DisplayServer.window_set_size(Vector2i(393, 852))
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	var main: Control = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	GameManager.new_career("审计", "prodigy")
	main._enter_game()
	# 造一点数据，避免空状态掩盖问题
	for i in range(30):
		GameManager.p.ap = 3
		GameManager.train("tech", "fh")
		GameManager.advance_week()
	GameManager.p.money = 52000
	GameManager.p.record["matches"] = 18
	GameManager.p.record["wins"] = 11
	GameManager.p.record["champions"] = 1
	GameManager.p.record["best_adult"] = 88
	await get_tree().process_frame

	var vp := get_viewport().get_visible_rect().size
	vw = vp.x
	vh = vp.y
	print("[AUDIT] 视口 %.0f x %.0f  竖屏=%s" % [vw, vh, str(portrait)])

	await _check(main, "日常", main.Page.CAREER)
	await _check(main, "赛事", main.Page.TOURNEY)
	await _check(main, "论坛", main.Page.FORUM)
	await _check(main, "档案·概览", main.Page.PROFILE, 0)
	await _check(main, "档案·器材", main.Page.PROFILE, 1)
	await _check(main, "档案·成就", main.Page.PROFILE, 2)
	await _check_menu(main)

	print("[AUDIT] 问题数 ", problems.size())
	for p in problems:
		print("  ✗ ", p)
	get_tree().quit()

func _check(main: Control, label: String, page: int, tab: int = -1) -> void:
	main.show_page(page, false)
	if tab >= 0 and main.current_view != null:
		main.current_view.tab = tab
		main.current_view.refresh()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	_scan(main.current_view, label)

func _check_menu(main: Control) -> void:
	main._open_menu()
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	_scan(main, "菜单弹窗")
	main._close_modal()
	await get_tree().process_frame

func _scan(root: Node, label: String) -> void:
	if root == null:
		return
	var n := 0
	_walk(root, label, false)
	n = problems.size()

## in_scroll：祖先里有 ScrollContainer 时，纵向溢出是预期行为，只查横向
func _walk(node: Node, label: String, in_scroll: bool) -> void:
	var child_scroll := in_scroll
	for c in node.get_children():
		if not (c is Control):
			continue
		var ctl: Control = c
		var scroll_here := child_scroll or (ctl is ScrollContainer)
		if ctl.visible and ctl.size.x > 0.5 and ctl.size.y > 0.5:
			var pos := ctl.global_position
			var sz := ctl.size
			var right := pos.x + sz.x
			var bottom := pos.y + sz.y
			# 横向越界：无论是否在滚动容器里都算问题
			if right > vw + 1.5 or pos.x < -1.5:
				problems.append("%s | %s 横向越界 x=%.0f..%.0f (视口 %.0f)" % [
					label, _path(ctl), pos.x, right, vw])
			# 纵向越界：滚动容器内的内容不算
			if not scroll_here and (bottom > vh + 1.5 or pos.y < -1.5):
				problems.append("%s | %s 纵向越界 y=%.0f..%.0f (视口 %.0f)" % [
					label, _path(ctl), pos.y, bottom, vh])
		_walk(ctl, label, scroll_here)

func _path(n: Node) -> String:
	var parts: Array[String] = []
	var cur := n
	var depth := 0
	while cur != null and depth < 3:
		var nm := str(cur.name)
		if cur is Button:
			nm = "Button(%s)" % str((cur as Button).text)
		elif cur is Label:
			var t := str((cur as Label).text)
			nm = "Label(%s)" % (t.substr(0, 12) if t.length() > 0 else "-")
		elif cur is RichTextLabel:
			nm = "Rich(%s)" % str((cur as RichTextLabel).get_parsed_text()).substr(0, 12)
		parts.push_front(nm)
		cur = cur.get_parent()
		depth += 1
	return "/".join(parts)
