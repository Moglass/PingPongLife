extends Node
## 竖屏适配验证：把窗口压成 480x900，截日常页。

func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(480, 900))
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	var main: Control = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	GameManager.new_career("陈默", "prodigy")
	main._enter_game()
	for i in range(40):
		GameManager.p.ap = 3
		GameManager.train("tech", "fh")
		GameManager.advance_week()
	main.show_page(main.Page.CAREER)
	await get_tree().create_timer(0.8).timeout
	await get_tree().process_frame
	print("[PORTRAIT] viewport=", get_viewport().get_visible_rect().size,
		" window=", DisplayServer.window_get_size(),
		" scale_size=", get_window().content_scale_size,
		" is_portrait=", UIKit.is_portrait())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("D:/workbuddys/table tennis/PingPongLife/shots/17_portrait.png")
	get_tree().quit()
