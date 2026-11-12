class_name TableRenderer
extends Control
## 球台渲染器：透视梯形球台 + 光点 + 拖尾 + 落点波纹 + 球员光环。
## 全部由 _draw 与 Tween 驱动，零位图资源。
##
## 坐标约定：u ∈ [0,1] 横向，v ∈ [0,1] 纵向（0 = 远端 / 对手，1 = 近端 / 玩家）。

const NEAR_L := Vector2(0.06, 0.88)
const NEAR_R := Vector2(0.94, 0.88)
const FAR_L := Vector2(0.26, 0.12)
const FAR_R := Vector2(0.74, 0.12)

var color_player: Color = UIKit.CYAN
var color_opp: Color = UIKit.RED
var color_table: Color = Color("#2c6e8f")
var home_advantage: bool = false

var stamina_player: float = 100.0
var stamina_opp: float = 100.0

var _ball_t: float = 0.0
var _ball_active: bool = false
var _ball_from: Vector2 = Vector2(0.5, 0.8)
var _ball_to: Vector2 = Vector2(0.5, 0.2)
var _ball_arc: float = 0.0
var _ball_style: String = "drive"
var _ball_color: Color = UIKit.RED
var _trail: Array[Vector2] = []
var _ripples: Array[Dictionary] = []
var _shake: Vector2 = Vector2.ZERO
var _flash: float = 0.0
var _net_flash: float = 0.0
var _pulse: float = 0.0
var _highlight_zone: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	_pulse += delta
	# 波纹寿命
	for i in range(_ripples.size() - 1, -1, -1):
		_ripples[i]["life"] = float(_ripples[i]["life"]) - delta
		if float(_ripples[i]["life"]) <= 0.0:
			_ripples.remove_at(i)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.2)
	if _net_flash > 0.0:
		_net_flash = maxf(0.0, _net_flash - delta * 2.6)
	queue_redraw()

# ---------------------------------------------------------------- 坐标

func court_point(u: float, v: float) -> Vector2:
	var left := FAR_L.lerp(NEAR_L, v)
	var right := FAR_R.lerp(NEAR_R, v)
	return Vector2(lerpf(left.x, right.x, u) * size.x, lerpf(left.y, right.y, v) * size.y)

func _ball_pos() -> Vector2:
	var base := _ball_from.lerp(_ball_to, _ball_t)
	# 弧线：垂直于行进方向的抛物偏移
	var mid := (_ball_from + _ball_to) * 0.5
	var dir := (_ball_to - _ball_from)
	var perp := Vector2(-dir.y, dir.x).normalized()
	var arc := sin(_ball_t * PI) * _ball_arc
	base += perp * arc
	return court_point(base.x, base.y)

# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	var off := _shake
	# 台面
	var pts := PackedVector2Array([
		court_point(0, 0) + off, court_point(1, 0) + off,
		court_point(1, 1) + off, court_point(0, 1) + off,
	])
	var fill := Color(color_table.r, color_table.g, color_table.b, 0.075)
	draw_colored_polygon(pts, fill)

	# 外框（主场金色 / 客场暗色）
	var frame_col := Color(UIKit.GOLD.r, UIKit.GOLD.g, UIKit.GOLD.b, 0.55) if home_advantage else Color(color_table.r, color_table.g, color_table.b, 0.45)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), frame_col, 1.4, true)

	# 中线
	draw_line(court_point(0.5, 0) + off, court_point(0.5, 1) + off, Color(color_table.r, color_table.g, color_table.b, 0.20), 1.0)
	# 边线内缩
	draw_polyline(PackedVector2Array([
		court_point(0.03, 0.02) + off, court_point(0.97, 0.02) + off,
		court_point(0.97, 0.98) + off, court_point(0.03, 0.98) + off,
		court_point(0.03, 0.02) + off,
	]), Color(color_table.r, color_table.g, color_table.b, 0.16), 1.0)

	# 球网
	var nl := court_point(-0.04, 0.5) + off
	var nr := court_point(1.04, 0.5) + off
	var net_col := Color(UIKit.INK.r, UIKit.INK.g, UIKit.INK.b, 0.55)
	if _net_flash > 0.0:
		net_col = Color(UIKit.GOLD.r, UIKit.GOLD.g, UIKit.GOLD.b, 0.5 + _net_flash)
	draw_line(nl, nr, net_col, 2.0, true)
	# 网柱
	draw_circle(nl, 2.2, net_col)
	draw_circle(nr, 2.2, net_col)

	# 落点波纹
	for r in _ripples:
		var p: Vector2 = r["pos"] + off
		var life := float(r["life"])
		var t := 1.0 - life / 0.7
		var col: Color = r["color"]
		var rad := 8.0 + t * 42.0
		draw_arc(p, rad, 0, TAU, 36, Color(col.r, col.g, col.b, (1.0 - t) * 0.55), 1.4, true)
		draw_arc(p, rad * 0.55, 0, TAU, 24, Color(col.r, col.g, col.b, (1.0 - t) * 0.28), 1.0, true)

	# 球员光环
	_draw_cursor(court_point(0.5, 1.02) + off, stamina_player, color_player)
	_draw_cursor(court_point(0.5, -0.02) + off, stamina_opp, color_opp, true)

	# 拖尾
	if _trail.size() > 1:
		for i in range(1, _trail.size()):
			var a := float(i) / float(_trail.size())
			draw_line(_trail[i - 1] + off, _trail[i] + off, Color(_ball_color.r, _ball_color.g, _ball_color.b, a * 0.28), 1.0 + a * 2.0, true)

	# 光点
	if _ball_active:
		var bp := _ball_pos() + off
		if _ball_style == "drive":
			# 拉长光束
			var d := (_ball_to - _ball_from).normalized()
			var tail := bp - d * 26.0
			draw_line(tail, bp, Color(_ball_color.r, _ball_color.g, _ball_color.b, 0.6), 3.0, true)
			draw_circle(bp, 3.6, _ball_color)
		elif _ball_style == "loop":
			draw_circle(bp, 4.0, _ball_color)
			draw_arc(bp, 9.0, _pulse * 6.0, _pulse * 6.0 + PI * 1.3, 20, Color(_ball_color.r, _ball_color.g, _ball_color.b, 0.5), 1.2, true)
		elif _ball_style == "short":
			draw_circle(bp, 2.6, _ball_color)
		else:
			draw_circle(bp, 3.2, Color(_ball_color.r, _ball_color.g, _ball_color.b, 0.85))

	# 十字闪光
	if _flash > 0.0:
		var c := court_point(0.5, 0.5) + off
		draw_line(c - Vector2(40, 0) * _flash, c + Vector2(40, 0) * _flash, Color(1, 1, 1, _flash * 0.8), 1.0)
		draw_line(c - Vector2(0, 40) * _flash, c + Vector2(0, 40) * _flash, Color(1, 1, 1, _flash * 0.8), 1.0)

func _draw_cursor(pos: Vector2, stamina: float, col: Color, is_opp: bool = false) -> void:
	var base := 15.0
	var a := 0.55 if not is_opp else 0.42
	draw_arc(pos, base, 0, TAU, 40, Color(col.r, col.g, col.b, a), 1.2, true)
	# 体力环
	var frac := clampf(stamina / 100.0, 0.0, 1.0)
	var ring_col := col
	if frac < 0.3:
		ring_col = UIKit.RED
	draw_arc(pos, base + 5.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 40, Color(ring_col.r, ring_col.g, ring_col.b, 0.85), 1.8, true)
	# 核心
	draw_circle(pos, 2.2, Color(col.r, col.g, col.b, 0.9))

# ---------------------------------------------------------------- 动画 API

## 打一球。返回 Tween，调用方可 await。
func animate_ball(from_uv: Vector2, to_uv: Vector2, style: String, dur: float = 0.32) -> Tween:
	_ball_from = from_uv
	_ball_to = to_uv
	_ball_style = style
	_ball_arc = 0.0
	match style:
		"drive":
			_ball_arc = 0.04
			_ball_color = UIKit.RED
		"loop":
			_ball_arc = 0.10
			_ball_color = Color("#c0563f")
		"short":
			_ball_arc = -0.03
			_ball_color = UIKit.CYAN
		"pips":
			_ball_arc = 0.13
			_ball_color = Color("#7a5aa0")
		_:
			_ball_arc = 0.05
			_ball_color = UIKit.RED
	_ball_t = 0.0
	_ball_active = true
	_trail.clear()
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		_ball_t = t
		_trail.append(_ball_pos())
		if _trail.size() > 9:
			_trail.pop_front()
	, 0.0, 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return tw

func ripple(uv: Vector2, col: Color = UIKit.RED) -> void:
	_ripples.append({"pos": court_point(uv.x, uv.y), "life": 0.7, "color": col})

func hide_ball() -> void:
	_ball_active = false
	_trail.clear()

func flash() -> void:
	_flash = 1.0

func net_flash() -> void:
	_net_flash = 1.0

func shake(strength: float = 4.0, dur: float = 0.18) -> void:
	var tw := create_tween()
	var steps := 5
	for i in range(steps):
		tw.tween_callback(func() -> void:
			_shake = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		)
		tw.tween_interval(dur / float(steps))
	tw.tween_callback(func() -> void: _shake = Vector2.ZERO)
