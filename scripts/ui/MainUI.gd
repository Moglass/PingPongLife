extends Control
## 主壳：纸纹背景 + 顶栏 + 页面路由 + 转场 + 弹窗 + Toast。
## 页面只负责自己的内容，不关心导航与全局状态。

const CareerView := preload("res://scripts/ui/CareerView.gd")
const TourneyView := preload("res://scripts/ui/TourneyView.gd")
const MatchView := preload("res://scripts/ui/MatchView.gd")
const ForumView := preload("res://scripts/ui/ForumView.gd")
const WEEK_NAME: Array[String] = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
const ProfileView := preload("res://scripts/ui/ProfileView.gd")
const TeamView := preload("res://scripts/ui/TeamView.gd")

enum Page { TITLE, CAREER, TOURNEY, MATCH, FORUM, PROFILE, TEAM }

var page: Page = Page.TITLE
var current_view: Control = null
var _root: Control
var _body: Control
var _topbar: Control
var _navbar: Control
var _overlay: Control
var _toast_box: VBoxContainer
var _paper_mat: ShaderMaterial
var _title_screen: Control

func _ready() -> void:
	theme = UIKit.make_theme()
	_apply_content_scale()
	if get_window() != null:
		get_window().size_changed.connect(_on_window_resized)
	if not TimeManager.day_changed.is_connected(_on_day_changed):
		TimeManager.day_changed.connect(_on_day_changed)
	if not TimeManager.scale_changed.is_connected(_on_scale_changed):
		TimeManager.scale_changed.connect(_on_scale_changed)
	_build_background()
	_build_layout()
	_build_overlay()
	_show_title()
	EventBus.toast_requested.connect(toast)
	EventBus.match_started.connect(_on_match_started)
	EventBus.player_retired.connect(_on_retired)

## 横竖屏切换基础分辨率（细节在 LayoutAdapter）
func _apply_content_scale() -> void:
	LayoutAdapter.apply_content_scale()

func _on_window_resized() -> void:
	var before := LayoutAdapter.is_portrait()
	_apply_content_scale()
	if before == LayoutAdapter.is_portrait():
		return
	if page == Page.TITLE:
		_show_title()
		return
	_build_topbar()
	_build_navbar()
	show_page(page, false)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			LifecycleAdapter.on_focus_out()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			LifecycleAdapter.on_focus_in()

# ---------------------------------------------------------------- 基础层

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/paper.gdshader")
	bg.material = mat
	add_child(bg)
	_paper_mat = mat

func _build_layout() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 0)
	_root.add_child(vb)
	_apply_safe_area(vb)

	_topbar = Control.new()
	_topbar.custom_minimum_size = Vector2(0, 58 if UIKit.is_portrait() else 68)
	vb.add_child(_topbar)

	_body = Control.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 页面里个别滚动容器会把最小宽度算进滚动条占位，多出几像素。
	# 裁掉，避免整页被推着横向溢出（点击区域仍在屏幕内）。
	_body.clip_contents = true
	vb.add_child(_body)

	_navbar = Control.new()
	_navbar.custom_minimum_size = Vector2(0, 60 if UIKit.is_portrait() else 62)
	vb.add_child(_navbar)

## iPhone 灵动岛 / Android 挖孔屏安全区
func _apply_safe_area(vb: VBoxContainer) -> void:
	var inset := LayoutAdapter.safe_area()
	var top: int = int(inset["top"])
	var bottom: int = int(inset["bottom"])
	if top > 0 or bottom > 0:
		vb.add_theme_constant_override("separation", 0)
		var pad_top := Control.new()
		pad_top.custom_minimum_size = Vector2(0, top)
		vb.add_child(pad_top)
		vb.move_child(pad_top, 0)
		var pad_bottom := Control.new()
		pad_bottom.custom_minimum_size = Vector2(0, bottom)
		vb.add_child(pad_bottom)

## 时间流每推进一天，只刷新顶栏文字，不重建整个页面
func _on_day_changed(d: int, w: int, _y: int) -> void:
	if page != Page.CAREER:
		return
	if _topbar != null:
		_build_topbar()
		_update_nav_state()
	# 正文标题也要跟，否则顶栏显示第 3 周、正文还写着第 1 周
	if current_view != null:
		var lbl = current_view.get("_week_label")
		if lbl != null and is_instance_valid(lbl):
			lbl.text = "第 %d 周 · %s" % [w, WEEK_NAME[clampi(d - 1, 0, 6)]]

func _on_scale_changed(_s: float) -> void:
	if _navbar != null:
		_build_navbar()

func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_box.position = Vector2(-160, 84)
	_toast_box.custom_minimum_size = Vector2(320, 0)
	_toast_box.add_theme_constant_override("separation", 6)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_toast_box)

# ---------------------------------------------------------------- 标题页

func _show_title() -> void:
	page = Page.TITLE
	_topbar.visible = false
	_navbar.visible = false
	_clear_body()
	if UIKit.is_portrait():
		_show_title_portrait()
		return

	var t := Control.new()
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.add_child(t)

	# 右侧球台意象（全屏自绘，避免尺寸为 0）
	var art := Control.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(func() -> void: _draw_table_art(art))
	t.add_child(art)

	var vb := UIKit.vbox(0)
	var lm := UIKit.margin(vb, 132, 118, 40, 30)
	lm.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.add_child(lm)

	vb.add_child(UIKit.label("A TABLE TENNIS LIFE", 13, UIKit.INK_3))
	vb.add_child(UIKit.spacer(10))
	vb.add_child(UIKit.label("乒乓来福", 86, UIKit.INK))
	vb.add_child(UIKit.label("v0.8  ·  文字内核 / 极简几何", 15, UIKit.INK_3))
	vb.add_child(UIKit.spacer(36))

	var quote := UIKit.wrap("从市体校的水泥台，到世界赛场中央那张蓝色球台。\n你这一生，会输给很多人，也会在某一天，输给时间。", 17, UIKit.INK_2)
	quote.custom_minimum_size = Vector2(520, 0)
	vb.add_child(quote)
	vb.add_child(UIKit.spacer(32))

	var hb := UIKit.hbox(12)
	var b1 := _title_btn("开始新的生涯", "primary", _open_new_game)
	hb.add_child(b1)
	if DataManager.has_save(1):
		hb.add_child(_title_btn("继续", "normal", _continue_game))
	hb.add_child(_title_btn("读取存档", "ghost", _open_saves))
	var hbw := UIKit.hbox(0)
	hbw.add_child(hb)
	hbw.add_child(UIKit.hfill())
	vb.add_child(hbw)

	vb.add_child(UIKit.vfill())
	var foot := UIKit.label("Godot 4.7  ·  1600×900 基准  ·  所有数值与文案均为本地生成", 12, UIKit.INK_3)
	vb.add_child(foot)

## 竖屏标题页：内容上移、字号收小、球台意象压到下半屏
func _show_title_portrait() -> void:
	var t := Control.new()
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.add_child(t)

	var art := Control.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(func() -> void: _draw_table_art(art))
	t.add_child(art)

	var vb := UIKit.vbox(0)
	var lm := UIKit.margin(vb, 26, 76, 26, 22)
	lm.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.add_child(lm)

	vb.add_child(UIKit.label("A TABLE TENNIS LIFE", 10, UIKit.INK_3))
	vb.add_child(UIKit.spacer(6))
	var big := UIKit.label("乒乓来福", 40, UIKit.INK)
	big.custom_minimum_size = Vector2(0, 54)
	vb.add_child(big)
	vb.add_child(UIKit.spacer(2))
	vb.add_child(UIKit.label("v0.8  ·  文字内核 / 极简几何", 12, UIKit.INK_3))
	vb.add_child(UIKit.spacer(20))

	var quote := UIKit.wrap("从市体校的水泥台，到世界赛场中央那张蓝色球台。\n你这一生，会输给很多人，也会在某一天，输给时间。", 14, UIKit.INK_2)
	vb.add_child(quote)
	vb.add_child(UIKit.spacer(18))

	# 按钮竖排，拇指可达
	var b1 := _title_btn("开始新的生涯", "primary", _open_new_game)
	b1.custom_minimum_size = Vector2(0, 50)
	vb.add_child(b1)
	if DataManager.has_save(1):
		var bc := _title_btn("继续", "normal", _continue_game)
		bc.custom_minimum_size = Vector2(0, 50)
		vb.add_child(UIKit.spacer(10))
		vb.add_child(bc)
	var bs := _title_btn("读取存档", "ghost", _open_saves)
	bs.custom_minimum_size = Vector2(0, 46)
	vb.add_child(UIKit.spacer(10))
	vb.add_child(bs)

	vb.add_child(UIKit.vfill())
	var foot := UIKit.label("Godot 4.7  ·  本地生成", 10, UIKit.INK_3)
	vb.add_child(foot)

func _draw_table_art(c: Control) -> void:
	var w := c.size.x
	var h := c.size.y
	if w < 10.0 or h < 10.0:
		return
	var portrait := UIKit.is_portrait()
	var cx := w * 0.50 if portrait else w * 0.70
	var cy := h * 0.54 if portrait else h * 0.50
	var tw := 258.0 if portrait else 380.0
	var th := 150.0 if portrait else 220.0
	var tl := Vector2(cx - tw * 0.5, cy - th * 0.5)
	var tr := Vector2(cx + tw * 0.5, cy - th * 0.5)
	var br := Vector2(cx + tw * 0.62, cy + th * 0.5)
	var bl := Vector2(cx - tw * 0.62, cy + th * 0.5)
	c.draw_colored_polygon(PackedVector2Array([tl, tr, br, bl]), Color(0.17, 0.32, 0.40, 0.05))
	c.draw_polyline(PackedVector2Array([tl, tr, br, bl, tl]), Color(UIKit.CYAN.r, UIKit.CYAN.g, UIKit.CYAN.b, 0.55), 1.2, true)
	c.draw_line(Vector2(cx, cy - th * 0.5), Vector2(cx, cy + th * 0.5), Color(UIKit.CYAN.r, UIKit.CYAN.g, UIKit.CYAN.b, 0.22), 1.0)
	c.draw_line(Vector2(cx - tw * 0.56, cy), Vector2(cx + tw * 0.56, cy), Color(UIKit.INK.r, UIKit.INK.g, UIKit.INK.b, 0.45), 2.0)

	var p0 := Vector2(cx - 100, cy + 58)
	var p1 := Vector2(cx + 82, cy - 28)
	c.draw_line(p0, p1, Color(UIKit.RED.r, UIKit.RED.g, UIKit.RED.b, 0.38), 1.4, true)
	c.draw_circle(p1, 4.0, UIKit.RED)
	c.draw_circle(p1, 10.0, Color(UIKit.RED.r, UIKit.RED.g, UIKit.RED.b, 0.10))
	c.draw_arc(Vector2(cx - 132, cy + 66), 24.0, 0, TAU, 40, Color(UIKit.RED.r, UIKit.RED.g, UIKit.RED.b, 0.16), 1.0)
	c.draw_arc(Vector2(cx - 132, cy + 66), 44.0, 0, TAU, 40, Color(UIKit.RED.r, UIKit.RED.g, UIKit.RED.b, 0.08), 1.0)

	for i in range(6):
		var y := cy - th * 0.5 + th * float(i) / 5.0
		c.draw_line(Vector2(cx + tw * 0.5 + 14, y), Vector2(cx + tw * 0.5 + 30, y), Color(UIKit.LINE.r, UIKit.LINE.g, UIKit.LINE.b, 0.9), 1.0)

func _title_btn(text: String, kind: String, cb: Callable) -> Button:
	var b := UIKit.btn(text, kind, cb)
	b.custom_minimum_size = Vector2(150, 44)
	return b

# ---------------------------------------------------------------- 新游戏 / 存档

func _open_new_game() -> void:
	var body := UIKit.vbox(14)
	body.add_child(UIKit.label("你叫什么名字？", 15, UIKit.INK_2))
	var name_edit := LineEdit.new()
	name_edit.text = "陈默"
	name_edit.max_length = 8
	name_edit.custom_minimum_size = Vector2(0, 40)
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.add_theme_font_size_override("font_size", 18)
	name_edit.add_theme_stylebox_override("normal", _input_style())
	name_edit.add_theme_stylebox_override("focus", _input_style(UIKit.INK))
	name_edit.add_theme_color_override("font_color", UIKit.INK)
	name_edit.add_theme_color_override("caret_color", UIKit.INK)
	name_edit.add_theme_color_override("font_placeholder_color", UIKit.INK_3)
	body.add_child(name_edit)

	body.add_child(UIKit.spacer(6))
	body.add_child(UIKit.label("你从哪儿来？", 15, UIKit.INK_2))
	var origin := "sports_family"
	var opts: Array[Dictionary] = [
		{"k": "sports_family", "n": "体育世家", "d": "父母都打过球。你三岁就摸拍子，战术和心理起步更高。"},
		{"k": "working_class", "n": "普通工薪", "d": "家里没人懂球。你能吃苦，身体底子更硬。"},
		{"k": "prodigy", "n": "天才少年", "d": "反应快得不像话。所有人都在等你长大。"},
		{"k": "late_bloomer", "n": "开窍晚", "d": "小时候平平无奇。但你学东西，越往后越快。"},
	]
	var group := ButtonGroup.new()
	var list := UIKit.vbox(8)
	for o in opts:
		var rb := CheckBox.new()
		rb.text = "%s —— %s" % [str(o["n"]), str(o["d"])]
		rb.button_group = group
		rb.button_pressed = str(o["k"]) == "sports_family"
		rb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rb.custom_minimum_size = Vector2(0, 0)
		rb.add_theme_font_size_override("font_size", 14)
		rb.add_theme_color_override("font_color", UIKit.INK_2)
		rb.toggled.connect(func(on: bool) -> void:
			if on:
				origin = str(o["k"])
		)
		list.add_child(rb)
	body.add_child(list)

	var start_cb := func() -> void:
		var nm := name_edit.text.strip_edges()
		GameManager.new_career(nm, origin)
		_close_modal()
		_enter_game()
		_intro()
	modal("新的生涯", body, [
		{"t": "开始", "kind": "primary", "cb": start_cb},
		{"t": "取消", "kind": "ghost", "cb": _close_modal},
	], true)

func _continue_game() -> void:
	if GameManager.load_from(1):
		_enter_game()
	else:
		toast("存档读取失败", "warn")

func _open_saves() -> void:
	var body := UIKit.vbox(10)
	var saves := DataManager.list_saves()
	if saves.is_empty():
		body.add_child(UIKit.dim("还没有存档。"))
	for s in saves:
		var hb := UIKit.hbox(12)
		hb.add_child(UIKit.label("%s · %d 岁 · %s" % [str(s["name"]), int(s["age"]), _stage_label(int(s["stage"]))], 15))
		hb.add_child(UIKit.hfill())
		var slot_id: int = int(s["slot"])
		hb.add_child(UIKit.btn("读取", "normal", func() -> void:
			if GameManager.load_from(slot_id):
				_close_modal()
				_enter_game()
		))
		body.add_child(hb)
	modal("读取存档", body, [{"t": "关闭", "kind": "ghost", "cb": _close_modal}], true)

func _stage_label(i: int) -> String:
	return str(DataManager.stage_def(i).get("n", "—"))

func _input_style(border: Color = UIKit.LINE) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UIKit.WHITE
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

func _intro() -> void:
	var body := UIKit.vbox(12)
	body.add_child(UIKit.wrap("2010 年，夏天。\n\n市体校的旧馆里只有四张球台，其中一张的网是用绳子拉的。你被父亲领到教练面前，教练低头看了你一眼，问：\n\n「想打吗？」", 15, UIKit.INK_2))
	modal("启蒙", body, [{"t": "想", "kind": "primary", "cb": _close_modal}], true)

# ---------------------------------------------------------------- 进入游戏

func _enter_game() -> void:
	_topbar.visible = true
	_navbar.visible = true
	_build_topbar()
	_build_navbar()
	show_page(Page.CAREER, false)

func show_page(target: Page, animate: bool = true) -> void:
	if target == page and current_view != null:
		return
	page = target
	TimeManager.set_active(target == Page.CAREER)
	_topbar.visible = target != Page.MATCH
	_navbar.visible = target != Page.MATCH
	if target == Page.MATCH:
		_clear_body()
		var mv: Control = MatchView.new()
		mv.set_anchors_preset(Control.PRESET_FULL_RECT)
		_body.add_child(mv)
		current_view = mv
		if mv.has_method("setup"):
			mv.call("setup", self)
		return

	var view: Control
	match target:
		Page.CAREER: view = CareerView.new()
		Page.TOURNEY: view = TourneyView.new()
		Page.FORUM: view = ForumView.new()
		Page.PROFILE: view = ProfileView.new()
		Page.TEAM: view = TeamView.new()
		_: return
	_clear_body()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.add_child(view)
	current_view = view
	if view.has_method("setup"):
		view.call("setup", self)
	if animate:
		view.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(view, "modulate:a", 1.0, 0.18)
	_update_nav_state()

func _clear_body() -> void:
	for c in _body.get_children():
		c.queue_free()
	current_view = null

func _on_match_started(_ctx: Dictionary) -> void:
	show_page(Page.MATCH, false)

func _on_retired(_text: String, _id: String) -> void:
	show_page(Page.PROFILE)

# ---------------------------------------------------------------- 顶栏 / 导航

func _build_topbar() -> void:
	for c in _topbar.get_children():
		c.queue_free()
	if UIKit.is_portrait():
		_build_topbar_portrait()
		return
	var hb := UIKit.hbox(20)
	var m := UIKit.margin(hb, 26, 0, 26, 0)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	_topbar.add_child(m)
	hb.alignment = BoxContainer.ALIGNMENT_BEGIN

	var name_v := UIKit.vbox(2)
	name_v.alignment = BoxContainer.ALIGNMENT_CENTER
	var nm_l := UIKit.label(GameManager.p.player_name, 20, UIKit.INK)
	nm_l.custom_minimum_size = Vector2(0, 26)
	name_v.add_child(nm_l)
	var stage_line := "%s · %d 岁" % [str(GameManager.identity().get("n", "")), GameManager.p.age]
	var st_l := UIKit.dim(stage_line, 12)
	st_l.custom_minimum_size = Vector2(0, 16)
	name_v.add_child(st_l)
	hb.add_child(name_v)
	hb.add_child(_vsep())
	hb.add_child(_top_stat("年 / 周", "%d · 第%d周" % [GameManager.p.year, GameManager.p.week]))
	if UIKit.is_portrait():
		hb.add_child(_top_stat("排名", ("#%d" % GameManager.p.rank) if GameManager.p.rank > 0 else "—"))
		hb.add_child(_top_stat("资金", DataManager.fmt_money(GameManager.p.money)))
	else:
		hb.add_child(_top_stat("世界排名", ("#%d" % GameManager.p.rank) if GameManager.p.rank > 0 else "未上榜"))
		hb.add_child(_top_stat("积分", str(GameManager.p.points)))
		hb.add_child(_top_stat("资金", DataManager.fmt_money(GameManager.p.money)))
		hb.add_child(_top_stat("声望", str(GameManager.p.fame)))
	hb.add_child(UIKit.hfill())
	hb.add_child(_ap_dots())

	var menu := UIKit.btn("菜单", "ghost", _open_menu)
	menu.custom_minimum_size = Vector2(64, 34)
	hb.add_child(menu)

## 竖屏顶栏：只留「我是谁 / 第几周 / 钱 / AP」
func _build_topbar_portrait() -> void:
	var p := GameManager.p
	var hb := UIKit.hbox(8)
	var m := UIKit.margin(hb, 14, 0, 10, 0)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	_topbar.add_child(m)

	var name_v := UIKit.vbox(0)
	name_v.alignment = BoxContainer.ALIGNMENT_CENTER
	var nm := UIKit.label(p.player_name, 16, UIKit.INK)
	nm.custom_minimum_size = Vector2(0, 21)
	name_v.add_child(nm)
	var sub := UIKit.dim("%d 岁 · %s" % [p.age, str(GameManager.identity().get("n", ""))], 10)
	sub.custom_minimum_size = Vector2(0, 13)
	name_v.add_child(sub)
	hb.add_child(name_v)

	hb.add_child(UIKit.hfill())

	var wk := UIKit.vbox(0)
	wk.alignment = BoxContainer.ALIGNMENT_CENTER
	var wkl := UIKit.dim("第 %d 周 · %s" % [p.week, WEEK_NAME[clampi(p.day - 1, 0, 6)]], 10)
	wkl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wkl.custom_minimum_size = Vector2(0, 13)
	wk.add_child(wkl)
	var money := UIKit.label(DataManager.fmt_money(p.money), 14, UIKit.INK)
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	money.custom_minimum_size = Vector2(0, 19)
	wk.add_child(money)
	hb.add_child(wk)

	hb.add_child(UIKit.spacer(2))
	hb.add_child(_ap_dots(true))
	var menu := _menu_btn()
	menu.custom_minimum_size = Vector2(38, 38)
	hb.add_child(menu)

## 三横线菜单键。不用 ☰ 字符——打包字体里没有这个字形，真机会显示成方块。
func _menu_btn() -> Button:
	var b := UIKit.btn("", "ghost", _open_menu)
	var lines := Control.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.draw.connect(func() -> void:
		var cx := lines.size.x * 0.5
		var cy := lines.size.y * 0.5
		for i in range(3):
			var y := cy - 5.0 + float(i) * 5.0
			lines.draw_line(Vector2(cx - 7.0, y), Vector2(cx + 7.0, y), UIKit.INK_2, 1.4, true)
	)
	b.add_child(lines)
	return b

func _vsep() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(1, 26)
	c.draw.connect(func() -> void: c.draw_line(Vector2(0, 0), Vector2(0, c.size.y), UIKit.LINE, 1.0))
	return c

func _top_stat(k: String, v: String) -> VBoxContainer:
	var vb := UIKit.vbox(2)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	var kl := UIKit.dim(k, 11)
	kl.custom_minimum_size = Vector2(0, 14)
	vb.add_child(kl)
	var vl := UIKit.label(v, 15, UIKit.INK)
	vl.custom_minimum_size = Vector2(0, 20)
	vb.add_child(vl)
	return vb

func _ap_dots(compact: bool = false) -> Control:
	var vb := UIKit.vbox(2)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	if not compact:
		vb.add_child(UIKit.dim("本周 AP", 11))
	var hb := UIKit.hbox(4)
	for i in range(GameManager.p.ap_max):
		var c := Control.new()
		c.custom_minimum_size = Vector2(9, 9)
		var filled: bool = i < GameManager.p.ap
		c.draw.connect(func() -> void:
			if filled:
				c.draw_circle(Vector2(4.5, 4.5), 4.3, UIKit.RED)
			else:
				c.draw_arc(Vector2(4.5, 4.5), 3.8, 0, TAU, 18, UIKit.INK_3, 1.0)
		)
		hb.add_child(c)
	vb.add_child(hb)
	return vb

func _build_navbar() -> void:
	for c in _navbar.get_children():
		c.queue_free()
	var hb := UIKit.hbox(4 if not UIKit.is_portrait() else 0)
	var pad := 26 if not UIKit.is_portrait() else 8
	var m := UIKit.margin(hb, pad, 0, pad, 6 if UIKit.is_portrait() else 0)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	_navbar.add_child(m)

	hb.add_child(_nav_btn("日常", Page.CAREER))
	hb.add_child(_nav_btn("赛事", Page.TOURNEY))
	hb.add_child(_nav_btn("论坛", Page.FORUM))
	hb.add_child(_nav_btn("档案", Page.PROFILE))
	hb.add_child(UIKit.hfill())

	if not UIKit.is_mobile() and not UIKit.is_portrait():
		hb.add_child(UIKit.dim("空格：下一周", 11))
		hb.add_child(UIKit.spacer(10))
	hb.add_child(_build_time_controls(UIKit.is_portrait()))

## v0.81 时间流控制。竖屏压成两个键（播放/暂停 + 倍速循环），横屏铺开四档。
func _build_time_controls(compact: bool) -> Control:
	var hb := UIKit.hbox(4)
	if compact:
		var running := TimeManager.time_scale > 0.0
		var pb := UIKit.btn("停" if running else "跑", "normal" if running else "primary", func() -> void:
			TimeManager.toggle_play()
			# 玩家主动点继续，等于跳过当前的暂停原因（赛事提示、体力告警等）
			if TimeManager.time_scale > 0.0:
				PauseManager.release_all()
			_build_navbar()
		)
		pb.custom_minimum_size = Vector2(40, 40)
		pb.add_theme_font_size_override("font_size", 14)
		hb.add_child(pb)

		var sb := UIKit.btn(TimeManager.speed_label(), "ghost", func() -> void:
			var i := TimeManager.speed_index()
			i = 2 if i <= 1 else (3 if i == 2 else 1)
			TimeManager.set_speed(i)
			_build_navbar()
		)
		sb.custom_minimum_size = Vector2(42, 40)
		sb.add_theme_font_size_override("font_size", 13)
		hb.add_child(sb)
	else:
		for i in range(TimeManager.SPEED_NAME.size()):
			var idx := i
			var cur := TimeManager.speed_index() == i
			var b := UIKit.btn(TimeManager.SPEED_NAME[i], "normal" if cur else "ghost", func() -> void:
				TimeManager.set_speed(idx)
				_build_navbar()
			)
			b.custom_minimum_size = Vector2(54, 40)
			b.add_theme_font_size_override("font_size", 13)
			hb.add_child(b)
	return hb

func _nav_btn(text: String, target: Page) -> Button:
	var b := UIKit.btn(text, "ghost", func() -> void: show_page(target))
	if UIKit.is_portrait():
		b.custom_minimum_size = Vector2(0, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 14)
	else:
		b.custom_minimum_size = Vector2(88, 38)
	b.set_meta("target", int(target))
	return b

func _update_nav_state() -> void:
	for c in _navbar.get_children():
		_walk_nav(c)

func _walk_nav(n: Node) -> void:
	if n is Button and n.has_meta("target"):
		var is_current: bool = int(n.get_meta("target")) == int(page)
		n.add_theme_color_override("font_color", UIKit.INK if is_current else UIKit.INK_3)
		var sb := StyleBoxFlat.new()
		sb.bg_color = UIKit.PAPER_2 if is_current else Color.TRANSPARENT
		sb.set_corner_radius_all(2)
		n.add_theme_stylebox_override("normal", sb)
	for c in n.get_children():
		_walk_nav(c)

func _next_week() -> void:
	if GameManager.phase != GameManager.Phase.CAREER:
		return
	GameManager.advance_week()
	_build_topbar()
	_build_navbar()
	_update_nav_state()
	if page == Page.CAREER and current_view != null and current_view.has_method("refresh"):
		current_view.call("refresh")
	elif page != Page.CAREER:
		show_page(Page.CAREER)
	if not GameManager.pending_event.is_empty():
		_show_event(GameManager.pending_event)
		GameManager.pending_event = {}
	if not GameManager.pressure.is_empty() and int(GameManager.pressure.get("level", 0)) >= 2:
		_show_pressure()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey:
		AudioAdapter.unlock()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE and page != Page.MATCH:
			_next_week()
			get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- 事件 / 压力 / 菜单

func _show_event(card: Dictionary) -> void:
	var body := UIKit.vbox(14)
	body.add_child(UIKit.label(str(card.get("kind", "事件")), 12, UIKit.INK_3))
	body.add_child(UIKit.wrap(str(card.get("text", "")), 16, UIKit.INK_2))
	body.add_child(UIKit.hsep())
	var opts: Array = card.get("options", [])
	var buttons: Array = []
	for i in range(opts.size()):
		var o: Dictionary = opts[i]
		var idx := i
		var pick_cb := func() -> void:
			var r := GameManager.event_pool.apply(GameManager.p, card, idx)
			PauseManager.release("event")
			_close_modal()
			_build_topbar()
			if current_view != null and current_view.has_method("refresh"):
				current_view.call("refresh")
			toast(str(r.get("text", "")), "info")
		buttons.append({
			"t": str(o.get("text", "")),
			"kind": "normal" if i > 0 else "primary",
			"cb": pick_cb,
		})
	if buttons.is_empty():
		buttons.append({"t": "知道了", "kind": "ghost", "cb": _close_modal})
	modal(str(card.get("title", "一件小事")), body, buttons, true)

func _show_pressure() -> void:
	var body := UIKit.vbox(12)
	body.add_child(UIKit.wrap(str(GameManager.pressure.get("notes", [""])[0]), 15, UIKit.INK_2))
	body.add_child(UIKit.spacer(8))
	body.add_child(UIKit.dim("你还有选择。", 12))
	var retire_cb := func() -> void:
		_close_modal()
		_open_retire()
	modal("来自体系的挤压", body, [
		{"t": "继续打下去", "kind": "normal", "cb": _close_modal},
		{"t": "考虑退役", "kind": "ghost", "cb": retire_cb},
	], true)

func _open_retire() -> void:
	var body := UIKit.vbox(10)
	body.add_child(UIKit.wrap("退役之后，你想怎么走？\n\n这不是系统的判决，只是你自己的决定。", 15, UIKit.INK_2))
	var picks: Array[Dictionary] = [
		{"id": "farewell", "n": "体面告别", "d": "激流勇退，保留最后的体面。"},
		{"id": "veteran", "n": "倔强老兵", "d": "去海外联赛，靠经验教小将做人。"},
		{"id": "doubles", "n": "转攻双打", "d": "跑不动了，但手感和战术还在。"},
		{"id": "bench", "n": "留在队里当陪练", "d": "拿点死工资，看别人拿冠军。"},
	]
	for pk in picks:
		var pid: String = str(pk["id"])
		var hb := UIKit.hbox(10)
		var vb := UIKit.vbox(2)
		vb.add_child(UIKit.label(str(pk["n"]), 15))
		vb.add_child(UIKit.dim(str(pk["d"]), 12))
		hb.add_child(vb)
		hb.add_child(UIKit.hfill())
		var retire_cb := func() -> void:
			_close_modal()
			GameManager.retire(pid)
			DataManager.profile["runs"] = int(DataManager.profile.get("runs", 0)) + 1
			DataManager.save_profile()
			toast("生涯结束。", "info")
		hb.add_child(UIKit.btn("选择", "normal", retire_cb))
		body.add_child(hb)
	modal("退役", body, [{"t": "再想想", "kind": "ghost", "cb": _close_modal}], true)

func _open_menu() -> void:
	var body := UIKit.vbox(8)
	body.add_child(UIKit.btn("保存进度", "normal", func() -> void:
		GameManager.save_to(1)
		_close_modal()
		toast("已保存到存档 1", "ok")
	))
	body.add_child(UIKit.btn("读取存档", "normal", func() -> void:
		_close_modal()
		_open_saves()
	))
	body.add_child(UIKit.btn("退役…", "ghost", func() -> void:
		_close_modal()
		_open_retire()
	))
	body.add_child(UIKit.hsep())
	body.add_child(UIKit.btn("导出存档（跨设备）", "normal", func() -> void:
		_close_modal()
		_open_export()
	))
	body.add_child(UIKit.btn("导入存档码", "normal", func() -> void:
		_close_modal()
		_open_import()
	))
	body.add_child(UIKit.hsep())
	body.add_child(UIKit.dim("存档码可复制到手机粘贴导入。所有数据保存在 user://saves", 11))
	modal("菜单", body, [{"t": "关闭", "kind": "ghost", "cb": _close_modal}], false)

# ---------------------------------------------------------------- 存档迁移

func _open_export() -> void:
	var code := StorageAdapter.export_code(1)
	var body := UIKit.vbox(10)
	body.add_child(UIKit.dim("复制这段文本，在另一台设备用「导入存档码」粘贴。", 12))
	var te := TextEdit.new()
	te.text = code
	te.editable = false
	te.custom_minimum_size = Vector2(600, 110)
	te.add_theme_font_size_override("font_size", 11)
	te.add_theme_color_override("font_color", UIKit.INK_2)
	body.add_child(te)
	body.add_child(UIKit.dim("长度 %s · 含全部生涯数据" % StorageAdapter.code_size(code), 10))

	var copy_cb := func() -> void:
		DisplayServer.clipboard_set(code)
		toast("已复制到剪贴板", "ok")
	var dl_cb := func() -> void:
		var r := StorageAdapter.download_code(code)
		if r == "ok" or r == "err":
			toast("已开始下载" if r == "ok" else "下载失败", "ok" if r == "ok" else "warn")
		else:
			toast("已保存：" + r, "ok")
	modal("导出存档", body, [
		{"t": "复制", "kind": "primary", "cb": copy_cb},
		{"t": "下载文件", "kind": "normal", "cb": dl_cb},
		{"t": "关闭", "kind": "ghost", "cb": _close_modal},
	], true)

func _open_import() -> void:
	var body := UIKit.vbox(10)
	body.add_child(UIKit.dim("粘贴另一台设备导出的存档码（以 PPL1. 开头）。", 12))
	var te := TextEdit.new()
	te.custom_minimum_size = Vector2(600, 130)
	te.add_theme_font_size_override("font_size", 11)
	te.add_theme_color_override("font_color", UIKit.INK)
	body.add_child(te)
	body.add_child(UIKit.dim("导入会覆盖当前进度，请先导出备份。", 10))

	var do_import := func() -> void:
		var r := StorageAdapter.import_code(te.text)
		if not bool(r.get("ok", false)):
			toast(str(r.get("text", "导入失败")), "warn")
			return
		_close_modal()
		_build_topbar()
		_build_navbar()
		show_page(Page.CAREER)
		toast(str(r.get("text", "已导入")), "ok")
	modal("导入存档码", body, [
		{"t": "导入", "kind": "primary", "cb": do_import},
		{"t": "取消", "kind": "ghost", "cb": _close_modal},
	], true)

# ---------------------------------------------------------------- 弹窗 / Toast

func modal(title_text: String, body: Control, buttons: Array = [], wide: bool = false) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.11, 0.10, 0.28)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(dim)
	dim.set_meta("modal", true)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(cc)
	var pc := UIKit.panel(UIKit.WHITE, UIKit.LINE, 3)
	# 宽度要跟着视口走：560 在 1600 横屏下是 35%，在 393 竖屏下会溢出屏幕把文字截断
	# 竖屏基准固定 393 宽，弹窗给 360 刚好留 16pt 边距。
	# 不用 get_viewport_rect()：Web 上它返回的是 DPR 放大后的物理像素，换算不可靠。
	var want := 560.0 if not wide else 680.0
	if UIKit.is_portrait():
		want = 360.0
	pc.custom_minimum_size = Vector2(want, 0)
	cc.add_child(pc)

	var vb := UIKit.vbox(14)
	vb.add_child(UIKit.label(title_text, 22, UIKit.INK))
	vb.add_child(UIKit.hsep())
	vb.add_child(body)
	if not buttons.is_empty():
		vb.add_child(UIKit.spacer(6))
		var hb := UIKit.hbox(8)
		hb.alignment = BoxContainer.ALIGNMENT_END
		for b in buttons:
			var btn := UIKit.btn(str(b.get("t", "")), str(b.get("kind", "normal")))
			btn.custom_minimum_size = Vector2(maxf(88.0, float(str(b.get("t", "")).length()) * 20.0 + 36.0), 40)
			var cb: Callable = b.get("cb", Callable())
			if cb.is_valid():
				btn.pressed.connect(cb)
			hb.add_child(btn)
		vb.add_child(hb)

	var mx := 24 if not UIKit.is_portrait() else 16
	pc.add_child(UIKit.margin(vb, mx, 20, mx, 20))
	dim.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(dim, "modulate:a", 1.0, 0.14)

func _close_modal() -> void:
	for c in _overlay.get_children():
		if c.has_meta("modal"):
			var tw := create_tween()
			tw.tween_property(c, "modulate:a", 0.0, 0.1)
			tw.tween_callback(c.queue_free)

func toast(text: String, tone: String = "info") -> void:
	if text.strip_edges() == "":
		return
	# 同时最多 3 条：之前一次解锁十几项成就，toast 会叠满整屏把界面盖死
	while _toast_box.get_child_count() >= 3:
		var old := _toast_box.get_child(0)
		_toast_box.remove_child(old)
		old.queue_free()
	var pc := UIKit.panel(UIKit.INK, UIKit.INK, 2)
	var col := UIKit.PAPER
	if tone == "warn":
		col = Color("#ffd9d2")
	elif tone == "ok":
		col = Color("#d8efd8")
	var l := UIKit.label(text, 13, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pc.add_child(UIKit.margin(l, 14, 8, 14, 8))
	_toast_box.add_child(pc)
	pc.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(pc, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.2)
	tw.tween_property(pc, "modulate:a", 0.0, 0.25)
	tw.tween_callback(pc.queue_free)
