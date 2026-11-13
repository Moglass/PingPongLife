class_name AchievementSystem
extends RefCounted
## 成就系统：143 个条目，按「铜 / 银 / 金 / 白金 / 隐藏」分级。
## 数据来自 StaticDB.ACHV（k = 统计键，v = 阈值），解锁状态写进全局档案，
## 因此跨存档、跨周目保留——这是玩家唯一的「收藏」。

const TIER_COLOR: Dictionary = {
	"bronze": Color("#a9713f"),
	"silver": Color("#8b8b8b"),
	"gold": Color("#9c7c2e"),
	"platinum": Color("#2c6e8f"),
	"hidden": Color("#b03a2e"),
}
const TIER_NAME: Dictionary = {
	"bronze": "铜", "silver": "银", "gold": "金", "platinum": "白金", "hidden": "隐藏",
}

## 这几个键是「名次」，越小越好。其余都是累计量，越大越好。
## 漏掉它们会让未上榜（默认 999）直接刷掉所有排名成就。
const LOWER_IS_BETTER: Array[String] = ["bestAdult", "bestYouth", "bestDomestic"]
## 未上榜的哨兵值：达到它说明「还没有名次」，任何名次成就都不该成立
const UNRANKED := 999.0

var unlocked: Dictionary = {}

func load_from_profile() -> void:
	var raw: Dictionary = DataManager.profile.get("achievements", {})
	unlocked = raw.duplicate()

## 修正历史数据：早期版本把名次当累计量判（>=），导致「世界第一」在未上榜时被解锁。
## 用 record 里的历史最佳名次复核，只撤销站不住的条目。
func sanitize(p: PlayerStats) -> int:
	var bad: Array[String] = []
	for id in unlocked.keys():
		var item: Dictionary = _by_id(str(id))
		if item.is_empty():
			continue
		var k := str(item.get("k", ""))
		if not LOWER_IS_BETTER.has(k):
			continue
		var cur := stat_value(p, k)
		if cur >= UNRANKED or cur > float(item.get("v", 0)):
			bad.append(str(id))
	for id in bad:
		unlocked.erase(id)
	if not bad.is_empty():
		save_to_profile()
	return bad.size()

var _id_index: Dictionary = {}
func _by_id(id: String) -> Dictionary:
	if _id_index.is_empty():
		for a in DataManager.db.ACHV:
			_id_index[str(a.get("id", ""))] = a
	return _id_index.get(id, {})

func save_to_profile() -> void:
	DataManager.profile["achievements"] = unlocked.duplicate()
	DataManager.save_profile()

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

func count() -> int:
	return unlocked.size()

func total() -> int:
	return DataManager.db.ACHV.size()

## 检查并返回本次新解锁的成就列表
func check(p: PlayerStats) -> Array[Dictionary]:
	var newly: Array[Dictionary] = []
	for a in DataManager.db.ACHV:
		var item: Dictionary = a
		var id := str(item.get("id", ""))
		if unlocked.has(id):
			continue
		var k := str(item.get("k", ""))
		var v := float(item.get("v", 0))
		if k == "achvCount":
			if float(unlocked.size()) >= v:
				newly.append(item)
			continue
		var cur := stat_value(p, k)
		if LOWER_IS_BETTER.has(k):
			# 名次类：越小越好，且未上榜时一律不成立
			if cur < UNRANKED and cur <= v:
				newly.append(item)
		elif cur >= v:
			newly.append(item)
	for item in newly:
		unlocked[str(item["id"])] = Time.get_datetime_string_from_system()
	if not newly.is_empty():
		save_to_profile()
	return newly

## 把成就的统计键映射到玩家真实数据。未知键返回 0（永远不会误解锁）。
func stat_value(p: PlayerStats, k: String) -> float:
	var r := p.record
	match k:
		"matches": return float(r.get("matches", 0))
		"wins": return float(r.get("wins", 0))
		"champions": return float(r.get("champions", 0))
		"maxWinStreak": return float(r.get("max_win_streak", 0))
		"winStreak": return float(r.get("max_win_streak", 0))
		"trains": return float(r.get("trains", 0))
		"techSessions": return float(r.get("tech_sessions", 0))
		"fitSessions": return float(r.get("fit_sessions", 0))
		"psySessions": return float(r.get("psy_sessions", 0))
		"tacSessions": return float(r.get("tac_sessions", 0))
		"restWeeks": return float(r.get("rest_weeks", 0))
		"prize": return float(r.get("prize", 0))
		"rep": return float(p.rep)
		"fame": return float(p.fame)
		"coachTrust": return float(p.trust)
		"seasons": return float(r.get("seasons", 0))
		"caps": return float(r.get("caps", 0))
		"goals": return float(r.get("goals", 0))
		"subs": return float(r.get("subs", 0))
		"bestAdult": return float(r.get("best_adult", 999))
		"bestYouth": return float(r.get("best_youth", 999))
		"bestDomestic": return float(r.get("best_domestic", 999))
		"oppMet": return float(r.get("opp_met", 0))
		"matchesInYear": return float(r.get("matches_in_year", 0))
		"championsInYear": return float(r.get("champions_in_year", 0))
		"deuceWins": return float(r.get("deuce_wins", 0))
		"deuceGames": return float(r.get("deuce_games", 0))
		"perfectGames": return float(r.get("perfect_games", 0))
		"pairWins": return float(r.get("pair_wins", 0))
		"pairMatches": return float(r.get("pair_matches", 0))
		"maxRivalry": return float(r.get("max_rivalry", 0))
		"breakLv": return float(p.break_pts / 12)
		"breakOk": return float(r.get("break_ok", 0))
		"breakTry": return float(r.get("break_try", 0))
		"injuries": return float(r.get("injuries", 0))
		"comebacks": return float(r.get("comebacks", 0))
		"top1Weeks": return float(r.get("top1_weeks", 0))
		"top10Weeks": return float(r.get("top10_weeks", 0))
		"wttTitles": return float(r.get("wtt_titles", 0))
		"titlesYouth": return float(_title_count(p, ["ypy", "yp", "ync", "ynj", "ya", "yw", "ych"]))
		"titlesDomestic": return float(_title_count(p, ["domestic"]))
		"titlesAsian": return float(_title_count(p, ["asia"]))
		"titlesWorld": return float(_title_count(p, ["worldcup", "major", "finals"]))
		"achvCount": return float(unlocked.size())
		"study": return float(r.get("study", 0))
		"winsVsTop100": return float(r.get("wins_vs_top100", 0))
		"winsVsTop50": return float(r.get("wins_vs_top50", 0))
		"winsVsTop10": return float(r.get("wins_vs_top10", 0))
		_:
			return 0.0

func _title_count(p: PlayerStats, tiers: Array) -> int:
	var titles: Dictionary = p.record.get("titles", {})
	var sum := 0
	for t in tiers:
		sum += int(titles.get(str(t), 0))
	return sum

## 按稀有度分组，供 UI 渲染
func grouped() -> Dictionary:
	var out := {"bronze": [], "silver": [], "gold": [], "platinum": [], "hidden": []}
	for a in DataManager.db.ACHV:
		var item: Dictionary = a
		var t := str(item.get("t", "bronze"))
		if not out.has(t):
			out[t] = []
		var copy := item.duplicate(true)
		copy["unlocked"] = unlocked.has(str(item["id"]))
		copy["progress"] = 1.0 if copy["unlocked"] else 0.0
		out[t].append(copy)
	return out
