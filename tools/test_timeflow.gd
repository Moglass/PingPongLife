extends Node
## v0.81 时间流验收：4 倍速下时间该自己走，事件频率该降下来。

func _ready() -> void:
	GameManager.new_career("时光", "prodigy")
	await get_tree().process_frame

	var d0 := GameManager.p.day
	var w0 := GameManager.p.week
	var y0 := GameManager.p.year
	print("[FLOW] 起始 第%d周 周%d %d年" % [w0, d0, y0])

	TimeManager.set_active(true)
	TimeManager.set_speed(3)  # 4×
	print("[FLOW] 档位 ", TimeManager.speed_label(), " scale=", TimeManager.time_scale)

	# 4× → 1 秒 4 天，等 3.5 秒 ≈ 14 天
	await get_tree().create_timer(3.5).timeout
	print("[FLOW] 3.5 秒后 第%d周 周%d %d年  体力%.0f" % [
		GameManager.p.week, GameManager.p.day, GameManager.p.year, GameManager.p.stamina_cur])

	var advanced := GameManager.p.week * 7 + GameManager.p.day - (w0 * 7 + d0)
	print("[FLOW] 推进天数=", advanced, " （4×≈14 天）")

	# 事件频率：连续跑 100 天，统计触发次数
	TimeManager.set_speed(0)
	var events := 0
	var pause_hits := 0
	for i in range(100):
		GameManager.p.stamina_cur = 90.0
		if not GameManager.pending_event.is_empty():
			GameManager.pending_event = {}
			events += 1
		var r: Dictionary = GameManager.advance_day()
		if bool(r.get("should_pause", false)):
			pause_hits += 1
	print("[FLOW] 100 天内触发事件 ", events, " 次，暂停点 ", pause_hits, " 次")

	# 体力保护：压到 10 应立刻刹停
	GameManager.p.stamina_cur = 10.0
	var r2: Dictionary = GameManager.advance_day()
	print("[FLOW] 体力10 时 should_pause=", r2.get("should_pause"), " 原因=", r2.get("pause_reason"))

	get_tree().quit()
