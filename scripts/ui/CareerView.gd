extends Control
## 日常页：左（身体与技术）/ 中（本周行动 + 周报流）/ 右（论坛热帖）。

var main: Control

func setup(m: Control) -> void:
	main = m
	_build()

func refresh() -> void:
	for c in get_children():
		c.queue_free()
	_build()

func _build() -> void:
	if UIKit.is_portrait():
		_build_portrait()
		return
	var cols := UIKit.hbox(18)
	var root := UIKit.margin(cols, 26, 18, 26, 12)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	cols.add_child(_build_left())
	cols.add_child(_build_center())
	cols.add_child(_build_right())

## 竖屏：单栏滚动。状态压成一条，行动 2 列，周报和论坛依次向下。
func _build_portrait() -> void:
	var p := GameManager.p
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var vb := UIKit.vbox(12)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var wrap := UIKit.margin(vb, 14, 12, 14, 12)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(wrap)

	# 状态条
	var top := UIKit.panel()
	var tv := UIKit.vbox(6)
	var h1 := UIKit.hbox(10)
	var d := p.derive()
	h1.add_child(UIKit.label("%.1f" % float(d["ovr"]), 34, UIKit.INK))
	var f := p.form_label()
	h1.add_child(UIKit.chip(str(f["t"]), Color(str(f["c"])), false))
	h1.add_child(UIKit.hfill())
	h1.add_child(UIKit.dim("Ovr", 11))
	tv.add_child(h1)
	tv.add_child(UIKit.bar(p.stamina_cur, 100.0, UIKit.RED if p.stamina_cur < 30.0 else UIKit.CYAN, 200, 5))
	var h2 := UIKit.hbox(10)
	var st_l := UIKit.dim("体力 %.0f" % p.stamina_cur, 11)
	st_l.custom_minimum_size = Vector2(0, 16)
	h2.add_child(st_l)
	h2.add_child(UIKit.hfill())
	var ap_l := UIKit.label("AP %d/%d" % [p.ap, p.ap_max], 12, UIKit.INK_2)
	ap_l.custom_minimum_size = Vector2(0, 16)
	h2.add_child(ap_l)
	tv.add_child(h2)
	top.add_child(UIKit.margin(tv, 14, 10, 14, 10))
	vb.add_child(top)

	# 行动
	var head := UIKit.hbox(8)
	var wk_l := UIKit.label("第 %d 周" % p.week, 20, UIKit.INK)
	wk_l.custom_minimum_size = Vector2(0, 30)
	head.add_child(wk_l)
	head.add_child(UIKit.hfill())
	head.add_child(UIKit.dim("每次 1 AP", 10))
	vb.add_child(head)

	var acts := UIKit.vbox(8)
	acts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(acts)
	for a in CareerSystem.ACTIONS:
		acts.add_child(_action_row(a))

	# 周报
	vb.add_child(UIKit.label("最近发生", 13, UIKit.INK_2))
	var fl := UIKit.vbox(0)
	for i in range(mini(8, GameManager.feed.size())):
		var it: Dictionary = GameManager.feed[i]
		var row := UIKit.hbox(8)
		var wk := UIKit.label("W%d" % int(it.get("week", 0)), 10, UIKit.INK_3)
		wk.custom_minimum_size = Vector2(28, 0)
		row.add_child(wk)
		row.add_child(UIKit.wrap(str(it.get("text", "")), 12, UIKit.INK_2))
		fl.add_child(UIKit.margin(row, 0, 4, 0, 4))
	vb.add_child(fl)

	# 论坛
	vb.add_child(UIKit.label("论坛", 13, UIKit.INK_2))
	for t in ForumManager.latest(3):
		vb.add_child(_thread_card(t))
	var go := UIKit.btn("进入论坛  →", "ghost", func() -> void: main.show_page(main.Page.FORUM))
	go.custom_minimum_size = Vector2(0, 44)
	vb.add_child(go)

# ---------------------------------------------------------------- 左栏

func _build_left() -> Control:
	var vb := UIKit.vbox(12)
	vb.custom_minimum_size = Vector2(302, 0)

	var p := GameManager.p

	# Ovr 卡
	var ovr_card := UIKit.panel()
	var ovb := UIKit.vbox(6)
	var top := UIKit.hbox(8)
	var d := p.derive()
	top.add_child(UIKit.label("综合", 12, UIKit.INK_3))
	top.add_child(UIKit.hfill())
	top.add_child(UIKit.label("Ovr", 12, UIKit.INK_3))
	ovb.add_child(top)

	var num_row := UIKit.hbox(6)
	num_row.add_child(UIKit.label("%.1f" % float(d["ovr"]), 40, UIKit.INK))
	var form := p.form_label()
	num_row.add_child(UIKit.chip(str(form["t"]), Color(str(form["c"])), false))
	ovb.add_child(num_row)
	ovb.add_child(UIKit.dim("上限 %.0f · 年龄 %d" % [p.ladder_cap(), p.age], 11))
	ovb.add_child(UIKit.hsep())
	ovb.add_child(UIKit.kv("排名", ("#%d" % p.rank) if p.rank > 0 else "未上榜"))
	ovb.add_child(UIKit.kv("积分", str(p.points)))
	ovb.add_child(UIKit.kv("教练信任", "%.0f" % p.trust))
	ovr_card.add_child(UIKit.margin(ovb, 14, 12, 14, 12))
	vb.add_child(ovr_card)

	# 雷达
	var radar_card := UIKit.panel()
	var rv := UIKit.vbox(4)
	rv.add_child(UIKit.label("能力结构", 12, UIKit.INK_3))
	var radar := RadarChart.new()
	radar.custom_minimum_size = Vector2(260, 190)
	radar.max_value = 124.0
	radar.set_values(p.radar())
	rv.add_child(radar)
	var legend := UIKit.hbox(10)
	legend.add_child(UIKit.dim("进攻 %.0f" % float(d["atk"]), 11))
	legend.add_child(UIKit.dim("防守 %.0f" % float(d["defn"]), 11))
	legend.add_child(UIKit.dim("控制 %.0f" % float(d["ctrl"]), 11))
	rv.add_child(legend)
	radar_card.add_child(UIKit.margin(rv, 12, 10, 12, 8))
	vb.add_child(radar_card)

	# 体力
	var st_card := UIKit.panel()
	var sv := UIKit.vbox(6)
	var sh := UIKit.hbox(8)
	sh.add_child(UIKit.label("体力", 12, UIKit.INK_3))
	sh.add_child(UIKit.hfill())
	sh.add_child(UIKit.label("%.0f" % p.stamina_cur, 13, UIKit.INK))
	sv.add_child(sh)
	var stam_col := UIKit.CYAN
	if p.stamina_cur < 30.0:
		stam_col = UIKit.RED
	sv.add_child(UIKit.bar(p.stamina_cur, 100.0, stam_col, 260, 5))
	if p.fatigue > 40.0:
		sv.add_child(UIKit.dim("疲劳 %.0f · 伤病风险上升" % p.fatigue, 11))
	if p.injury_weeks > 0:
		sv.add_child(UIKit.label("伤停 %d 周" % p.injury_weeks, 12, UIKit.RED))
	st_card.add_child(UIKit.margin(sv, 14, 10, 14, 10))
	vb.add_child(st_card)

	# 状态
	if not p.status_effects.is_empty():
		var sc := UIKit.panel()
		var scv := UIKit.vbox(6)
		scv.add_child(UIKit.label("状态", 12, UIKit.INK_3))
		for e in p.status_effects:
			var hb := UIKit.hbox(6)
			var col := UIKit.CYAN if float(e.get("form", 0.0)) >= 0.0 else UIKit.RED
			hb.add_child(UIKit.icon_dot(col, 6))
			hb.add_child(UIKit.label(str(e.get("name", "")), 13))
			hb.add_child(UIKit.hfill())
			hb.add_child(UIKit.dim("%d 周" % int(e.get("weeks_left", 0)), 11))
			scv.add_child(hb)
		sc.add_child(UIKit.margin(scv, 14, 10, 14, 10))
		vb.add_child(sc)

	# 特质
	if not p.traits.is_empty():
		var tc := UIKit.panel(UIKit.PAPER_2, UIKit.LINE_SOFT, 3)
		var tv := UIKit.vbox(4)
		tv.add_child(UIKit.label("已显现的特质", 12, UIKit.INK_3))
		for t in p.traits:
			tv.add_child(UIKit.label(_trait_name(t), 13, UIKit.INK_2))
		tc.add_child(UIKit.margin(tv, 14, 10, 14, 10))
		vb.add_child(tc)

	vb.add_child(UIKit.vfill())
	return vb

func _trait_name(k: String) -> String:
	match k:
		"monster": return "怪物新人 · 练得比谁都多"
		"late_bloomer": return "大器晚成 · 越往后越快"
		_:
			return k

# ---------------------------------------------------------------- 中栏

func _build_center() -> Control:
	var vb := UIKit.vbox(12)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 标题行
	var head := UIKit.hbox(10)
	head.add_child(UIKit.label("第 %d 周" % GameManager.p.week, 26, UIKit.INK))
	head.add_child(UIKit.label("%d 年 · %s" % [GameManager.p.year, str(GameManager.identity().get("n", ""))], 14, UIKit.INK_3))
	head.add_child(UIKit.hfill())
	head.add_child(UIKit.label("AP %d / %d" % [GameManager.p.ap, GameManager.p.ap_max], 13, UIKit.INK_2))
	vb.add_child(head)

	# 阶段提示
	var note := UIKit.wrap(str(GameManager.identity().get("note", "")), 13, UIKit.INK_3)
	vb.add_child(note)

	# 行动
	var act_head := UIKit.hbox(8)
	act_head.add_child(UIKit.label("本周安排", 14, UIKit.INK_2))
	act_head.add_child(UIKit.hfill())
	act_head.add_child(UIKit.dim("每次消耗 1 AP", 11))
	vb.add_child(act_head)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(grid)

	for a in CareerSystem.ACTIONS:
		grid.add_child(_action_card(a))

	# 周报流
	vb.add_child(UIKit.spacer(4))
	var feed_head := UIKit.hbox(8)
	feed_head.add_child(UIKit.label("最近发生", 14, UIKit.INK_2))
	feed_head.add_child(UIKit.hfill())
	feed_head.add_child(UIKit.dim("记录会随周数累积", 11))
	vb.add_child(feed_head)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var fl := UIKit.vbox(0)
	fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(fl)

	var items := GameManager.recent_feed(14)
	if items.is_empty():
		fl.add_child(UIKit.dim("还没有记录。", 13))
	for i in range(items.size()):
		var it: Dictionary = items[i]
		var row := UIKit.hbox(10)
		var wk := UIKit.label("W%d" % int(it.get("week", 0)), 11, UIKit.INK_3)
		wk.custom_minimum_size = Vector2(34, 0)
		row.add_child(wk)
		var txt := UIKit.wrap(str(it.get("text", "")), 13, UIKit.INK_2 if i > 0 else UIKit.INK)
		row.add_child(txt)
		fl.add_child(UIKit.margin(row, 0, 6, 0, 6))
		if i < items.size() - 1:
			fl.add_child(UIKit.hsep(UIKit.LINE_SOFT))

	return vb

func _action_card(a: Dictionary) -> Control:
	var pc := UIKit.panel(UIKit.WHITE, UIKit.LINE, 3)
	var vb := UIKit.vbox(4)
	var top := UIKit.hbox(6)
	top.add_child(UIKit.label(str(a["n"]), 15, UIKit.INK))
	top.add_child(UIKit.hfill())
	top.add_child(UIKit.dim("1 AP", 10))
	vb.add_child(top)
	var d := UIKit.wrap(str(a["d"]), 11, UIKit.INK_3)
	d.custom_minimum_size = Vector2(0, 30)
	vb.add_child(d)

	var available := GameManager.p.ap > 0 and not (GameManager.p.injury_weeks > 0 and str(a["k"]) not in ["rest", "study"])
	var b := UIKit.btn("执行", "ghost" if not available else "normal", func() -> void: _do_action(str(a["k"])))
	b.disabled = not available
	b.custom_minimum_size = Vector2(0, 28)
	vb.add_child(b)

	pc.add_child(UIKit.margin(vb, 12, 10, 12, 10))
	pc.custom_minimum_size = Vector2(0, 108)
	return pc

## 竖屏用的横向行动条：左边标题+一句描述，右边执行键，拇指一列点下来
func _action_row(a: Dictionary) -> Control:
	var pc := UIKit.panel(UIKit.WHITE, UIKit.LINE, 3)
	var hb := UIKit.hbox(12)
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var left := UIKit.vbox(2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UIKit.label(str(a["n"]), 15, UIKit.INK)
	title.custom_minimum_size = Vector2(0, 22)
	left.add_child(title)
	var desc := UIKit.label(str(a["d"]), 11, UIKit.INK_3)
	desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc.custom_minimum_size = Vector2(0, 16)
	left.add_child(desc)
	hb.add_child(left)

	var available := GameManager.p.ap > 0 and not (GameManager.p.injury_weeks > 0 and str(a["k"]) not in ["rest", "study"])
	var b := UIKit.btn("执行", "ghost" if not available else "normal", func() -> void: _do_action(str(a["k"])))
	b.disabled = not available
	b.custom_minimum_size = Vector2(66, 42)
	hb.add_child(b)

	pc.add_child(UIKit.margin(hb, 14, 10, 12, 10))
	return pc

func _do_action(key: String) -> void:
	if key == "tech":
		_open_tech_picker()
		return
	var r := GameManager.train(key)
	_after_action(r)

func _open_tech_picker() -> void:
	if GameManager.p.ap <= 0:
		return
	var body := UIKit.vbox(8)
	body.add_child(UIKit.dim("选一项技术练一整周。练技术也会带动相关身体素质。", 12))
	for t in CareerSystem.TECH_FOCUS:
		var k := str(t["k"])
		var val := GameManager.p.get_tech(k)
		var hb := UIKit.hbox(10)
		hb.add_child(UIKit.label(str(t["n"]), 15))
		hb.add_child(UIKit.hfill())
		var bar := UIKit.bar(val, GameManager.p.ladder_cap() * 1.06, UIKit.CYAN, 120, 4)
		bar.custom_minimum_size = Vector2(120, 4)
		hb.add_child(bar)
		hb.add_child(UIKit.dim("%.0f" % val, 12))
		var pick := UIKit.btn("练", "normal", func() -> void:
			main._close_modal()
			var r := GameManager.train("tech", k)
			_after_action(r)
		)
		pick.custom_minimum_size = Vector2(46, 30)
		hb.add_child(pick)
		body.add_child(hb)
	main.modal("技术训练", body, [{"t": "取消", "kind": "ghost", "cb": main._close_modal}], true)

func _after_action(r: Dictionary) -> void:
	var gains: Array = r.get("gains", [])
	var txt := str(r.get("text", ""))
	if not gains.is_empty():
		main.toast("%s  %s" % [txt.substr(0, 18), " · ".join(gains)], "info")
	else:
		main.toast(txt, "info")
	main._build_topbar()
	main._build_navbar()
	main._update_nav_state()
	refresh()

# ---------------------------------------------------------------- 右栏

func _build_right() -> Control:
	var vb := UIKit.vbox(12)
	vb.custom_minimum_size = Vector2(344, 0)

	var head := UIKit.hbox(8)
	head.add_child(UIKit.label("论坛", 14, UIKit.INK_2))
	head.add_child(UIKit.hfill())
	head.add_child(UIKit.dim("热度 %d" % ForumManager.heat, 11))
	vb.add_child(head)

	var threads := ForumManager.latest(4)
	if threads.is_empty():
		vb.add_child(UIKit.dim("还没有人讨论你。", 12))
	for t in threads:
		vb.add_child(_thread_card(t))

	vb.add_child(UIKit.hfill())

	var go := UIKit.btn("进入论坛  →", "ghost", func() -> void: main.show_page(main.Page.FORUM))
	vb.add_child(go)
	return vb

func _thread_card(t: Dictionary) -> Control:
	var pc := UIKit.panel(UIKit.WHITE, UIKit.LINE_SOFT, 2)
	var vb := UIKit.vbox(4)
	var head := UIKit.hbox(6)
	var fac := str(t.get("faction", "neutral"))
	head.add_child(UIKit.chip(str(ForumManager.FACTION_NAME.get(fac, "")), Color(str(ForumManager.FACTION_COLOR.get(fac, "#8a8175"))), false))
	head.add_child(UIKit.hfill())
	head.add_child(UIKit.dim("♥ %d" % int(t.get("likes", 0)), 10))
	vb.add_child(head)
	var title := UIKit.wrap(str(t.get("title", "")), 13, UIKit.INK)
	vb.add_child(title)
	var meta := UIKit.hbox(4)
	meta.add_child(UIKit.dim(str(t.get("user", "")) if str(t.get("user", "")).length() < 14 else str(t.get("user", "")).substr(0, 14) + "…", 10))
	meta.add_child(UIKit.hfill())
	meta.add_child(UIKit.dim("%d 回复" % t.get("replies", []).size(), 10))
	vb.add_child(meta)
	pc.add_child(UIKit.margin(vb, 10, 8, 10, 8))
	return pc
