extends Control
## 比赛表现层：球台 + 比分板 + 数据流 + 解说 + 关键分决策 + 赛后复盘。
## 规则全部来自 MatchEngine；本文件只决定「怎么呈现」与「什么时候停下来问玩家」。

signal critical_choice_made(choice: String)

const SPEED_NAME: Dictionary = {
	MatchEngine.Speed.IMMERSIVE: "沉浸",
	MatchEngine.Speed.TACTICAL: "战术",
	MatchEngine.Speed.FAST: "快进",
	MatchEngine.Speed.SKIP: "跳过",
}

var main: Control
var engine: MatchEngine
var ctx: Dictionary = {}
var speed: int = MatchEngine.Speed.IMMERSIVE
var tactic: String = "target_bh"
var busy: bool = false
var finished: bool = false

var _table: TableRenderer
var _score_label: Label
var _game_label: Label
var _name_a: Label
var _name_b: Label
var _comment: RichTextLabel
var _ticker_l: VBoxContainer
var _ticker_r: VBoxContainer
var _speed_btns: Dictionary = {}
var _critical_layer: Control
var _dim_layer: ColorRect
var _entry_layer: Control
var _rally_count: int = 0
var _last_serve_side: int = 0
var _log_lines: Array[String] = []
var _critical_timeout: float = 0.0
var _critical_timer_label: Label
var _limit_enabled: bool = true

func setup(m: Control) -> void:
	main = m
	ctx = GameManager.current_match
	engine = GameManager.engine
	_build()
	_run()

# ---------------------------------------------------------------- 构建

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = UIKit.PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vb := UIKit.vbox(8)
	var root := UIKit.margin(vb, 30, 16, 30, 16)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	vb.add_child(_build_scoreboard())

	# 球台区
	var tw := Control.new()
	tw.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(tw)

	_table = TableRenderer.new()
	_table.set_anchors_preset(Control.PRESET_FULL_RECT)
	_table.home_advantage = false
	tw.add_child(_table)

	# 左右数据流
	_ticker_l = _build_ticker(tw, true)
	_ticker_r = _build_ticker(tw, false)

	# 底部解说
	var cbox := UIKit.panel(UIKit.WHITE, UIKit.LINE_SOFT, 3)
	cbox.custom_minimum_size = Vector2(0, 132)
	var cv := UIKit.vbox(6)
	var ch := UIKit.hbox(8)
	ch.add_child(UIKit.label("现场", 11, UIKit.INK_3))
	ch.add_child(UIKit.hfill())
	ch.add_child(_build_speed_controls())
	cv.add_child(ch)
	_comment = UIKit.rich("", 14, UIKit.INK)
	_comment.add_theme_constant_override("line_separation", 5)
	_comment.custom_minimum_size = Vector2(0, 76)
	_comment.fit_content = false
	_comment.scroll_active = true
	_comment.scroll_following = true
	cv.add_child(_comment)
	cbox.add_child(UIKit.margin(cv, 16, 10, 16, 10))
	vb.add_child(cbox)

	# 暗角层（关键分时压暗四周）
	_dim_layer = ColorRect.new()
	_dim_layer.color = Color(0.10, 0.09, 0.08, 0.0)
	_dim_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim_layer)

func _build_scoreboard() -> Control:
	var portrait := UIKit.is_portrait()
	var gap := 8 if portrait else 18
	var hb := UIKit.hbox(gap)

	# 左：玩家
	var left := UIKit.vbox(2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	_name_a = UIKit.label(GameManager.p.player_name, 15 if portrait else 18, UIKit.INK)
	_name_a.custom_minimum_size = Vector2(0, 24)
	left.add_child(_name_a)
	left.add_child(UIKit.dim("你 · Ovr %.0f" % GameManager.p.ovr(), 11))

	# 中：比分
	var center := UIKit.vbox(0)
	center.custom_minimum_size = Vector2(126 if portrait else 190, 0)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	_game_label = UIKit.label("局 0 : 0", 12, UIKit.INK_3)
	_game_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_game_label)
	_score_label = UIKit.label("0 : 0", 34 if portrait else 44, UIKit.INK)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_score_label)

	# 右：对手
	var right := UIKit.vbox(2)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	var opp: Dictionary = ctx.get("opponent", {})
	_name_b = UIKit.label(str(opp.get("name", "对手")), 15 if portrait else 18, UIKit.INK)
	_name_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_name_b.custom_minimum_size = Vector2(0, 24)
	right.add_child(_name_b)
	var osub := UIKit.dim("%s · Ovr %.0f" % [str(opp.get("style_name", "")), float(opp.get("ovr", 0))], 11)
	osub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(osub)

	# 赛事（叠在右上）
	var meta := UIKit.vbox(1)
	meta.custom_minimum_size = Vector2(150, 0)
	var mname := UIKit.label(str(ctx.get("tourney", "")), 11, UIKit.INK_3)
	mname.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.add_child(mname)
	var rname := UIKit.label(str(ctx.get("round_name", "")), 10, UIKit.INK_3)
	rname.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.add_child(rname)

	hb.add_child(left)
	hb.add_child(center)
	hb.add_child(right)
	if not portrait:
		hb.add_child(meta)

	var m := UIKit.margin(hb, 4, 6 if portrait else 8, 4, 6 if portrait else 8)
	m.custom_minimum_size = Vector2(0, 62 if portrait else 76)
	return m

func _build_ticker(parent: Control, left: bool) -> VBoxContainer:
	var vb := UIKit.vbox(3)
	vb.custom_minimum_size = Vector2(130, 0)
	if left:
		vb.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		vb.position = Vector2(8, -60)
	else:
		vb.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		vb.position = Vector2(-138, -60)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vb)
	return vb

func _build_speed_controls() -> Control:
	var hb := UIKit.hbox(2)
	for s in [MatchEngine.Speed.IMMERSIVE, MatchEngine.Speed.TACTICAL, MatchEngine.Speed.FAST, MatchEngine.Speed.SKIP]:
		var b := UIKit.btn(str(SPEED_NAME[s]), "ghost", func() -> void: _set_speed(int(s)))
		b.custom_minimum_size = Vector2(52, 26)
		b.add_theme_font_size_override("font_size", 12)
		hb.add_child(b)
		_speed_btns[int(s)] = b
	_update_speed_ui()
	return hb

func _set_speed(s: int) -> void:
	speed = s
	_update_speed_ui()
	if s == MatchEngine.Speed.SKIP and not finished:
		_skip_rest()

func _update_speed_ui() -> void:
	for k in _speed_btns.keys():
		var b: Button = _speed_btns[k]
		var on: bool = int(k) == speed
		b.add_theme_color_override("font_color", UIKit.INK if on else UIKit.INK_3)
		var sb := StyleBoxFlat.new()
		sb.bg_color = UIKit.PAPER_2 if on else Color.TRANSPARENT
		sb.set_corner_radius_all(2)
		b.add_theme_stylebox_override("normal", sb)

# ---------------------------------------------------------------- 主流程

func _run() -> void:
	AudioDirector.set_ambience(0.22)
	_show_entry()
	await get_tree().create_timer(1.6).timeout
	_hide_entry()
	await _ask_tactic_first()
	while not engine.finished:
		if engine.is_critical() and speed != MatchEngine.Speed.SKIP:
			var choice: String = ""
			if speed == MatchEngine.Speed.FAST:
				choice = "steady"
			else:
				choice = await _ask_critical()
			_step(choice)
		else:
			_step("")
		await _wait_point()
	_finish()

func _step(choice: String) -> void:
	var r := engine.play_point(tactic, choice)
	_apply_result(r, choice)

func _wait_point() -> void:
	match speed:
		MatchEngine.Speed.IMMERSIVE:
			await get_tree().create_timer(0.42).timeout
		MatchEngine.Speed.TACTICAL:
			await get_tree().create_timer(0.10).timeout
		MatchEngine.Speed.FAST:
			await get_tree().create_timer(0.02).timeout
		_:
			await get_tree().process_frame

func _skip_rest() -> void:
	if busy:
		return
	busy = true
	var r := engine.simulate_remaining(tactic, "steady")
	_refresh_score()
	_comment.clear()
	_comment.append_text("[color=#8a8175]（已跳过过程）[/color]")
	busy = false
	_finish()

func _apply_result(r: Dictionary, choice: String) -> void:
	var events: Array = r.get("events", [])
	var winner: int = int(r.get("winner", 0))
	var scored_by_player := winner == 0

	# 局末 / 场末优先处理
	var game_end := false
	var match_end := false
	for e in events:
		var t := str(e.get("type", ""))
		if t == "game_end":
			game_end = true
		elif t == "match_end":
			match_end = true
		elif t == "towel":
			_rally_count = 0
		elif t == "expedite_on":
			_push_log("裁判示意：轮换发球法。", UIKit.GOLD)
		elif t == "change_ends":
			_push_log("决胜局 %d 分，交换方位。" % int(e.get("at", 5)), UIKit.INK_3)
		elif t == "serve_change":
			_last_serve_side = int(e.get("server", 0))

	_refresh_score()
	_adapt_ambience(scored_by_player)

	if speed == MatchEngine.Speed.IMMERSIVE and not game_end:
		_play_rally_anim(scored_by_player)
	_push_comment(scored_by_player, r, choice)

	if game_end:
		var gs: Array = r.get("games", [0, 0])
		_comment.clear()
		_comment.append_text("[color=#8a8175]第 %d 局结束。[/color]  [b]%d : %d[/b]" % [engine.game_index, int(gs[0]), int(gs[1])])
	if match_end:
		finished = true

## 环境音随局势呼吸：关键分抽成真空，得分瞬间爆发。
func _adapt_ambience(player_scored: bool) -> void:
	if engine.is_critical():
		AudioDirector.set_ambience(0.05)
		AudioDirector.play_sfx("heart")
		return
	var base := 0.24
	var pts := engine.score[0] + engine.score[1]
	base += clampf(float(pts) / 40.0, 0.0, 0.22)
	if player_scored:
		AudioDirector.set_ambience(0.62)
		var tw := create_tween()
		tw.tween_interval(0.45)
		tw.tween_callback(func() -> void: AudioDirector.set_ambience(base))
	else:
		AudioDirector.set_ambience(base)

# ---------------------------------------------------------------- 动画

func _play_rally_anim(player_scored: bool) -> void:
	var from_uv := Vector2(randf_range(0.2, 0.8), 0.86)
	var to_uv := Vector2(randf_range(0.15, 0.85), 0.18)
	var style := "drive"
	match tactic:
		"rush_fh": style = "drive"
		"target_bh": style = "loop"
		"target_mid": style = "drive"
		"short_game": style = "short"
	if player_scored:
		# 玩家得分：球从对手侧回到玩家侧，落点在对方台面
		from_uv = Vector2(randf_range(0.2, 0.8), 0.86)
		to_uv = Vector2(randf_range(0.15, 0.85), 0.22)
	else:
		from_uv = Vector2(randf_range(0.2, 0.8), 0.16)
		to_uv = Vector2(randf_range(0.15, 0.85), 0.82)

	AudioDirector.play_sfx("hit_chop" if style == "short" else "hit")
	_table.animate_ball(from_uv, to_uv, style, 0.26 if speed == MatchEngine.Speed.IMMERSIVE else 0.1)
	await get_tree().create_timer(0.26).timeout
	var impact := to_uv
	_table.ripple(impact, UIKit.RED if player_scored else UIKit.CYAN)
	if style == "drive":
		_table.flash()
		_table.shake(2.6, 0.14)
	if randf() < 0.06:
		_table.net_flash()
	_table.hide_ball()

func _refresh_score() -> void:
	_score_label.text = "%d : %d" % [engine.score[0], engine.score[1]]
	_game_label.text = "局 %d : %d" % [engine.games[0], engine.games[1]]
	_table.stamina_player = engine.stamina[0]
	_table.stamina_opp = engine.stamina[1]
	_refresh_ticker()

func _refresh_ticker() -> void:
	for box in [_ticker_l, _ticker_r]:
		for c in box.get_children():
			c.queue_free()
	var lines_l: Array[String] = [
		"回合 %d" % (int(engine.stats["rally_total"]) / maxi(1, int(engine.stats["points_won"][0]) + int(engine.stats["points_won"][1]))),
		"最长 %d 板" % int(engine.stats["max_rally"]),
		"关键分 %d/%d" % [int(engine.stats["critical_won"]), int(engine.stats["critical_played"])],
	]
	var lines_r: Array[String] = [
		"体力 %.0f%%" % engine.stamina[0],
		"战术命中 %d" % int(engine.stats["tactic_hits"]),
		"用时 %.0f′" % engine.total_minutes,
	]
	for l in lines_l:
		_ticker_l.add_child(_ticker_line(l))
	for l in lines_r:
		_ticker_r.add_child(_ticker_line(l, true))

func _ticker_line(t: String, right: bool = false) -> Label:
	var l := UIKit.label(t, 11, UIKit.INK_3)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	return l

# ---------------------------------------------------------------- 解说

func _push_comment(scored_by_player: bool, r: Dictionary, choice: String) -> void:
	if speed == MatchEngine.Speed.SKIP:
		return
	var rally := int(r.get("score", [0, 0])[0])
	var sc: Array = r.get("score", [0, 0])
	var col := "#b03a2e" if scored_by_player else "#2c6e8f"
	var who := GameManager.p.player_name if scored_by_player else str(ctx.get("opponent", {}).get("name", "对手"))
	var text := _rally_text(scored_by_player, int(r.get("rally", 5)))
	var prefix := ""
	if engine.is_deuce():
		prefix = "[color=#9c7c2e]平分。[/color] "
	elif engine.is_match_point_for(0):
		prefix = "[color=#b03a2e]赛点。[/color] "
	elif engine.is_game_point_for(0):
		prefix = "[color=#9c7c2e]局点。[/color] "

	if _comment.get_parsed_text().length() > 0:
		_comment.append_text("\n")
	_comment.append_text(prefix)
	_comment.append_text("[color=%s]%s[/color]  %s  [color=#8a8175](%d : %d)[/color]" % [
		col, who, text, int(sc[0]), int(sc[1])])

func _rally_text(scored: bool, rally: int) -> String:
	var win_pool: Array[String] = [
		"正手抢冲直线，球擦着白边落下。",
		"反手拧起来，对手没碰到。",
		"多拍相持，对面先顶不住了。",
		"发球抢攻，一板过。",
		"对手回球下网。",
		"侧身爆冲，全场都听见了那一声。",
	]
	var lose_pool: Array[String] = [
		"反手拉球出界。",
		"接发球冒高，被一板打死。",
		"相持中脚下慢了半拍。",
		"摆短下网。",
		"对手变线，你没跟上。",
		"关键分，手腕僵了。",
	]
	var pool := win_pool if scored else lose_pool
	if rally >= 9:
		pool = ["十几板的相持，最后是体力说话。"] if scored else ["十几板的相持，你的腿先沉了。"]
	return pool[randi() % pool.size()]

func _push_log(text: String, col: Color) -> void:
	_log_lines.append(text)
	if _log_lines.size() > 4:
		_log_lines.pop_front()

# ---------------------------------------------------------------- 入场

func _show_entry() -> void:
	_entry_layer = Control.new()
	_entry_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_entry_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_entry_layer)

	var bg := ColorRect.new()
	bg.color = UIKit.PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_entry_layer.add_child(bg)

	var vb := UIKit.vbox(14)
	if UIKit.is_portrait():
		# 竖屏用真正的居中容器；原来的 position 偏移是按 760 宽算的，竖屏会偏出左侧
		var cc := CenterContainer.new()
		cc.set_anchors_preset(Control.PRESET_FULL_RECT)
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_entry_layer.add_child(cc)
		cc.add_child(UIKit.margin(vb, 24, 0, 24, 0))
	else:
		vb.set_anchors_preset(Control.PRESET_CENTER)
		vb.position = Vector2(-380, -120)
		_entry_layer.add_child(vb)

	var tour := str(ctx.get("tourney", ""))
	var rnd := str(ctx.get("round_name", ""))
	vb.add_child(UIKit.label(tour, 13, UIKit.INK_3))
	vb.add_child(UIKit.label("%s  ·  %s" % [rnd, str(SPEED_NAME.get(speed, ""))], 15, UIKit.INK_2))
	vb.add_child(UIKit.spacer(18))

	var opp: Dictionary = ctx.get("opponent", {})
	var intro := _entry_text(opp)
	var portrait := UIKit.is_portrait()
	var t := UIKit.wrap(intro, 19 if portrait else 26, UIKit.INK)
	if not portrait:
		t.custom_minimum_size = Vector2(760, 0)
	vb.add_child(t)

	if speed == MatchEngine.Speed.IMMERSIVE:
		for c in vb.get_children():
			c.modulate.a = 0.0
			var tw2 := create_tween()
			tw2.tween_property(c, "modulate:a", 1.0, 0.5)
			await get_tree().create_timer(0.12).timeout

func _entry_text(opp: Dictionary) -> String:
	var name := str(opp.get("name", "对手"))
	var style := str(opp.get("style_name", ""))
	var tier := str(ctx.get("tier", ""))
	if tier in ["major", "finals", "worldcup"]:
		return "灯光暗下来。\n观众的声音像潮水一样压过来。\n\n球台对面，%s 正在试拍。%s。\n你们都知道这场球意味着什么。" % [name, style]
	if tier in ["champ", "star", "asia"]:
		return "%s 站在球台对面，低着头转拍子。\n%s。\n\n裁判报分。你活动了一下手腕。" % [name, style]
	return "%s。%s。\n馆里人不多，能听见球落在台面上的声音。" % [name, style]

func _hide_entry() -> void:
	if _entry_layer != null:
		var tw := create_tween()
		tw.tween_property(_entry_layer, "modulate:a", 0.0, 0.4)
		tw.tween_callback(_entry_layer.queue_free)
		_entry_layer = null

# ---------------------------------------------------------------- 赛前战术

func _ask_tactic_first() -> void:
	_comment.clear()
	_comment.append_text("[color=#8a8175]赛前，选一套主要战术。局间可以换。[/color]")
	var pd := _panel_layer("赛前布置")
	var layer: Control = pd["layer"]
	var body: VBoxContainer = pd["body"]
	var opp: Dictionary = ctx.get("opponent", {})
	var weak: Array = opp.get("weakness", [])
	body.add_child(UIKit.dim("对手弱点：" + (", ".join(_weak_names(weak)) if not weak.is_empty() else "无明显短板"), 12))

	var portrait := UIKit.is_portrait()
	var picked := false
	for t in MatchEngine.TACTICS:
		var key := str(t)
		var hit := _tactic_hits(key, weak)
		var hb := UIKit.hbox(8 if portrait else 10)
		var tvb := UIKit.vbox(2)
		tvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_row := UIKit.hbox(6)
		name_row.add_child(UIKit.label(str(MatchEngine.TACTIC_NAMES.get(key, key)), 15))
		if hit and portrait:
			# 竖屏放不下整块 chip，压成一个红点
			name_row.add_child(UIKit.icon_dot(UIKit.RED, 6))
		name_row.add_child(UIKit.hfill())
		tvb.add_child(name_row)
		var dsc := UIKit.dim(_tactic_desc(key), 11)
		if portrait:
			dsc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			dsc.custom_minimum_size = Vector2(0, 16)
		tvb.add_child(dsc)
		hb.add_child(tvb)
		hb.add_child(UIKit.hfill())
		if hit and not portrait:
			hb.add_child(UIKit.chip("命中弱点", UIKit.RED, false))
		var pick_cb := func() -> void:
			tactic = key
			picked = true
			layer.queue_free()
			_comment.clear()
			_comment.append_text("[color=#8a8175]战术：%s[/color]" % str(MatchEngine.TACTIC_NAMES.get(key, key)))
		var b := UIKit.btn("选" if portrait else "用这套", "normal" if key != "target_bh" else "primary", pick_cb)
		b.custom_minimum_size = Vector2(44 if portrait else 78, 34 if portrait else 32)
		b.add_theme_font_size_override("font_size", 13 if portrait else 15)
		hb.add_child(b)
		body.add_child(hb)

	var elapsed := 0.0
	while not picked and elapsed < 18.0 and is_instance_valid(layer):
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if is_instance_valid(layer):
		layer.queue_free()

func _panel_layer(title_text: String) -> Dictionary:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var col := ColorRect.new()
	col.color = Color(0.10, 0.09, 0.08, 0.35)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(col)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cc)
	var pc := UIKit.panel(UIKit.WHITE, UIKit.LINE, 3)
	pc.custom_minimum_size = Vector2(360, 0) if UIKit.is_portrait() else Vector2(560, 0)
	cc.add_child(pc)
	var vb := UIKit.vbox(12)
	vb.add_child(UIKit.label(title_text, 20, UIKit.INK))
	vb.add_child(UIKit.hsep())
	pc.add_child(UIKit.margin(vb, 24, 20, 24, 20))
	return {"layer": layer, "body": vb}

func _tactic_hits(key: String, weak: Array) -> bool:
	var counters: Array = MatchEngine.TACTIC_COUNTER.get(key, [])
	for w in weak:
		if counters.has(str(w)):
			return true
	return false

func _tactic_desc(k: String) -> String:
	match k:
		"rush_fh": return "发球就抢，用正手解决。风险高，但一旦打顺会压垮对手。"
		"target_bh": return "盯着反手位打，逼他用最不舒服的方式回球。"
		"target_mid": return "冲中路，让他侧不开身。"
		"short_game": return "台内斗短，谁先起板谁吃亏。磨。"
		_: return ""

func _weak_names(w: Array) -> Array[String]:
	var out: Array[String] = []
	var m := {"bh": "反手", "fh": "正手", "mid": "中路", "footwork": "步法", "touch": "台内", "serve_recv": "接发球"}
	for x in w:
		out.append(str(m.get(str(x), str(x))))
	return out

# ---------------------------------------------------------------- 关键分

func _ask_critical() -> String:
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0.10, 0.09, 0.08, 0.42)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cc)
	var pc := UIKit.panel(UIKit.WHITE, UIKit.RED, 3)
	pc.custom_minimum_size = Vector2(364, 0) if UIKit.is_portrait() else Vector2(600, 0)
	cc.add_child(pc)

	var vb := UIKit.vbox(12)
	var is_mp := engine.is_match_point_for(0) or engine.is_match_point_for(1)
	var is_gp := engine.is_game_point_for(0) or engine.is_game_point_for(1)
	var head := "%d : %d" % [engine.score[0], engine.score[1]]
	var tag := "关键分"
	if is_mp:
		tag = "赛点"
	elif is_mp and engine.is_match_point_for(1):
		tag = "对手赛点"
	elif is_gp:
		tag = "局点"
	vb.add_child(UIKit.label(head, 46, UIKit.INK))
	var sub := UIKit.hbox(8)
	sub.add_child(UIKit.chip(tag, UIKit.RED, true))
	sub.add_child(UIKit.dim("第 %d 局 · %s" % [engine.game_index + 1, str(MatchEngine.TACTIC_NAMES.get(tactic, ""))], 12))
	vb.add_child(sub)
	vb.add_child(UIKit.hsep())

	var body := UIKit.vbox(8)
	var choices: Array[Dictionary] = [
		{"k": "rush", "n": "搏杀", "d": "侧身抢冲。赢了士气如虹，输了直接送分。"},
		{"k": "steady", "n": "稳住", "d": "把球多打一板，等对面先出错。"},
		{"k": "timeout", "n": "暂停", "d": "用掉唯一的暂停。恢复体力，冷静下来。", "cost": engine.timeouts[0] <= 0},
	]
	for c in choices:
		if bool(c.get("cost", false)):
			continue
		var ck := str(c["k"])
		var hb := UIKit.hbox(8 if UIKit.is_portrait() else 10)
		var cvb := UIKit.vbox(3)
		cvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cl := UIKit.label(str(c["n"]), 16)
		cl.custom_minimum_size = Vector2(0, 22)
		cvb.add_child(cl)
		var dl := UIKit.dim(str(c["d"]), 11)
		dl.custom_minimum_size = Vector2(0, 18)
		if UIKit.is_portrait():
			dl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cvb.add_child(dl)
		hb.add_child(cvb)
		hb.add_child(UIKit.hfill())
		var b := UIKit.btn("选", "primary" if ck == "rush" else "normal", func() -> void:
			layer.queue_free()
			critical_choice_made.emit(ck)
		)
		b.custom_minimum_size = Vector2(56, 36)
		hb.add_child(b)
		body.add_child(hb)
	vb.add_child(body)

	var timer_bar := UIKit.bar(1.0, 1.0, UIKit.RED, 300 if UIKit.is_portrait() else 520, 3)
	vb.add_child(timer_bar)
	var hint := UIKit.dim("6 秒内不做选择，默认「稳住」", 10)
	vb.add_child(hint)

	pc.add_child(UIKit.margin(vb, 26, 22, 26, 22))

	# 暗角
	var tw := create_tween()
	tw.tween_property(_dim_layer, "color:a", 0.55, 0.25)

	var auto_tw := create_tween()
	auto_tw.tween_method(func(v: float) -> void:
		if is_instance_valid(timer_bar):
			timer_bar.value = v
	, 1.0, 0.0, 6.0)
	auto_tw.tween_callback(func() -> void:
		if is_instance_valid(layer):
			layer.queue_free()
			critical_choice_made.emit("steady")
	)

	var choice: String = await critical_choice_made
	auto_tw.kill()
	var tw2 := create_tween()
	tw2.tween_property(_dim_layer, "color:a", 0.0, 0.2)
	return choice

# ---------------------------------------------------------------- 结束

func _finish() -> void:
	if busy:
		return
	busy = true
	AudioDirector.ambience_off()
	var won: bool = engine.winner == 0
	var result := GameManager.conclude_match(won)
	await get_tree().create_timer(0.5).timeout
	_show_review(result)

func _show_review(result: Dictionary) -> void:
	for c in get_children():
		c.queue_free()

	var bg := ColorRect.new()
	bg.color = UIKit.PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vb := UIKit.vbox(14)
	var root := UIKit.margin(vb, 46, 28, 46, 24)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var won := bool(result.get("won", false))
	var title_col := UIKit.RED if won else UIKit.CYAN

	# ---- 头部 ----
	var head := UIKit.hbox(16)
	var big := UIKit.label("胜" if won else "负", 52, title_col)
	big.custom_minimum_size = Vector2(0, 66)
	head.add_child(big)
	var tb := UIKit.vbox(3)
	tb.alignment = BoxContainer.ALIGNMENT_CENTER
	var tl := UIKit.label(str(result.get("tourney", "")), 17, UIKit.INK)
	tl.custom_minimum_size = Vector2(0, 24)
	tb.add_child(tl)
	tb.add_child(UIKit.dim("%d : %d  ·  %s  ·  %.0f 分钟" % [
		engine.games[0], engine.games[1], str(ctx.get("round_name", "")), engine.total_minutes], 12))
	head.add_child(tb)
	head.add_child(UIKit.hfill())
	var place := int(result.get("place", 99))
	var tag_box := UIKit.vbox(2)
	if place == 1:
		var ch := UIKit.hbox(0)
		ch.add_child(UIKit.chip("冠军", UIKit.RED, true))
		ch.add_child(UIKit.hfill())
		tag_box.add_child(ch)
	elif place <= 16:
		var ch2 := UIKit.hbox(0)
		ch2.add_child(UIKit.chip(TournamentSystem.place_label(place), UIKit.GOLD, false))
		ch2.add_child(UIKit.hfill())
		tag_box.add_child(ch2)
	head.add_child(tag_box)
	vb.add_child(head)
	vb.add_child(UIKit.hsep())

	# ---- 三栏 ----
	var portrait := UIKit.is_portrait()
	var cols: BoxContainer = UIKit.vbox(12) if portrait else UIKit.hbox(16)
	if not portrait:
		cols.alignment = BoxContainer.ALIGNMENT_BEGIN
	vb.add_child(cols)

	var opp: Dictionary = ctx.get("opponent", {})
	var opp_ovr := float(opp.get("ovr", 50))

	# 雷达
	var rc := UIKit.panel()
	rc.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rc.custom_minimum_size = Vector2(0, 0) if portrait else Vector2(300, 0)
	rc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rv := UIKit.vbox(4)
	rv.add_child(UIKit.label("五维对比", 12, UIKit.INK_3))
	var radar := RadarChart.new()
	radar.custom_minimum_size = Vector2(300, 220) if portrait else Vector2(272, 200)
	radar.max_value = 124.0
	radar.set_values(GameManager.p.radar(), [opp_ovr, opp_ovr * 0.96, opp_ovr * 0.99, opp_ovr, opp_ovr * 0.94])
	rv.add_child(radar)
	var lg := UIKit.hbox(12)
	lg.add_child(UIKit.label("— 你", 11, UIKit.CYAN))
	lg.add_child(UIKit.label("— %s" % str(opp.get("name", "对手")), 11, UIKit.RED))
	rv.add_child(lg)
	rc.add_child(UIKit.margin(rv, 14, 12, 14, 12))
	cols.add_child(rc)

	# 技术统计
	var dc := UIKit.panel()
	dc.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dc.custom_minimum_size = Vector2(0, 0) if portrait else Vector2(296, 0)
	dc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dv := UIKit.vbox(5)
	dv.add_child(UIKit.label("技术统计", 12, UIKit.INK_3))
	var st: Dictionary = engine.stats
	var total_points := int(st["points_won"][0]) + int(st["points_won"][1])
	dv.add_child(UIKit.kv("总得分", "%d : %d" % [int(st["points_won"][0]), int(st["points_won"][1])], UIKit.INK))
	dv.add_child(UIKit.kv("最长回合", "%d 板" % int(st["max_rally"])))
	dv.add_child(UIKit.kv("平均回合", "%.1f 板" % (float(st["rally_total"]) / maxf(1.0, float(total_points)))))
	dv.add_child(UIKit.kv("关键分", "%d / %d" % [int(st["critical_won"]), int(st["critical_played"])]))
	dv.add_child(UIKit.kv("战术命中", "%d 次" % int(st["tactic_hits"])))
	dv.add_child(UIKit.kv("体力剩余", "%.0f%%" % GameManager.p.stamina_cur))
	var clog: Array = st.get("critical_log", [])
	if not clog.is_empty():
		dv.add_child(UIKit.hsep(UIKit.LINE_SOFT))
		dv.add_child(UIKit.label("关键分回放", 11, UIKit.INK_3))
		for i in range(mini(4, clog.size())):
			var c: Dictionary = clog[i]
			var ch := UIKit.hbox(6)
			ch.add_child(UIKit.label("第%d局 %s" % [int(c.get("game", 0)), str(c.get("score", ""))], 10, UIKit.INK_3))
			var cn := str(c.get("choice", ""))
			var cn_label := "搏杀" if cn == "rush" else ("稳住" if cn == "steady" else "暂停")
			ch.add_child(UIKit.label(cn_label, 10, UIKit.INK_2))
			ch.add_child(UIKit.hfill())
			ch.add_child(UIKit.label("赢" if bool(c.get("won", false)) else "失", 10,
				UIKit.RED if bool(c.get("won", false)) else UIKit.CYAN))
			dv.add_child(ch)
	dv.add_child(UIKit.hsep(UIKit.LINE_SOFT))
	var review := UIKit.wrap(_coach_review(won, st, engine), 13, UIKit.INK_2)
	dv.add_child(review)
	dc.add_child(UIKit.margin(dv, 16, 12, 16, 12))
	cols.add_child(dc)

	# 叙述
	var sc := UIKit.panel(UIKit.PAPER_2, UIKit.LINE_SOFT, 3)
	sc.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sv := UIKit.vbox(8)
	sv.add_child(UIKit.label("这场球", 12, UIKit.INK_3))
	var narr := UIKit.wrap(_match_narrative(won), 15, UIKit.INK)
	sv.add_child(narr)
	sv.add_child(UIKit.hsep())
	var rec := GameManager.p.record
	sv.add_child(UIKit.kv("生涯战绩", "%d 胜 %d 负" % [int(rec.get("wins", 0)), int(rec.get("losses", 0))]))
	sv.add_child(UIKit.kv("世界排名", ("#%d" % GameManager.p.rank) if GameManager.p.rank > 0 else "未上榜"))
	sc.add_child(UIKit.margin(sv, 18, 14, 18, 14))
	cols.add_child(sc)

	vb.add_child(UIKit.vfill())

	# ---- 底部 ----
	var settled: Dictionary = GameManager.active_run.get("settled", {})
	var foot := UIKit.hbox(12)
	if not settled.is_empty() and not GameManager.has_next_round():
		foot.add_child(UIKit.dim("本站结算：积分 %+d · 奖金 %s · %s" % [
			int(settled.get("points", 0)), DataManager.fmt_money(int(settled.get("money", 0))),
			str(settled.get("text", ""))], 12))
	foot.add_child(UIKit.hfill())
	if bool(result.get("team", false)):
		var team_btn := UIKit.btn("继续团体赛  →", "primary", func() -> void:
			main.show_page(main.Page.TEAM)
		)
		team_btn.custom_minimum_size = Vector2(180, 42)
		foot.add_child(team_btn)
	elif GameManager.has_next_round():
		var nb := UIKit.btn("下一轮  →", "primary", func() -> void:
			var c := GameManager.begin_round()
			if not c.is_empty():
				main.show_page(main.Page.MATCH, false)
		)
		nb.custom_minimum_size = Vector2(150, 42)
		foot.add_child(nb)
	else:
		var rb := UIKit.btn("返回", "primary", func() -> void:
			GameManager.active_run = {}
			main.show_page(main.Page.TOURNEY)
		)
		rb.custom_minimum_size = Vector2(120, 42)
		foot.add_child(rb)
	vb.add_child(foot)

func _coach_review(won: bool, st: Dictionary, e: MatchEngine) -> String:
	var critical := int(st["critical_played"])
	var won_c := int(st["critical_won"])
	var lines: Array[String] = []
	if won:
		lines.append("赢了。")
		if critical > 0 and won_c * 2 >= critical:
			lines.append("关键分你顶住了，这比赢球本身更重要。")
		else:
			lines.append("但关键分还是有点软，别高兴太早。")
	else:
		lines.append("输了。")
		if int(st["max_rally"]) < 8:
			lines.append("回合太短，你一直在前三板解决战斗，这不是你的节奏。")
		else:
			lines.append("相持不落下风，问题出在接发球那两板。")
	if e.stamina[0] < 35.0:
		lines.append("体力见底了。下站之前必须休息。")
	return " ".join(lines)

func _match_narrative(won: bool) -> String:
	var opp: Dictionary = ctx.get("opponent", {})
	var nm := str(opp.get("name", "对手"))
	if won:
		var pool: Array[String] = [
			"最后一分落地，%s 站在原地，球拍垂在手里。你听见自己的呼吸声。" % nm,
			"你赢了。没有想象中那么激动，只是觉得很累。",
			"握手的时候，%s 说了句什么，你没听清。" % nm,
		]
		return pool[randi() % pool.size()]
	var pool2: Array[String] = [
		"你收拾球拍的时候，%s 已经在接受采访了。" % nm,
		"输了。你坐在椅子上多待了一会儿，才站起来。",
		"走廊很长，灯是白的。你想起教练说过，输球要记住这种感觉。",
	]
	return pool2[randi() % pool2.size()]
