extends Node
## 游戏主控（Autoload）：状态机 + 周循环 + 生涯编排。
## 只做「编排」：规则在 MatchEngine / TournamentSystem，世界在 NPCWorld，
## 文案在 ForumManager / EventPool，UI 通过 EventBus 订阅。

enum Phase { TITLE, CAREER, MATCH, TEAM, RETIRED }

const START_YEAR: int = 2010
const START_AGE: int = 8
const WEEKS_PER_YEAR: int = 52

## v0.8 六阶段身份矩阵（排阵权重 / 教练话语权 / 博弈手段）
const IDENTITY: Array[Dictionary] = [
	{"n": "启蒙", "org": "市体校", "age": [8, 10], "w": "20/50/0/30", "coach": "极高", "coach_type": "护犊子型",
	 "means": "无。你只能服从。", "note": "决定你去处的不是积分，是球馆里那几个大人看你的眼神。"},
	{"n": "少儿", "org": "省二队", "age": [10, 13], "w": "40/30/0/30", "coach": "高", "coach_type": "数据型",
	 "means": "消耗 AP 针对性加练，影响教练的权重评估。", "note": "第一次有了积分。它不给你奖励，只决定你有没有资格被叫去试训。"},
	{"n": "省青", "org": "省队", "age": [13, 16], "w": "50/30/0/20", "coach": "高", "coach_type": "人情型",
	 "means": "队内选拔赛打爆老将，强行改写排阵。", "note": "你可能是全队最强，但一单的位置还轮不到你。"},
	{"n": "国青", "org": "国家青年队", "age": [16, 19], "w": "30/30/40/0", "coach": "极高", "coach_type": "保守型",
	 "means": "更衣室请缨、战术妥协、诈伤避战。", "note": "外战输一场，教练就再也不敢让你打一单。"},
	{"n": "国内", "org": "省队 / 俱乐部", "age": [19, 27], "w": "40/20/0/40", "coach": "中", "coach_type": "资本型",
	 "means": "商业价值施压、转会威胁、论坛造势。", "note": "你是俱乐部花大价钱买来的外援，队友全是本土小将。你必须拿两分。"},
	{"n": "国家队", "org": "国家一队", "age": [20, 45], "w": "30/20/50/0", "coach": "绝对权威", "coach_type": "数据型",
	 "means": "请缨死战、直通赛逆袭、舆论造势。", "note": "全场几亿双眼睛看着你。你打一单，意味着第一盘和第四盘都要上。"},
]

var phase: Phase = Phase.TITLE
var p: PlayerStats = PlayerStats.new()
var slot: int = 1

var world: NPCWorld = NPCWorld.new()
var tourney_sys: TournamentSystem = TournamentSystem.new()
var event_pool: EventPool = EventPool.new()
var career: CareerSystem = CareerSystem.new()
var gear: GearSystem = GearSystem.new()
var achv: AchievementSystem = AchievementSystem.new()
var team: TeamSystem = TeamSystem.new()

var active_run: Dictionary = {}
var engine: MatchEngine = null
var current_match: Dictionary = {}
var pending_event: Dictionary = {}
var week_report: Dictionary = {}
var last_result: Dictionary = {}
var feed: Array[Dictionary] = []          # 周报/日志流
var forum_effects: Dictionary = {}        # 舆论施加的临时状态
var pressure: Dictionary = {}
var week_major: bool = false
var team_run: Dictionary = {}
var milestones: Array[Dictionary] = []
var pending_achievements: Array = []

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

# ---------------------------------------------------------------- 生涯

func new_career(player_name: String, origin: String = "sports_family") -> void:
	rng.randomize()
	p = PlayerStats.new()
	p.player_name = player_name if player_name.strip_edges() != "" else "陈默"
	p.age = START_AGE
	p.stage = 0
	p.year = START_YEAR
	p.week = 1
	p.ap_max = 3
	p.ap = 3
	p.money = 500
	p.trust = 40.0
	p.weakness = ["mid"]
	p.record = PlayerStats.blank_record()
	_apply_origin(origin)

	world.build(rng.randi())
	gear = GearSystem.new()
	achv = AchievementSystem.new()
	achv.load_from_profile()
	achv.sanitize(p)   # 清掉旧版本按错误方向判定的名次成就
	apply_gear()

	tourney_sys.rng.seed = rng.randi()
	event_pool.rng.seed = rng.randi()
	career.rng.seed = rng.randi()
	ForumManager.reset()

	active_run = {}
	engine = null
	current_match = {}
	team_run = {}
	pending_event = {}
	pending_achievements.clear()
	milestones.clear()
	feed.clear()
	_add_milestone("生涯开始", "%d 年，%d 岁，%s。" % [p.year, p.age, str(identity().get("org", ""))])
	pressure = {}
	week_major = false

	if str(p.player_name) == "":
		p.player_name = "陈默"

	_update_stage(true)
	phase = Phase.CAREER
	_push_feed("生涯开始。%d 年，%d 岁，%s。" % [p.year, p.age, identity().get("org", "")])
	EventBus.stage_changed.emit(p.stage, stage_name())
	EventBus.week_started.emit(p.week, p.year)
	update_ranking()

func _apply_origin(origin: String) -> void:
	match origin:
		"sports_family":
			p.tactic += 3.0
			p.mental += 2.0
		"working_class":
			p.stamina += 3.0
			p.power += 2.0
		"late_bloomer":
			p.touch += 2.0
			p.weight_late = 12.0
		"prodigy":
			p.speed += 3.0
			p.tech_fh += 2.0
			p.weight_monster = 12.0

## 把当前器材的四维加成写进玩家资源。装备变化 / 读档后必须调用。
func apply_gear() -> void:
	p.gear_bonus = gear.bonus()

func stage_name() -> String:
	return str(DataManager.stage_def(p.stage).get("n", "—"))

func stage_label() -> String:
	var d := DataManager.stage_def(p.stage)
	return "%s · %s" % [str(d.get("n", "—")), str(d.get("org", ""))]

## 六阶段身份（用于排阵与叙事）
func identity_index() -> int:
	if p.rank > 0 and p.rank <= 20 and p.age >= 18:
		return 5
	if p.age >= 19:
		return 4
	if p.age >= 16:
		return 3
	if p.age >= 13:
		return 2
	if p.age >= 10:
		return 1
	return 0

func identity() -> Dictionary:
	return IDENTITY[clampi(identity_index(), 0, IDENTITY.size() - 1)]

# ---------------------------------------------------------------- 周循环

func advance_week() -> Dictionary:
	if phase != Phase.CAREER:
		return {}
	var before_stage := p.stage
	var events: Array[String] = []

	p.week += 1
	var new_year := false
	if p.week > WEEKS_PER_YEAR:
		p.week = 1
		p.year += 1
		p.age += 1
		p.record["seasons"] = int(p.record.get("seasons", 0)) + 1
		p.decay_for_age()
		new_year = true
		events.append("你又长了一岁。%d 岁。" % p.age)
		EventBus.season_changed.emit(p.year)
		var yr := world.tick_year(p.year)
		if not yr["retired"].is_empty():
			for nm in yr["retired"].slice(0, 2):
				events.append("%s 宣布退役。" % nm)
		# 赛季末：隐藏流派结算
		var tr := career.settle_season(p)
		if tr != "":
			events.append(tr)
		p.points = int(float(p.points) * 0.72)  # 年度积分衰减
		p.record["matches_in_year"] = 0
		p.record["champions_in_year"] = 0

	var tick := p.tick_week()
	if tick.get("injury", -1) >= 0 and p.injury_weeks > 0:
		events.append("伤还没好。你只能看着别人练。")

	# 伤病判定
	for note in career.weekly_check(p):
		events.append(note)

	# AP 重置
	p.ap = p.ap_max
	_update_stage(before_stage)

	# 论坛的日常呼吸
	var flavor := ForumManager.generate_week_flavor(p)
	if not flavor.is_empty():
		for f in flavor.slice(0, 1):
			events.append("论坛：" + str(f.get("title", "")))

	# 随机事件：大赛周不打扰
	pending_event = event_pool.pick_for(p, week_major)

	# 排名与舆论涟漪
	update_ranking()
	_apply_forum_effect()

	# 生态挤压
	pressure = check_pressure()

	week_report = {
		"week": p.week, "year": p.year, "age": p.age, "stage": p.stage,
		"events": events, "new_year": new_year, "identity": identity(),
	}
	for e in events:
		_push_feed(e)
	EventBus.week_settled.emit(week_report)
	return week_report

func _update_stage(force: bool = false) -> void:
	var stages: Array = DataManager.db.STAGES
	var new_stage := p.stage
	for i in range(stages.size() - 1, -1, -1):
		var st: Dictionary = stages[i]
		var rg: Array = st.get("age", [8, 99])
		if p.age >= int(rg[0]):
			new_stage = i
			break
	if new_stage != p.stage or force:
		var rising := new_stage > p.stage
		p.stage = new_stage
		if rising:
			_add_milestone("进入" + stage_name(), "第 %d 年，你 %d 岁。" % [p.year, p.age])
		p.ap_max = int(DataManager.stage_def(p.stage).get("ap", 3))
		EventBus.stage_changed.emit(p.stage, stage_name())

# ---------------------------------------------------------------- 训练

func train(action: String, tech_key: String = "fh") -> Dictionary:
	if phase != Phase.CAREER:
		return {"text": "", "gains": []}
	if p.ap <= 0:
		return {"text": "这周的力气用完了。", "gains": []}
	if p.injury_weeks > 0 and action != "study" and action != "rest":
		return {"text": "伤还没好，练不了。", "gains": []}
	var r := career.train(p, action, tech_key)
	p.record["trains"] = int(p.record.get("trains", 0)) + 1
	match action:
		"tech": p.record["tech_sessions"] = int(p.record.get("tech_sessions", 0)) + 1
		"fit": p.record["fit_sessions"] = int(p.record.get("fit_sessions", 0)) + 1
		"psy": p.record["psy_sessions"] = int(p.record.get("psy_sessions", 0)) + 1
		"tac": p.record["tac_sessions"] = int(p.record.get("tac_sessions", 0)) + 1
		"rest": p.record["rest_weeks"] = int(p.record.get("rest_weeks", 0)) + 1
	_check_achievements()
	_push_feed(str(r["text"]))
	return r

# ---------------------------------------------------------------- 赛事

func available_tourneys() -> Array[Dictionary]:
	return tourney_sys.available(DataManager.db.TOURNEYS, p, p.week)

func enter_tournament(t: Dictionary, channel: int) -> Dictionary:
	if phase != Phase.CAREER:
		return {}
	var cost := tourney_sys.channel_cost(t, channel)
	p.stamina_cur = clampf(p.stamina_cur - float(cost.get("stamina", 0.0)), 0.0, 100.0)
	p.trust = clampf(p.trust + float(cost.get("trust", 0.0)), 0.0, 100.0)
	p.money = maxi(0, p.money + int(cost.get("money", 0)))

	active_run = tourney_sys.start_run(t, channel, p, world)
	active_run["age_at_entry"] = p.age
	active_run["coach_type"] = str(identity().get("coach_type", ""))
	_push_feed("报名「%s」· %s。%s" % [str(t.get("n", "")), TournamentSystem.CHANNEL_NAME.get(channel, ""), str(cost.get("text", ""))])
	return active_run

## 打完一轮后的下一步：true 表示还能继续打
func has_next_round() -> bool:
	return not active_run.is_empty() and not bool(active_run.get("done", false))

func begin_round() -> Dictionary:
	if active_run.is_empty() or bool(active_run.get("done", false)):
		return {}
	var opp := tourney_sys.current_opponent(active_run)
	if opp.is_empty():
		return {}
	var rules := {
		"best_of": int(active_run.get("bo", 5)),
		"points_to_win": 11,
		"deuce_at": 10,
		"exchange_at_deciding": 5,
		"timeouts_per_match": 1,
	}
	engine = MatchEngine.new()
	engine.rng.seed = rng.randi()
	engine.setup(p.to_match_dict(), opp_match_dict(opp), rules)
	var phase_label := tourney_sys.round_name(active_run)
	current_match = {
		"tourney": active_run.get("name", ""),
		"tier": active_run.get("tier", ""),
		"round_name": phase_label,
		"round_index": int(active_run.get("round", 0)),
		"opponent": opp,
		"rules": rules,
		"best_of": int(rules["best_of"]),
		"seed": engine.rng.seed,
	}
	phase = Phase.MATCH
	week_major = true
	EventBus.match_started.emit(current_match)
	return current_match

func opp_match_dict(o: Dictionary) -> Dictionary:
	var ovr := float(o.get("ovr", 50.0))
	return {
		"name": str(o.get("name", "对手")),
		"ovr": ovr,
		"attack": ovr * 1.03,
		"defense": ovr * 0.97,
		"control": ovr * 0.99,
		"physical": ovr * 1.0,
		"mental": ovr * (0.9 + float(o.get("rivalry", 0)) * 0.01),
		"form": float(o.get("form", 0.5)),
		"weakness": o.get("weakness", ["mid"]),
		"tactic": o.get("tactic", "target_bh"),
		"big_match_bonus": 2.0 if int(o.get("tier", 0)) == 1 else 0.0,
	}

## 比赛结束（由 MatchView 调用）
func conclude_match(won: bool) -> Dictionary:
	if engine == null:
		return {}
	if bool(current_match.get("team", false)):
		return _conclude_team(won)
	var opp: Dictionary = current_match.get("opponent", {})
	var opp_ovr := float(opp.get("ovr", 50.0))
	var upset := won and opp_ovr > p.ovr() + 6.0
	var place_before := int(active_run.get("round", 0))

	# 统计
	p.record["matches"] = int(p.record.get("matches", 0)) + 1
	if won:
		p.record["wins"] = int(p.record.get("wins", 0)) + 1
		p.record["win_streak"] = int(p.record.get("win_streak", 0)) + 1
		p.record["loss_streak"] = 0
		p.record["max_win_streak"] = maxi(int(p.record.get("max_win_streak", 0)), int(p.record["win_streak"]))
	else:
		p.record["losses"] = int(p.record.get("losses", 0)) + 1
		p.record["loss_streak"] = int(p.record.get("loss_streak", 0)) + 1
		p.record["win_streak"] = 0

	p.record["critical_played"] = int(p.record.get("critical_played", 0)) + int(engine.stats["critical_played"])
	p.record["critical_won"] = int(p.record.get("critical_won", 0)) + int(engine.stats["critical_won"])

	# 体力消耗（含低龄成人赛惩罚）
	var phys := _physical_penalty()
	if int(active_run.get("slot", -1)) == 0:
		phys *= 1.5  # 一单要打两盘
	p.stamina_cur = clampf(p.stamina_cur - 9.0 * phys, 0.0, 100.0)
	p.fatigue = clampf(p.fatigue + 7.0 * phys, 0.0, 100.0)
	if won:
		p.rep += 1
		p.fame += 1
		p.break_pts += 1

	# 局级细节：零封与 10 平之后的硬仗
	var perfect := 0
	var deuce_games := 0
	for g in engine.stats.get("games", []):
		var ga := int(g.get("a", 0))
		var gb := int(g.get("b", 0))
		var hi := maxi(ga, gb)
		var lo := mini(ga, gb)
		if hi >= 11 and lo == 0:
			perfect += 1
		if hi >= 12 and hi - lo == 2:
			deuce_games += 1
	p.record["perfect_games"] = int(p.record.get("perfect_games", 0)) + perfect
	p.record["deuce_games"] = int(p.record.get("deuce_games", 0)) + deuce_games
	if won:
		p.record["deuce_wins"] = int(p.record.get("deuce_wins", 0)) + deuce_games
	p.record["matches_in_year"] = int(p.record.get("matches_in_year", 0)) + 1
	p.record["opp_met"] = int(p.record.get("opp_met", 0)) + 1

	# 对手排名相关的胜利
	if won:
		var opp_rank := int(opp.get("rank", 0))
		if opp_rank > 0:
			if opp_rank <= 100:
				p.record["wins_vs_top100"] = int(p.record.get("wins_vs_top100", 0)) + 1
			if opp_rank <= 50:
				p.record["wins_vs_top50"] = int(p.record.get("wins_vs_top50", 0)) + 1
			if opp_rank <= 10:
				p.record["wins_vs_top10"] = int(p.record.get("wins_vs_top10", 0)) + 1
		var tier_now := str(active_run.get("tier", ""))
		if tier_now in ["major", "worldcup", "finals", "asia"]:
			p.record["caps"] = int(p.record.get("caps", 0)) + 1

	# 交手记录
	if not opp.is_empty() and str(opp.get("id", "")) != "":
		var rec: Dictionary = opp.get("record", {"wins": 0, "losses": 0})
		if won:
			rec["wins"] = int(rec.get("wins", 0)) + 1
		else:
			rec["losses"] = int(rec.get("losses", 0)) + 1
		opp["record"] = rec

	tourney_sys.advance(active_run, won)
	active_run["last_opp"] = str(opp.get("name", ""))

	var result := {
		"won": won,
		"opp_name": str(opp.get("name", "对手")),
		"opp_ovr": opp_ovr,
		"score": engine.match_score_text(),
		"upset": upset,
		"final": place_before >= int(active_run.get("rounds", 1)) - 1,
		"streak": int(p.record.get("loss_streak", 0)) if not won else int(p.record.get("win_streak", 0)),
		"tourney": str(active_run.get("name", "")),
		"place": int(active_run.get("place", 99)),
		"stats": engine.stats.duplicate(true),
		"minutes": engine.total_minutes,
	}
	last_result = result
	phase = Phase.CAREER
	week_major = false
	EventBus.match_finished.emit(result)

	# 论坛：赛后即时反应
	ForumManager.generate_after_match(result, p)

	if won and int(p.record.get("wins", 0)) == 1:
		milestone_once("first_win", "第一场胜利", "你赢了。握手的时候手还在抖。")
	if won and int(p.record.get("champions", 0)) == 1:
		_add_milestone("第一个冠军", "你站在最高的地方，有点不真实。")
	if p.rank == 1:
		milestone_once("world_no1", "世界第一", "排名榜最上面那个名字，是你。")
	if int(p.record.get("wins", 0)) == 100:
		_add_milestone("第 100 胜", "你已经赢了 100 场。有些对手的名字，你都记不清了。")

	_check_achievements()
	if bool(active_run.get("done", false)):
		_finish_tournament()
	return result

func _finish_tournament() -> void:
	var t := DataManager.tourney(str(active_run.get("tourney_id", "")))
	if t.is_empty():
		return
	var s := tourney_sys.settle(active_run, t, p)
	p.points += int(s["points"])
	p.money += int(s["money"])
	p.record["prize"] = int(p.record.get("prize", 0)) + int(s["money"])
	p.rep += int(s["rep"])
	p.fame += int(s["fame"])
	var place_now := int(s["place"])
	if tourney_sys.is_youth(t):
		p.record["best_youth"] = mini(int(p.record.get("best_youth", 999)), place_now)
	else:
		p.record["best_adult"] = mini(int(p.record.get("best_adult", 999)), place_now)
	if place_now == 1:
		p.record["champions"] = int(p.record.get("champions", 0)) + 1
		p.record["champions_in_year"] = int(p.record.get("champions_in_year", 0)) + 1
		var titles: Dictionary = p.record.get("titles", {})
		titles[str(t.get("tier", ""))] = int(titles.get(str(t.get("tier", "")), 0)) + 1
		p.record["titles"] = titles
		if tourney_sys.is_youth(t):
			p.recent_junior_titles += 1
	_push_feed("「%s」结束：%s。积分 %+d，奖金 %s。" % [
		str(t.get("n", "")), str(s["text"]), int(s["points"]), DataManager.fmt_money(int(s["money"]))])
	update_ranking()
	active_run["settled"] = s
	active_run["prize_money"] = int(s["money"])
	active_run["points_gain"] = int(s["points"])

func _physical_penalty() -> float:
	if p.age <= 16:
		return 1.30
	elif p.age <= 18:
		return 1.15
	return 1.0

# ---------------------------------------------------------------- 里程碑

func _add_milestone(title: String, text: String) -> void:
	milestones.push_front({"t": title, "d": text, "age": p.age, "year": p.year, "week": p.week})
	if milestones.size() > 40:
		milestones.resize(40)

## 在关键节点调用：只记一次，不重复刷屏
func milestone_once(key: String, title: String, text: String) -> void:
	for m in milestones:
		if str(m.get("t", "")) == title:
			return
	_add_milestone(title, text)
	EventBus.toast_requested.emit("里程碑 · " + title, "ok")

# ---------------------------------------------------------------- 成就

func _check_achievements() -> void:
	var newly := achv.check(p)
	if newly.is_empty():
		return
	for a in newly:
		pending_achievements.append(a)
		_push_feed("解锁成就【%s】—— %s" % [str(a.get("n", "")), str(a.get("d", ""))])
	# 一次解锁多项时只弹一条汇总，否则十几条 toast 会把整屏盖住
	if newly.size() == 1:
		EventBus.toast_requested.emit("成就 · %s" % str(newly[0].get("n", "")), "ok")
	else:
		EventBus.toast_requested.emit("解锁 %d 项成就" % newly.size(), "ok")

# ---------------------------------------------------------------- 排名

func update_ranking() -> void:
	var board := world.world_board()
	var my_pts := p.points
	var rank := 1
	for o in board:
		if int(o["points"]) > my_pts:
			rank += 1
	if my_pts <= 0:
		rank = 0
	p.rank = rank
	if rank > 0:
		p.best_rank = mini(p.best_rank, rank)
		if rank <= 10:
			p.record["top10_weeks"] = int(p.record.get("top10_weeks", 0)) + 1
		if rank == 1:
			p.record["top1_weeks"] = int(p.record.get("top1_weeks", 0)) + 1
	# 曝光度随排名上升
	if rank > 0 and rank <= 30:
		p.fame = mini(999, p.fame + 1)

# ---------------------------------------------------------------- 舆论涟漪

func _apply_forum_effect() -> void:
	var streak := int(p.record.get("loss_streak", 0))
	if streak >= 3:
		if not p.has_status("eager"):
			p.add_status({
				"id": "eager", "name": "急于证明自己", "weeks_left": 2,
				"form": -0.05, "mods": {"ovr": 1.0, "mental": -3.0},
			})
	elif p.rank > 0 and p.rank <= 5:
		if not p.has_status("roar"):
			p.add_status({
				"id": "roar", "name": "声浪加持", "weeks_left": 1,
				"form": 0.04, "mods": {"mental": 2.0},
			})

# ---------------------------------------------------------------- 生态挤压

func check_pressure() -> Dictionary:
	if p.age < 27:
		return {}
	var level := 0
	var notes: Array[String] = []
	if p.age >= 28 and p.rank > 20 and int(p.record.get("loss_streak", 0)) >= 2:
		level = 2
		notes.append("主教练找你谈话，说新的奥运周期开始了，队里打算让年轻人多打打。")
	elif p.age >= 29 and p.rank > 40:
		level = 1
		notes.append("器材商没有续约。你自己去店里买了新胶皮。")
	elif p.age >= 31:
		level = 1
		notes.append("训练完，膝盖要冰敷二十分钟才能下楼。")
	if level > 0:
		return {"level": level, "notes": notes, "week": p.week}
	return {}

func can_retire() -> bool:
	return p.age >= 23

func retire(ending_id: String = "farewell") -> void:
	phase = Phase.RETIRED
	var endings := {
		"farewell": "你在一个普通的下午收拾更衣柜，把带国旗的队服叠好，留给了那个常帮你捡球的小孩。",
		"veteran": "42 岁那年，你在一站挑战赛拿了冠军。没有转播，只有几个老球迷在论坛发帖：真神不老。",
		"doubles": "你专攻双打，靠手感和战术又撑了几年。最后一个世界冠军，是在混双拿的。",
		"bench": "你留在了省队当陪练。直到某天发现比你小的队友都拿了全运冠军，你才觉得索然无味。",
	}
	EventBus.player_retired.emit(str(endings.get(ending_id, endings["farewell"])), ending_id)
	ForumManager.generate_retire(p)
	_push_feed(str(endings.get(ending_id, endings["farewell"])))

# ---------------------------------------------------------------- 日志

func _push_feed(text: String) -> void:
	if text.strip_edges() == "":
		return
	feed.push_front({"text": text, "week": p.week, "year": p.year})
	if feed.size() > 80:
		feed.resize(80)

func recent_feed(n: int = 8) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(mini(n, feed.size())):
		out.append(feed[i])
	return out

# ---------------------------------------------------------------- 团体赛

func team_events() -> Array[Dictionary]:
	return team.team_events_for(p, p.week)

## 报名团体赛：建队 → 教练排阵 → 名单公布
func enter_team_event(ev: Dictionary) -> Dictionary:
	if phase != Phase.CAREER:
		return {}
	var my := team.build_my_team(p, world, p.stage)
	var opp := team.build_opp_team(world, float(ev.get("level", 60.0)), p.stage, p.ovr())
	var arr := team.arrange(p, my, opp, p.stage)
	team_run = team.start(my, opp, arr, int(ev.get("bo", 5)))
	team_run["event"] = ev
	team_run["note"] = str(arr.get("note", ""))
	team_run["controversial"] = bool(arr.get("controversial", false))
	var slot := int(arr.get("slot", 0))
	phase = Phase.TEAM
	ForumManager.generate_roster(TeamSystem.SLOT_NAME[slot], str(arr.get("note", "")), p, bool(arr.get("controversial", false)))
	_push_feed("团体赛「%s」名单公布：你打%s。" % [str(ev.get("n", "")), TeamSystem.SLOT_NAME[slot]])
	return team_run

## 推进一盘。返回 kind = player / auto / done
func team_step() -> Dictionary:
	if team_run.is_empty() or bool(team_run.get("done", false)):
		return {"kind": "done"}
	if team.is_player_turn(team_run):
		var opp := team.current_opponent(team_run)
		var rules := {
			"best_of": int(team_run.get("bo", 5)),
			"points_to_win": 11, "deuce_at": 10,
			"exchange_at_deciding": 5, "timeouts_per_match": 1,
		}
		engine = MatchEngine.new()
		engine.rng.seed = rng.randi()
		engine.setup(p.to_match_dict(), opp_match_dict(opp), rules)
		var ev: Dictionary = team_run.get("event", {})
		current_match = {
			"team": true,
			"tourney": str(ev.get("n", "团体赛")),
			"round_name": team.round_label(team_run),
			"opponent": opp,
			"rules": rules,
			"best_of": int(rules["best_of"]),
			"seed": engine.rng.seed,
			"slot": int(team_run.get("slot", 0)),
			"team_score": team_run.get("score", [0, 0]).duplicate(),
		}
		phase = Phase.MATCH
		EventBus.match_started.emit(current_match)
		return {"kind": "player", "ctx": current_match}

	var won := team.auto_play(team_run)
	team.resolve_game(team_run, won)
	phase = Phase.TEAM
	return {"kind": "auto", "won": won, "run": team_run}

func _conclude_team(won: bool) -> Dictionary:
	var opp: Dictionary = current_match.get("opponent", {})
	var slot := int(team_run.get("slot", 0))

	p.record["matches"] = int(p.record.get("matches", 0)) + 1
	p.record["matches_in_year"] = int(p.record.get("matches_in_year", 0)) + 1
	if won:
		p.record["wins"] = int(p.record.get("wins", 0)) + 1
		p.record["win_streak"] = int(p.record.get("win_streak", 0)) + 1
		p.record["max_win_streak"] = maxi(int(p.record.get("max_win_streak", 0)), int(p.record["win_streak"]))
		p.record["loss_streak"] = 0
	else:
		p.record["losses"] = int(p.record.get("losses", 0)) + 1
		p.record["loss_streak"] = int(p.record.get("loss_streak", 0)) + 1
		p.record["win_streak"] = 0

	p.record["critical_played"] = int(p.record.get("critical_played", 0)) + int(engine.stats["critical_played"])
	p.record["critical_won"] = int(p.record.get("critical_won", 0)) + int(engine.stats["critical_won"])

	var phys := _physical_penalty()
	if slot == 0:
		phys *= 1.5
	p.stamina_cur = clampf(p.stamina_cur - 8.5 * phys, 0.0, 100.0)
	p.fatigue = clampf(p.fatigue + 6.5 * phys, 0.0, 100.0)

	var before := int(team_run.get("score", [0, 0])[0]) - int(team_run.get("score", [0, 0])[1])
	team.resolve_game(team_run, won)

	var result := {
		"won": won,
		"opp_name": str(opp.get("name", "对手")),
		"opp_ovr": float(opp.get("ovr", 50.0)),
		"score": engine.match_score_text(),
		"upset": won and float(opp.get("ovr", 50.0)) > p.ovr() + 6.0,
		"tourney": str(team_run.get("event", {}).get("n", "团体赛")),
		"round_name": team.round_label(team_run),
		"place": 99,
		"stats": engine.stats.duplicate(true),
		"minutes": engine.total_minutes,
		"team": true,
		"team_score": team_run.get("score", [0, 0]).duplicate(),
	}
	last_result = result
	phase = Phase.TEAM
	week_major = false
	EventBus.match_finished.emit(result)
	_check_achievements()

	if bool(team_run.get("done", false)):
		_finish_team_event()
	return result

func _finish_team_event() -> void:
	var ev: Dictionary = team_run.get("event", {})
	var sc: Array = team_run.get("score", [0, 0])
	var won := int(sc[0]) > int(sc[1])
	var contribution := int(team_run.get("player_wins", 0))
	var scale := 1.0 if won else 0.38
	# 空砍：自己赢了两盘但队伍输了
	var empty_stats := (not won) and contribution >= 2
	var money := int(float(ev.get("prize", 0)) * scale)
	p.money += money
	p.rep += int(float(ev.get("rep", 0)) * scale)
	p.fame += int(float(ev.get("fame", 0)) * scale)
	if won:
		p.record["champions"] = int(p.record.get("champions", 0)) + 1
		p.record["champions_in_year"] = int(p.record.get("champions_in_year", 0)) + 1
		p.record["caps"] = int(p.record.get("caps", 0)) + 1

	team_run["settled"] = {
		"won": won, "score": sc.duplicate(), "money": money,
		"player_wins": contribution, "empty_stats": empty_stats,
	}
	_push_feed("团体赛「%s」结束：%d:%d，你拿了 %d 分。%s" % [
		str(ev.get("n", "")), int(sc[0]), int(sc[1]), contribution,
		"队伍赢了。" if won else ("你赢了两盘，但队伍还是输了。" if empty_stats else "队伍输了。")])
	ForumManager.generate_after_match({
		"won": won, "place": 1 if won else 5, "tourney": str(ev.get("n", "")),
		"opp_name": "对手", "score": "%d:%d" % [int(sc[0]), int(sc[1])],
		"upset": false, "final": true, "streak": 0,
	}, p)
	update_ranking()
	_check_achievements()

func leave_team() -> void:
	team_run = {}
	phase = Phase.CAREER

# ---------------------------------------------------------------- 存档

func snapshot() -> Dictionary:
	return {
		"player": p.to_dict(),
		"week": p.week, "year": p.year, "stage": p.stage, "age": p.age,
		"world": world.to_dict(),
		"gear": {"equipped": gear.equipped.duplicate(), "owned": gear.owned.duplicate()},
		"team_run": team_run.duplicate(true),
		"milestones": milestones.duplicate(true),
		"forum": ForumManager.threads.duplicate(true),
		"forum_heat": ForumManager.heat,
		"feed": feed.duplicate(true),
		"active_run": active_run.duplicate(true),
		"phase": int(phase),
	}

func save_to(s: int) -> bool:
	slot = s
	return DataManager.save_game(s, snapshot())

func load_from(s: int) -> bool:
	var state := DataManager.load_game(s)
	if state.is_empty():
		return false
	return restore(state)

## 从任意已解析的存档字典恢复（存档码导入也走这里）
func restore(state: Dictionary) -> bool:
	if state.is_empty():
		return false
	p = PlayerStats.new()
	p.from_dict(state.get("player", {}))
	world.from_dict(state.get("world", {}))
	var gd: Dictionary = state.get("gear", {})
	if not gd.is_empty():
		gear.equipped = gd.get("equipped", gear.equipped)
		gear.owned = gd.get("owned", gear.owned)
	apply_gear()
	team_run = state.get("team_run", {})
	milestones.clear()
	for m in state.get("milestones", []):
		milestones.append(m)
	achv.load_from_profile()
	achv.sanitize(p)
	ForumManager.reset()
	for t in state.get("forum", []):
		ForumManager.threads.append(t)
	ForumManager.heat = int(state.get("forum_heat", 0))
	feed.clear()
	for f in state.get("feed", []):
		feed.append(f)
	active_run = state.get("active_run", {})
	phase = Phase.CAREER
	return true
