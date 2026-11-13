class_name SmoothScroll
extends ScrollContainer
## 移动端可拖拽的滚动容器。
##
## 为什么不用原生 ScrollContainer：它的拖拽逻辑在 _gui_input 里，
## 而列表里的 Button 会先消费到底下的触摸事件（Button 的 mouse_filter 是 STOP），
## 于是「手指按在卡片上往下划」完全滚不动，只有按住卡片之间的缝隙才行。
## 真机上体感就是「滑动有点问题，有时候滑不动」。
##
## 这里改在 _input 阶段接管：它早于 GUI 事件分发，能拿到原始触摸；
## 移动超过死区才认定是拖拽，并标记事件已处理，避免误触按钮。
## 点击（按下即抬起、位移小于死区）不受影响，按钮照常工作。

const DEADZONE := 10.0

var _touch_index := -1
var _start_pos := Vector2.ZERO
var _dragging := false
var _dragged_enough := false

func _ready() -> void:
	# 移动端横向滚动没有意义，关掉可以省掉一层手势冲突
	horizontal_scroll_mode = SCROLL_MODE_DISABLED
	vertical_scroll_mode = SCROLL_MODE_AUTO
	follow_focus = true
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _touch_index == -1:
				_touch_index = t.index
				_start_pos = t.position
				_dragging = false
				_dragged_enough = false
		elif t.index == _touch_index:
			_touch_index = -1
			_dragging = false
		return

	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index != _touch_index:
			return
		if not _dragging:
			if d.position.distance_to(_start_pos) < DEADZONE:
				return
			_dragging = true
			_dragged_enough = true
		# 手指上移 => 内容上移 => scroll_vertical 增大，所以是减 relative
		scroll_vertical = int(scroll_vertical - d.relative.y)
		get_viewport().set_input_as_handled()
		return

	# 滚轮交给原生 ScrollContainer 处理，这里不重复接管，
	# 否则桌面端一次滚轮会滚动两倍。
