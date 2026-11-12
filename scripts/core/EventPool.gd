class_name EventPool
extends RefCounted
## 随机事件池（v0.8）：数值做减法，情绪做加法。
## 复用 v0.7 的 35 张事件卡文案，但把效果压到「临时状态 / 微量成长 / 人际」，
## 不再出现 +10 属性的超模奖励。

const TRIGGER_CHANCE: float = 0.32
const EFFECT_SCALE: float = 0.55

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

## 选一张本周事件。返回 {} 表示这周不出事——留白也是设计的一部分。
func pick_for(p: PlayerStats, major_week: bool = false) -> Dictionary:
	if major_week:
		return {}
	if rng.randf() > TRIGGER_CHANCE:
		return {}
	var pool := _valid_pool(p)
	if pool.is_empty():
		return {}
	var card: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
	var c: Dictionary = card.duplicate(true)
	c["options"] = _build_options(c, p)
	return c

func _valid_pool(p: PlayerStats) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for card in DataManager.db.EVENT_CARDS:
		var cond: Dictionary = card.get("cond", {})
		if cond.has("stageMin") and p.stage < int(cond["stageMin"]):
			continue
		if cond.has("stageMax") and p.stage > int(cond["stageMax"]):
			continue
		if cond.has("ageMin") and p.age < int(cond["ageMin"]):
			continue
		if cond.has("ageMax") and p.age > int(cond["ageMax"]):
			continue
		# 情绪投喂：低落时只出温情/家庭，顺风时多出职场/造梗
		var kind := str(card.get("kind", ""))
		if p.record.get("loss_streak", 0) >= 3 and kind in ["商业", "舆论", "机会"]:
			if rng.randf() < 0.7:
				continue
		out.append(card)
	return out

func _build_options(card: Dictionary, p: PlayerStats) -> Array[Dictionary]:
	var opts: Array = card.get("opts", [])
	var out: Array[Dictionary] = []
	for o in opts:
		var fx: Dictionary = o.get("fx", {})
		out.append({
			"text": str(o.get("t", "")),
			"effect_text": str(o.get("e", "")),
			"fx": fx,
		})
	return out

## 应用选项。返回给 UI 的反馈文本。
func apply(p: PlayerStats, card: Dictionary, idx: int) -> Dictionary:
	var opts: Array = card.get("options", card.get("opts", []))
	if idx < 0 or idx >= opts.size():
		return {"text": "你什么也没做。", "gains": []}
	var opt: Dictionary = opts[idx]
	var fx: Dictionary = opt.get("fx", {})
	var gains: Array[String] = []

	if fx.has("tech"):
		var td: Dictionary = fx["tech"]
		for k in td.keys():
			var d := p.add_tech(str(k), float(td[k]) * EFFECT_SCALE * 6.0)
			if absf(d) > 0.05:
				gains.append("%s +%.1f" % [_tech_name(str(k)), d])
	if fx.has("attr"):
		var ad: Dictionary = fx["attr"]
		for k in ad.keys():
			var d2 := p.add_attr(str(k), float(ad[k]) * EFFECT_SCALE)
			if absf(d2) > 0.05:
				gains.append("%s +%.1f" % [str(k), d2])
	if fx.has("stam"):
		p.stamina_cur = clampf(p.stamina_cur + float(fx["stam"]), 0.0, 100.0)
		var v := float(fx["stam"])
		gains.append("体力 %s%.0f" % ["+" if v > 0 else "", v])
	if fx.has("fatigue"):
		p.fatigue = clampf(p.fatigue + float(fx["fatigue"]), 0.0, 100.0)
	if fx.has("trust"):
		p.trust = clampf(p.trust + float(fx["trust"]), 0.0, 100.0)
		gains.append("教练信任 %+.0f" % float(fx["trust"]))
	if fx.has("money"):
		p.money = maxi(0, p.money + int(fx["money"]))
	if fx.has("study"):
		p.record["study"] = int(p.record.get("study", 0)) + int(fx["study"])
	if fx.has("form"):
		p.form_noise = clampf(p.form_noise + float(fx["form"]), -0.4, 0.4)
	if fx.has("status"):
		var st: Dictionary = fx["status"]
		var eff: Dictionary = st.duplicate(true)
		eff["weeks_left"] = int(st.get("weeks", 2))
		p.add_status(eff)
		gains.append("获得状态【%s】" % str(eff.get("name", "")))

	var text := str(fx.get("log", opt.get("e", "")))
	return {"text": text, "gains": gains, "title": str(card.get("title", ""))}

func _tech_name(k: String) -> String:
	var m: Dictionary = DataManager.db.TECH_MAP.get(k, {})
	return str(m.get("n", k))
