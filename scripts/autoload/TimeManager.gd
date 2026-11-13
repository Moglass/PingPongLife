extends Node
## v0.81 时间流：现实 1 秒 = 游戏内 1 天。
## 只在「生涯页面 + 没有弹窗 + 没有比赛」时流动，遇到需要决策的节点自动刹车。

signal scale_changed(scale: float)
signal day_changed(day: int, week: int, year: int)

## 现实多少秒推进一天。1 秒 = 1 天，一周 7 秒。
const SECONDS_PER_DAY := 1.0
const SPEEDS: Array[float] = [0.0, 1.0, 2.0, 4.0]
const SPEED_NAME: Array[String] = ["暂停", "1×", "2×", "4×"]

var time_scale: float = 0.0
var _acc: float = 0.0
var _active: bool = false
## 上一次自动暂停的原因，给 UI 显示
var pause_reason: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## 只有停留在日常页时才走时间
func set_active(v: bool) -> void:
	if _active == v:
		return
	_active = v
	if not v:
		_acc = 0.0

func set_speed(idx: int) -> void:
	var i := clampi(idx, 0, SPEEDS.size() - 1)
	time_scale = SPEEDS[i]
	if time_scale > 0.0:
		pause_reason = ""
	scale_changed.emit(time_scale)

func speed_index() -> int:
	return SPEEDS.find(time_scale) if SPEEDS.has(time_scale) else 0

func speed_label() -> String:
	return SPEED_NAME[clampi(speed_index(), 0, SPEED_NAME.size() - 1)]

## 进入暂停，并记录原因（事件、体力、赛事、教练谈话）
func pause_for(reason: String) -> void:
	pause_reason = reason
	if time_scale != 0.0:
		time_scale = 0.0
		scale_changed.emit(0.0)
	elif time_scale == 0.0:
		scale_changed.emit(0.0)

func toggle_play() -> void:
	if time_scale > 0.0:
		set_speed(0)
	else:
		set_speed(1)

func is_running() -> bool:
	return _active and time_scale > 0.0

func _process(delta: float) -> void:
	if not _active or time_scale <= 0.0:
		return
	# 有弹窗时先把档位真正归零，否则 UI 还显示「运行中」
	if GameManager != null and not GameManager.pending_event.is_empty():
		pause_for("有事发生")
		return
	if not _can_flow():
		return
	_acc += delta * time_scale
	var guard := 0
	while _acc >= SECONDS_PER_DAY and guard < 8:
		guard += 1
		_acc -= SECONDS_PER_DAY
		var r: Dictionary = GameManager.advance_day()
		day_changed.emit(GameManager.p.day, GameManager.p.week, GameManager.p.year)
		if bool(r.get("should_pause", false)):
			pause_for(str(r.get("pause_reason", "")))
			break

## 什么时候不该流动：不在生涯页、有弹窗、有比赛、在退役结算
func _can_flow() -> bool:
	if GameManager == null:
		return false
	if GameManager.phase != GameManager.Phase.CAREER:
		return false
	if not GameManager.pending_event.is_empty():
		return false
	if not GameManager.active_run.is_empty() and not bool(GameManager.active_run.get("done", false)):
		return false
	if GameManager.p.injury_weeks > 0 and GameManager.p.stamina_cur < 12.0:
		return false
	return true
