extends Node
## 论坛管理器（Autoload）：赛博看台。
## 只订阅 EventBus，按「游戏周」生成 3-5 条核心热帖；旧帖自动沉底。
##
## 结构：派系（决定立场）× 词库插槽（决定文案）× 楼中楼（强制立场冲突）
## 硬规则：论坛不直接决定胜负，只施加极小的心理涟漪。

const FACTIONS: Array[String] = ["data", "fun", "neutral", "hater", "fan"]
const FACTION_NAME: Dictionary = {
	"data": "数据帝", "fun": "乐子人", "neutral": "理中客",
	"hater": "黑粉", "fan": "死忠",
}
const FACTION_COLOR: Dictionary = {
	"data": "#2c6e8f", "fun": "#9c7c2e", "neutral": "#4a443c",
	"hater": "#b03a2e", "fan": "#4a6b4a",
}

var threads: Array[Dictionary] = []
var heat: int = 0
var _next_id: int = 1
var _used_titles: Dictionary = {}
var _recent_tpl: Array[String] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func reset() -> void:
	threads.clear()
	heat = 0
	_next_id = 1
	_used_titles.clear()

func add_thread(t: Dictionary) -> Dictionary:
	t["id"] = _next_id
	_next_id += 1
	threads.push_front(t)
	if threads.size() > 60:
		threads.resize(60)
	EventBus.forum_thread_created.emit(t)
	return t

func latest(n: int = 5) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(mini(n, threads.size())):
		out.append(threads[i])
	return out

func total_likes() -> int:
	var s := 0
	for t in threads:
		s += int(t.get("likes", 0))
	return s

# ---------------------------------------------------------------- 用户

func random_user(faction: String) -> String:
	var pre: Array = DataManager.db.HANDLE_PREFIX
	var suf: Array = DataManager.db.HANDLE_SUFFIX
	var mid_pool: Array[String] = ["", "", "的", "今天", "又", "不"]
	var mid := mid_pool[rng.randi_range(0, mid_pool.size() - 1)]
	var name := "%s%s%s" % [str(pre[rng.randi_range(0, pre.size() - 1)]), mid, str(suf[rng.randi_range(0, suf.size() - 1)])]
	if rng.randf() < 0.25:
		name += str(rng.randi_range(2, 99))
	return name

# ---------------------------------------------------------------- 绰号

## 绰号随生涯阶段演化：这比任何数值都更让玩家有实感。
func nickname(p: PlayerStats) -> String:
	var surname := p.player_name.substr(0, 1)
	if p.rank >= 1 and p.rank <= 3:
		return "%s神" % surname
	if p.rank <= 10:
		return "大魔王" if p.age >= 26 else "六边形战士"
	if p.record.get("loss_streak", 0) >= 4:
		return "软脚虾"
	if p.record.get("wins", 0) <= 2:
		return "那个小孩"
	if p.age <= 16:
		return "%s小将" % surname
	if p.rank <= 30:
		return "国乒%s" % surname
	return "%s某" % surname

# ---------------------------------------------------------------- 生成入口

## 赛后生成。result: {won, place, tourney, opp_name, score, upset, final, streak}
func generate_after_match(result: Dictionary, p: PlayerStats) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var won := bool(result.get("won", false))
	var place := int(result.get("place", 99))
	var upset := bool(result.get("upset", false))
	var is_final := bool(result.get("final", false))
	var streak := int(result.get("streak", 0))

	if won and place == 1:
		out.append(_thread("fan", "win_title", result, p))
		out.append(_thread("hater", "hater_grudging", result, p))
		out.append(_thread("fun", "fun_meme", result, p))
		out.append(_thread("data", "data_title", result, p))
	elif won and upset:
		out.append(_thread("fan", "win_upset", result, p))
		out.append(_thread("hater", "apology", result, p))
		out.append(_thread("neutral", "neutral_upset", result, p))
	elif won and is_final:
		out.append(_thread("fan", "win_final", result, p))
		out.append(_thread("data", "data_final", result, p))
	elif won:
		out.append(_thread("neutral", "win_normal", result, p))
		if rng.randf() < 0.5:
			out.append(_thread("fun", "fun_note", result, p))
	elif streak <= -3:
		out.append(_thread("hater", "loss_streak", result, p))
		out.append(_thread("fan", "fan_defend", result, p))
		out.append(_thread("neutral", "neutral_worry", result, p))
	elif place >= 17:
		out.append(_thread("hater", "loss_early", result, p))
		out.append(_thread("data", "data_loss", result, p))
	else:
		out.append(_thread("neutral", "loss_normal", result, p))
		if rng.randf() < 0.4:
			out.append(_thread("fun", "fun_loss", result, p))

	for t in out:
		add_thread(t)
	heat = clampi(heat + out.size() * 2 + (3 if place == 1 else 0), 0, 100)
	return out

## 名单公布 / 排阵相关
func generate_roster(position: String, coach_note: String, p: PlayerStats, is_controversial: bool = false) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ctx := {"position": position, "coach_note": coach_note, "won": false, "place": 99, "opp_name": "对手", "score": ""}
	if is_controversial:
		out.append(_thread("hater", "roster_why", ctx, p))
		out.append(_thread("fan", "roster_trust", ctx, p))
		out.append(_thread("neutral", "roster_neutral", ctx, p))
	else:
		out.append(_thread("neutral", "roster_ok", ctx, p))
		out.append(_thread("data", "roster_data", ctx, p))
	for t in out:
		add_thread(t)
	return out

## 退役 / 生涯节点
func generate_retire(p: PlayerStats) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append(_thread("neutral", "retire_main", {}, p))
	out.append(_thread("fan", "retire_fan", {}, p))
	if p.age >= 33:
		out.append(_thread("hater", "retire_hater", {}, p))
	for t in out:
		add_thread(t)
	return out

## 周常：训练/生活/流言，维持世界的呼吸感
func generate_week_flavor(p: PlayerStats) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var pool: Array[String] = ["flavor_canteen", "flavor_teammate", "flavor_gym", "flavor_rumor", "flavor_gear"]
	pool.shuffle()
	var n := 1 if rng.randf() < 0.55 else 2
	for i in range(n):
		out.append(_thread("fun", pool[i], {}, p))
	for t in out:
		add_thread(t)
	return out

# ---------------------------------------------------------------- 内部

func _thread(faction: String, kind: String, ctx: Dictionary, p: PlayerStats) -> Dictionary:
	var tpl := _pick_template(kind, faction)
	var nick := nickname(p)
	var opp := str(ctx.get("opp_name", "对手"))
	var score := str(ctx.get("score", ""))
	var place := int(ctx.get("place", 99))
	var title := _fill(str(tpl["title"]), p, nick, opp, score, place, ctx)
	var body := _fill(str(tpl["body"]), p, nick, opp, score, place, ctx)
	var heat_base := _heat_for(kind)
	var likes := int(heat_base * rng.randf_range(0.7, 1.8) * (1.0 + float(p.fame) / 120.0))
	var t := {
		"faction": faction,
		"user": random_user(faction),
		"title": title,
		"body": body,
		"likes": likes,
		"dislikes": int(likes * rng.randf_range(0.05, 0.35)),
		"heat": heat_base,
		"tag": str(tpl.get("tag", "")),
		"week": p.week,
		"year": p.year,
		"replies": _build_replies(kind, faction, p, nick, opp),
	}
	return t

func _pick_template(kind: String, faction: String) -> Dictionary:
	var arr: Array = TEMPLATES.get(kind, [])
	if arr.is_empty():
		arr = TEMPLATES["neutral_worry"]
	# 同派系优先，且尽量不重复最近用过的标题
	var pool: Array = []
	for t in arr:
		if str(t.get("faction", "")) == faction:
			pool.append(t)
	if pool.is_empty():
		pool = arr
	var fresh: Array = []
	for t in pool:
		if not _recent_tpl.has(kind + "|" + str(t.get("title", ""))):
			fresh.append(t)
	var chosen: Dictionary = fresh[rng.randi_range(0, fresh.size() - 1)] if not fresh.is_empty() else pool[rng.randi_range(0, pool.size() - 1)]
	_recent_tpl.append(kind + "|" + str(chosen.get("title", "")))
	if _recent_tpl.size() > 24:
		_recent_tpl.pop_front()
	return chosen

func _heat_for(kind: String) -> int:
	if kind.begins_with("win_title") or kind == "retire_main":
		return rng.randi_range(26, 48)
	if kind in ["loss_streak", "apology", "roster_why"]:
		return rng.randi_range(18, 36)
	return rng.randi_range(4, 16)

func _fill(s: String, p: PlayerStats, nick: String, opp: String, score: String, place: int, ctx: Dictionary) -> String:
	var out := s
	out = out.replace("{name}", p.player_name)
	out = out.replace("{nick}", nick)
	out = out.replace("{opp}", opp)
	out = out.replace("{score}", score)
	out = out.replace("{age}", str(p.age))
	out = out.replace("{place}", TournamentSystem.place_label(place) if place < 99 else "参赛")
	out = out.replace("{position}", str(ctx.get("position", "三单")))
	out = out.replace("{coach}", str(ctx.get("coach_note", "")))
	return out

## 楼中楼：强制拉一个对立派系来吵，制造"歪楼"的真实感。
func _build_replies(kind: String, faction: String, p: PlayerStats, nick: String, opp: String) -> Array[Dictionary]:
	var replies: Array[Dictionary] = []
	var opposing := _opposing_faction(faction)
	replies.append({
		"user": random_user(opposing),
		"faction": opposing,
		"text": _reply_text(kind, opposing, nick, opp, p),
		"likes": rng.randi_range(0, 40),
	})
	if rng.randf() < 0.62:
		replies.append({
			"user": random_user("fun"),
			"faction": "fun",
			"text": _fun_reply(kind, nick),
			"likes": rng.randi_range(1, 26),
		})
	return replies

func _opposing_faction(f: String) -> String:
	match f:
		"hater": return "fan"
		"fan": return "hater"
		"data": return "neutral"
		"neutral": return "data"
		_: return "hater"

func _reply_text(kind: String, f: String, nick: String, opp: String, p: PlayerStats) -> String:
	if f == "fan":
		var arr: Array[String] = [
			"你行你上，键盘敲得震天响。",
			"人家一年打八十场，你一年下楼两次。",
			"赢了叫运气，输了叫原形毕露，你这话术挺全。",
			"他才 %d 岁，你 %d 岁的时候在干嘛？" % [p.age, p.age],
		]
		return arr[rng.randi_range(0, arr.size() - 1)]
	if f == "hater":
		var arr2: Array[String] = [
			"吹得越高摔得越狠，等着看。",
			"这也能吹？换个对手试试。",
			"粉丝滤镜比球台还厚。",
			"上一场怎么输的，忘了？",
		]
		return arr2[rng.randi_range(0, arr2.size() - 1)]
	if f == "data":
		return "样本量太小，建议看完整个赛季再下结论。"
	return "有一说一，这场的关键不在%s，在接发球。" % nick

func _fun_reply(kind: String, nick: String) -> String:
	var arr: Array[String] = [
		"别吵了，他今天那款胶皮淘宝有卖吗？",
		"我就想知道他擦汗用的是哪条毛巾。",
		"这帖子怎么又歪楼了。",
		"建议改成竞猜楼：下一场他第几局开始摸台。",
		"路过，单纯觉得球台颜色挺好看。",
	]
	return arr[rng.randi_range(0, arr.size() - 1)]

# ---------------------------------------------------------------- 词库

const TEMPLATES: Dictionary = {
	"win_title": [
		{"faction": "fan", "tag": "夺冠", "title": "他做到了！{name} 拿下{tourney}冠军", "body": "最后一分落地的时候，他站在原地没动，像是没反应过来。过了两秒才想起举手。\n\n{age} 岁，{place}。这条路他走了太久。"},
		{"faction": "fan", "tag": "夺冠", "title": "从市体校到最高领奖台，{name} 用了 {age} 年", "body": "有人记得他第一次打市级比赛，连球衣都是借的。今天他穿着带国旗的外套，站在最高的地方。"},
		{"faction": "data", "tag": "数据", "title": "{name} 夺冠夜：正手得分率 71%，这不是运气", "body": "全场 11 板以上相持 19 次，他赢了 14 次。关键分 5 次全部拿下。\n\n数据不会说谎，但数据也解释不了他为什么在 9 平的时候还敢侧身。"},
	],
	"win_upset": [
		{"faction": "fan", "tag": "爆冷", "title": "谁认识他？现在认识了。{name} 掀翻{opp}", "body": "赛前没人看好他。赔率、排名、交手记录，没有一项站在他这边。\n\n他 3:{score} 赢了。就这样。"},
		{"faction": "neutral", "tag": "爆冷", "title": "冷静说说 {name} 赢{opp}这场", "body": "不是对手打得差，是他把节奏拖进了自己熟悉的泥潭里。前三板不抢，只求落点。这种赢法很难看，但很有效。"},
	],
	"hater_grudging": [
		{"faction": "hater", "tag": "", "title": "赢了就赢了，别吹成历史第一", "body": "一场比赛而已。等他能连续三年保持这个水平，再来谈什么时代。"},
	],
	"apology": [
		{"faction": "hater", "tag": "排队道歉", "title": "我错了，给大哥磕一个", "body": "赛前我说他撑不过第二轮。现在我在排队。\n\n对不起。"},
		{"faction": "hater", "tag": "排队道歉", "title": "道歉楼，一个一个来", "body": "我先来。之前说他“签运好”的是我，说他“心理不行”的也是我。今天这球，我服。"},
	],
	"neutral_upset": [
		{"faction": "neutral", "tag": "", "title": "有一说一，{name} 这场赢在接发球", "body": "第三局开始他站位往前压了半步，对手的短球一下就失效了。这个调整很细，但很致命。"},
	],
	"win_final": [
		{"faction": "fan", "tag": "决赛", "title": "{name} 进决赛了，这次别再留遗憾", "body": "上一次他在这里输球，走的时候没接受采访。今天他赢了，还是没说什么。"},
	],
	"data_final": [
		{"faction": "data", "tag": "数据", "title": "半决赛数据：{name} 反手失误 9 次，仍然赢了", "body": "反手失误率 18%，是他本赛季最差的一场。但他把对手的正手使用率压到了 39%。\n\n用短板换对方的短板，这买卖不亏。"},
	],
	"win_normal": [
		{"faction": "neutral", "tag": "", "title": "{name} 过首轮，没什么波澜", "body": "3:{score}，对手排名低了不少，赢下来是应该的。真正的考验在下一轮。"},
		{"faction": "neutral", "tag": "", "title": "稳稳晋级，{name} 这场没什么可挑的", "body": "该赢的球赢了，体能也没怎么消耗。这种比赛的价值在于不让状态掉下去。"},
	],
	"fun_note": [
		{"faction": "fun", "tag": "乐子", "title": "你们注意到{name}赢球后的表情了吗", "body": "就那种“哦，赢了啊”的表情，跟下班打卡一样。"},
	],
	"loss_streak": [
		{"faction": "hater", "tag": "连败", "title": "三连败了，还想进国家队？", "body": "不是我说，这个状态去国际赛场就是送。教练组该考虑换人了。"},
		{"faction": "hater", "tag": "连败", "title": "{name} 的问题从来不是技术", "body": "是关键分不敢出手。9 平之后他的球明显变短，这不是一天两天了。"},
	],
	"fan_defend": [
		{"faction": "fan", "tag": "", "title": "你们忘了他上个月是怎么赢的？", "body": "状态有起伏很正常。他今年才 {age} 岁，你们要求的是一个完美的机器，不是一个人。"},
	],
	"neutral_worry": [
		{"faction": "neutral", "tag": "", "title": "输一场不是世界末日，但有些东西该改了", "body": "接发球轮次丢分太集中。对手一旦压他反手位，他整局都在被动。"},
		{"faction": "neutral", "tag": "", "title": "客观说，这场球输在准备不足", "body": "对手的录像不是没有，是没看进去。第三局那个发球，重复了四次。"},
	],
	"loss_early": [
		{"faction": "hater", "tag": "一轮游", "title": "一轮游。就这？", "body": "报名的时候挺积极，打球的时候人呢。"},
	],
	"data_loss": [
		{"faction": "data", "tag": "数据", "title": "拆解 {name} 这场失利：失误集中在反手位", "body": "反手位失误 14 次，占总失误的 61%。对手明显做过功课。"},
	],
	"loss_normal": [
		{"faction": "neutral", "tag": "", "title": "{name} 止步{place}，输得不冤", "body": "对手排名更高，实力也更强。这场球的价值在于他打满了五局，没有崩。"},
	],
	"fun_loss": [
		{"faction": "fun", "tag": "乐子", "title": "输球不可怕，可怕的是他赛后还在笑", "body": "镜头扫过去，他一边收拍一边跟对手聊天，笑得挺开心。我竟然不知道该心疼还是该放心。"},
	],
	"roster_why": [
		{"faction": "hater", "tag": "排阵", "title": "为什么让{name}打{position}？教练在玩火", "body": "上一场状态那么差，这场还让他顶这个位置。真出了事谁负责？"},
	],
	"roster_trust": [
		{"faction": "fan", "tag": "排阵", "title": "相信教练组的判断", "body": "人家天天在队里看着，比我们这些看转播的清楚。别赢球吹教练，输球骂教练。"},
	],
	"roster_neutral": [
		{"faction": "neutral", "tag": "排阵", "title": "这个排阵不算离谱，但风险确实有", "body": "让{name}打{position}，赢面大概五五开。教练赌的是他的状态能回来。"},
	],
	"roster_ok": [
		{"faction": "neutral", "tag": "", "title": "名单出来了，{name} 打{position}", "body": "没什么争议。按实力排，就该是这个顺序。"},
	],
	"roster_data": [
		{"faction": "data", "tag": "数据", "title": "从胜率看这次排阵：{name} 打{position}合理吗", "body": "他对外协会选手的近两年胜率 68%，在这个位置上算及格。但关键分胜率只有 51%，这是隐患。"},
	],
	"retire_main": [
		{"faction": "neutral", "tag": "退役", "title": "{name} 宣布退役：{age} 岁，一个时代结束了", "body": "发布会很短。他说膝盖不行了，说谢谢大家，然后站起来鞠了个躬。\n\n没有眼泪，也没有煽情。就像他打球的样子。"},
	],
	"retire_fan": [
		{"faction": "fan", "tag": "退役", "title": "我看了他十年，今天有点说不出话", "body": "第一次看他比赛是在一个小馆里，连转播都没有。今天他的退役上了热搜。\n\n就这样吧。谢谢。"},
	],
	"retire_hater": [
		{"faction": "hater", "tag": "退役", "title": "终于退了", "body": "这话我三年前就说过。占着位置不走，对谁都不好。"},
	],
	"flavor_canteen": [
		{"faction": "fun", "tag": "日常", "title": "食堂阿姨今天给我多打了一勺肉", "body": "她说看了我上周的比赛。我怀疑她跟每个人都这么说。"},
	],
	"flavor_teammate": [
		{"faction": "fun", "tag": "日常", "title": "听说隔壁桌的周哥昨天被教练骂哭了", "body": "练多球练到一半，教练把一筐球全倒在他脚边。整个馆都听见了。"},
	],
	"flavor_gym": [
		{"faction": "fun", "tag": "日常", "title": "训练馆的灯又坏了一盏", "body": "就是最里面那个角。现在那边一到晚上就黑着，没人愿意去那儿捡球。"},
	],
	"flavor_rumor": [
		{"faction": "neutral", "tag": "流言", "title": "听说队里要调整主力名单了", "body": "不知道真假。反正最近几场的热身顺序变了，懂的都懂。"},
	],
	"flavor_gear": [
		{"faction": "fun", "tag": "器材", "title": "他的底板好像换了", "body": "柄的颜色不一样了。也可能是贴了新胶皮。反正我买不起。"},
	],
}
