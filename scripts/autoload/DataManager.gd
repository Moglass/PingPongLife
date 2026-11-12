extends Node
## 数据层（Autoload）：静态配置、存档、全局档案。
## - 静态数据：StaticDB（纯数据，零外部依赖）
## - 存档：user://saves/slot_N.json（JSON + 版本迁移 + 类型修复）
## - 全局档案：user://profile.json（成就 / 图鉴 / 周目传承）

const SAVE_VERSION: int = 8
const SAVE_DIR: String = "user://saves"
const PROFILE_PATH: String = "user://profile.json"

var db: StaticDB = StaticDB.new()
var profile: Dictionary = {}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_load_profile()

# ---------------------------------------------------------------- 存档

func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))

func save_game(slot: int, state: Dictionary) -> bool:
	var payload := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"state": state,
	}
	var f := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if f == null:
		push_error("无法写入存档：%s" % slot_path(slot))
		return false
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	EventBus.save_completed.emit(slot)
	return true

func load_game(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var f := FileAccess.open(slot_path(slot), FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("存档损坏：%s" % slot_path(slot))
		return {}
	var payload: Dictionary = parsed
	if int(payload.get("version", 0)) > SAVE_VERSION:
		push_error("存档版本高于当前游戏版本")
		return {}
	var state: Dictionary = payload.get("state", {})
	return repair_types(state)

## JSON 会把所有数字读成 float；这里按关键字段恢复 int，
## 避免后续整型比较、数组下标出现 3.0000001 之类的静默错误。
func repair_types(state: Dictionary) -> Dictionary:
	var int_keys: Array[String] = [
		"week", "year", "age", "stage", "money", "rep", "fame", "rank",
		"points", "ap", "break_pts", "slot", "seed", "week_index",
	]
	for k in int_keys:
		if state.has(k):
			state[k] = int(state[k])
	if state.has("player") and typeof(state["player"]) == TYPE_DICTIONARY:
		var p: Dictionary = state["player"]
		for k in ["age", "stage", "money", "rep", "fame", "rank", "points", "ap", "break_pts", "week"]:
			if p.has(k):
				p[k] = int(p[k])
		state["player"] = p
	return state

func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))

func list_saves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(1, 4):
		if not has_save(i):
			continue
		var f := FileAccess.open(slot_path(i), FileAccess.READ)
		if f == null:
			continue
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var payload: Dictionary = parsed
		var st: Dictionary = payload.get("state", {})
		var p: Dictionary = st.get("player", {})
		out.append({
			"slot": i,
			"name": str(p.get("name", "无名")),
			"age": int(p.get("age", 0)),
			"stage": int(p.get("stage", 0)),
			"year": int(st.get("year", 0)),
			"saved_at": str(payload.get("saved_at", "")),
		})
	return out

# ---------------------------------------------------------------- 全局档案

func _load_profile() -> void:
	profile = {
		"achievements": {},
		"endings": {},
		"legacy_points": 0,
		"runs": 0,
		"best_rank": 999,
	}
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in profile.keys():
			if parsed.has(k):
				profile[k] = parsed[k]

func save_profile() -> void:
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(profile, "\t"))
	f.close()

func unlock_achievement(id: String) -> bool:
	var got: Dictionary = profile.get("achievements", {})
	if got.has(id):
		return false
	got[id] = Time.get_datetime_string_from_system()
	profile["achievements"] = got
	save_profile()
	return true

# ---------------------------------------------------------------- 查询辅助

func stage_def(index: int) -> Dictionary:
	return db.stage_at(index)

func stage_count() -> int:
	return db.STAGES.size()

func tourney(id: String) -> Dictionary:
	return db.tourney(id)

func point_table(tier: String) -> Array:
	return db.POINTS.get(tier, db.POINTS.get("cont", []))

func fmt_money(v: int) -> String:
	if abs(v) >= 10000:
		return "¥%.1f万" % (float(v) / 10000.0)
	return "¥%d" % v
