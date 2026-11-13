class_name StorageAdapter
extends RefCounted
## 存档的跨平台迁移：导出「存档码」，在另一台设备粘贴导入。
##
## 为什么用文本码而不是文件：
## - Web 端没有可写的用户目录，浏览器下载受弹窗拦截影响；
## - iOS Safari 的文件 App 交互成本高；
## - 一段 Base64 文本可以复制到微信/备忘录，PC→手机是最短路径。
##
## 格式：PPL1.<base64(JSON)>，前缀用于识别与版本校验。

const TAG := "PPL1"

## 导出当前生涯为存档码
static func export_code(slot: int = 1) -> String:
	var state := GameManager.snapshot()
	state["exported_at"] = Time.get_datetime_string_from_system()
	var json := JSON.stringify({"v": DataManager.SAVE_VERSION, "state": state})
	var b64 := Marshalls.utf8_to_base64(json)
	return "%s.%s" % [TAG, b64]

## 从存档码导入。返回 {ok, text}
static func import_code(code: String) -> Dictionary:
	var raw := code.strip_edges()
	if not raw.begins_with(TAG + "."):
		return {"ok": false, "text": "这不是有效的存档码。"}
	var b64 := raw.substr(TAG.length() + 1)
	var json := Marshalls.base64_to_utf8(b64)
	if json == "":
		return {"ok": false, "text": "存档码已损坏。"}
	var parsed: Variant = JSON.parse_string(json)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "text": "存档码无法解析。"}
	var payload: Dictionary = parsed
	var ver := int(payload.get("v", 0))
	if ver > DataManager.SAVE_VERSION:
		return {"ok": false, "text": "存档来自更新的版本（v%d），请升级游戏。" % ver}
	var state: Dictionary = payload.get("state", {})
	if state.is_empty():
		return {"ok": false, "text": "存档内容为空。"}
	state = DataManager.repair_types(state)
	var ok := GameManager.restore(state)
	if not ok:
		return {"ok": false, "text": "存档结构不兼容。"}
	return {"ok": true, "text": "已导入：%s · %d 岁。" % [GameManager.p.player_name, GameManager.p.age]}

## Web：触发浏览器下载（桌面端写 user://exports/）
static func download_code(code: String, filename: String = "pingpong_save.txt") -> String:
	if PlatformAdapter.is_web():
		var js := """
		(function(){
			try {
				const text = %s;
				const blob = new Blob([text], {type: 'text/plain'});
				const a = document.createElement('a');
				a.href = URL.createObjectURL(blob);
				a.download = %s;
				document.body.appendChild(a);
				a.click();
				setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 1500);
				return 'ok';
			} catch(e) { return 'err:' + e.message; }
		})()
		""" % [JSON.stringify(code), JSON.stringify(filename)]
		var r: Variant = JavaScriptBridge.eval(js, true)
		return str(r) if r != null else "err"
	DirAccess.make_dir_recursive_absolute("user://exports")
	var path := "user://exports/" + filename
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return "err"
	f.store_string(code)
	f.close()
	return ProjectSettings.globalize_path(path)

## 存档体积（用于 UI 提示）
static func code_size(code: String) -> String:
	var kb := float(code.length()) / 1024.0
	return "%.1f KB" % kb
