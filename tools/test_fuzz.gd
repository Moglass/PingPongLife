extends Node
## 漏洞压力测试：长时间推进 + 极端值 + 存读档往返。
## 目标不是跑分，是把「跑到第 N 天突然崩」这类问题逼出来。

var errors: Array[String] = []

func _ready() -> void:
	DataManager.profile["achievements"] = {}
	DataManager.save_profile()
	GameManager.new_career("压力", "prodigy")

	# ---- 1) 2000 天连续推进，事件自动选择 ----
	var t0 := Time.get_ticks_msec()
	var events := 0
	for i in range(2000):
		GameManager.p.stamina_cur = maxf(GameManager.p.stamina_cur, 90.0)
		_drain_event()
		var r: Dictionary = GameManager.advance_day()
		if not bool(r.get("should_pause", false)) and GameManager.pending_event.is_empty():
			pass
		events += 1
	var t1 := Time.get_ticks_msec()
	print("[FUZZ] 2000 天完成 %dms  age=%d year=%d week=%d day=%d ovr=%.1f 钱=%d" % [
		t1 - t0, GameManager.p.age, GameManager.p.year, GameManager.p.week,
		GameManager.p.day, GameManager.p.ovr(), GameManager.p.money])
	_check_range("age", GameManager.p.age, 8, 45)
	_check_range("week", GameManager.p.week, 1, GameManager.WEEKS_PER_YEAR)
	_check_range("day", GameManager.p.day, 1, 7)
	_check_range("ovr", GameManager.p.ovr(), 0.0, 130.0)
	if GameManager.p.money < 0:
		errors.append("金钱为负：%d" % GameManager.p.money)

	# ---- 2) 极端值 ----
	GameManager.p.stamina_cur = 0.0
	GameManager.p.fatigue = 100.0
	GameManager.p.injury_weeks = 52
	GameManager.advance_day()
	print("[FUZZ] 体力0/伤病52周 推进正常 day=%d injury=%d" % [GameManager.p.day, GameManager.p.injury_weeks])

	GameManager.p.stamina_cur = 100.0
	GameManager.p.injury_weeks = 0
	GameManager.p.money = 0
	GameManager.p.ap = 0
	GameManager.advance_day()
	print("[FUZZ] 零资源推进正常")

	# 排程数组被外部改坏
	GameManager.p.schedule.clear()
	GameManager.advance_day()
	print("[FUZZ] 空排程不崩")
	GameManager.p.schedule.assign(["tech", "tech", "fit", "tech", "fit", "rest", "study"])

	# ---- 3) 存读档往返（含 v0.81 新字段）----
	GameManager.p.day = 5
	GameManager.p.stamina_cur = 63.0
	GameManager.p.schedule[3] = "psy"
	var ok := GameManager.save_to(3)
	if not ok:
		errors.append("存档失败")
	var d_before := GameManager.p.day
	var sch_before := str(GameManager.p.schedule[3])
	var stam_before := GameManager.p.stamina_cur
	var loaded := GameManager.load_from(3)
	if not loaded:
		errors.append("读档失败")
	if GameManager.p.day != d_before:
		errors.append("day 往返不一致 %d -> %d" % [d_before, GameManager.p.day])
	if str(GameManager.p.schedule[3]) != sch_before:
		errors.append("schedule 往返不一致 %s -> %s" % [sch_before, str(GameManager.p.schedule[3])])
	if absf(GameManager.p.stamina_cur - stam_before) > 0.01:
		errors.append("体力往返不一致")
	print("[FUZZ] 存读档往返 day=%d sch=%s" % [GameManager.p.day, str(GameManager.p.schedule[3])])

	# ---- 4) 时间流开关 ----
	TimeManager.set_active(true)
	TimeManager.set_speed(3)
	if TimeManager.time_scale != 4.0:
		errors.append("4 倍速设置失败")
	TimeManager.set_speed(0)
	if TimeManager.time_scale != 0.0:
		errors.append("暂停设置失败")
	print("[FUZZ] 时间档位切换正常")

	# ---- 5) 暂停原因集合 ----
	PauseManager.request("event")
	PauseManager.request("tourney")
	PauseManager.release("event")
	if not PauseManager.is_paused():
		errors.append("仍有 tourney 原因却不认为暂停")
	PauseManager.release_all()
	if PauseManager.is_paused():
		errors.append("release_all 后仍暂停")
	print("[FUZZ] 暂停原因集合正常")

	print("[FUZZ] 问题数 ", errors.size())
	for e in errors:
		print("  ✗ ", e)
	get_tree().quit()

## 把待处理事件自动选掉，避免卡住推进
func _drain_event() -> void:
	if GameManager.pending_event.is_empty():
		return
	var card: Dictionary = GameManager.pending_event
	var opts: Array = card.get("options", [])
	if not opts.is_empty():
		GameManager.event_pool.apply(GameManager.p, card, 0)
	GameManager.pending_event = {}
	PauseManager.release_all()

func _check_range(name: String, v: float, lo: float, hi: float) -> void:
	if v < lo or v > hi:
		errors.append("%s 越界：%.1f (应在 %.0f–%.0f)" % [name, v, lo, hi])
