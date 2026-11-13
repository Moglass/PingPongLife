extends Node
## 全局信号总线（Autoload）。
## 只承载「跨场景」事件；单场景内的通信请用局部 signal。
## 命名统一 snake_case，参数全部显式类型。

# ---- 时间与阶段 ----
signal week_started(week: int, year: int)
signal day_advanced(day: int, week: int, year: int)

signal week_settled(report: Dictionary)
signal season_changed(year: int)
signal stage_changed(stage_index: int, stage_name: String)

# ---- 比赛 ----
signal match_started(context: Dictionary)
signal match_point(point: Dictionary)
signal match_game_ended(game_index: int, score: Dictionary)
signal match_finished(result: Dictionary)

# ---- 世界反馈 ----
signal forum_thread_created(thread: Dictionary)
signal status_effect_changed(effects: Array)
signal career_pressure(level: int, payload: Dictionary)
signal player_retired(reason: String, ending_id: String)

# ---- 表现层 ----
signal toast_requested(text: String, tone: String)
signal sfx_requested(id: String)
signal ambience_requested(mode: String, intensity: float)
signal camera_shake_requested(strength: float, duration: float)
signal save_completed(slot: int)
