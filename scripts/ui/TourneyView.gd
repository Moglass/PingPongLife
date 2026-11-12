extends Control
## 赛事页：本周可报名的赛事 + 三条越级通道 + 当前赛事进度。

var main: Control

const TIER_LABEL: Dictionary = {
	"ypy": "市少儿", "yp": "省少儿", "ync": "全国少儿", "ynj": "全国青年",
	"ya": "亚青", "yw": "世青", "ych": "全青", "feeder": "WTT 支线",
	"cont": "WTT 常规", "star": "WTT 球星", "champ": "WTT 冠军",
	"major": "大满贯", "finals": "总决赛", "worldcup": "世界杯",
	"asia": "亚洲杯", "domestic": "国内赛",
}

func setup(m: Control) -> void:
	main = m
	_build()

func refresh() -> void:
	for c in get_children():
		c.queue_free()
	_build()

func _build() -> void:
	var vb := UIKit.vbox(12)
	var root := UIKit.margin(vb, 26, 18, 26, 12)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var head := UIKit.hbox(10)
	head.add_child(UIKit.label("赛事", 26, UIKit.INK))
	head.add_child(UIKit.label("%d 年 第 %d 周" % [GameManager.p.year, GameManager.p.week], 14, UIKit.INK_3))
	head.add_child(UIKit.hfill())
	head.add_child(UIKit.dim("年龄不拦你报名，拦你的是资格和身体", 12))
	vb.add_child(head)

	if not GameManager.active_run.is_empty() and not bool(GameManager.active_run.get("done", false)):
		vb.add_child(_active_card())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var list := UIKit.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	# 团体赛优先展示
	if not GameManager.team_run.is_empty() and not bool(GameManager.team_run.get("done", false)):
		var cont := UIKit.panel(UIKit.PAPER_2, UIKit.CYAN, 3)
		var cv := UIKit.vbox(6)
		cv.add_child(UIKit.label("团体赛进行中：" + str(GameManager.team_run.get("event", {}).get("n", "")), 15, UIKit.INK))
		cv.add_child(UIKit.dim("第 %d 盘 · 比分 %d:%d" % [
			int(GameManager.team_run.get("idx", 0)) + 1,
			int(GameManager.team_run.get("score", [0, 0])[0]),
			int(GameManager.team_run.get("score", [0, 0])[1])], 12))
		cv.add_child(UIKit.btn("回到赛场  →", "primary", func() -> void: main.show_page(main.Page.TEAM)))
		cont.add_child(UIKit.margin(cv, 18, 12, 18, 12))
		list.add_child(cont)

	var tevents := GameManager.team_events()
	if not tevents.is_empty():
		list.add_child(UIKit.label("团体赛", 14, UIKit.INK_2))
		for ev in tevents:
			list.add_child(_team_card(ev))
		list.add_child(UIKit.spacer(6))

	var tours := GameManager.available_tourneys()
	if tours.is_empty():
		var empty := UIKit.panel(UIKit.PAPER_2, UIKit.LINE_SOFT, 3)
		var ev := UIKit.vbox(8)
		ev.add_child(UIKit.label("这周没有赛事", 16, UIKit.INK_2))
		ev.add_child(UIKit.wrap("赛事按周排布。空窗期不是浪费——体力、技术、心理，都是在这时候长出来的。", 13, UIKit.INK_3))
		var back := UIKit.btn("回日常训练", "normal", func() -> void: main.show_page(main.Page.CAREER))
		back.custom_minimum_size = Vector2(140, 36)
		ev.add_child(back)
		empty.add_child(UIKit.margin(ev, 20, 18, 20, 18))
		list.add_child(empty)
		return

	for t in tours:
		list.add_child(_tourney_card(t))

func _active_card() -> Control:
	var run := GameManager.active_run
	var pc := UIKit.panel(UIKit.PAPER_2, UIKit.INK_3, 3)
	var vb := UIKit.vbox(8)
	var head := UIKit.hbox(10)
	head.add_child(UIKit.label(str(run.get("name", "")), 18, UIKit.INK))
	head.add_child(UIKit.chip("进行中", UIKit.RED, true))
	head.add_child(UIKit.hfill())
	head.add_child(UIKit.dim(TournamentSystem.CHANNEL_NAME.get(int(run.get("channel", 0)), ""), 12))
	vb.add_child(head)

	var info := UIKit.hbox(16)
	info.add_child(UIKit.dim("轮次 " + GameManager.tourney_sys.round_name(run), 13))
	info.add_child(UIKit.dim("%d 签" % int(run.get("draw", 32)), 12))
	info.add_child(UIKit.dim("已胜 %d 场" % int(run.get("wins", 0)), 12))
	vb.add_child(info)

	var opp := TournamentSystem.new().current_opponent(run)
	if not opp.is_empty():
		var oh := UIKit.hbox(10)
		oh.add_child(UIKit.label("对手", 12, UIKit.INK_3))
		oh.add_child(UIKit.label(str(opp.get("name", "")), 16))
		oh.add_child(UIKit.dim("%s · %d 岁 · Ovr %.0f" % [str(opp.get("style_name", "")), int(opp.get("age", 0)), float(opp.get("ovr", 0))], 12))
		oh.add_child(UIKit.hfill())
		var mine := GameManager.p.ovr()
		var diff := mine - float(opp.get("ovr", 0))
		var tag := "优势" if diff > 4.0 else ("接近" if diff > -4.0 else "劣势")
		var col := UIKit.RED if diff > 4.0 else (UIKit.GREEN if diff < -4.0 else UIKit.INK_3)
		oh.add_child(UIKit.chip(tag, col, false))
		vb.add_child(oh)

	var b := UIKit.btn("上场  →", "primary", func() -> void:
		var ctx := GameManager.begin_round()
		if not ctx.is_empty():
			main.show_page(main.Page.MATCH, false)
	)
	b.custom_minimum_size = Vector2(180, 42)
	vb.add_child(b)

	pc.add_child(UIKit.margin(vb, 18, 14, 18, 14))
	return pc

func _team_card(ev: Dictionary) -> Control:
	var pc := UIKit.panel(UIKit.CYAN_SOFT, UIKit.CYAN, 3)
	var vb := UIKit.vbox(8)
	var head := UIKit.hbox(10)
	head.add_child(UIKit.label(str(ev.get("n", "")), 17, UIKit.INK))
	head.add_child(UIKit.chip("团体 · 5 盘 3 胜", UIKit.CYAN, true))
	head.add_child(UIKit.hfill())
	head.add_child(UIKit.dim("第 %d–%d 周" % [int(ev["w"][0]), int(ev["w"][1])], 11))
	vb.add_child(head)
	vb.add_child(UIKit.wrap(str(ev.get("d", "")), 13, UIKit.INK_2))
	var meta := UIKit.hbox(16)
	meta.add_child(UIKit.dim("奖金 %s" % DataManager.fmt_money(int(ev.get("prize", 0))), 11))
	meta.add_child(UIKit.dim("声望 +%d" % int(ev.get("rep", 0)), 11))
	meta.add_child(UIKit.dim("对手水平 %.0f" % float(ev.get("level", 60)), 11))
	vb.add_child(meta)
	vb.add_child(UIKit.btn("进队  →", "primary", func() -> void:
		GameManager.enter_team_event(ev)
		main.show_page(main.Page.TEAM)
	))
	pc.add_child(UIKit.margin(vb, 18, 12, 18, 12))
	return pc

func _tourney_card(t: Dictionary) -> Control:
	var pc := UIKit.panel()
	var vb := UIKit.vbox(8)

	var head := UIKit.hbox(10)
	head.add_child(UIKit.label(str(t.get("n", "")), 17, UIKit.INK))
	head.add_child(UIKit.chip(str(TIER_LABEL.get(str(t.get("tier", "")), str(t.get("tier", "")))), UIKit.INK_3, false))
	head.add_child(UIKit.hfill())
	var w: Array = t.get("w", [1, 52])
	head.add_child(UIKit.dim("第 %d–%d 周" % [int(w[0]), int(w[1])], 11))
	vb.add_child(head)

	var desc := UIKit.wrap(str(t.get("d", "")), 13, UIKit.INK_2)
	vb.add_child(desc)

	var meta := UIKit.hbox(16)
	meta.add_child(UIKit.dim("%d 签" % int(t.get("draw", 32)), 11))
	meta.add_child(UIKit.dim("%d 局 %d 胜" % [int(t.get("bo", 5)), int(t.get("bo", 5)) / 2 + 1], 11))
	meta.add_child(UIKit.dim("积分 %d" % int(t.get("pts", 0)), 11))
	meta.add_child(UIKit.dim("奖金 %s" % DataManager.fmt_money(int(t.get("prize", 0))), 11))
	var age: Array = t.get("age", [0, 99])
	meta.add_child(UIKit.dim("年龄 %d–%d" % [int(age[0]), int(age[1])], 11))
	vb.add_child(meta)

	vb.add_child(UIKit.hsep(UIKit.LINE_SOFT))

	var chs: Array = t.get("channels", [])
	if chs.is_empty():
		vb.add_child(UIKit.dim("你还没有拿到参赛资格。", 12))
	else:
		var hb := UIKit.hbox(10)
		var lab := UIKit.dim("报名通道", 11)
		lab.custom_minimum_size = Vector2(56, 0)
		hb.add_child(lab)
		for ch in chs:
			var c: int = int(ch)
			var cost := GameManager.tourney_sys.channel_cost(t, c)
			var label := "%s  %s" % [str(TournamentSystem.CHANNEL_NAME.get(c, "")), _cost_brief(cost)]
			var b := UIKit.btn(label, "normal" if c != int(t.get("recommended", 0)) else "primary", func() -> void:
				_enter(t, c)
			)
			b.custom_minimum_size = Vector2(150, 34)
			b.add_theme_font_size_override("font_size", 13)
			hb.add_child(b)
		vb.add_child(hb)

	pc.add_child(UIKit.margin(vb, 18, 12, 18, 12))
	return pc

func _cost_brief(cost: Dictionary) -> String:
	var parts: Array[String] = []
	var st := float(cost.get("stamina", 0.0))
	if st > 0.0:
		parts.append("体力-%.0f" % st)
	var tr := float(cost.get("trust", 0.0))
	if absf(tr) > 0.01:
		parts.append("信任%+.0f" % tr)
	var mo := int(cost.get("money", 0))
	if mo != 0:
		parts.append("¥%+d" % mo)
	if parts.is_empty():
		return "无代价"
	return " ".join(parts)

func _enter(t: Dictionary, ch: int) -> void:
	GameManager.enter_tournament(t, ch)
	main._build_topbar()
	refresh()
	main.toast("已报名：%s" % str(t.get("n", "")), "ok")
