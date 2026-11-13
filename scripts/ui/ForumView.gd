extends Control
## 论坛页：完整帖子流 + 楼中楼。极简文字流，几何头像。

var main: Control

func setup(m: Control) -> void:
	main = m
	_build()

func _build() -> void:
	var vb := UIKit.vbox(12)
	var root := UIKit.margin(vb, 26, 18, 26, 12)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var head := UIKit.hbox(10)
	head.add_child(UIKit.label("论坛", 26, UIKit.INK))
	head.add_child(UIKit.label("赛博看台", 13, UIKit.INK_3))
	head.add_child(UIKit.hfill())
	head.add_child(UIKit.dim("热度 %d · %d 条讨论" % [ForumManager.heat, ForumManager.threads.size()], 12))
	vb.add_child(head)

	var scroll := SmoothScroll.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var list := UIKit.vbox(0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	if ForumManager.threads.is_empty():
		list.add_child(UIKit.dim("还没有帖子。打一场比赛，或者等一周。", 13))
		return

	for t in ForumManager.threads:
		list.add_child(_post(t))
		list.add_child(UIKit.hsep(UIKit.LINE_SOFT))

func _post(t: Dictionary) -> Control:
	var pc := UIKit.panel(UIKit.WHITE, Color.TRANSPARENT, 0)
	var vb := UIKit.vbox(8)
	var m := UIKit.margin(vb, 14, 14, 14, 14)
	pc.add_child(m)

	var head := UIKit.hbox(8)
	var fac := str(t.get("faction", "neutral"))
	var av := _avatar(str(t.get("user", "")), Color(str(ForumManager.FACTION_COLOR.get(fac, "#8a8175"))))
	head.add_child(av)
	var name_v := UIKit.vbox(1)
	name_v.add_child(UIKit.label(str(t.get("user", "")), 13, UIKit.INK))
	name_v.add_child(UIKit.dim("%s · 第 %d 周" % [str(ForumManager.FACTION_NAME.get(fac, "")), int(t.get("week", 0))], 10))
	head.add_child(name_v)
	head.add_child(UIKit.hfill())
	if str(t.get("tag", "")) != "":
		head.add_child(UIKit.chip(str(t["tag"]), Color(str(ForumManager.FACTION_COLOR.get(fac, "#8a8175"))), false))
	vb.add_child(head)

	vb.add_child(UIKit.wrap(str(t.get("title", "")), 17, UIKit.INK))
	if str(t.get("body", "")) != "":
		vb.add_child(UIKit.wrap(str(t.get("body", "")), 14, UIKit.INK_2))

	var bar := UIKit.hbox(14)
	bar.add_child(UIKit.dim("♥ %d" % int(t.get("likes", 0)), 11))
	bar.add_child(UIKit.dim("✕ %d" % int(t.get("dislikes", 0)), 11))
	bar.add_child(UIKit.hfill())
	bar.add_child(UIKit.dim("%d 条回复" % t.get("replies", []).size(), 11))
	vb.add_child(bar)

	var replies: Array = t.get("replies", [])
	for r in replies:
		var rvb := UIKit.vbox(2)
		var rh := UIKit.hbox(6)
		var rf := str(r.get("faction", ""))
		rh.add_child(UIKit.label(str(r.get("user", "")), 11, Color(str(ForumManager.FACTION_COLOR.get(rf, "#8a8175")))))
		rh.add_child(UIKit.dim("· %s" % str(ForumManager.FACTION_NAME.get(rf, "")), 10))
		rvb.add_child(rh)
		rvb.add_child(UIKit.wrap(str(r.get("text", "")), 12, UIKit.INK_2))
		var rm := UIKit.margin(rvb, 12, 4, 0, 4)
		vb.add_child(rm)

	return pc

func _avatar(name: String, col: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(28, 28)
	var ch := name.substr(0, 1)
	var sz := 28.0
	c.draw.connect(func() -> void:
		c.draw_rect(Rect2(Vector2.ZERO, Vector2(sz, sz)), Color(col.r, col.g, col.b, 0.12), true)
		c.draw_rect(Rect2(Vector2.ZERO, Vector2(sz, sz)), Color(col.r, col.g, col.b, 0.35), false, 1.0)
		var f := ThemeDB.fallback_font
		var w := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		c.draw_string(f, Vector2(sz * 0.5 - w * 0.5, sz * 0.5 + 4), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
	)
	return c
