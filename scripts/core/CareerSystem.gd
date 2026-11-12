class_name CareerSystem
extends RefCounted
## 日常训练与周结算（v0.8）。
## 6 个动作争夺每周 3-6 点 AP：技术 / 体能 / 心理 / 战术 / 休息 / 文化课。

const ACTIONS: Array[Dictionary] = [
	{"k": "tech", "n": "技术训练", "icon": "技", "ap": 1, "d": "打磨一项技术，推进当前短板"},
	{"k": "fit", "n": "体能训练", "icon": "体", "ap": 1, "d": "多球、折返、核心。长肌肉也长耐心"},
	{"k": "psy", "n": "心理训练", "icon": "心", "ap": 1, "d": "关键分模拟、呼吸、抗压"},
	{"k": "tac", "n": "战术复盘", "icon": "战", "ap": 1, "d": "看录像，记对手的落点习惯"},
	{"k": "rest", "n": "休息", "icon": "息", "ap": 1, "d": "恢复体力，降低伤病风险"},
	{"k": "study", "n": "文化课", "icon": "学", "ap": 1, "d": "为退役后的那条路留一点余地"},
]

## 技术 -> 关联属性。避免「只练技术、身体不动」的畸形成长。
const TECH_ATTR_LINK: Dictionary = {
	"serve": "touch", "receive": "touch", "short": "touch",
	"fh": "power", "bh": "power", "def": "stamina", "foot": "speed",
}
const ATTR_NAME: Dictionary = {
	"power": "力量", "speed": "速度", "stamina": "耐力",
	"touch": "手感", "tactic": "战术", "mental": "心理",
}

const TECH_FOCUS: Array[Dictionary] = [
	{"k": "serve", "n": "发球"}, {"k": "receive", "n": "接发球"}, {"k": "short", "n": "台内球"},
	{"k": "fh", "n": "正手"}, {"k": "bh", "n": "反手"}, {"k": "def", "n": "防守"}, {"k": "foot", "n": "步法"},
]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

## 执行一次训练。tech_key 仅在 action == "tech" 时使用。
## 返回 {text, gains, stamina_cost}
func train(p: PlayerStats, action: String, tech_key: String = "fh") -> Dictionary:
	var gains: Array[String] = []
	var text := ""
	var cost := 0.0
	var fatigue_add := 0.0

	# 身体状态会影响训练效果：累了练不动，伤了不能练
	var eff := 1.0
	if p.stamina_cur < 30.0:
		eff = 0.55
	elif p.stamina_cur < 55.0:
		eff = 0.82
	if p.injury_weeks > 0:
		eff *= 0.35

	match action:
		"tech":
			var d := p.add_tech(tech_key, 0.58 * eff)
			var nm := tech_key
			for t in TECH_FOCUS:
				if str(t["k"]) == tech_key:
					nm = str(t["n"])
			gains.append("%s +%.1f" % [nm, d])
			# 技术训练会带动关联身体素质：练正手也长力量，练步法也长速度
			var linked: String = str(TECH_ATTR_LINK.get(tech_key, ""))
			if linked != "":
				var da := p.add_attr(linked, 0.26 * eff)
				if da > 0.02:
					gains.append("%s +%.1f" % [ATTR_NAME.get(linked, linked), da])
			cost = 11.0
			fatigue_add = 7.0
			text = _tech_flavor(tech_key, d, p)
		"fit":
			var d1 := p.add_attr("stamina", 0.62 * eff)
			var d2 := p.add_attr("power", 0.30 * eff)
			var d4 := p.add_attr("speed", 0.34 * eff)
			gains.append("耐力 +%.1f" % d1)
			if d2 > 0.03:
				gains.append("力量 +%.1f" % d2)
			if d4 > 0.03:
				gains.append("速度 +%.1f" % d4)
			cost = 17.0
			fatigue_add = 11.0
			text = "多球练到最后一筐，腿开始发沉。教练说，这就是比赛第七局的感觉。"
		"psy":
			var d3 := p.add_attr("mental", 0.55 * eff)
			gains.append("心理 +%.1f" % d3)
			cost = 5.0
			fatigue_add = 3.0
			text = "你闭上眼，想象 9 平。心跳很快，但手是稳的。"
			if rng.randf() < 0.18:
				gains.append("触发【关键分心流】")
				p.add_status({"id": "flow", "name": "心流", "weeks_left": 2, "form": 0.06, "mods": {"mental": 2.0}})
		"tac":
			var d4 := p.add_attr("tactic", 0.50 * eff)
			gains.append("战术 +%.1f" % d4)
			cost = 4.0
			fatigue_add = 2.0
			text = "你把对手最近三场的落点画在纸上。有些习惯，藏不住。"
		"rest":
			var rec := 26.0 + float(p.age) * -0.15
			p.stamina_cur = clampf(p.stamina_cur + rec, 0.0, 100.0)
			p.fatigue = maxf(0.0, p.fatigue - 14.0)
			p.form_noise = clampf(p.form_noise + 0.04, -0.4, 0.4)
			gains.append("体力 +%.0f" % rec)
			text = "你什么也没干。睡到中午，去楼下吃了碗面。下午的阳光落在球台上，你没去碰它。"
		"study":
			p.record["study"] = int(p.record.get("study", 0)) + 1
			p.mental = minf(p.ladder_cap(), p.mental + 0.25)
			gains.append("学业 +1")
			text = "语文老师问你，以后是不是要打球。你说不知道。她说，那先把这篇作文写完。"
		_:
			return {"text": "什么也没发生。", "gains": gains, "stamina_cost": 0.0}

	p.ap = maxi(0, p.ap - 1)
	p.stamina_cur = clampf(p.stamina_cur - cost, 0.0, 100.0)
	p.fatigue = clampf(p.fatigue + fatigue_add, 0.0, 100.0)

	# 隐藏流派权重：不同训练偏好自然演化出路线
	match action:
		"fit":
			p.weight_monster += 0.6
		"tech":
			p.weight_normal += 0.5
		"tac", "psy":
			p.weight_late += 0.4

	return {"text": text, "gains": gains, "stamina_cost": cost}

func _tech_flavor(k: String, gain: float, p: PlayerStats) -> String:
	if gain < 0.15:
		var stuck: Array[String] = [
			"你练了一下午，球还是那个球。教练说，瓶颈期都这样。",
			"动作对了，但手感没跟上。你有点烦。",
			"你反复看自己的录像，发现问题在重心，不在手上。",
		]
		return stuck[rng.randi_range(0, stuck.size() - 1)]
	match k:
		"fh":
			return "正手连续拉了三十板不失误。教练在旁边点了点头，没说话。"
		"bh":
			return "反手拧拉终于能吃住球了。手腕一紧，球就过去了。"
		"serve":
			return "你练了一百个同一个落点。到第九十个的时候，闭着眼也能发进去。"
		"receive":
			return "接发球不再靠猜。你盯着对方的手腕，球出手的一瞬间就知道了。"
		"short":
			return "台内摆短，球擦着网过去，第二跳几乎不出台。对手够不着。"
		"def":
			return "防守不是挨打。你把球一板一板送回去，对面先急了。"
		"foot":
			return "步法练到小腿发酸。但你终于能在球出手前就站到位。"
	return "练完了。"

func action_by_key(k: String) -> Dictionary:
	for a in ACTIONS:
		if str(a["k"]) == k:
			return a
	return {}

# ---------------------------------------------------------------- 周结算

## 每周的伤病 / 状态判定。返回需要展示的文本。
func weekly_check(p: PlayerStats) -> Array[String]:
	var notes: Array[String] = []
	if p.injury_weeks > 0:
		p.injury_weeks -= 1
		if p.injury_weeks == 0:
			notes.append("伤好了。你试着活动了一下脚踝，还有点酸，但能打了。")
		return notes

	# 伤病概率：疲劳 + 低体力 + 年龄
	var risk := 0.0
	if p.fatigue > 65.0:
		risk += (p.fatigue - 65.0) * 0.0045
	if p.stamina_cur < 30.0:
		risk += 0.055
	if p.age >= 30:
		risk += float(p.age - 29) * 0.008
	if rng.randf() < risk:
		var weeks := rng.randi_range(2, 5)
		if p.age >= 31 and rng.randf() < 0.35:
			weeks = rng.randi_range(8, 16)
		p.injury_weeks = weeks
		p.add_status({
			"id": "injury", "name": "伤病", "weeks_left": weeks,
			"form": -0.25, "mods": {"ovr": -6.0},
		})
		notes.append("你在一次侧身中拉伤了大腿。队医说至少 %d 周。" % weeks)
	return notes

## 赛季末：隐藏流派结算为特质
func settle_season(p: PlayerStats) -> String:
	var best := "normal"
	var v := p.weight_normal
	if p.weight_monster > v:
		best = "monster"
		v = p.weight_monster
	if p.weight_late > v:
		best = "late"
	match best:
		"monster":
			if not p.traits.has("monster"):
				p.traits.append("monster")
				return "队里开始有人叫你「怪物」。你自己不觉得，你只是练得比谁都多。"
		"late":
			if not p.traits.has("late_bloomer"):
				p.traits.append("late_bloomer")
				return "教练说你「开窍晚」。你不太懂，但你确实开始看懂球了。"
	return ""
