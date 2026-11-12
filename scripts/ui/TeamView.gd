extends Control
## 团体赛：排阵板 → 逐盘推进 → 结果。
## 玩家只打自己那几盘，其余自动模拟。位置决定你要承受什么。

var main: Control

func setup(m: Control) -> void:
	main = m
	_build()

func _build() -> void:
	var vb := UIKit.vbox(14)
	var root := UIKit.margin(vb, 34, 20, 34, 14)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	if GameManager.team_run.is_empty():
		vb.add_child(UIKit.label("团体赛", 26, UIKit.INK))
		vb.add_child(UIKit.dim("当前没有进行中的团体赛。", 13))
		vb.add_child(UIKit.btn("返回赛事", "normal", func() -> void: main.show_page(main.Page.TOURNEY)))
		return

	var run := GameManager.team_run
	var ev: Dictionary = run.get("event", {})
	var started := int(run.get("idx", 0)) > 0 or int(run.get("score", [0, 0])[0]) + int(run.get("score", [0, 0])[1]) > 0

	# 头部
	var head := UIKit.hbox(14)
	head.add_child(UIKit.label(str(ev.get("n", "团体赛")), 26, UIKit.INK))
	head.add_child(UIKit.chip("团体 · 5 盘 3 胜", UIKit.INK_3, false))
	head.add_child(UIKit.hfill())
	var sc: Array = run.get("score", [0, 0])
	head.add_child(UIKit.label("%d : %d" % [int(sc[0]), int(sc[1])], 34, UIKit.INK))
	vb.add_child(head)
	vb.add_child(UIKit.wrap(str(ev.get("d", "")), 13, UIKit.INK_3))

	vb.add_child(UIKit.hsep())

	var cols := UIKit.hbox(20)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(cols)
	cols.add_child(_roster(run, true))
	cols.add_child(_center(run, started))
	cols.add_child(_roster(run, false))

func _roster(run: Dictionary, mine: bool) -> Control:
	var side := "my" if mine else "opp"
	var team: Array = run.get("my_team" if mine else "opp_team", [])
	var order: Array = run.get("my_order" if mine else "opp_order", [0, 1, 2])
	var vb := UIKit.vbox(8)
	vb.custom_minimum_size = Vector2(280, 0)

	vb.add_child(UIKit.label("我方" if mine else "对方", 12, UIKit.INK_3))
	for pos in range(order.size()):
		var idx := int(order[pos])
		var m: Dictionary = team[clampi(idx, 0, team.size() - 1)]
		var is_player := bool(m.get("is_player", false))
		var pc := UIKit.panel(UIKit.CYAN_SOFT if is_player else UIKit.WHITE, UIKit.CYAN if is_player else UIKit.LINE_SOFT, 3)
		var bv := UIKit.vbox(3)
		var hb := UIKit.hbox(8)
		hb.add_child(UIKit.label(TeamSystem.SLOT_NAME[pos], 12, UIKit.INK_3))
		hb.add_child(UIKit.hfill())
		hb.add_child(UIKit.label("%.0f" % float(m.get("ovr", 0)), 13, UIKit.INK))
		bv.add_child(hb)
		var nm := UIKit.label(str(m.get("name", "")), 16, UIKit.INK)
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		bv.add_child(nm)
		bv.add_child(UIKit.dim("%d 岁 · %s" % [int(m.get("age", 0)), str(m.get("style_name", ""))], 10))
		pc.add_child(UIKit.margin(bv, 12, 8, 12, 8))
		vb.add_child(pc)

	if mine:
		vb.add_child(UIKit.vfill())
		var note := str(run.get("note", ""))
		if note != "":
			var nb := UIKit.panel(UIKit.PAPER_2, UIKit.LINE_SOFT, 3)
			var nv := UIKit.vbox(4)
			nv.add_child(UIKit.label("教练", 11, UIKit.INK_3))
			nv.add_child(UIKit.wrap("「%s」" % note, 12, UIKit.INK_2))
			nb.add_child(UIKit.margin(nv, 12, 8, 12, 8))
			vb.add_child(nb)
	return vb

func _center(run: Dictionary, started: bool) -> Control:
	var vb := UIKit.vbox(12)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(UIKit.label("盘次", 12, UIKit.INK_3))

	var pairs: Array = TeamSystem.PAIR_ORDER
	var log: Array = run.get("log", [])
	for i in range(5):
		var pr: Array = pairs[i]
		var my_order: Array = run["my_order"]
		var opp_order: Array = run["opp_order"]
		var my_team: Array = run["my_team"]
		var opp_team: Array = run["opp_team"]
		var mi := int(my_order[int(pr[0])])
		var oi := int(opp_order[int(pr[1])])
		var me: Dictionary = my_team[clampi(mi, 0, my_team.size() - 1)]
		var op: Dictionary = opp_team[clampi(oi, 0, opp_team.size() - 1)]
		var done := i < log.size()
		var current := i == int(run.get("idx", 0)) and not bool(run.get("done", false))

		var hb := UIKit.hbox(8)
		var tag := UIKit.label("第%d盘" % (i + 1), 11, UIKit.INK_3)
		tag.custom_minimum_size = Vector2(46, 0)
		hb.add_child(tag)
		if bool(me.get("is_player", false)):
			var me_l := UIKit.label("你", 13, UIKit.CYAN)
			me_l.custom_minimum_size = Vector2(18, 0)
			hb.add_child(me_l)
			hb.add_child(UIKit.label(str(me.get("name", "")), 13, UIKit.INK))
		else:
			hb.add_child(UIKit.label(str(me.get("name", "")), 13, UIKit.INK))
		hb.add_child(UIKit.dim("vs", 10))
		hb.add_child(UIKit.label(str(op.get("name", "")), 13, UIKit.INK_2))
		hb.add_child(UIKit.hfill())

		if done:
			var rec: Dictionary = log[i]
			hb.add_child(UIKit.label("胜" if bool(rec.get("won", false)) else "负", 14,
				UIKit.RED if bool(rec.get("won", false)) else UIKit.CYAN))
		elif current:
			hb.add_child(UIKit.chip("当前", UIKit.RED, false))
		else:
			hb.add_child(UIKit.dim("—", 11))

		if current:
			var pc := UIKit.panel(UIKit.PAPER_2, UIKit.LINE, 3)
			pc.add_child(UIKit.margin(hb, 10, 6, 10, 6))
			vb.add_child(pc)
		else:
			vb.add_child(UIKit.margin(hb, 10, 6, 10, 6))

	vb.add_child(UIKit.vfill())

	# 行动区
	if bool(run.get("done", false)):
		vb.add_child(_result_block(run))
	elif started or bool(run.get("started", false)):
		var is_mine: bool = GameManager.team.is_player_turn(run)
		var label := "上场" if is_mine else "模拟这一盘"
		var bh := UIKit.hbox(0)
		var b := UIKit.btn(label + "  →", "primary", func() -> void: _advance())
		b.custom_minimum_size = Vector2(240, 46)
		bh.add_child(b)
		bh.add_child(UIKit.hfill())
		vb.add_child(bh)
		vb.add_child(UIKit.dim("第 %d 盘 · %s" % [int(run.get("idx", 0)) + 1, GameManager.team.round_label(run)], 11))
	else:
		var bh2 := UIKit.hbox(0)
		var b2 := UIKit.btn("开赛  →", "primary", func() -> void:
			GameManager.team_run["started"] = true
			refresh()
		)
		b2.custom_minimum_size = Vector2(240, 46)
		bh2.add_child(b2)
		bh2.add_child(UIKit.hfill())
		vb.add_child(bh2)
	return vb

func _result_block(run: Dictionary) -> Control:
	var settled: Dictionary = run.get("settled", {})
	var won := bool(settled.get("won", false))
	var vb := UIKit.vbox(8)
	vb.add_child(UIKit.label("胜" if won else "负", 40, UIKit.RED if won else UIKit.CYAN))
	var sc: Array = run.get("score", [0, 0])
	vb.add_child(UIKit.label("%d : %d" % [int(sc[0]), int(sc[1])], 20, UIKit.INK))
	vb.add_child(UIKit.dim("你拿了 %d 分 · 奖金 %s" % [
		int(settled.get("player_wins", 0)), DataManager.fmt_money(int(settled.get("money", 0)))], 12))
	if bool(settled.get("empty_stats", false)):
		vb.add_child(UIKit.wrap("你赢了自己那两盘。队伍还是输了。你坐在场边，看着老将接受采访说「我尽力了」。", 13, UIKit.INK_2))
	var b := UIKit.btn("离开", "normal", func() -> void:
		GameManager.leave_team()
		main.show_page(main.Page.TOURNEY)
	)
	b.custom_minimum_size = Vector2(0, 42)
	vb.add_child(b)
	return vb

func _advance() -> void:
	var step := GameManager.team_step()
	match str(step.get("kind", "")):
		"player":
			main.show_page(main.Page.MATCH, false)
		"auto":
			refresh()
			var won := bool(step.get("won", false))
			main.toast("这一盘%s。" % ("赢了" if won else "输了"), "ok" if won else "warn")
			if bool(GameManager.team_run.get("done", false)):
				refresh()
		_:
			refresh()

func refresh() -> void:
	for c in get_children():
		c.queue_free()
	_build()
