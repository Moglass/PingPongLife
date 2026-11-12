class_name GearSystem
extends RefCounted
## 器材系统：一块拍、正反手胶皮、鞋、球衣。
## 装备只加「四维」小数值（atk/ctrl/defn/mob），不改变技术上限——
## 器材让你打得舒服，不让你变成另一个人。

const SLOTS: Array[Dictionary] = [
	{"k": "blade", "n": "底板", "d": "决定手感的地基"},
	{"k": "fh", "n": "正手胶皮", "d": "吃球、摩擦、出球速度"},
	{"k": "bh", "n": "反手胶皮", "d": "拧拉与相持的质量"},
	{"k": "shoe", "n": "球鞋", "d": "步法的下限"},
	{"k": "shirt", "n": "球衣", "d": "轻一点，汗少一点"},
]

var equipped: Dictionary = {
	"blade": "bl1", "fh": "fh1", "bh": "bh1", "shoe": "sh1", "shirt": "st1",
}
var owned: Dictionary = {}

func _init() -> void:
	for s in SLOTS:
		owned[str(equipped[s["k"]])] = true

func bonus() -> Dictionary:
	var out := {"atk": 0.0, "ctrl": 0.0, "defn": 0.0, "mob": 0.0}
	for slot in equipped.keys():
		var g: Dictionary = DataManager.db.GEAR_MAP.get(str(equipped[slot]), {})
		if g.is_empty():
			continue
		out["atk"] = float(out["atk"]) + float(g.get("atk", 0))
		out["ctrl"] = float(out["ctrl"]) + float(g.get("ctrl", 0))
		out["defn"] = float(out["defn"]) + float(g.get("defn", 0))
		out["mob"] = float(out["mob"]) + float(g.get("mob", 0))
	return out

## 已解锁的器材：tier 不超过当前阶段的购买力
func shop_list(p: PlayerStats) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var max_tier := 2
	if p.stage >= 1:
		max_tier = 3
	if p.stage >= 2:
		max_tier = 4
	if p.stage >= 3:
		max_tier = 5
	if p.stage >= 4:
		max_tier = 6
	for g in DataManager.db.GEAR:
		var item: Dictionary = g
		if int(item.get("tier", 1)) > max_tier:
			continue
		var copy := item.duplicate(true)
		copy["owned"] = owned.has(str(item["id"]))
		copy["equipped"] = str(equipped.get(str(item.get("cat", "")), "")) == str(item["id"])
		copy["affordable"] = p.money >= int(item.get("price", 0))
		out.append(copy)
	return out

func buy(id: String, p: PlayerStats) -> Dictionary:
	var g: Dictionary = DataManager.db.GEAR_MAP.get(id, {})
	if g.is_empty():
		return {"ok": false, "text": "没有这件东西。"}
	if owned.has(id):
		return {"ok": false, "text": "你已经有了。"}
	var price := int(g.get("price", 0))
	if p.money < price:
		return {"ok": false, "text": "钱不够。还差 %s。" % DataManager.fmt_money(price - p.money)}
	p.money -= price
	owned[id] = true
	return {"ok": true, "text": "买下了「%s」。" % str(g.get("n", "")), "item": g}

func equip_item(id: String, p: PlayerStats) -> Dictionary:
	var g: Dictionary = DataManager.db.GEAR_MAP.get(id, {})
	if g.is_empty() or not owned.has(id):
		return {"ok": false, "text": "你还没有这件东西。"}
	var slot := str(g.get("cat", ""))
	equipped[slot] = id
	GameManager.apply_gear()
	return {"ok": true, "text": "换上「%s」。" % str(g.get("n", "")), "item": g}

## 当前装备的「性格」描述，用于档案页的一句话总结
func style_note() -> String:
	var b := bonus()
	var best := "atk"
	var bv := float(b["atk"])
	for k in ["ctrl", "defn", "mob"]:
		if float(b[k]) > bv:
			bv = float(b[k])
			best = k
	match best:
		"atk": return "这套装备偏向进攻，出球快、容错低。"
		"ctrl": return "这套装备偏向控制，台内球更听话。"
		"defn": return "这套装备偏向防守，退台之后还有球。"
		_: return "这套装备偏向移动，衔接更轻。"
