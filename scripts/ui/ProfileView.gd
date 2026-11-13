extends Control
## 档案页：概览 / 器材 / 成就 三个标签。
## 概览 = 数值；器材 = 你的选择；成就 = 你走过的路。

var main: Control
var tab: int = 0
var _content: Control

const ATTR_LABEL: Dictionary = {
	"power": "力量", "speed": "速度", "stamina": "耐力",
	"touch": "手感", "tactic": "战术", "mental": "心理",
}
const TECH_LABEL: Dictionary = {
	"serve": "发球", "receive": "接发球", "short": "台内球",
	"fh": "正手", "bh": "反手", "def": "防守", "foot": "步法",
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
	var portrait := UIKit.is_portrait()
	var root := UIKit.margin(vb, 12, 12, 12, 8) if portrait else UIKit.margin(vb, 26, 18, 26, 12)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var p := GameManager.p
	if portrait:
		# 竖屏顶栏已经显示姓名/年龄/阶段，这里只补 Ovr，避免同一屏出现两次「陈默」
		var ph := UIKit.hbox(8)
		ph.add_child(UIKit.chip("Ovr %.1f" % p.ovr(), UIKit.RED, false))
		ph.add_child(UIKit.dim("综合评分", 10))
		ph.add_child(UIKit.hfill())
		if GameManager.phase == GameManager.Phase.RETIRED:
			ph.add_child(UIKit.chip("已退役", UIKit.INK_3, true))
		vb.add_child(ph)
	else:
		var head := UIKit.hbox(12)
		head.add_child(UIKit.label(p.player_name, 30, UIKit.INK))
		head.add_child(UIKit.chip("%d 岁" % p.age, UIKit.INK_3, false))
		head.add_child(UIKit.chip(str(GameManager.identity().get("n", "")), UIKit.CYAN, false))
		head.add_child(UIKit.chip("Ovr %.1f" % p.ovr(), UIKit.RED, false))
		head.add_child(UIKit.hfill())
		if GameManager.phase == GameManager.Phase.RETIRED:
			head.add_child(UIKit.chip("已退役", UIKit.INK_3, true))
		vb.add_child(head)

	var tabs := UIKit.hbox(6)
	var names := ["概览", "器材", "成就"]
	for i in range(3):
		var idx := i
		var b := UIKit.btn(names[i], "ghost", func() -> void:
			tab = idx
			refresh()
		)
		b.custom_minimum_size = Vector2(76, 34) if portrait else Vector2(88, 34)
		if i == tab:
			b.add_theme_color_override("font_color", UIKit.INK)
			var sb := StyleBoxFlat.new()
			sb.bg_color = UIKit.PAPER_2
			sb.set_corner_radius_all(2)
			b.add_theme_stylebox_override("normal", sb)
		else:
			b.add_theme_color_override("font_color", UIKit.INK_3)
		tabs.add_child(b)
	tabs.add_child(UIKit.hfill())
	if tab == 2 and not portrait:
		tabs.add_child(UIKit.dim("已解锁 %d / %d" % [GameManager.achv.count(), GameManager.achv.total()], 12))
	if tab == 1 and not portrait:
		tabs.add_child(UIKit.dim("资金 %s" % DataManager.fmt_money(p.money), 12))
	vb.add_child(tabs)
	vb.add_child(UIKit.hsep())

	_content = Control.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_content)

	match tab:
		0: _build_overview(p)
		1: _build_gear(p)
		2: _build_achievements(p)

func _mount(cols: Control) -> void:
	cols.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.add_child(cols)

## 竖屏挂载：内容纵向滚动，横向撑满。桌面端仍走 _mount。
func _mount_box(box: Control) -> void:
	if not UIKit.is_portrait():
		_mount(box)
		return
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# ScrollContainer 会把子节点的最小宽度算进来（含滚动条占位），
	# 不裁的话整块内容会比视口宽出几个像素。
	scroll.clip_contents = true
	_content.add_child(scroll)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(0, box.custom_minimum_size.y)
	scroll.add_child(box)

# ---------------------------------------------------------------- 概览

func _build_overview(p: PlayerStats) -> void:
	if UIKit.is_portrait():
		var col := UIKit.vbox(12)
		_mount_box(col)
		for part in [_left(p), _mid(p), _right(p)]:
			var c: Control = part
			c.custom_minimum_size = Vector2(0, 0)
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.add_child(c)
		return
	var cols := UIKit.hbox(18)
	_mount(cols)
	cols.add_child(_left(p))
	cols.add_child(_mid(p))
	cols.add_child(_right(p))

func _left(p: PlayerStats) -> Control:
	var vb := UIKit.vbox(12)
	vb.custom_minimum_size = Vector2(300, 0)

	var rc := UIKit.panel()
	var rv := UIKit.vbox(4)
	rv.add_child(UIKit.label("五维", 12, UIKit.INK_3))
	var radar := RadarChart.new()
	radar.custom_minimum_size = Vector2(320, 236) if UIKit.is_portrait() else Vector2(260, 190)
	radar.max_value = 124.0
	radar.set_values(p.radar())
	rv.add_child(radar)
	rc.add_child(UIKit.margin(rv, 12, 10, 12, 8))
	vb.add_child(rc)

	var sc := UIKit.panel()
	var sv := UIKit.vbox(4)
	sv.add_child(UIKit.label("生涯", 12, UIKit.INK_3))
	var rec := p.record
	sv.add_child(UIKit.kv("比赛", str(rec.get("matches", 0))))
	sv.add_child(UIKit.kv("胜场", str(rec.get("wins", 0))))
	sv.add_child(UIKit.kv("冠军", str(rec.get("champions", 0))))
	sv.add_child(UIKit.kv("最高排名", ("#%d" % p.best_rank) if p.best_rank < 999 else "—"))
	sv.add_child(UIKit.kv("奖金总额", DataManager.fmt_money(int(rec.get("prize", 0)))))
	sv.add_child(UIKit.kv("关键分", "%d / %d" % [int(rec.get("critical_won", 0)), int(rec.get("critical_played", 0))]))
	sv.add_child(UIKit.kv("零封局", str(rec.get("perfect_games", 0))))
	sc.add_child(UIKit.margin(sv, 14, 10, 14, 10))
	vb.add_child(sc)

	if not GameManager.milestones.is_empty():
		var mc := UIKit.panel(UIKit.PAPER_2, UIKit.LINE_SOFT, 3)
		var mvb := UIKit.vbox(5)
		mvb.add_child(UIKit.label("里程碑", 12, UIKit.INK_3))
		for i in range(mini(5, GameManager.milestones.size())):
			var m: Dictionary = GameManager.milestones[i]
			var row := UIKit.vbox(1)
			var h := UIKit.hbox(6)
			h.add_child(UIKit.icon_dot(UIKit.RED if i == 0 else UIKit.LINE, 5))
			h.add_child(UIKit.label(str(m.get("t", "")), 12, UIKit.INK if i == 0 else UIKit.INK_2))
			h.add_child(UIKit.hfill())
			h.add_child(UIKit.dim("%d 岁" % int(m.get("age", 0)), 10))
			row.add_child(h)
			if i == 0:
				row.add_child(UIKit.wrap(str(m.get("d", "")), 10, UIKit.INK_3))
			mvb.add_child(row)
		mc.add_child(UIKit.margin(mvb, 14, 10, 14, 10))
		vb.add_child(mc)

	vb.add_child(UIKit.vfill())
	return vb

func _mid(p: PlayerStats) -> Control:
	var vb := UIKit.vbox(12)
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	vb.add_child(_bars_card("六属性", ATTR_LABEL, ["power", "speed", "stamina", "touch", "tactic", "mental"], p, p.ladder_cap()))
	vb.add_child(_bars_card("七技术", TECH_LABEL, ["serve", "receive", "short", "fh", "bh", "def", "foot"], p, p.ladder_cap() * 1.06))

	var wc := UIKit.panel()
	var wv := UIKit.vbox(6)
	wv.add_child(UIKit.label("世界排名 · 前 12", 12, UIKit.INK_3))
	var board := GameManager.world.world_board()
	for i in range(mini(12, board.size())):
		var o: Dictionary = board[i]
		var hb := UIKit.hbox(10)
		var rk := UIKit.label("%2d" % (i + 1), 12, UIKit.INK_3)
		rk.custom_minimum_size = Vector2(26, 0)
		hb.add_child(rk)
		var nml := UIKit.label(str(o.get("name", "")), 13, UIKit.INK)
		nml.custom_minimum_size = Vector2(96, 0)
		nml.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hb.add_child(nml)
		var cty := UIKit.dim(str(o.get("country", "")), 10)
		cty.custom_minimum_size = Vector2(34, 0)
		hb.add_child(cty)
		hb.add_child(UIKit.hfill())
		var ov := UIKit.label("%.0f" % float(o.get("ovr", 0)), 12, UIKit.INK_2)
		ov.custom_minimum_size = Vector2(34, 0)
		ov.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hb.add_child(ov)
		var pt := UIKit.dim("%d" % int(o.get("points", 0)), 11)
		pt.custom_minimum_size = Vector2(56, 0)
		pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hb.add_child(pt)
		wv.add_child(hb)
	wc.add_child(UIKit.margin(wv, 14, 10, 14, 10))
	vb.add_child(wc)
	return vb

func _bars_card(title_text: String, labels: Dictionary, keys: Array, p: PlayerStats, cap: float) -> Control:
	var pc := UIKit.panel()
	var vb := UIKit.vbox(6)
	var head := UIKit.hbox(8)
	head.add_child(UIKit.label(title_text, 12, UIKit.INK_3))
	head.add_child(UIKit.hfill())
	head.add_child(UIKit.dim("上限 %.0f" % cap, 10))
	vb.add_child(head)
	for k in keys:
		var key := str(k)
		var val: float = p.get_attr(key) if labels == ATTR_LABEL else p.get_tech(key)
		var hb := UIKit.hbox(10)
		var nm := UIKit.label(str(labels.get(key, key)), 12, UIKit.INK_2)
		nm.custom_minimum_size = Vector2(52, 0)
		hb.add_child(nm)
		hb.add_child(UIKit.bar(val, cap, UIKit.CYAN if labels == ATTR_LABEL else UIKit.GOLD, 200, 4))
		var vv := UIKit.label("%.0f" % val, 12, UIKit.INK)
		vv.custom_minimum_size = Vector2(34, 0)
		vv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hb.add_child(vv)
		vb.add_child(hb)
	pc.add_child(UIKit.margin(vb, 14, 10, 14, 10))
	return pc

func _right(p: PlayerStats) -> Control:
	var vb := UIKit.vbox(12)
	vb.custom_minimum_size = Vector2(320, 0)

	var tc := UIKit.panel()
	var tv := UIKit.vbox(6)
	tv.add_child(UIKit.label("特质", 12, UIKit.INK_3))
	if p.traits.is_empty():
		tv.add_child(UIKit.dim("还没有显现。你的选择会慢慢塑造它。", 11))
	for t in p.traits:
		var th := UIKit.hbox(0)
		th.add_child(UIKit.chip(_trait_name(t), UIKit.RED, false))
		th.add_child(UIKit.hfill())
		tv.add_child(th)
	tc.add_child(UIKit.margin(tv, 14, 10, 14, 10))
	vb.add_child(tc)

	var rc := UIKit.panel()
	var rv := UIKit.vbox(6)
	rv.add_child(UIKit.label("宿敌", 12, UIKit.INK_3))
	var rival := GameManager.world.rival()
	if rival.is_empty():
		rv.add_child(UIKit.dim("还没有。", 11))
	else:
		rv.add_child(UIKit.label(str(rival.get("name", "")), 15, UIKit.INK))
		rv.add_child(UIKit.dim("%s · %d 岁 · Ovr %.0f" % [str(rival.get("style_name", "")), int(rival.get("age", 0)), float(rival.get("ovr", 0))], 11))
		var rrec: Dictionary = rival.get("record", {})
		rv.add_child(UIKit.kv("交手（他胜/你胜）", "%d : %d" % [int(rrec.get("losses", 0)), int(rrec.get("wins", 0))]))
	rc.add_child(UIKit.margin(rv, 14, 10, 14, 10))
	vb.add_child(rc)

	var bc := UIKit.panel()
	var bv := UIKit.vbox(6)
	bv.add_child(UIKit.label("身体", 12, UIKit.INK_3))
	bv.add_child(UIKit.kv("体力", "%.0f" % p.stamina_cur))
	bv.add_child(UIKit.kv("疲劳", "%.0f" % p.fatigue))
	bv.add_child(UIKit.kv("伤病", ("%d 周" % p.injury_weeks) if p.injury_weeks > 0 else "无"))
	bv.add_child(UIKit.kv("教练信任", "%.0f" % p.trust))
	bv.add_child(UIKit.kv("流派倾向", _style_hint(p)))
	bc.add_child(UIKit.margin(bv, 14, 10, 14, 10))
	vb.add_child(bc)

	vb.add_child(UIKit.vfill())
	return vb

# ---------------------------------------------------------------- 器材

func _build_gear(p: PlayerStats) -> void:
	var vertical := UIKit.is_portrait()
	var cols: BoxContainer = UIKit.vbox(12) if vertical else UIKit.hbox(18)
	_mount_box(cols)

	var left := UIKit.vbox(12)
	left.custom_minimum_size = Vector2(0, 0) if vertical else Vector2(340, 0)
	var sc := UIKit.panel()
	var sv := UIKit.vbox(8)
	var sh := UIKit.hbox(8)
	sh.add_child(UIKit.label("当前配置", 12, UIKit.INK_3))
	sh.add_child(UIKit.hfill())
	var note := UIKit.dim(GameManager.gear.style_note(), 10)
	sh.add_child(note)
	sv.add_child(sh)
	for slot in GearSystem.SLOTS:
		var k := str(slot["k"])
		var g: Dictionary = DataManager.db.GEAR_MAP.get(str(GameManager.gear.equipped.get(k, "")), {})
		var row := UIKit.vbox(2)
		var hb := UIKit.hbox(8)
		hb.add_child(UIKit.label(str(slot["n"]), 11, UIKit.INK_3))
		hb.add_child(UIKit.hfill())
		hb.add_child(UIKit.dim(_gear_stats(g), 10))
		row.add_child(hb)
		row.add_child(UIKit.label(str(g.get("n", "—")), 14, UIKit.INK))
		sv.add_child(row)
	sv.add_child(UIKit.hsep())
	var b := GameManager.gear.bonus()
	sv.add_child(UIKit.kv("进攻加成", "+%.0f" % float(b["atk"]), UIKit.RED))
	sv.add_child(UIKit.kv("控制加成", "+%.0f" % float(b["ctrl"]), UIKit.CYAN))
	sv.add_child(UIKit.kv("防守加成", "+%.0f" % float(b["defn"]), UIKit.INK_2))
	sv.add_child(UIKit.kv("移动加成", "+%.0f" % float(b["mob"]), UIKit.INK_2))
	sc.add_child(UIKit.margin(sv, 16, 12, 16, 12))
	left.add_child(sc)
	if not vertical:
		left.add_child(UIKit.vfill())
	cols.add_child(left)

	var right := UIKit.vbox(10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := UIKit.hbox(8)
	head.add_child(UIKit.label("器材店", 12, UIKit.INK_3))
	head.add_child(UIKit.hfill())
	if not vertical:
		head.add_child(UIKit.dim("按阶段解锁 · 买断制", 10))
	right.add_child(head)

	var list := UIKit.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if vertical:
		# 竖屏外层已经有一层滚动；内层再嵌 ScrollContainer 会因高度无人分配而塌成 0
		right.add_child(list)
	else:
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.add_child(list)
		right.add_child(scroll)

	var shop := GameManager.gear.shop_list(p)
	var by_cat := {}
	for it in shop:
		var c := str(it.get("cat", ""))
		if not by_cat.has(c):
			by_cat[c] = []
		by_cat[c].append(it)
	for slot in GearSystem.SLOTS:
		var k := str(slot["k"])
		if not by_cat.has(k):
			continue
		list.add_child(UIKit.label(str(slot["n"]), 13, UIKit.INK_2))
		for it in by_cat[k]:
			list.add_child(_gear_row(it, p))
	cols.add_child(right)

func _gear_stats(g: Dictionary) -> String:
	var parts: Array[String] = []
	if int(g.get("atk", 0)) > 0:
		parts.append("攻+%d" % int(g["atk"]))
	if int(g.get("ctrl", 0)) > 0:
		parts.append("控+%d" % int(g["ctrl"]))
	if int(g.get("defn", 0)) > 0:
		parts.append("防+%d" % int(g["defn"]))
	if int(g.get("mob", 0)) > 0:
		parts.append("移+%d" % int(g["mob"]))
	return " ".join(parts)

func _gear_row(it: Dictionary, p: PlayerStats) -> Control:
	var obj := UIKit.panel(UIKit.WHITE, UIKit.CYAN if bool(it.get("equipped", false)) else UIKit.LINE_SOFT, 2)
	var hb := UIKit.hbox(10)
	var vb := UIKit.vbox(2)
	var h := UIKit.hbox(8)
	h.add_child(UIKit.label(str(it.get("n", "")), 14, UIKit.INK))
	if bool(it.get("equipped", false)):
		h.add_child(UIKit.chip("已装备", UIKit.CYAN, true))
	vb.add_child(h)
	vb.add_child(UIKit.dim("%s · %s" % [_gear_stats(it), str(it.get("d", ""))], 10))
	hb.add_child(vb)
	hb.add_child(UIKit.hfill())

	if not bool(it.get("equipped", false)):
		if bool(it.get("owned", false)):
			var eq := UIKit.btn("换上", "normal", func() -> void:
				GameManager.gear.equip_item(str(it["id"]), p)
				main._build_topbar()
				refresh()
			)
			eq.custom_minimum_size = Vector2(62, 30)
			hb.add_child(eq)
		else:
			var price := UIKit.label(DataManager.fmt_money(int(it.get("price", 0))), 12,
				UIKit.INK if bool(it.get("affordable", false)) else UIKit.INK_3)
			price.custom_minimum_size = Vector2(64, 0)
			price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hb.add_child(price)
			var buy := UIKit.btn("买", "primary" if bool(it.get("affordable", false)) else "ghost", func() -> void:
				var r := GameManager.gear.buy(str(it["id"]), p)
				main.toast(str(r.get("text", "")), "ok" if bool(r.get("ok", false)) else "warn")
				main._build_topbar()
				refresh()
			)
			buy.disabled = not bool(it.get("affordable", false))
			buy.custom_minimum_size = Vector2(50, 30)
			hb.add_child(buy)

	obj.add_child(UIKit.margin(hb, 12, 8, 12, 8))
	return obj

# ---------------------------------------------------------------- 成就

func _build_achievements(p: PlayerStats) -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)

	var list := UIKit.vbox(14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var groups := GameManager.achv.grouped()
	var order := ["platinum", "gold", "silver", "bronze", "hidden"]
	for tier in order:
		var arr: Array = groups.get(tier, [])
		if arr.is_empty():
			continue
		var unlocked_n := 0
		for a in arr:
			if bool(a.get("unlocked", false)):
				unlocked_n += 1
		var head := UIKit.hbox(8)
		var col: Color = AchievementSystem.TIER_COLOR.get(tier, UIKit.INK_3)
		head.add_child(UIKit.chip(str(AchievementSystem.TIER_NAME.get(tier, tier)), col, true))
		head.add_child(UIKit.label("%d / %d" % [unlocked_n, arr.size()], 11, UIKit.INK_3))
		list.add_child(head)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(grid)
		for a in arr:
			grid.add_child(_achv_card(a, col))

func _achv_card(a: Dictionary, col: Color) -> Control:
	var got := bool(a.get("unlocked", false))
	var pc := UIKit.panel(UIKit.WHITE if got else UIKit.PAPER_2, Color(col.r, col.g, col.b, 0.9) if got else UIKit.LINE_SOFT, 2)
	var vb := UIKit.vbox(3)
	var h := UIKit.hbox(6)
	h.add_child(UIKit.label(str(a.get("n", "")), 13, UIKit.INK if got else UIKit.INK_3))
	h.add_child(UIKit.hfill())
	if got:
		h.add_child(UIKit.icon_dot(col, 6))
	vb.add_child(h)
	vb.add_child(UIKit.wrap(str(a.get("d", "")), 10, UIKit.INK_3))
	pc.add_child(UIKit.margin(vb, 10, 7, 10, 7))
	pc.custom_minimum_size = Vector2(0, 54)
	# 竖屏下让两张卡均分可用宽度，否则整块网格缩在左侧 2/3
	if UIKit.is_portrait():
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return pc

# ---------------------------------------------------------------- 辅助

func _trait_name(k: String) -> String:
	match k:
		"monster": return "怪物新人"
		"late_bloomer": return "大器晚成"
		_: return k

func _style_hint(p: PlayerStats) -> String:
	var best := "均衡"
	var v := 0.0
	if p.weight_monster > v:
		v = p.weight_monster
		best = "强攻"
	if p.weight_late > v:
		v = p.weight_late
		best = "后发"
	if p.weight_normal > v:
		best = "稳态"
	return best
