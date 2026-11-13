class_name InputAdapter
extends RefCounted
## 输入适配：鼠标 / 键盘 / 触控统一到「确认」和「取消」两个语义。
## 具体事件映射由 project.godot 的 emulate_mouse_from_touch 处理，
## 这里只提供语义查询，避免页面里散落 InputEventMouseButton 判断。

static func is_touch_device() -> bool:
	return PlatformAdapter.is_mobile()

## 这一帧是否按下了「确认」（回车 / 空格 / 鼠标左键）
static func confirm_pressed(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE
	return false

static func cancel_pressed(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ESCAPE
	return false

## 全局提示文案：不同平台的操作说明
static func hint_text() -> String:
	if PlatformAdapter.is_mobile():
		return "点击继续"
	return "空格：下一周"
