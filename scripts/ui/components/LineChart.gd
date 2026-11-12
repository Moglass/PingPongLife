class_name LineChart
extends Control
## 排名 / 实力折线图：坐标反转（排名越小越靠上），带节点脉冲。

var points: Array[float] = []
var labels: Array[String] = []
var invert: bool = true
var color: Color = UIKit.CYAN
var fill_area: bool = true
var max_hint: float = 100.0

var _reveal: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(280, 140)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		_reveal = v
		queue_redraw()
	, 0.0, 1.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func set_points(pts: Array) -> void:
	points.clear()
	for p in pts:
		points.append(float(p))
	queue_redraw()

func _draw() -> void:
	if points.size() < 2:
		var f := ThemeDB.fallback_font
		draw_string(f, Vector2(8, size.y * 0.5), "数据不足", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIKit.INK_3)
		return
	var pad_l := 6.0
	var pad_r := 6.0
	var pad_t := 10.0
	var pad_b := 16.0
	var w := size.x - pad_l - pad_r
	var h := size.y - pad_t - pad_b

	var lo: float = points[0]
	var hi: float = points[0]
	for v in points:
		lo = minf(lo, v)
		hi = maxf(hi, v)
	if absf(hi - lo) < 0.001:
		hi = lo + 1.0

	# 横向基准线
	for i in range(3):
		var yy := pad_t + h * float(i) / 2.0
		draw_line(Vector2(pad_l, yy), Vector2(size.x - pad_r, yy), UIKit.LINE_SOFT, 1.0)

	var pts := PackedVector2Array()
	var count := points.size()
	for i in range(count):
		var tx := pad_l + w * float(i) / float(maxi(1, count - 1))
		var norm := (points[i] - lo) / (hi - lo)
		if invert:
			norm = 1.0 - norm
		var ty := pad_t + h * norm
		pts.append(Vector2(tx, ty))

	var shown := int(ceil(float(pts.size()) * _reveal))
	if shown < 2:
		return
	var seg := PackedVector2Array()
	for i in range(shown):
		seg.append(pts[i])

	if fill_area and seg.size() > 1:
		var poly: PackedVector2Array = seg.duplicate()
		poly.append(Vector2(seg[seg.size() - 1].x, size.y - pad_b))
		poly.append(Vector2(seg[0].x, size.y - pad_b))
		draw_colored_polygon(poly, Color(color.r, color.g, color.b, 0.08))

	draw_polyline(seg, color, 1.8, true)
	for i in range(seg.size()):
		var r := 3.0
		if i == seg.size() - 1:
			r = 4.2
		draw_circle(seg[i], r, color)
		draw_circle(seg[i], r + 2.0, Color(color.r, color.g, color.b, 0.15))
