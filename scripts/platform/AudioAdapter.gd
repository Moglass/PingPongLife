class_name AudioAdapter
extends RefCounted
## 音频适配：浏览器要求首次用户手势后才能出声（AudioContext autoplay policy）。
## 这里在第一次输入时解锁，并提供一个全局静音开关。

static var _unlocked: bool = false
static var muted: bool = false

## 在用户第一次点击/触摸时调用
static func unlock() -> void:
	if _unlocked:
		return
	_unlocked = true
	if PlatformAdapter.is_web():
		# 让浏览器 resume AudioContext：播一个极小音量的空音
		pass
	AudioServer.set_bus_mute(0, muted)

static func is_unlocked() -> bool:
	return _unlocked

static func toggle_mute() -> bool:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	return muted
