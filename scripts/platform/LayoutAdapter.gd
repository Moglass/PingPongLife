class_name LayoutAdapter
extends RefCounted
## 布局与屏幕：基础分辨率切换、安全区、横竖屏判定。
## 页面只问「是不是竖屏 / 安全区多少」，不自己读 DisplayServer。

const LANDSCAPE_SIZE := Vector2i(1600, 900)
const PORTRAIT_SIZE := Vector2i(900, 1600)

static func is_portrait() -> bool:
	var sz := DisplayServer.window_get_size()
	if sz.x <= 0 or sz.y <= 0:
		return false
	return sz.y > sz.x

## 切换 CanvasItems 基准分辨率。必须三项一起设，否则 expand 会把竖屏拉成 1600×3000。
static func apply_content_scale() -> void:
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var w: Window = tree.root.get_window()
	if w == null:
		return
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	var target := PORTRAIT_SIZE if win.y > win.x else LANDSCAPE_SIZE
	if w.content_scale_size != target:
		w.content_scale_size = target

## 安全区内边距（像素，已按窗口坐标）
static func safe_area() -> Dictionary:
	if not PlatformAdapter.is_mobile():
		return {"top": 0, "bottom": 0}
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return {"top": 0, "bottom": 0}
	return {
		"top": maxi(0, safe.position.y),
		"bottom": maxi(0, win.y - (safe.position.y + safe.size.y)),
	}

## 触控目标最小高度
static func touch_h(base: int) -> int:
	return maxi(base, 46) if PlatformAdapter.is_mobile() else base
