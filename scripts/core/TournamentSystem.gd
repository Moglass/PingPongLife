class_name TournamentSystem
extends RefCounted
## 赛事系统（v0.8）：年龄不是墙，是一道要自己翻的坎。
## 三条越级通道：资格赛（稳、累）/ 外卡（快、不稳）/ 直通赛（硬、公平）。
## 签表用「强度递增」模型生成，玩家逐轮亲自打，其余场次自动模拟。

enum Channel { RANKING, QUALIFIER, WILDCARD, TRIAL, NONE }

const CHANNEL_NAME: Dictionary = {
	Channel.RANKING: "排名直通",
	Channel.QUALIFIER: "资格赛",
	Channel.WILDCARD: "外卡",
	Channel.TRIAL: "队内直通赛",
	Channel.NONE: "无资格",
}

const YOUTH_TIERS: Array[String] = ["ypy", "yp", "ync", "ynj", "ya", "yw", "ych"]
const ADULT_TIERS: Array[String] = ["feeder", "cont", "star", "champ", "major", "finals", "worldcup", "asia"]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

# ---------------------------------------------------------------- 资格

func is_youth(t: Dictionary) -> bool:
	return YOUTH_TIERS.has(str(t.get("tier", "")))

func in_window(t: Dictionary, week: int) -> bool:
	var w: Array = t.get("w", [1, 52])
	return week >= int(w[0]) and week <= int(w[1])

func age_ok(t: Dictionary, age: int) -> bool:
	var a: Array = t.get("age", [0, 99])
	return age >= int(a[0]) and age <= int(a[1])

## 该周可报名的赛事（按年龄窗口 + 阶段门槛）
func available(tourneys: Array, player: PlayerStats, week: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t in tourneys:
		if not in_window(t, week):
			continue
		if not age_ok(t, player.age):
			continue
		var min_stage := int(t.get("stage", 0))
		if player.stage < min_stage - 1:
			continue
		var entry: Dictionary = t.duplicate(true)
		entry["channels"] = entry_channels(t, player)
		entry["recommended"] = recommend_channel(t, player)
		out.append(entry)
	out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		return int(x.get("stage", 0)) > int(y.get("stage", 0))
	)
	return out

## 通道开放规则（文档 v0.8 第四节）
func entry_channels(t: Dictionary, p: PlayerStats) -> Array[int]:
	var out: Array[int] = []
	var adult := ADULT_TIERS.has(str(t.get("tier", "")))
	if not adult:
		out.append(Channel.RANKING)
		return out

	# 15 岁以下：教练不放心，需信任 >= 60 才能报资格赛
	if p.age < 15:
		if p.trust >= 60.0:
			out.append(Channel.QUALIFIER)
		if p.trust >= 72.0 and p.recent_junior_titles >= 2:
			out.append(Channel.WILDCARD)
		if p.trust >= 78.0 and p.recent_junior_titles >= 2:
			out.append(Channel.TRIAL)
		return out

	out.append(Channel.QUALIFIER)
	if p.age >= 15 or p.recent_junior_titles >= 2:
		var tier := str(t.get("tier", ""))
		if tier in ["star", "champ", "major", "finals"]:
			if p.trust >= 55.0 and p.recent_junior_titles >= 2:
				out.append(Channel.WILDCARD)
		else:
			out.append(Channel.WILDCARD)
	if p.stage >= 2 and p.trust >= 70.0:
		out.append(Channel.TRIAL)
	return out

func recommend_channel(t: Dictionary, p: PlayerStats) -> int:
	var ch := entry_channels(t, p)
	if ch.has(Channel.RANKING):
		return Channel.RANKING
	if ch.has(Channel.TRIAL) and p.trust >= 76.0:
		return Channel.TRIAL
	if ch.has(Channel.QUALIFIER):
		return Channel.QUALIFIER
	if ch.has(Channel.WILDCARD):
		return Channel.WILDCARD
	return Channel.NONE

## 通道代价：体能、信任、资金
func channel_cost(t: Dictionary, ch: int) -> Dictionary:
	var tier := str(t.get("tier", ""))
	var base_stam := 12.0
	if tier in ["major", "finals", "worldcup"]:
		base_stam = 26.0
	elif tier in ["champ", "star", "asia"]:
		base_stam = 20.0
	match ch:
		Channel.QUALIFIER:
			return {"stamina": base_stam * 0.55, "trust": -1.0, "money": -200, "text": "多打两轮资格赛，赢了才有正赛席位。"}
		Channel.WILDCARD:
			return {"stamina": 0.0, "trust": -4.0, "money": -400, "text": "外卡挤掉的是别人的名额，教练要替你担责。"}
		Channel.TRIAL:
			return {"stamina": base_stam * 0.4, "trust": 1.5, "money": 0, "text": "队内大循环，赢了直接拿走名额。"}
		_:
			return {"stamina": 0.0, "trust": 0.0, "money": 0, "text": "排名够，直接进正赛。"}

# ---------------------------------------------------------------- 签表

## 开一站比赛。返回 run 字典，由 GameManager 逐轮推进。
func start_run(t: Dictionary, ch: int, p: PlayerStats, world: NPCWorld) -> Dictionary:
	var draw := int(t.get("draw", 32))
	var rounds := int(round(log(float(draw)) / log(2.0)))
	if rounds < 1:
		rounds = 1
	var opponents: Array[Dictionary] = []
	var used: Dictionary = {}
	var youth := is_youth(t)
	# 青少年赛的对手是同龄人：以玩家实力为基准逐轮加码，而不是从成人池里抽
	var my_ovr := p.ovr()
	for i in range(rounds):
		var strength := lerpf(0.10, 0.94, float(i) / float(maxi(1, rounds - 1)))
		strength = clampf(strength * _tier_weight(t) + _tier_floor(t), 0.0, 1.0)
		var o: Dictionary
		if youth:
			var gap := lerpf(-10.0, 7.0, strength)
			o = world.make_temp_opponent(my_ovr + gap + randf_range(-3.0, 3.0), int(p.age + randf_range(-1.0, 1.0)))
		else:
			o = world.pick_opponent(strength, used)
		if o.is_empty():
			o = {"id": "fallback", "name": "无名选手", "ovr": 50.0, "weakness": ["mid"], "tactic": "target_bh", "style_name": "全面型", "age": 22}
		used[str(o.get("id", ""))] = true
		var copy: Dictionary = o.duplicate(true)
		# 轮次越深，对手状态越好
		copy["form"] = clampf(0.45 + float(i) * 0.05, 0.0, 0.85)
		opponents.append(copy)
	return {
		"tourney_id": str(t.get("id", "")),
		"name": str(t.get("n", "")),
		"tier": str(t.get("tier", "")),
		"draw": draw,
		"rounds": rounds,
		"round": 0,
		"channel": ch,
		"opponents": opponents,
		"bo": int(t.get("bo", 5)),
		"done": false,
		"place": 0,
		"wins": 0,
		"log": [],
	}

func _tier_weight(t: Dictionary) -> float:
	match str(t.get("tier", "")):
		"major", "finals", "worldcup", "asia":
			return 1.15
		"champ", "star":
			return 1.05
		"cont", "domestic":
			return 0.92
		"feeder", "ypy", "yp", "ync", "ynj", "ya", "yw", "ych":
			return 0.78
		_:
			return 0.9

func _tier_floor(t: Dictionary) -> float:
	match str(t.get("tier", "")):
		"major", "finals", "worldcup":
			return 0.18
		"champ", "asia":
			return 0.12
		"star":
			return 0.06
		_:
			return 0.0

func round_name(run: Dictionary) -> String:
	var left := int(run["rounds"]) - int(run["round"])
	var size := int(pow(2.0, float(left)))
	if size <= 2:
		return "决赛"
	if size == 4:
		return "半决赛"
	if size == 8:
		return "1/4 决赛"
	if size == 16:
		return "1/8 决赛"
	return "第 %d 轮" % (int(run["round"]) + 1)

func current_opponent(run: Dictionary) -> Dictionary:
	var idx := int(run["round"])
	var arr: Array = run.get("opponents", [])
	if idx >= 0 and idx < arr.size():
		return arr[idx]
	return {}

## 玩家打完一轮。won=true 晋级，false 淘汰。
func advance(run: Dictionary, won: bool) -> Dictionary:
	if bool(run.get("done", false)):
		return run
	if won:
		run["round"] = int(run["round"]) + 1
		run["wins"] = int(run["wins"]) + 1
		if int(run["round"]) >= int(run["rounds"]):
			run["done"] = true
			run["place"] = 1
	else:
		run["done"] = true
		var left := int(run["rounds"]) - int(run["round"])
		run["place"] = int(pow(2.0, float(left)))
	var log_arr: Array = run.get("log", [])
	log_arr.append({"round": int(run["round"]), "won": won})
	run["log"] = log_arr
	return run

static func place_label(place: int) -> String:
	match place:
		1: return "冠军"
		2: return "亚军"
		3, 4: return "四强"
		5, 6, 7, 8: return "八强"
		9, 10, 11, 12, 13, 14, 15, 16: return "十六强"
		17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32: return "三十二强"
		_: return "参赛"

## 结算：积分 / 奖金 / 声望
func settle(run: Dictionary, t: Dictionary, p: PlayerStats) -> Dictionary:
	var place := int(run.get("place", 99))
	var pts := DataManager.db.points_for(str(t.get("tier", "cont")), place - 1)
	var prize_scale := 1.0
	if place == 1:
		prize_scale = 1.0
	elif place == 2:
		prize_scale = 0.55
	elif place <= 4:
		prize_scale = 0.30
	elif place <= 8:
		prize_scale = 0.16
	elif place <= 16:
		prize_scale = 0.08
	else:
		prize_scale = 0.03
	var money := int(float(t.get("prize", 0)) * prize_scale)
	var rep := int(float(t.get("rep", 0)) * (1.0 if place <= 4 else 0.45))
	var fame := int(float(t.get("fame", 0)) * (1.0 if place <= 8 else 0.4))
	return {
		"place": place,
		"points": pts,
		"money": money,
		"rep": rep,
		"fame": fame,
		"text": place_label(place),
	}
