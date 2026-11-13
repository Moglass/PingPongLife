class_name UIKit
extends RefCounted
## 设计系统：纸张质感 + 墨色排版 + 极简几何。
## 所有颜色、间距、组件工厂集中在这里，页面只负责组合。
## 规则：正文用 16px，小字 13px，数字用等宽感的字号跳跃；圆角一律克制（2~4px）。

# ---- 色板 ----
const PAPER := Color("#f4f1ea")
const PAPER_2 := Color("#ece7dd")
const PAPER_3 := Color("#e2dbcd")
const INK := Color("#1e1b17")
const INK_2 := Color("#4a443c")
const INK_3 := Color("#8a8175")
const LINE := Color("#d6cfc2")
const LINE_SOFT := Color("#e3dccf")
const RED := Color("#b03a2e")
const RED_SOFT := Color("#f3e3df")
const CYAN := Color("#2c6e8f")
const CYAN_SOFT := Color("#dfeaf0")
const GOLD := Color("#9c7c2e")
const GREEN := Color("#4a6b4a")
const WHITE := Color("#fbf9f5")

# ---- 间距 ----
const GAP_XS := 4
const GAP_S := 8
const GAP_M := 14
const GAP_L := 22
const GAP_XL := 34

static func fs(size: int) -> int:
	return size

## 是否运行在触屏设备上（移动端把点击目标放到 44pt 以上）
static func is_mobile() -> bool:
	return PlatformAdapter.is_mobile()

static func touch_size(base_h: int) -> int:
	return LayoutAdapter.touch_h(base_h)

## 竖屏判定：移动端需要单栏布局
static func is_portrait() -> bool:
	return LayoutAdapter.is_portrait()

## 自绘控件（雷达图等）必须拿到同一份打包字体。
## 不能直接用 ThemeDB.fallback_font —— Web 上那是无中文字形的默认字体，会画成豆腐块。
static var _font_cache: Font = null

static func font() -> Font:
	if _font_cache == null:
		_font_cache = make_font()
	return _font_cache

## 系统字体（缺字回退用）。Web 环境没有系统字体，只作为桌面端的兜底。
static func make_system_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray([
		"Microsoft YaHei UI", "Microsoft YaHei", "PingFang SC",
		"Noto Sans CJK SC", "Noto Sans SC", "Source Han Sans SC",
		"Hiragino Sans GB", "WenQuanYi Micro Hei", "sans-serif",
	])
	f.allow_system_fallback = true
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return f

## 默认字体：打包的霞鹜文楷子集（3946 字，889KB WOFF2），缺字回退系统字体。
## 打包字体是 Web 导出的硬前提——浏览器里没有「微软雅黑」。
static func make_font() -> Font:
	if ResourceLoader.exists("res://assets/fonts/game.woff2"):
		var f: FontFile = load("res://assets/fonts/game.woff2")
		if f != null:
			var fb: Array[Font] = [make_system_font()]
			f.fallbacks = fb
			return f
	return make_system_font()

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = make_font()
	t.default_font_size = 16

	# Button
	var b_normal := _sb(PAPER_2, LINE, 2, 1)
	b_normal.content_margin_left = 14
	b_normal.content_margin_right = 14
	b_normal.content_margin_top = 8
	b_normal.content_margin_bottom = 8
	var b_hover := b_normal.duplicate() as StyleBoxFlat
	b_hover.bg_color = PAPER_3
	b_hover.border_color = INK_3
	var b_pressed := b_normal.duplicate() as StyleBoxFlat
	b_pressed.bg_color = LINE
	var b_disabled := b_normal.duplicate() as StyleBoxFlat
	b_disabled.bg_color = PAPER
	b_disabled.border_color = LINE_SOFT

	t.set_stylebox("normal", "Button", b_normal)
	t.set_stylebox("hover", "Button", b_hover)
	t.set_stylebox("pressed", "Button", b_pressed)
	t.set_stylebox("disabled", "Button", b_disabled)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", INK_3)

	# Panel
	t.set_stylebox("panel", "PanelContainer", _sb(WHITE, LINE, 3, 1))
	t.set_stylebox("panel", "Panel", _sb(WHITE, LINE, 3, 1))

	# Label
	t.set_color("font_color", "Label", INK)

	# RichTextLabel
	t.set_color("default_color", "RichTextLabel", INK)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())

	# ProgressBar
	var pb_bg := _sb(PAPER_3, Color.TRANSPARENT, 1, 0)
	pb_bg.content_margin_top = 0
	var pb_fill := _sb(CYAN, Color.TRANSPARENT, 1, 0)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fill)

	# LineEdit（Web 上默认是白字，必须显式覆盖）
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_uneditable_color", "LineEdit", INK_3)
	t.set_color("font_placeholder_color", "LineEdit", INK_3)
	t.set_color("caret_color", "LineEdit", INK)
	t.set_color("selection_color", "LineEdit", CYAN_SOFT)
	t.set_stylebox("normal", "LineEdit", _sb(WHITE, LINE, 2, 1))
	t.set_stylebox("focus", "LineEdit", _sb(WHITE, INK, 2, 1))

	# TextEdit
	t.set_color("font_color", "TextEdit", INK)
	t.set_color("caret_color", "TextEdit", INK)
	t.set_color("selection_color", "TextEdit", CYAN_SOFT)
	t.set_stylebox("normal", "TextEdit", _sb(WHITE, LINE, 2, 1))
	t.set_stylebox("focus", "TextEdit", _sb(WHITE, INK, 2, 1))

	# CheckBox / CheckButton
	t.set_color("font_color", "CheckBox", INK_2)
	t.set_color("font_hover_color", "CheckBox", INK)
	t.set_color("font_pressed_color", "CheckBox", INK)
	t.set_color("font_hover_pressed_color", "CheckBox", INK)
	t.set_color("icon_normal_color", "CheckBox", INK_3)
	t.set_color("icon_hover_color", "CheckBox", INK)
	t.set_color("icon_pressed_color", "CheckBox", RED)
	t.set_color("icon_hover_pressed_color", "CheckBox", RED)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		t.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())

	# OptionButton / PopupMenu
	t.set_color("font_color", "OptionButton", INK)
	t.set_color("font_hover_color", "OptionButton", INK)
	t.set_color("font_pressed_color", "OptionButton", INK)
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", INK)
	t.set_color("font_separator_color", "PopupMenu", INK_3)
	t.set_stylebox("panel", "PopupMenu", _sb(WHITE, LINE, 2, 1))
	t.set_stylebox("hover", "PopupMenu", _sb(PAPER_2, Color.TRANSPARENT, 2, 0))

	# Tooltip / AcceptDialog
	t.set_color("font_color", "TooltipLabel", PAPER)
	t.set_stylebox("panel", "TooltipPanel", _sb(INK, INK, 2, 0))

	# ScrollContainer 滚动条
	var grab := _sb(INK_2, Color.TRANSPARENT, 2, 0)
	grab.content_margin_left = 2
	grab.content_margin_right = 2
	grab.corner_radius_top_left = 3
	grab.corner_radius_top_right = 3
	grab.corner_radius_bottom_left = 3
	grab.corner_radius_bottom_right = 3
	t.set_stylebox("grabber", "VScrollBar", grab)
	var grab_hi := _sb(INK_3, Color.TRANSPARENT, 2, 0)
	grab_hi.content_margin_left = 2
	grab_hi.content_margin_right = 2
	grab_hi.corner_radius_top_left = 3
	grab_hi.corner_radius_top_right = 3
	grab_hi.corner_radius_bottom_left = 3
	grab_hi.corner_radius_bottom_right = 3
	t.set_stylebox("grabber_highlight", "VScrollBar", grab_hi)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab_hi)
	t.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())

	return t

static func _sb(bg: Color, border: Color, radius: int, border_w: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	return sb

# ---------------------------------------------------------------- 容器

static func vbox(sep: int = GAP_S) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b

static func hbox(sep: int = GAP_S) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	return b

static func margin(child: Control, l: int = GAP_M, t: int = GAP_M, r: int = GAP_M, b: int = GAP_M) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(child)
	return m

static func spacer(h: float = GAP_S) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

static func hfill() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

static func vfill() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c

static func hsep(color: Color = LINE) -> HSeparator:
	var s := HSeparator.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	s.add_theme_stylebox_override("separator", sb)
	return s

# ---------------------------------------------------------------- 文本

static func label(text: String, size: int = 16, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func dim(text: String, size: int = 13) -> Label:
	return label(text, size, INK_3)

static func title(text: String, size: int = 30) -> Label:
	var l := label(text, size, INK)
	l.add_theme_constant_override("outline_size", 0)
	return l

static func wrap(text: String, size: int = 16, color: Color = INK) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

static func rich(text: String, size: int = 16, color: Color = INK) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = text
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r

## 数字（带单位后缀，弱化单位）
static func num(value: String, suffix: String = "", size: int = 20, color: Color = INK) -> RichTextLabel:
	var r := rich("[b]%s[/b][color=#8a8175]%s[/color]" % [value, suffix], size, color)
	return r

# ---------------------------------------------------------------- 组件

static func panel(bg: Color = WHITE, border: Color = LINE, radius: int = 3) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(bg, border, radius, 1))
	return pc

static func card(title_text: String, body: Control, sub: String = "") -> PanelContainer:
	var pc := panel()
	var vb := vbox(GAP_S)
	var head := hbox(GAP_S)
	head.add_child(label(title_text, 15, INK))
	head.add_child(hfill())
	if sub != "":
		head.add_child(dim(sub, 12))
	vb.add_child(head)
	vb.add_child(hsep(LINE_SOFT))
	vb.add_child(body)
	pc.add_child(margin(vb, GAP_M, GAP_S + 2, GAP_M, GAP_M))
	return pc

static func btn(text: String, kind: String = "normal", cb: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(0, touch_size(38))
	match kind:
		"primary":
			b.add_theme_stylebox_override("normal", _sb(INK, INK, 2, 0))
			b.add_theme_stylebox_override("hover", _sb(INK_2, INK_2, 2, 0))
			b.add_theme_stylebox_override("pressed", _sb(Color("#000000"), Color("#000000"), 2, 0))
			for st in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
				b.add_theme_color_override(st, PAPER)
		"danger":
			b.add_theme_stylebox_override("normal", _sb(RED, RED, 2, 0))
			for st in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
				b.add_theme_color_override(st, WHITE)
		"ghost":
			b.add_theme_stylebox_override("normal", _sb(Color.TRANSPARENT, Color.TRANSPARENT, 2, 0))
			b.add_theme_stylebox_override("hover", _sb(PAPER_2, Color.TRANSPARENT, 2, 0))
			for st in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
				b.add_theme_color_override(st, INK_2)
	if cb.is_valid():
		b.pressed.connect(cb)
	b.pressed.connect(func() -> void: AudioDirector.play_sfx("ui"))
	return b

static func chip(text: String, color: Color = INK_3, filled: bool = false) -> PanelContainer:
	var pc := panel(color if filled else Color.TRANSPARENT, color, 2)
	var l := label(text, 12, PAPER if filled else color)
	l.add_theme_constant_override("outline_size", 0)
	pc.add_child(margin(l, 7, 2, 7, 2))
	return pc

static func bar(value: float, maxv: float, color: Color = CYAN, w: float = 120.0, h: float = 5.0) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.max_value = maxf(1.0, maxv)
	pb.value = clampf(value, 0.0, maxv)
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(w, h)
	pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := _sb(PAPER_3, Color.TRANSPARENT, 1, 0)
	var fill := _sb(color, Color.TRANSPARENT, 1, 0)
	pb.add_theme_stylebox_override("background", bg)
	pb.add_theme_stylebox_override("fill", fill)
	return pb

## 一行「标签 ———— 值」
static func kv(key: String, value: String, value_color: Color = INK, key_size: int = 13, val_size: int = 15) -> HBoxContainer:
	var h := hbox(GAP_S)
	var k := label(key, key_size, INK_3)
	h.add_child(k)
	h.add_child(hfill())
	var v := label(value, val_size, value_color)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	return h

## 数值变化飘字（返回节点，调用方 add_child 后自动飞走）
static func float_text(text: String, color: Color = RED) -> Label:
	var l := label(text, 15, color)
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "modulate:a", 1.0, 0.18)
	tw.tween_property(l, "position:y", l.position.y - 26.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)
	return l

static func icon_dot(color: Color, size: float = 8.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.draw.connect(func() -> void:
		c.draw_circle(Vector2(size, size) * 0.5, size * 0.5, color)
	)
	return c
