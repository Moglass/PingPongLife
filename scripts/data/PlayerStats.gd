class_name PlayerStats
extends Resource
## 玩家状态资源（v0.8）。
## 设计原则：20+ 个底层数值只用于计算，UI 常态只暴露「四维 + Ovr」。
## 存档通过 to_dict()/from_dict() 走 JSON；运行时直接作为对象使用。
##
## 六属性：力量 / 速度 / 耐力 / 手感 / 战术 / 心理
## 七技术：发球 / 接发球 / 台内 / 正手 / 反手 / 防守 / 步法

@export_group("身份")
@export var player_name: String = "陈默"
@export var age: int = 8
@export var stage: int = 0
@export var year: int = 2010
@export var week: int = 1
## v0.81 时间流：一周 7 天，从 1 开始
@export var day: int = 1
## 伤病剩余天数（7 天折 1 周，与 injury_weeks 并行记录）
@export var injury_days: int = 0
## 周排程：周一到周日各做什么。空字符串表示自由活动。
@export var schedule: Array[String] = ["tech", "tech", "fit", "tech", "fit", "rest", "study"]

@export_group("六属性")
@export var power: float = 10.0
@export var speed: float = 10.0
@export var stamina: float = 12.0
@export var touch: float = 10.0
@export var tactic: float = 8.0
@export var mental: float = 12.0

@export_group("七技术")
@export var tech_serve: float = 6.0
@export var tech_receive: float = 6.0
@export var tech_short: float = 6.0
@export var tech_fh: float = 8.0
@export var tech_bh: float = 7.0
@export var tech_def: float = 6.0
@export var tech_foot: float = 7.0

@export_group("资源")
@export var money: int = 0
@export var rep: int = 8
@export var fame: int = 0
@export var trust: float = 40.0
@export var break_pts: int = 0
@export var ap: int = 3
@export var ap_max: int = 3

@export_group("身体与状态")
@export var stamina_cur: float = 100.0
@export var fatigue: float = 0.0
@export var injury_weeks: int = 0
@export var form_noise: float = 0.0

@export_group("排名")
@export var rank: int = 0
@export var points: int = 0
@export var best_rank: int = 999
@export var recent_junior_titles: int = 0

@export_group("流派权重（隐藏）")
@export var weight_monster: float = 0.0
@export var weight_normal: float = 0.0
@export var weight_late: float = 0.0

## 器材加成（由 GameManager.apply_gear 写入，derive() 时叠加）
var gear_bonus: Dictionary = {"atk": 0.0, "ctrl": 0.0, "defn": 0.0, "mob": 0.0}

var status_effects: Array[Dictionary] = []
var traits: Array[String] = []
var record: Dictionary = {}
var weakness: Array[String] = []
var big_match_bonus: float = 0.0

const ATTR_KEYS: Array[String] = ["power", "speed", "stamina", "touch", "tactic", "mental"]
const TECH_KEYS: Array[String] = ["serve", "receive", "short", "fh", "bh", "def", "foot"]

func _init() -> void:
	record = blank_record()

static func blank_record() -> Dictionary:
	return {
		"matches": 0, "wins": 0, "losses": 0, "champions": 0, "finals": 0,
		"win_streak": 0, "max_win_streak": 0, "loss_streak": 0,
		"titles": {}, "prize": 0, "injuries": 0, "seasons": 0,
		"top10_weeks": 0, "top1_weeks": 0, "wtt_titles": 0,
		"comebacks": 0, "critical_won": 0, "critical_played": 0,
		# 训练与日常
		"trains": 0, "tech_sessions": 0, "fit_sessions": 0, "psy_sessions": 0,
		"tac_sessions": 0, "rest_weeks": 0, "study": 0,
		# 赛事与名次
		"caps": 0, "goals": 0, "subs": 0,
		"best_adult": 999, "best_youth": 999, "best_domestic": 999, "opp_met": 0,
		"matches_in_year": 0, "champions_in_year": 0,
		# 细节
		"deuce_wins": 0, "deuce_games": 0, "perfect_games": 0,
		"pair_wins": 0, "pair_matches": 0, "max_rivalry": 0,
		"break_ok": 0, "break_try": 0,
		"wins_vs_top100": 0, "wins_vs_top50": 0, "wins_vs_top10": 0,
	}

# ---------------------------------------------------------------- 派生

## 四维与 Ovr。UI 常态只显示这五个数。
func derive() -> Dictionary:
	var atk := (tech_fh * 0.44 + tech_bh * 0.28 + tech_short * 0.12) * 0.66 + power * 0.34 + float(gear_bonus.get("atk", 0.0))
	var ctrl := (tech_serve * 0.34 + tech_receive * 0.40 + tech_short * 0.12) * 0.66 + touch * 0.34 + float(gear_bonus.get("ctrl", 0.0))
	var defn := (tech_def * 0.58 + tech_foot * 0.30) * 0.66 + stamina * 0.34 + float(gear_bonus.get("defn", 0.0))
	var mob := tech_foot * 0.60 + speed * 0.40 + float(gear_bonus.get("mob", 0.0))
	var ovr := atk * 0.30 + ctrl * 0.24 + defn * 0.18 + mob * 0.13 + tactic * 0.08 + mental * 0.07
	return {"atk": atk, "ctrl": ctrl, "defn": defn, "mob": mob, "ovr": ovr, "mental": mental}

func ovr() -> float:
	return float(derive()["ovr"])

func radar() -> Array[float]:
	var d := derive()
	return [float(d["atk"]), float(d["defn"]), float(d["ctrl"]), float(d["mob"]), mental]

## 年龄硬上限：限制的是单项数值能长到多高，不是能不能参赛。
func ladder_cap(a: int = -1) -> float:
	var age_v := age if a < 0 else a
	var cap := 124.0
	if age_v <= 10:
		cap = 46.0
	elif age_v <= 12:
		cap = 56.0
	elif age_v <= 14:
		cap = 70.0
	elif age_v <= 16:
		cap = 84.0
	elif age_v <= 18:
		cap = 96.0
	elif age_v <= 21:
		cap = 108.0
	elif age_v <= 26:
		cap = 124.0
	elif age_v <= 29:
		cap = 120.0
	elif age_v <= 32:
		cap = 112.0
	elif age_v <= 35:
		cap = 104.0
	else:
		cap = 96.0
	return cap

## 年龄对成长速度的乘数（越接近天花板越慢，30 岁后转负）
func growth_mul() -> float:
	if age <= 12:
		return 1.25
	if age <= 16:
		return 1.18
	if age <= 21:
		return 1.0
	if age <= 26:
		return 0.72
	if age <= 29:
		return 0.35
	return -0.25

func form_value() -> float:
	## 返回 -1.0 ~ 1.0
	var f := (stamina_cur - 62.0) / 40.0 - fatigue / 55.0 + form_noise
	if injury_weeks > 0:
		f -= 0.7
	for e in status_effects:
		f += float(e.get("form", 0.0))
	return clampf(f, -1.0, 1.0)

func form_label() -> Dictionary:
	var f := form_value()
	if f >= 0.45:
		return {"t": "巅峰", "c": "#c0392b"}
	if f >= 0.12:
		return {"t": "良好", "c": "#2c6e8f"}
	if f > -0.28:
		return {"t": "一般", "c": "#7a7268"}
	return {"t": "低迷", "c": "#8b8b8b"}

# ---------------------------------------------------------------- 成长

## 指数成长曲线：80 以后每一点都需要更多训练量。
func add_attr(key: String, base_exp: float) -> float:
	var cur := get_attr(key)
	var cap := ladder_cap()
	var mul := 1.0
	if cur > 78.0:
		mul = pow((cur - 72.0) / 6.0, 1.45)
	var gain := base_exp * growth_mul() / mul
	var next: float = minf(cur + gain, cap)
	set_attr(key, next)
	return next - cur

func add_tech(key: String, base_exp: float) -> float:
	var cur := get_tech(key)
	var cap := ladder_cap() * 1.06
	var mul := 1.0
	if cur > 80.0:
		mul = pow((cur - 74.0) / 6.0, 1.5)
	var gain := base_exp * growth_mul() / mul
	var next: float = minf(cur + gain, cap)
	set_tech(key, next)
	return next - cur

func get_attr(key: String) -> float:
	return float(get(key))

func set_attr(key: String, v: float) -> void:
	set(key, clampf(v, 1.0, ladder_cap()))

func get_tech(key: String) -> float:
	return float(get("tech_" + key))

func set_tech(key: String, v: float) -> void:
	set("tech_" + key, clampf(v, 1.0, ladder_cap() * 1.06))

func decay_for_age() -> void:
	if age < 28:
		return
	var loss := 0.55 + float(age - 28) * 0.22
	stamina = maxf(1.0, stamina - loss * 1.2)
	speed = maxf(1.0, speed - loss)
	power = maxf(1.0, power - loss * 0.55)
	tactic = minf(124.0, tactic + loss * 0.08)

# ---------------------------------------------------------------- 周结算

func tick_week() -> Dictionary:
	var notes: Dictionary = {}
	var recovery := 18.0 + stamina * 0.12
	if injury_weeks > 0:
		injury_weeks -= 1
		recovery *= 0.45
		notes["injury"] = injury_weeks
	# 年龄越大恢复越慢
	if age >= 28:
		recovery *= maxf(0.45, 1.0 - float(age - 27) * 0.06)
	stamina_cur = minf(100.0, stamina_cur + recovery)
	fatigue = maxf(0.0, fatigue - 6.0)
	form_noise = rng_noise()

	var expired: Array[String] = []
	for i in range(status_effects.size() - 1, -1, -1):
		var e: Dictionary = status_effects[i]
		e["weeks_left"] = int(e.get("weeks_left", 0)) - 1
		if int(e["weeks_left"]) <= 0:
			expired.append(str(e.get("name", "")))
			status_effects.remove_at(i)
	notes["expired"] = expired
	notes["stamina"] = stamina_cur
	return notes

func rng_noise() -> float:
	return randf_range(-0.10, 0.10)

func add_status(effect: Dictionary) -> void:
	for i in range(status_effects.size()):
		if str(status_effects[i].get("id", "")) == str(effect.get("id", "")):
			status_effects[i] = effect
			return
	status_effects.append(effect)
	EventBus.status_effect_changed.emit(status_effects.duplicate(true))

func has_status(id: String) -> bool:
	for e in status_effects:
		if str(e.get("id", "")) == id:
			return true
	return false

func status_mod(key: String) -> float:
	var sum := 0.0
	for e in status_effects:
		var mods: Dictionary = e.get("mods", {})
		sum += float(mods.get(key, 0.0))
	return sum

# ---------------------------------------------------------------- 比赛适配

## 转成 MatchEngine 需要的字典格式
func to_match_dict() -> Dictionary:
	var d := derive()
	return {
		"name": player_name,
		"ovr": float(d["ovr"]) + status_mod("ovr"),
		"attack": float(d["atk"]),
		"defense": float(d["defn"]),
		"control": float(d["ctrl"]),
		"physical": float(d["mob"]),
		"mental": mental + status_mod("mental"),
		"form": (form_value() + 1.0) * 0.5,
		"weakness": weakness.duplicate(),
		"stamina": stamina_cur,
		"big_match_bonus": big_match_bonus,
	}

# ---------------------------------------------------------------- 序列化

func to_dict() -> Dictionary:
	return {
		"player_name": player_name, "age": age, "stage": stage, "year": year, "week": week, "day": day,
		"injury_days": injury_days, "schedule": schedule.duplicate(),
		"power": power, "speed": speed, "stamina": stamina, "touch": touch, "tactic": tactic, "mental": mental,
		"tech_serve": tech_serve, "tech_receive": tech_receive, "tech_short": tech_short,
		"tech_fh": tech_fh, "tech_bh": tech_bh, "tech_def": tech_def, "tech_foot": tech_foot,
		"money": money, "rep": rep, "fame": fame, "trust": trust, "break_pts": break_pts,
		"ap": ap, "ap_max": ap_max,
		"stamina_cur": stamina_cur, "fatigue": fatigue, "injury_weeks": injury_weeks,
		"form_noise": form_noise, "rank": rank, "points": points, "best_rank": best_rank,
		"recent_junior_titles": recent_junior_titles,
		"weight_monster": weight_monster, "weight_normal": weight_normal, "weight_late": weight_late,
		"status_effects": status_effects.duplicate(true),
		"traits": traits.duplicate(),
		"record": record.duplicate(true),
		"weakness": weakness.duplicate(),
		"big_match_bonus": big_match_bonus,
	}

func from_dict(d: Dictionary) -> void:
	player_name = str(d.get("player_name", "陈默"))
	age = int(d.get("age", 8))
	stage = int(d.get("stage", 0))
	year = int(d.get("year", 2010))
	week = int(d.get("week", 1))
	day = int(d.get("day", 1))
	injury_days = int(d.get("injury_days", 0))
	var sch: Array = d.get("schedule", [])
	if sch.size() == 7:
		schedule.clear()
		for x in sch:
			schedule.append(str(x))
	for k in ATTR_KEYS:
		set(k, float(d.get(k, 10.0)))
	for k in TECH_KEYS:
		set("tech_" + k, float(d.get("tech_" + k, 6.0)))
	money = int(d.get("money", 0))
	rep = int(d.get("rep", 8))
	fame = int(d.get("fame", 0))
	trust = float(d.get("trust", 40.0))
	break_pts = int(d.get("break_pts", 0))
	ap = int(d.get("ap", 3))
	ap_max = int(d.get("ap_max", 3))
	stamina_cur = float(d.get("stamina_cur", 100.0))
	fatigue = float(d.get("fatigue", 0.0))
	injury_weeks = int(d.get("injury_weeks", 0))
	form_noise = float(d.get("form_noise", 0.0))
	rank = int(d.get("rank", 0))
	points = int(d.get("points", 0))
	best_rank = int(d.get("best_rank", 999))
	recent_junior_titles = int(d.get("recent_junior_titles", 0))
	weight_monster = float(d.get("weight_monster", 0.0))
	weight_normal = float(d.get("weight_normal", 0.0))
	weight_late = float(d.get("weight_late", 0.0))
	status_effects.clear()
	for e in d.get("status_effects", []):
		status_effects.append(e)
	traits.assign(d.get("traits", []))
	record = d.get("record", blank_record())
	weakness.assign(d.get("weakness", []))
	big_match_bonus = float(d.get("big_match_bonus", 0.0))
