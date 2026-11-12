class_name MatchEngine
extends RefCounted
## 规则层：ITTF / WTT 手册落地的纯逻辑比赛引擎。
## 不含任何 UI、节点、Tween。逐分推进，由表现层决定「如何呈现」。
##
## 使用：
##   var e := MatchEngine.new()
##   e.setup(player_dict, opponent_dict, rules_dict)
##   while not e.finished:
##       var r := e.play_point(tactic, critical_choice)   # critical_choice 仅关键分有效
##       ...
##
## 设计要点：
## - 同一 RNG 序列下，沉浸档与跳过档结果完全一致（档位只影响呈现，不影响判定）。
## - 每分返回 events 数组，表现层按需消费；规则事件（换发/换边/擦汗/暂停/轮换发球）全部显式。

enum Speed { IMMERSIVE, TACTICAL, FAST, SKIP }

const TACTICS: Array[String] = ["rush_fh", "target_bh", "target_mid", "short_game"]
const TACTIC_NAMES: Dictionary = {
	"rush_fh": "发球抢攻",
	"target_bh": "压制反手",
	"target_mid": "攻击中路",
	"short_game": "摆短控台",
}
## 战术 -> 能命中的对手弱点标签
const TACTIC_COUNTER: Dictionary = {
	"rush_fh": ["serve_recv", "fh"],
	"target_bh": ["bh", "footwork"],
	"target_mid": ["mid", "footwork"],
	"short_game": ["touch", "fh"],
}

# ---- 规则（可由 MatchRules.tres 覆盖）----
var best_of: int = 5
var points_to_win: int = 11
var deuce_at: int = 10
var exchange_at_deciding: int = 5
var expedite_minutes: float = 10.0
var expedite_total_points: int = 18
var expedite_max_rally: int = 13
var timeouts_per_match: int = 1

# ---- 双方 ----
var a: Dictionary = {}
var b: Dictionary = {}

# ---- 比分状态 ----
var games: Array[int] = [0, 0]
var score: Array[int] = [0, 0]
var server: int = 0
var game_index: int = 0
var finished: bool = false
var winner: int = -1

# ---- 资源与节奏 ----
var stamina: Array[float] = [100.0, 100.0]
var timeouts: Array[int] = [1, 1]
var game_minutes: float = 0.0
var total_minutes: float = 0.0
var expedite_active: bool = false
var ends_swapped: bool = false

# ---- 统计（赛后复盘用）----
var stats: Dictionary = {}

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()
	_reset_stats()

func _reset_stats() -> void:
	stats = {
		"points_won": [0, 0],
		"errors": [0, 0],
		"winners": [0, 0],
		"max_rally": 0,
		"rally_total": 0,
		"tactic_hits": 0,
		"tactic_miss": 0,
		"critical_played": 0,
		"critical_won": 0,
		"critical_log": [],
		"games": [],
	}

## 开局。a = 玩家侧，b = 对手侧。
## 字典字段：name, ovr, attack, defense, control, physical, mental, form(0~1), weakness(Array), style(String)
func setup(player_side: Dictionary, opp_side: Dictionary, rules: Dictionary = {}) -> void:
	a = player_side.duplicate(true)
	b = opp_side.duplicate(true)
	best_of = int(rules.get("best_of", 5))
	points_to_win = int(rules.get("points_to_win", 11))
	deuce_at = int(rules.get("deuce_at", 10))
	exchange_at_deciding = int(rules.get("exchange_at_deciding", 5))
	timeouts_per_match = int(rules.get("timeouts_per_match", 1))
	games = [0, 0]
	score = [0, 0]
	game_index = 0
	finished = false
	winner = -1
	server = 0 if rng.randf() < 0.5 else 1
	stamina = [100.0, 100.0]
	timeouts = [timeouts_per_match, timeouts_per_match]
	game_minutes = 0.0
	total_minutes = 0.0
	expedite_active = false
	ends_swapped = false
	_reset_stats()

# ---------------------------------------------------------------- 查询

func games_needed() -> int:
	return int(best_of / 2) + 1

func is_deciding_game() -> bool:
	return games[0] == games_needed() - 1 and games[1] == games_needed() - 1

func is_game_point_for(side: int) -> bool:
	var other := 1 - side
	return score[side] >= points_to_win - 1 and score[side] > score[other]

func is_match_point_for(side: int) -> bool:
	return is_game_point_for(side) and games[side] == games_needed() - 1

func is_deuce() -> bool:
	return score[0] >= deuce_at and score[0] == score[1]

## 当前这一分是否属于「关键分」：9平 / 10平之后 / 局点 / 赛点
func is_critical() -> bool:
	if score[0] >= deuce_at and score[1] >= deuce_at:
		return true
	if score[0] == 9 and score[1] == 9:
		return true
	if is_game_point_for(0) or is_game_point_for(1):
		return true
	return false

func current_score_text() -> String:
	return "%d:%d" % [score[0], score[1]]

func match_score_text() -> String:
	return "%d:%d" % [games[0], games[1]]

# ---------------------------------------------------------------- 单分

## 打一分。tactic 见 TACTICS；critical_choice: "" / "rush" / "steady" / "timeout"
## 返回：{winner, score, games, events, finished, critical}
func play_point(tactic: String = "target_bh", critical_choice: String = "") -> Dictionary:
	var events: Array[Dictionary] = []
	if finished:
		return {"winner": -1, "score": score.duplicate(), "games": games.duplicate(), "events": events, "finished": true}

	var critical := is_critical()
	var choice := critical_choice

	# 暂停：在关键分使用，恢复体力 + 清除心理紧张，不直接改变本分概率
	if choice == "timeout":
		if timeouts[0] > 0:
			timeouts[0] -= 1
			stamina[0] = minf(100.0, stamina[0] + 9.0)
			events.append({"type": "timeout", "side": 0, "left": timeouts[0]})
		choice = "steady"

	var rally := _roll_rally(tactic)
	var p := _point_probability(tactic, critical, choice)
	var win_a := rng.randf() < p
	var winner_side := 0 if win_a else 1

	# 轮换发球法：13 板内未分出胜负，接发球方得分
	if expedite_active and rally > expedite_max_rally:
		winner_side = 1 - server
		rally = expedite_max_rally
		events.append({"type": "expedite_point", "side": winner_side})

	score[winner_side] += 1
	stats["points_won"][winner_side] += 1
	if winner_side == 0:
		stats["winners"][0] += 1
	else:
		stats["errors"][0] += 1
	stats["max_rally"] = maxi(int(stats["max_rally"]), rally)
	stats["rally_total"] = int(stats["rally_total"]) + rally
	if critical:
		stats["critical_played"] = int(stats["critical_played"]) + 1
		if winner_side == 0:
			stats["critical_won"] = int(stats["critical_won"]) + 1
		var clog: Array = stats["critical_log"]
		clog.append({
			"game": game_index + 1,
			"score": "%d:%d" % [score[0], score[1]],
			"choice": choice,
			"won": winner_side == 0,
			"rally": rally,
		})
		stats["critical_log"] = clog

	# 体力与时间
	var cost_a := _stamina_cost(rally, choice)
	stamina[0] = maxf(0.0, stamina[0] - cost_a)
	stamina[1] = maxf(0.0, stamina[1] - cost_a * 0.94)
	var spent := 0.34 + float(rally) * 0.055
	game_minutes += spent
	total_minutes += spent

	var point := {
		"type": "point",
		"winner": winner_side,
		"score": score.duplicate(),
		"games": games.duplicate(),
		"rally": rally,
		"critical": critical,
		"tactic": tactic,
		"choice": choice,
		"stamina": stamina.duplicate(),
		"time": total_minutes,
	}
	events.append(point)

	# 关键分叙事
	if critical and critical_choice != "":
		events.append({
			"type": "critical_result",
			"choice": critical_choice,
			"won": winner_side == 0,
			"text": _critical_text(critical_choice, winner_side == 0),
		})

	# 轮换发球法触发（一局 >= 10 分钟且总分 < 18）
	if not expedite_active and game_minutes >= expedite_minutes and (score[0] + score[1]) < expedite_total_points:
		expedite_active = true
		events.append({"type": "expedite_on", "text": "本局超过 10 分钟，裁判示意：轮换发球法。"})

	# 擦汗点：双方总分每 6 分
	var total_pts := score[0] + score[1]
	if total_pts > 0 and total_pts % 6 == 0:
		stamina[0] = minf(100.0, stamina[0] + 1.5)
		stamina[1] = minf(100.0, stamina[1] + 1.5)
		events.append({"type": "towel", "total": total_pts})

	# 换发：常规每 2 分；10 平后每 1 分
	var rotate := 1 if is_deuce() else 2
	if total_pts % rotate == 0:
		server = 1 - server
		events.append({"type": "serve_change", "server": server})

	# 决胜局 5 分换边
	if is_deciding_game() and not ends_swapped:
		if score[0] == exchange_at_deciding or score[1] == exchange_at_deciding:
			ends_swapped = true
			events.append({"type": "change_ends", "at": maxi(score[0], score[1])})

	# 局结束判定
	if _game_over(winner_side):
		games[winner_side] += 1
		events.append({
			"type": "game_end",
			"winner": winner_side,
			"score": score.duplicate(),
			"games": games.duplicate(),
		})
		stats["games"].append({"a": score[0], "b": score[1], "winner": winner_side})
		game_index += 1
		score = [0, 0]
		game_minutes = 0.0
		expedite_active = false
		ends_swapped = false
		server = 0 if (game_index % 2 == 0) else 1
		stamina[0] = minf(100.0, stamina[0] + 12.0)
		stamina[1] = minf(100.0, stamina[1] + 12.0)

		if games[0] >= games_needed() or games[1] >= games_needed():
			finished = true
			winner = 0 if games[0] > games[1] else 1
			events.append({"type": "match_end", "winner": winner, "games": games.duplicate()})

	return {
		"winner": winner_side,
		"score": score.duplicate(),
		"games": games.duplicate(),
		"events": events,
		"finished": finished,
	}

func _game_over(winner_side: int) -> bool:
	var s := score[winner_side]
	var o := score[1 - winner_side]
	if s < points_to_win:
		return false
	return s - o >= 2

func _roll_rally(tactic: String) -> int:
	var base := 4.4
	if tactic == "short_game":
		base = 3.1
	elif tactic == "rush_fh":
		base = 2.9
	var r := base + rng.randf_range(-2.0, 6.0)
	return clampi(int(round(r)), 1, 24)

func _stamina_cost(rally: int, choice: String) -> float:
	var base := 0.22 + float(rally) * 0.028
	if choice == "rush":
		base *= 1.35
	elif choice == "steady":
		base *= 0.82
	return base

## 单分胜率模型：底层实力差 + 战术克制 + 关键分心理 + 体力 + 状态。
func _point_probability(tactic: String, critical: bool, choice: String) -> float:
	var ovr_a := float(a.get("ovr", 50.0))
	var ovr_b := float(b.get("ovr", 50.0))

	# 体力不足时按比例抽走实力（"腿跟不上了"）
	var sa := _effective_ovr(a, stamina[0])
	var sb := _effective_ovr(b, stamina[1])

	var p := 0.5 + (sa - sb) * 0.0050

	# 战术克制：双向结算。玩家命中对手弱点，对手也会照着自己的球路打你。
	var a_hit := _tactic_hits(tactic, b)
	var b_tactic := str(b.get("tactic", "target_bh"))
	var b_hit := _tactic_hits(b_tactic, a)
	if a_hit:
		p += 0.045
		stats["tactic_hits"] = int(stats["tactic_hits"]) + 1
	else:
		stats["tactic_miss"] = int(stats["tactic_miss"]) + 1
	if b_hit:
		p -= 0.045

	# 状态（0~1，0.5 为中性）
	p += (float(a.get("form", 0.5)) - float(b.get("form", 0.5))) * 0.10

	# 关键分：心理属性决定收缩幅度
	if critical:
		var ma := float(a.get("mental", 50.0))
		var mb := float(b.get("mental", 50.0))
		p += (ma - mb) * 0.0022
		if choice == "rush":
			p += 0.075
		elif choice == "steady":
			p += 0.030
		# 主场/客场氛围由调用方通过 form / mental 间接体现

	# 经验与年龄：低龄打成人赛的隐性代价（由调用方塞进 ovr 或这里读字段）
	p += float(a.get("big_match_bonus", 0.0)) - float(b.get("big_match_bonus", 0.0))

	return clampf(p, 0.16, 0.84)

func _effective_ovr(side: Dictionary, st: float) -> float:
	var ovr := float(side.get("ovr", 50.0))
	if st >= 45.0:
		return ovr
	var penalty := (45.0 - st) / 45.0 * 0.16  # 最多 -16%
	return ovr * (1.0 - penalty)

func _tactic_hits(tactic: String, target: Dictionary) -> bool:
	var counters: Array = TACTIC_COUNTER.get(tactic, [])
	for w in target.get("weakness", []):
		if counters.has(str(w)):
			return true
	return false

func _critical_text(choice: String, won: bool) -> String:
	match choice:
		"rush":
			return "你侧身抢冲，球擦着边线落下。" if won else "你强行搏杀，球拉出了界外。"
		"steady":
			return "你稳住节奏，多拍之后对手先失误。" if won else "你压住节奏，却被对手一板抽穿。"
		_:
			return "这一分拿下了。" if won else "这一分丢了。"

# ---------------------------------------------------------------- 整场

## 自动打完剩余分数（快进 / 跳过档）。auto_critical 决定关键分如何选。
func simulate_remaining(tactic: String = "target_bh", auto_critical: String = "steady") -> Dictionary:
	var guard := 0
	while not finished and guard < 600:
		var choice := ""
		if is_critical():
			choice = auto_critical
		play_point(tactic, choice)
		guard += 1
	return {
		"winner": winner,
		"games": games.duplicate(),
		"stats": stats,
		"minutes": total_minutes,
	}

func summary() -> Dictionary:
	return {
		"winner": winner,
		"games": games.duplicate(),
		"stats": stats,
		"minutes": total_minutes,
		"best_of": best_of,
		"expedite": expedite_active,
	}
