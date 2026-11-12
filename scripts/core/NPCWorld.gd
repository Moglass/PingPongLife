class_name NPCWorld
extends RefCounted
## 双轨制对手池（v0.8）。
## Tier1：约 15 名具名 NPC（宿敌 / 同期 / 大魔王），有完整属性与历史交手。
## Tier2：220 人的生态池，只保留「名字 / 国籍 / 年龄 / 打法 / Ovr / 积分」，
##        每年年末新陈代谢：成长、衰退、退役、新血注入。
## 存档只存字典，不依赖节点。

const TIER2_SIZE: int = 220
const RETIRE_AGE: int = 34

var list: Array[Dictionary] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _used_names: Dictionary = {}
var _next_id: int = 1

## 打法：决定弱点与默认战术
const STYLES: Array[Dictionary] = [
	{"k": "loop", "n": "两面弧圈", "weak": ["mid"], "tactic": "target_mid", "atk": 1.08, "def": 0.96},
	{"k": "fh", "n": "正手强攻", "weak": ["bh"], "tactic": "target_bh", "atk": 1.12, "def": 0.90},
	{"k": "bh", "n": "反手体系", "weak": ["fh"], "tactic": "rush_fh", "atk": 1.06, "def": 0.98},
	{"k": "chop", "n": "削球防守", "weak": ["short"], "tactic": "short_game", "atk": 0.86, "def": 1.18},
	{"k": "block", "n": "快攻挡拨", "weak": ["footwork"], "tactic": "target_bh", "atk": 1.02, "def": 1.02},
	{"k": "all", "n": "全面型", "weak": ["serve_recv"], "tactic": "rush_fh", "atk": 1.0, "def": 1.0},
	{"k": "pips", "n": "怪胶", "weak": ["touch"], "tactic": "short_game", "atk": 0.94, "def": 1.08},
]

## Tier1：具名角色。ovr 是 18 岁时的基准，实际按年龄曲线浮动。
const TIER1_DEFS: Array[Dictionary] = [
	{"id": "t1_lin", "name": "林致远", "country": "CHN", "age": 9, "base": 16.0, "peak": 24, "style": "loop", "tag": "同门师兄", "rival": 0},
	{"id": "t1_zhou", "name": "周牧", "country": "CHN", "age": 11, "base": 34.0, "peak": 25, "style": "fh", "tag": "省队一单", "rival": 2},
	{"id": "t1_xu", "name": "许听澜", "country": "CHN", "age": 14, "base": 62.0, "peak": 26, "style": "all", "tag": "国青主力", "rival": 4},
	{"id": "t1_shen", "name": "沈拓", "country": "CHN", "age": 17, "base": 82.0, "peak": 24, "style": "bh", "tag": "直通赛对手", "rival": 6},
	{"id": "t1_chen", "name": "陈野", "country": "CHN", "age": 21, "base": 98.0, "peak": 25, "style": "fh", "tag": "国家队一单", "rival": 8},
	{"id": "t1_gao", "name": "高木隼", "country": "JPN", "age": 9, "base": 18.0, "peak": 23, "style": "bh", "tag": "宿敌", "rival": 10},
	{"id": "t1_ito", "name": "伊藤凑", "country": "JPN", "age": 15, "base": 70.0, "peak": 22, "style": "block", "tag": "日本天才", "rival": 7},
	{"id": "t1_lucas", "name": "卢卡斯·贝格", "country": "DEU", "age": 18, "base": 88.0, "peak": 27, "style": "loop", "tag": "欧洲一哥", "rival": 5},
	{"id": "t1_hugo", "name": "雨果·勒克莱尔", "country": "FRA", "age": 16, "base": 74.0, "peak": 24, "style": "all", "tag": "法国新星", "rival": 3},
	{"id": "t1_erik", "name": "埃里克·林德", "country": "SWE", "age": 24, "base": 96.0, "peak": 26, "style": "chop", "tag": "削球大师", "rival": 4},
	{"id": "t1_park", "name": "朴叙俊", "country": "KOR", "age": 19, "base": 88.0, "peak": 25, "style": "fh", "tag": "韩国主力", "rival": 5},
	{"id": "t1_ivan", "name": "伊万·诺瓦克", "country": "CZE", "age": 27, "base": 92.0, "peak": 27, "style": "pips", "tag": "怪胶老将", "rival": 3},
	{"id": "t1_wang", "name": "王砚", "country": "CHN", "age": 31, "base": 100.0, "peak": 28, "style": "all", "tag": "上一代大魔王", "rival": 9},
	{"id": "t1_mei", "name": "梅川千夏", "country": "JPN", "age": 13, "base": 48.0, "peak": 22, "style": "block", "tag": "少女天才", "rival": 2},
	{"id": "t1_alex", "name": "亚历克斯·吴", "country": "USA", "age": 20, "base": 86.0, "peak": 26, "style": "loop", "tag": "美洲冠军", "rival": 2},
]

const COUNTRIES: Array[Dictionary] = [
	{"c": "CHN", "w": 42}, {"c": "JPN", "w": 14}, {"c": "DEU", "w": 8},
	{"c": "KOR", "w": 7}, {"c": "FRA", "w": 6}, {"c": "SWE", "w": 4},
	{"c": "USA", "w": 4}, {"c": "BRA", "w": 3}, {"c": "TPE", "w": 3},
	{"c": "HKG", "w": 2}, {"c": "SGP", "w": 2}, {"c": "CZE", "w": 2},
	{"c": "POR", "w": 2}, {"c": "IND", "w": 1},
]

func build(seed_value: int) -> void:
	rng.seed = seed_value
	list.clear()
	_used_names.clear()
	_next_id = 1
	for d in TIER1_DEFS:
		var o := _make_tier1(d)
		list.append(o)
	for i in range(TIER2_SIZE):
		var age := rng.randi_range(15, 33)
		var peak := rng.randi_range(21, 27)
		var potential := _potential_for_rank(i)
		list.append(_make_tier2(age, peak, potential, false))
	_recalc_points()

func _potential_for_rank(i: int) -> float:
	# 靠前的名额更强：0 -> 112, 219 -> 46
	var t := float(i) / float(TIER2_SIZE)
	return lerpf(112.0, 46.0, pow(t, 0.82))

func _make_tier1(d: Dictionary) -> Dictionary:
	var style := _style_by_key(str(d["style"]))
	var o := {
		"id": str(d["id"]),
		"name": str(d["name"]),
		"country": str(d["country"]),
		"age": int(d["age"]),
		"peak": int(d["peak"]),
		"base": float(d["base"]),
		"tier": 1,
		"style": style["k"],
		"style_name": style["n"],
		"weakness": style["weak"].duplicate(),
		"tactic": style["tactic"],
		"rivalry": int(d["rival"]),
		"tag": str(d["tag"]),
		"ovr": 0.0,
		"points": 0,
		"retired": false,
		"record": {"wins": 0, "losses": 0},
	}
	o["ovr"] = _ovr_at_age(o, int(d["age"]))
	return o

func _make_tier2(age: int, peak: int, potential: float, is_new: bool) -> Dictionary:
	var country := _roll_country()
	var nm := DataManager.db.gen_name(country, _used_names, rng)
	var style: Dictionary = STYLES[rng.randi_range(0, STYLES.size() - 1)]
	var o := {
		"id": "g%d" % _next_id,
		"name": nm,
		"country": country,
		"age": age,
		"peak": peak,
		"base": potential,
		"tier": 2,
		"style": style["k"],
		"style_name": style["n"],
		"weakness": style["weak"].duplicate(),
		"tactic": style["tactic"],
		"rivalry": 0,
		"tag": "新人" if is_new else "",
		"ovr": 0.0,
		"points": 0,
		"retired": false,
		"record": {"wins": 0, "losses": 0},
	}
	_next_id += 1
	o["ovr"] = _ovr_at_age(o, age)
	return o

func _roll_country() -> String:
	var total := 0
	for c in COUNTRIES:
		total += int(c["w"])
	var r := rng.randi_range(1, total)
	var acc := 0
	for c in COUNTRIES:
		acc += int(c["w"])
		if r <= acc:
			return str(c["c"])
	return "CHN"

func _style_by_key(k: String) -> Dictionary:
	for s in STYLES:
		if str(s["k"]) == k:
			return s
	return STYLES[0]

## 年龄曲线：16 岁前陡升，peak 附近封顶，30 后不可逆下滑。
func _ovr_at_age(o: Dictionary, age: int) -> float:
	var base := float(o.get("base", 60.0))
	var peak := int(o.get("peak", 25))
	var v := 0.0
	if age < peak:
		var t := clampf(float(age - 12) / float(maxi(1, peak - 12)), 0.0, 1.0)
		v = base * (0.34 + 0.66 * pow(t, 0.72))
	else:
		var over := float(age - peak)
		v = base * maxf(0.52, 1.0 - over * 0.028)
	if age < 15:
		v *= 0.92
	return clampf(v, 6.0, 126.0)

func _recalc_points() -> void:
	# 积分只是 Ovr 的排名投影，用于世界榜排序与种子
	for o in list:
		if bool(o.get("retired", false)):
			continue
		var ovr := float(o["ovr"])
		o["points"] = int(pow(maxf(0.0, ovr - 40.0), 2.1) * 3.0)

## 每年年末调用：成长 / 衰退 / 退役 / 新血。
func tick_year(year: int) -> Dictionary:
	var retired: Array[String] = []
	var born := 0
	for o in list:
		o["age"] = int(o["age"]) + 1
		o["ovr"] = _ovr_at_age(o, int(o["age"]))
		if int(o["age"]) >= RETIRE_AGE and rng.randf() < 0.55:
			o["retired"] = true
			if int(o["tier"]) == 1 or float(o["ovr"]) > 88.0:
				retired.append(str(o["name"]))
	# 清出退役者，注入新血
	var alive: Array[Dictionary] = []
	for o in list:
		if not bool(o.get("retired", false)):
			alive.append(o)
	var need := TIER2_SIZE + TIER1_DEFS.size() - alive.size()
	for i in range(need):
		var age := rng.randi_range(15, 17)
		var peak := rng.randi_range(21, 26)
		alive.append(_make_tier2(age, peak, rng.randf_range(44.0, 88.0), true))
		born += 1
	list = alive
	_recalc_points()
	return {"retired": retired, "newcomers": born, "year": year}

func by_id(id: String) -> Dictionary:
	for o in list:
		if str(o["id"]) == id:
			return o
	return {}

func active() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in list:
		if not bool(o.get("retired", false)):
			out.append(o)
	return out

## 世界排名（不含玩家）。玩家排名由外部插入计算。
func world_board() -> Array[Dictionary]:
	var arr := active()
	arr.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		return int(x["points"]) > int(y["points"])
	)
	for i in range(arr.size()):
		arr[i]["rank"] = i + 1
	return arr

## 抽取一个符合轮次强度的对手。strength 0..1 表示签表位置（越大越强）。
func pick_opponent(strength: float, exclude: Dictionary = {}) -> Dictionary:
	var pool := active()
	var want := lerpf(22.0, 120.0, clampf(strength, 0.0, 1.0))
	var best: Dictionary = {}
	var best_d := 999.0
	for i in range(14):
		var o: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		if exclude.has(str(o["id"])):
			continue
		var d := absf(float(o["ovr"]) - want)
		if d < best_d:
			best_d = d
			best = o
	if best.is_empty() and pool.size() > 0:
		best = pool[0]
	return best

## 青少年赛事专用：生成一个同龄临时对手，打完即弃，不进池子。
func make_temp_opponent(target_ovr: float, age: int) -> Dictionary:
	var country := _roll_country()
	var nm := DataManager.db.gen_name(country, _used_names, rng)
	var style: Dictionary = STYLES[rng.randi_range(0, STYLES.size() - 1)]
	return {
		"id": "",
		"name": nm,
		"country": country,
		"age": age,
		"tier": 2,
		"style": style["k"],
		"style_name": style["n"],
		"weakness": style["weak"].duplicate(),
		"tactic": style["tactic"],
		"rivalry": 0,
		"tag": "青少年选手",
		"ovr": clampf(target_ovr, 8.0, 118.0),
		"points": 0,
		"record": {"wins": 0, "losses": 0},
	}

## 找宿敌（rivalry 最高的 Tier1）
func rival() -> Dictionary:
	var best: Dictionary = {}
	var rv := -1
	for o in list:
		if int(o.get("tier", 0)) != 1:
			continue
		if int(o.get("rivalry", 0)) > rv:
			rv = int(o["rivalry"])
			best = o
	return best

func tier1_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in list:
		if int(o.get("tier", 0)) == 1:
			out.append(o)
	return out

func to_dict() -> Dictionary:
	return {"list": list.duplicate(true), "next_id": _next_id, "used": _used_names.duplicate()}

func from_dict(d: Dictionary) -> void:
	list.clear()
	for o in d.get("list", []):
		list.append(o)
	_next_id = int(d.get("next_id", 1))
	_used_names = d.get("used", {})
