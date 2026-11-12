class_name TeamSystem
extends RefCounted
## 团体赛：5 盘 3 胜（斯韦思林杯赛制）。
## 核心不是「多打几场」，而是**排阵**——你被放在哪个位置，决定了你要承受什么。
##
## 盘次：1=A-X  2=B-Y  3=C-Z  4=A-Y  5=B-X
## 位置体验：一单打 1、4 盘（体能 ×1.5）；二单打 2、5 盘（田忌赛马）；
##          三单只打第 3 盘，但如果前两盘 0:2，这一盘就是悬崖。

const PAIR_ORDER: Array = [[0, 0], [1, 1], [2, 2], [0, 1], [1, 0]]
const SLOT_NAME: Array[String] = ["一单", "二单", "三单"]

## 各阶段的排阵权重（Ovr / Form / 外战 / 资历）
const WEIGHTS: Array[Dictionary] = [
	{"ovr": 0.20, "form": 0.50, "foreign": 0.00, "exp": 0.30, "coach": "护犊子型"},
	{"ovr": 0.40, "form": 0.30, "foreign": 0.00, "exp": 0.30, "coach": "数据型"},
	{"ovr": 0.50, "form": 0.30, "foreign": 0.00, "exp": 0.20, "coach": "人情型"},
	{"ovr": 0.30, "form": 0.30, "foreign": 0.40, "exp": 0.00, "coach": "保守型"},
	{"ovr": 0.40, "form": 0.20, "foreign": 0.00, "exp": 0.40, "coach": "资本型"},
	{"ovr": 0.30, "form": 0.20, "foreign": 0.50, "exp": 0.00, "coach": "数据型"},
]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

# ---------------------------------------------------------------- 建队

## 玩家的队伍：自己 + 两名队友。队友强度随阶段走，略低于玩家。
func build_my_team(p: PlayerStats, world: NPCWorld, stage: int) -> Array[Dictionary]:
	var mine := p.to_match_dict()
	mine["is_player"] = true
	mine["age"] = p.age
	mine["style_name"] = "你自己"
	var out: Array[Dictionary] = [mine]
	var base := p.ovr()
	for i in range(2):
		var gap := rng.randf_range(-12.0, -2.0)
		var mate := world.make_temp_opponent(base + gap, p.age + rng.randi_range(-2, 3))
		mate["is_player"] = false
		mate["tag"] = "队友"
		out.append(mate)
	return out

## 对手队伍：强度按赛事级别
func build_opp_team(world: NPCWorld, level: float, stage: int, my_ovr: float = 60.0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	# 赛事级别是「名义强度」，但实际对手要贴住玩家水平，
	# 否则低龄/高潜力玩家会被赛事级别直接碾死。
	var base := clampf(level, my_ovr - 5.0, my_ovr + 11.0)
	for i in range(3):
		var v := base + rng.randf_range(-6.0, 6.0) + float(i) * 1.5
		var o := world.make_temp_opponent(v, 18 + rng.randi_range(0, 10))
		o["is_player"] = false
		out.append(o)
	return out

# ---------------------------------------------------------------- 排阵

## 教练排阵。返回 {my_order, opp_order, slot, note, weights}
## my_order[i] = 我队第 i 号位（一/二/三单）在 team 里的下标
func arrange(p: PlayerStats, my_team: Array, opp_team: Array, stage: int) -> Dictionary:
	var w: Dictionary = WEIGHTS[clampi(stage, 0, WEIGHTS.size() - 1)]
	var my_scored: Array[Dictionary] = []
	for i in range(my_team.size()):
		var m: Dictionary = my_team[i]
		my_scored.append({"idx": i, "score": _rank_score(m, w, i == 0, p)})
	my_scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["score"]) > float(b["score"])
	)

	var opp_scored: Array[Dictionary] = []
	for i in range(opp_team.size()):
		opp_scored.append({"idx": i, "score": _rank_score(opp_team[i], w, false, p)})
	opp_scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["score"]) > float(b["score"])
	)

	var my_order: Array[int] = []
	for e in my_scored:
		my_order.append(int(e["idx"]))
	var opp_order: Array[int] = []
	for e in opp_scored:
		opp_order.append(int(e["idx"]))

	var slot := my_order.find(0)  # 玩家在 team 里的下标是 0
	return {
		"my_order": my_order,
		"opp_order": opp_order,
		"slot": maxi(0, slot),
		"weights": w,
		"note": _coach_note(stage, maxi(0, slot), p, opp_team),
		"controversial": _is_controversial(p, my_order, my_team),
	}

func _rank_score(m: Dictionary, w: Dictionary, is_player: bool, p: PlayerStats) -> float:
	var ovr := float(m.get("ovr", 50.0))
	var form := float(m.get("form", 0.5)) * 100.0
	var exp := clampf(float(m.get("age", p.age)) / 30.0 * 100.0, 0.0, 100.0)
	var foreign := 50.0
	if is_player:
		# 用世界排名近似「外战胜率」
		if p.rank > 0 and p.rank <= 100:
			foreign = 100.0 - float(p.rank) * 0.8
		else:
			foreign = 30.0
	else:
		foreign = clampf(ovr - 20.0, 0.0, 100.0)
	return ovr * float(w["ovr"]) + form * float(w["form"]) + foreign * float(w["foreign"]) + exp * float(w["exp"])

func _is_controversial(p: PlayerStats, my_order: Array[int], my_team: Array) -> bool:
	# 玩家实力明显强于排在他前面的人 → 舆论会炸
	var my_idx := my_order.find(0)
	if my_idx <= 0:
		return false
	var ahead: Dictionary = my_team[my_order[my_idx - 1]]
	return p.ovr() - float(ahead.get("ovr", 0)) > 6.0

func _coach_note(stage: int, slot: int, p: PlayerStats, opp_team: Array) -> String:
	var opp_name := str(opp_team[0].get("name", "对方一单")) if not opp_team.is_empty() else "对方一单"
	match stage:
		0:
			return "教练在小黑板上写下名字，拍了拍你：「在下面好好看，好好学。」" if slot == 2 else "教练说：「上去别怕，输了我担着。」"
		1:
			return "教练把你排到%s，想让你去抓对方二单。「这是给你机会。」" % SLOT_NAME[slot]
		2:
			return "老将还是一单。教练说：「论资历，还轮不到你。」" if slot != 0 else "教练第一次把你放在一单，全队都在看你。"
		3:
			return "教练反复看录像：「你外战稳，这场你顶。」" if slot == 0 else "教练把你藏在%s，想让你避开对方主力。" % SLOT_NAME[slot]
		4:
			return "俱乐部老板在看台上。教练说：「你是花钱买来的，必须拿两分。」" if slot == 0 else "教练按赞助商的意思排了阵。你没什么可说的。"
		_:
			return "总教练只说了一句：「%s，第一盘必须拿下，打崩他的士气。」" % SLOT_NAME[slot]

# ---------------------------------------------------------------- 开赛

func start(my_team: Array, opp_team: Array, arrangement: Dictionary, bo: int = 5) -> Dictionary:
	return {
		"my_team": my_team,
		"opp_team": opp_team,
		"my_order": arrangement.get("my_order", [0, 1, 2]),
		"opp_order": arrangement.get("opp_order", [0, 1, 2]),
		"slot": int(arrangement.get("slot", 0)),
		"note": str(arrangement.get("note", "")),
		"score": [0, 0],
		"idx": 0,
		"done": false,
		"bo": bo,
		"log": [],
		"player_games": 0,
		"player_wins": 0,
	}

## 当前盘的双方（team 下标）
func current_pair(run: Dictionary) -> Array[int]:
	var i := int(run.get("idx", 0))
	var po: Array = PAIR_ORDER[clampi(i, 0, PAIR_ORDER.size() - 1)]
	return [int(po[0]), int(po[1])]

## 当前盘是否轮到玩家
func is_player_turn(run: Dictionary) -> bool:
	var pr := current_pair(run)
	var my_order: Array = run["my_order"]
	return int(my_order[int(pr[0])]) == 0

func current_opponent(run: Dictionary) -> Dictionary:
	var pr := current_pair(run)
	var opp_order: Array = run["opp_order"]
	var opp_team: Array = run["opp_team"]
	var oi := int(opp_order[int(pr[1])])
	return opp_team[clampi(oi, 0, opp_team.size() - 1)]

func current_mate(run: Dictionary) -> Dictionary:
	var pr := current_pair(run)
	var my_order: Array = run["my_order"]
	var my_team: Array = run["my_team"]
	var mi := int(my_order[int(pr[0])])
	return my_team[clampi(mi, 0, my_team.size() - 1)]

func round_label(run: Dictionary) -> String:
	var i := int(run.get("idx", 0))
	return "第 %d 盘 · %s" % [i + 1, ["A-X", "B-Y", "C-Z", "A-Y", "B-X"][clampi(i, 0, 4)]]

## 结算一盘。won 表示我方赢。
func resolve_game(run: Dictionary, won: bool) -> Dictionary:
	var sc: Array = run["score"]
	if won:
		sc[0] = int(sc[0]) + 1
		if is_player_turn(run):
			run["player_wins"] = int(run.get("player_wins", 0)) + 1
	else:
		sc[1] = int(sc[1]) + 1
	if is_player_turn(run):
		run["player_games"] = int(run.get("player_games", 0)) + 1

	var log_arr: Array = run["log"]
	log_arr.append({
		"idx": int(run["idx"]),
		"label": round_label(run),
		"won": won,
		"mine": is_player_turn(run),
		"opp": str(current_opponent(run).get("name", "")),
	})
	run["log"] = log_arr
	run["score"] = sc
	run["idx"] = int(run["idx"]) + 1

	var need := int(run.get("bo", 5)) / 2 + 1
	if int(sc[0]) >= need or int(sc[1]) >= need or int(run["idx"]) >= 5:
		run["done"] = true
	return run

## 自动模拟一盘（非玩家盘），返回 won
func auto_play(run: Dictionary) -> bool:
	var mate := current_mate(run)
	var opp := current_opponent(run)
	var e := MatchEngine.new()
	e.rng.seed = rng.randi()
	e.setup(mate, opp, {"best_of": 5})
	e.simulate_remaining("target_bh", "steady")
	return e.winner == 0

# ---------------------------------------------------------------- 团体赛日历

## 团体赛按阶段出现，单独于个人赛事日历
const TEAM_EVENTS: Array[Dictionary] = [
	{"n": "市少儿团体赛", "w": [18, 19], "stage": 0, "level": 26.0, "bo": 5, "prize": 600, "rep": 5, "fame": 3,
	 "d": "三个小孩，一间旧馆，一块掉了漆的记分牌。"},
	{"n": "省少儿团体锦标赛", "w": [22, 23], "stage": 1, "level": 42.0, "bo": 5, "prize": 3000, "rep": 9, "fame": 5,
	 "d": "省队的教练坐在看台上，手里拿着名单。"},
	{"n": "省运会 · 团体", "w": [30, 31], "stage": 2, "level": 62.0, "bo": 5, "prize": 8000, "rep": 16, "fame": 9,
	 "d": "四年一次。省体育局的领导全来了。"},
	{"n": "亚洲青年锦标赛 · 团体", "w": [26, 27], "stage": 3, "level": 78.0, "bo": 5, "prize": 20000, "rep": 24, "fame": 14,
	 "d": "对面是日本队。看台上有人举着国旗。"},
	{"n": "全国锦标赛 · 团体", "w": [12, 13], "stage": 4, "level": 92.0, "bo": 5, "prize": 60000, "rep": 30, "fame": 18,
	 "d": "省队对省队，打的是编制和经费。"},
	{"n": "世界乒乓球团体锦标赛", "w": [20, 21], "stage": 5, "level": 106.0, "bo": 5, "prize": 300000, "rep": 60, "fame": 40,
	 "d": "几亿人在看。你打一单，意味着第一盘和第四盘都要上。"},
]

func team_events_for(p: PlayerStats, week: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in TEAM_EVENTS:
		var ev: Dictionary = e
		var w: Array = ev["w"]
		if week < int(w[0]) or week > int(w[1]):
			continue
		if int(ev.get("stage", 0)) > p.stage:
			continue
		# 只显示当前阶段及上一阶段的赛事，避免低龄打世乒赛
		if int(ev.get("stage", 0)) < p.stage - 1:
			continue
		out.append(ev)
	return out
