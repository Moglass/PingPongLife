extends Node
## v0.82 PauseManager：统一管理「时间流为什么停」。
##
## 之前是各处直接调 TimeManager.pause_for()，谁都能把时间停掉，
## 但没有人知道该由谁来恢复。多个原因叠在一起时（比如赛事周恰好又弹了事件），
## 先处理完的那个会把时间放走，另一个原因还在，玩家就看到时间在弹窗底下偷偷跑。
##
## 这里改成「引用计数 + 原因集合」：谁请求的谁释放，全部释放完才允许继续，
## 而且恢复动作交给玩家自己点「跑」，不会突然开动。

signal pause_state_changed(paused: bool, reason: String)

var _reasons: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func request(reason: String) -> void:
	if _reasons.has(reason):
		return
	_reasons.append(reason)
	if TimeManager.time_scale > 0.0:
		TimeManager.set_speed(0)
	pause_state_changed.emit(true, reason)

func release(reason: String) -> void:
	if not _reasons.has(reason):
		return
	_reasons.erase(reason)
	# 不自动恢复：全部原因解除后只广播状态，等玩家自己点「跑」
	pause_state_changed.emit(not _reasons.is_empty(), current_reason())

func release_all() -> void:
	_reasons.clear()
	pause_state_changed.emit(false, "")

func is_paused() -> bool:
	return not _reasons.is_empty()

func has(reason: String) -> bool:
	return _reasons.has(reason)

func current_reason() -> String:
	return _reasons[0] if not _reasons.is_empty() else ""

func reason_text() -> String:
	if _reasons.is_empty():
		return ""
	var names := {
		"event": "有事发生",
		"tourney": "赛事周",
		"coach": "教练找你",
		"breaking": "破格窗口",
		"stamina": "体力见底",
	}
	var parts: Array[String] = []
	for r in _reasons:
		parts.append(str(names.get(r, r)))
	return " · ".join(parts)
