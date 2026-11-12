extends SceneTree
## 规则层自测（无 UI / 无 autoload）：
## godot --headless --script tools/test_match.gd

func _init() -> void:
	print("=== MatchEngine 自测 ===")
	_test_score_flow()
	_test_probability_curve()
	_test_rule_events()
	print("=== 完成 ===")
	quit()

func _mk(ovr: float, mental: float = 50.0) -> Dictionary:
	return {
		"name": "T%.0f" % ovr, "ovr": ovr, "attack": ovr, "defense": ovr,
		"control": ovr, "physical": ovr, "mental": mental, "form": 0.5,
		"weakness": ["bh"],
	}

func _test_score_flow() -> void:
	var e := MatchEngine.new()
	e.rng.seed = 12345
	e.setup(_mk(60), _mk(58), {"best_of": 7})
	var guard := 0
	while not e.finished and guard < 500:
		e.play_point("target_bh", "steady")
		guard += 1
	print("[OK] 七局四胜打完：%d:%d，用时 %.1f 分钟，共 %d 分" % [
		e.games[0], e.games[1], e.total_minutes,
		int(e.stats["points_won"][0]) + int(e.stats["points_won"][1]),
	])
	assert(e.games[0] == 4 or e.games[1] == 4, "必须有一方先到 4 局")
	assert(not e.finished or e.winner >= 0, "结束后必须有胜者")

func _test_probability_curve() -> void:
	# 同实力应接近 50%，强 20 点应显著占优
	var win_same := _sim_series(60.0, 60.0, 400)
	var win_up := _sim_series(80.0, 60.0, 400)
	var win_down := _sim_series(40.0, 60.0, 400)
	print("[STAT] 同档 %.1f%% | +20 档 %.1f%% | -20 档 %.1f%%" % [win_same * 100.0, win_up * 100.0, win_down * 100.0])
	assert(win_same > 0.40 and win_same < 0.60, "同实力胜率应接近 50%")
	assert(win_up > 0.75, "强 20 点应明显占优")
	assert(win_down < 0.25, "弱 20 点应明显劣势")

func _sim_series(a_ovr: float, b_ovr: float, n: int) -> float:
	var wins := 0
	for i in range(n):
		var e := MatchEngine.new()
		e.rng.seed = i * 7919 + 3
		e.setup(_mk(a_ovr), _mk(b_ovr), {"best_of": 5})
		e.simulate_remaining("target_bh", "steady")
		if e.winner == 0:
			wins += 1
	return float(wins) / float(n)

func _test_rule_events() -> void:
	var e := MatchEngine.new()
	e.rng.seed = 999
	e.setup(_mk(70), _mk(70), {"best_of": 5})
	var seen: Dictionary = {}
	var guard := 0
	while not e.finished and guard < 500:
		var r := e.play_point("target_mid", "steady")
		for ev in r["events"]:
			seen[str(ev["type"])] = int(seen.get(str(ev["type"]), 0)) + 1
		guard += 1
	print("[EVENTS] ", seen.keys())
	for need in ["point", "serve_change", "towel", "game_end", "match_end"]:
		assert(seen.has(need), "缺少规则事件：" + need)
	print("[OK] 规则事件齐全：换发 / 擦汗 / 局末 / 场末")
