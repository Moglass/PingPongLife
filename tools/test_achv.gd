extends Node
## 成就判定回归：新生涯不该解锁任何名次成就；把 record 改成真实名次后才解锁。

func _ready() -> void:
	# 清空历史档案，模拟全新玩家
	DataManager.profile["achievements"] = {}
	DataManager.save_profile()
	GameManager.new_career("测试", "prodigy")
	print("[ACHV] 初始已解锁 ", GameManager.achv.count())

	# 第一周做一次训练，看会不会爆发
	GameManager.p.ap = 3
	GameManager.train("tech", "fh")
	GameManager._check_achievements()
	print("[ACHV] 训练后已解锁 ", GameManager.achv.count())
	var bad := []
	for a in DataManager.db.ACHV:
		if GameManager.achv.is_unlocked(str(a["id"])):
			bad.append("%s(%s=%s)" % [str(a.get("n","")), str(a.get("k","")), str(a.get("v",""))])
	print("[ACHV] 第一周就解锁的: ", bad)

	# 造一个「世界第一」的 record，应该能正确解锁
	GameManager.p.record["best_adult"] = 1
	GameManager._check_achievements()
	print("[ACHV] 设为世界第一后解锁 ", GameManager.achv.count())

	# 撤销：改成未上榜，sanitize 应该收回
	GameManager.p.record["best_adult"] = 999
	var removed := GameManager.achv.sanitize(GameManager.p)
	print("[ACHV] sanitize 收回 ", removed, " 条，剩余 ", GameManager.achv.count())

	# 再跑 26 周，确认没有异常爆发
	for i in range(26):
		GameManager.p.ap = 3
		GameManager.train("fit")
		GameManager.advance_week()
	print("[ACHV] 26 周后已解锁 ", GameManager.achv.count(), " / ", GameManager.achv.total())
	get_tree().quit()
