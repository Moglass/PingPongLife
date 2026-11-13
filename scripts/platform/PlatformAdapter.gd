class_name PlatformAdapter
extends RefCounted
## 平台能力探测（唯一入口）。
## 其它模块不允许直接写 OS.has_feature("web")，一律走这里，
## 避免判断散落在每个页面里。

enum Kind { DESKTOP, WEB, MOBILE_NATIVE }

static func kind() -> Kind:
	if OS.has_feature("web"):
		return Kind.WEB
	if OS.has_feature("mobile"):
		return Kind.MOBILE_NATIVE
	return Kind.DESKTOP

static func is_web() -> bool:
	return OS.has_feature("web")

static func is_desktop() -> bool:
	return not OS.has_feature("web") and not OS.has_feature("mobile")

static func is_mobile() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web") and _web_is_touch()

## Web 端用 JS 判断是否触屏设备（UA + maxTouchPoints）
static func _web_is_touch() -> bool:
	if not OS.has_feature("web"):
		return false
	var js := """
	(function(){
		try {
			return (navigator.maxTouchPoints > 1) ||
				/iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
		} catch(e) { return false; }
	})()
	"""
	var r: Variant = JavaScriptBridge.eval(js, true)
	return bool(r) if r != null else false

## 是否支持「下载文件」（Web 用 a[download]，桌面用 user:// 目录）
static func can_download() -> bool:
	return true

## 是否支持系统字体回退（Web 端不保证）
static func has_system_fonts() -> bool:
	return not is_web()

static func label() -> String:
	match kind():
		Kind.WEB: return "Web"
		Kind.MOBILE_NATIVE: return "Mobile"
		_: return "Desktop"
