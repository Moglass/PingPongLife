class_name RadarChart
extends Control
## 五维雷达图：进攻 / 防守 / 控制 / 体能 / 心理。
## 纯 _draw 绘制，支持入场生长动画与双人叠图（赛后对比）。

var values: Array[float] = [0, 0, 0, 0, 0]
var values_b: Array[float] = []
var labels: Array[String] = ["进攻", "防守", "控制", "体能", "心理"]
var max_value: float = 124.0
var color_a: Color = UIKit.CYAN
var color_b: Color = UIKit.RED
var name_a: String = "你"
var name_b: String = ""
var show_labels: bool = true

var _reveal: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(230, 210)
	if _reveal == 0.0:
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void:
			_reveal = v
			queue_redraw()
		, 0.0, 1.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func set_values(a: Array, b: Array = []) -> void:
	values.clear()
	for v in a:
		values.append(float(v))
	while values.size() < 5:
		values.append(0.0)
	values_b.clear()
	for v in b:
		values_b.append(float(v))
	queue_redraw()

func _draw() -> void:
	var n := 5
	var center := size * 0.5
	var radius: float = minf(size.x, size.y) * 0.34
	var ang0 := -PI * 0.5

	# 网格
	for ring in range(1, 5):
		var rr := radius * float(ring) / 4.0
		var pts := PackedVector2Array()
		for i in range(n):
			var a := ang0 + TAU * float(i) / float(n)
			pts.append(center + Vector2(cos(a), sin(a)) * rr)
		pts.append(pts[0])
		draw_polyline(pts, UIKit.LINE_SOFT, 1.0, true)

	# 轴线
	for i in range(n):
		var a := ang0 + TAU * float(i) / float(n)
		var p := center + Vector2(cos(a), sin(a)) * radius
		draw_line(center, p, UIKit.LINE_SOFT, 1.0, true)

	# 数据面
	if values.size() >= 5:
		_draw_polygon(values, color_a)

	if values_b.size() >= 5:
		_draw_polygon(values_b, color_b)

	# 标签
	if show_labels:
		var f := UIKit.font()
		for i in range(n):
			var a := ang0 + TAU * float(i) / float(n)
			var p := center + Vector2(cos(a), sin(a)) * (radius + 18.0)
			var txt := labels[i] if i < labels.size() else ""
			var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(f, p - Vector2(w * 0.5, 0.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIKit.INK_3)

func _draw_polygon(vals: Array[float], col: Color) -> void:
	var n := 5
	var center := size * 0.5
	var radius: float = minf(size.x, size.y) * 0.34
	var ang0 := -PI * 0.5
	var pts := PackedVector2Array()
	for i in range(n):
		var a := ang0 + TAU * float(i) / float(n)
		var rv: float = clampf(vals[i] / max_value, 0.0, 1.0) * radius * _reveal
		pts.append(center + Vector2(cos(a), sin(a)) * rv)
	if pts.size() < 3:
		return
	pts.append(pts[0])
	draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.14))
	draw_polyline(pts, col, 1.6, true)
	for i in range(n):
		draw_circle(pts[i], 2.4, col)
