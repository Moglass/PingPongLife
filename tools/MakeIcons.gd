extends Node
## 从 icon.svg 生成 iOS/Android 需要的 PNG 图标。

func _ready() -> void:
	var tex: Texture2D = load("res://icon.svg")
	var base: Image = tex.get_image()
	if base == null:
		print("no image"); get_tree().quit(); return
	base.convert(Image.FORMAT_RGBA8)
	var sizes := [1024, 180, 167, 152, 120, 87, 80, 76, 60, 40, 29, 20]
	for s in sizes:
		var img := base.duplicate() as Image
		img.resize(s, s, Image.INTERPOLATE_LANCZOS)
		var path := "res://assets/icons/icon_%d.png" % s
		img.save_png(path)
		print("[ICON] ", path)
	get_tree().quit()
