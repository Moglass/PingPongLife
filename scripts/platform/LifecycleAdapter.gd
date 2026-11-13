class_name LifecycleAdapter
extends RefCounted
## 生命周期：切后台 / 回前台。
## Web 上浏览器标签切换会触发 focus out，此时暂停并落盘，避免后台空转和丢档。

static var _paused_by_lifecycle: bool = false

static func on_focus_out() -> void:
	if _paused_by_lifecycle:
		return
	_paused_by_lifecycle = true
	Engine.time_scale = 0.0
	AudioServer.set_bus_mute(0, true)
	# 自动存档：切后台前把当前生涯落到 1 号槽
	if GameManager.phase != GameManager.Phase.TITLE and GameManager.phase != GameManager.Phase.RETIRED:
		GameManager.save_to(1)

static func on_focus_in() -> void:
	if not _paused_by_lifecycle:
		return
	_paused_by_lifecycle = false
	Engine.time_scale = 1.0
	AudioServer.set_bus_mute(0, false)

static func is_paused() -> bool:
	return _paused_by_lifecycle
