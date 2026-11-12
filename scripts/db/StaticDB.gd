class_name StaticDB
extends RefCounted
# =========================================================
# StaticDB · v0.8 静态数据（继承自 v0.7 数据层）（由原型数据自动导出，勿手改数字）
# 赛事 / 事件卡 / 目标 / 成就 / 器材 / 名字库 / 世界配额
# =========================================================

var CFG: Dictionary = {
 "VERSION": 2,
 "START_AGE": 8,
 "START_YEAR": 2010,
 "MAX_AGE": 45,
 "WEEKS": 52,
 "AP_MAX": 6,
 "BREAK_MAX": 20,
 "MONEY_MAX": 9999999,
 "BOARD_SIZE": 256,
 "POOL_MAX": 40,
 "POOL_WEEKS": 52,
 "BEST_N": 8,
 "CONT_MAX": 1,
 "FORUM_MAX": 64,
 "USED_BODY_MAX": 2000,
 "LOG_MAX": 140,
 "REC_MAX": 10
}

var ATTRS: Array = [
 {
  "k": "power",
  "n": "力量",
  "d": "击球质量与中远台对拉"
 },
 {
  "k": "speed",
  "n": "速度",
  "d": "衔接与还原的快慢"
 },
 {
  "k": "stamina",
  "n": "耐力",
  "d": "多局拉锯与连续作战"
 },
 {
  "k": "touch",
  "n": "手感",
  "d": "台内控制与旋转感知"
 },
 {
  "k": "tactic",
  "n": "战术",
  "d": "阅读比赛与临场调整"
 },
 {
  "k": "mental",
  "n": "心理",
  "d": "关键分与逆风局"
 }
]

var TECHS: Array = [
 {
  "k": "serve",
  "n": "发球",
  "c": "发球是唯一不受对手干扰的一板"
 },
 {
  "k": "receive",
  "n": "接发球",
  "c": "所有被动都从这一板开始"
 },
 {
  "k": "short",
  "n": "台内球",
  "c": "短球的耐心决定谁能先上手"
 },
 {
  "k": "fh",
  "n": "正手",
  "c": "最可靠的得分方式"
 },
 {
  "k": "bh",
  "n": "反手",
  "c": "被压住时唯一的出口"
 },
 {
  "k": "def",
  "n": "防守",
  "c": "不是挨打，是把球再送回去"
 },
 {
  "k": "foot",
  "n": "步法",
  "c": "所有技术的前提是到位"
 }
]

var SUBTECHS: Dictionary = {
 "serve": [
  "正手转不转",
  "逆旋转发球",
  "勾手发球",
  "急长球",
  "短球落点"
 ],
 "receive": [
  "摆短",
  "劈长",
  "反手拧拉",
  "挑打",
  "侧切"
 ],
 "short": [
  "搓球控制",
  "摆短质量",
  "劈长突然性",
  "台内挑打",
  "晃撇"
 ],
 "fh": [
  "正手攻球",
  "前冲弧圈",
  "高吊弧圈",
  "正手爆冲",
  "反拉"
 ],
 "bh": [
  "反手拨球",
  "反手快撕",
  "反手拧拉",
  "弹击",
  "快带"
 ],
 "def": [
  "挡球",
  "减力挡",
  "放高球",
  "削球",
  "防中反拉"
 ],
 "foot": [
  "并步",
  "交叉步",
  "侧身步",
  "还原步",
  "扑正手"
 ]
}

var STAGES: Array = [
 {
  "i": 0,
  "n": "启蒙期",
  "org": "市体校",
  "age": [
   8,
   10
  ],
  "ap": 3,
  "attrCap": 42,
  "techCap": 60,
  "income": 800,
  "oppOvr": [
   8,
   26
  ],
  "rankPool": "none",
  "unlock": [
   "基础训练",
   "区县 / 市少儿赛",
   "教练信任度"
  ],
  "d": "没有排名。决定你去处的不是积分，是球馆里那几个大人看你的眼神。"
 },
 {
  "i": 1,
  "n": "少儿期",
  "org": "省二队集训",
  "age": [
   10,
   12
  ],
  "ap": 4,
  "attrCap": 56,
  "techCap": 70,
  "income": 600,
  "oppOvr": [
   24,
   44
  ],
  "rankPool": "domestic",
  "unlock": [
   "省内青少年积分",
   "省级少儿赛事",
   "省队转正评估"
  ],
  "d": "第一次有了积分。它不给你奖励，只决定你有没有资格被叫去试训。"
 },
 {
  "i": 2,
  "n": "省青期",
  "org": "省队正式编制",
  "age": [
   12,
   15
  ],
  "ap": 4,
  "attrCap": 70,
  "techCap": 85,
  "income": 2600,
  "oppOvr": [
   40,
   62
  ],
  "rankPool": "domestic",
  "unlock": [
   "全国少儿 / 青年赛",
   "国青国少选拔链",
   "双打配对"
  ],
  "d": "编制、工资、参赛名额。你开始被当作一个职业选手来安排。"
 },
 {
  "i": 3,
  "n": "国青期",
  "org": "国家青年队",
  "age": [
   15,
   18
  ],
  "ap": 5,
  "attrCap": 86,
  "techCap": 100,
  "income": 9000,
  "oppOvr": [
   58,
   78
  ],
  "rankPool": "youth",
  "unlock": [
   "WTT 青少年赛历",
   "ITTF 青少年世界排名",
   "成人赛外卡"
  ],
  "d": "世界排名第一次出现。它只是一行数字，但你盯着看了很久。"
 },
 {
  "i": 4,
  "n": "国家队",
  "org": "国家一队",
  "age": [
   18,
   45
  ],
  "ap": 5,
  "attrCap": 100,
  "techCap": 124,
  "income": 24000,
  "oppOvr": [
   72,
   96
  ],
  "rankPool": "adult",
  "unlock": [
   "成人世界排名",
   "三大赛 / 九大赛",
   "总决赛专属积分榜"
  ],
  "d": "你终于在名单上了。名单每年都会重印。"
 }
]

var SEASONS: Array = [
 {
  "k": "winter",
  "n": "冬训期",
  "w": [
   1,
   12
  ],
  "color": "#5f8fa8",
  "train": {
   "fit": 1.2,
   "tech": 0.9,
   "psy": 1,
   "tac": 1
  },
  "d": "体能和力量打底，技术长得慢一点"
 },
 {
  "k": "spring",
  "n": "春季赛",
  "w": [
   13,
   22
  ],
  "color": "#4f8a6a",
  "train": {
   "fit": 0.9,
   "tech": 0.8,
   "psy": 1,
   "tac": 1
  },
  "d": "赛程密集，训练时间被切碎"
 },
 {
  "k": "summer",
  "n": "夏训期",
  "w": [
   23,
   30
  ],
  "color": "#a8862f",
  "train": {
   "fit": 1,
   "tech": 1.2,
   "psy": 1,
   "tac": 1
  },
  "d": "技术打磨的窗口，练什么像什么"
 },
 {
  "k": "autumn",
  "n": "秋季赛",
  "w": [
   31,
   42
  ],
  "color": "#b1743c",
  "train": {
   "fit": 0.9,
   "tech": 0.8,
   "psy": 1,
   "tac": 1
  },
  "d": "一站接一站，比的是恢复"
 },
 {
  "k": "finals",
  "n": "总决赛期",
  "w": [
   43,
   46
  ],
  "color": "#96702a",
  "train": {
   "fit": 1,
   "tech": 0.9,
   "psy": 1.3,
   "tac": 1.1
  },
  "d": "心理和细节决定最后几场"
 },
 {
  "k": "rest",
  "n": "休整期",
  "w": [
   47,
   52
  ],
  "color": "#818a93",
  "train": {
   "fit": 1.4,
   "tech": 0.7,
   "psy": 1.1,
   "tac": 0.9
  },
  "d": "恢复、总结、把身体还给自己"
 }
]

var TACTICS: Array = [
 {
  "k": "rush",
  "n": "抢攻",
  "tag": "power",
  "d": "前三板压上，赢快也输快",
  "risk": 0.08
 },
 {
  "k": "rally",
  "n": "相持",
  "tag": "speed",
  "d": "把球拖进多板，比谁先失误",
  "risk": -0.02
 },
 {
  "k": "control",
  "n": "控制",
  "tag": "control",
  "d": "落点与旋转，磨掉对手的节奏",
  "risk": -0.04
 },
 {
  "k": "defend",
  "n": "防守",
  "tag": "defense",
  "d": "退半步，等他先动手",
  "risk": -0.03
 }
]

var COUNTER: Dictionary = {
 "speed": {
  "strong": "control",
  "weak": "power"
 },
 "control": {
  "strong": "defense",
  "weak": "speed"
 },
 "defense": {
  "strong": "power",
  "weak": "control"
 },
 "power": {
  "strong": "speed",
  "weak": "defense"
 },
 "trick": {
  "strong": null,
  "weak": null
 }
}

var WEAKNESS: Array = [
 {
  "k": "bh_receive",
  "n": "反手位接发球",
  "tactic": "rush"
 },
 {
  "k": "fh_short",
  "n": "正手小三角",
  "tactic": "control"
 },
 {
  "k": "middle",
  "n": "中路追身",
  "tactic": "rally"
 },
 {
  "k": "foot_back",
  "n": "退台后步法",
  "tactic": "control"
 },
 {
  "k": "clutch",
  "n": "关键分心理",
  "tactic": "defend"
 }
]

var ORIGINS: Array = [
 {
  "k": "sport",
  "n": "体校子弟",
  "d": "父母都在体育系统，从小在球馆长大",
  "eff": {
   "power": 2,
   "mental": 2
  },
  "money": 3000
 },
 {
  "k": "street",
  "n": "街头球台",
  "d": "水泥台、砖头网，手感是野出来的",
  "eff": {
   "stamina": 3,
   "touch": 2,
   "tactic": -1
  },
  "money": 1200
 },
 {
  "k": "academy",
  "n": "少年宫",
  "d": "动作规范，什么都不缺，也什么都不尖",
  "eff": {
   "touch": 1,
   "tactic": 1,
   "mental": 1,
   "speed": 1
  },
  "money": 4000
 },
 {
  "k": "genius",
  "n": "天才少年",
  "d": "教练说十年一遇，你自己不太信",
  "eff": {
   "touch": 2,
   "speed": 2,
   "mental": -3
  },
  "money": 2000
 }
]

var TALENTS: Array = [
 {
  "id": "feel",
  "n": "手感",
  "d": "技术训练收益 +12%"
 },
 {
  "id": "bigheart",
  "n": "大心脏",
  "d": "关键分判定 +8%"
 },
 {
  "id": "iron",
  "n": "铁人",
  "d": "疲劳增长 -20%"
 },
 {
  "id": "fast",
  "n": "领悟快",
  "d": "小项掌握速度 +25%"
 },
 {
  "id": "lefty",
  "n": "左手",
  "d": "对右手选手首次交手 +0.8"
 },
 {
  "id": "burst",
  "n": "爆发力",
  "d": "抢攻战术收益 +6%"
 },
 {
  "id": "recover",
  "n": "恢复快",
  "d": "每周体力恢复 +30%"
 },
 {
  "id": "nerve",
  "n": "抗压",
  "d": "落后时判定 +6%"
 },
 {
  "id": "brain",
  "n": "战术脑",
  "d": "战术训练收益 +15%"
 },
 {
  "id": "grind",
  "n": "耐磨",
  "d": "连续作战状态衰减减半"
 },
 {
  "id": "clutch",
  "n": "关键分",
  "d": "9 平后得分率 +5%"
 },
 {
  "id": "gear",
  "n": "器材通",
  "d": "器材效果 +10%，磨损 -25%"
 }
]

var COACHES: Array = [
 {
  "id": "c0",
  "n": "老周",
  "style": "启蒙",
  "bonus": {
   "tech": 1.05
  },
  "d": "话不多，专盯你的握拍"
 },
 {
  "id": "c1",
  "n": "陈指导",
  "style": "省队",
  "bonus": {
   "fit": 1.08
  },
  "d": "信体能，觉得技术是体能长出来的"
 },
 {
  "id": "c2",
  "n": "秦教练",
  "style": "技术流",
  "bonus": {
   "tech": 1.12
  },
  "d": "能把一个动作拆成七步"
 },
 {
  "id": "c3",
  "n": "吴指导",
  "style": "实战派",
  "bonus": {
   "tac": 1.15
  },
  "d": "只看比分，不听解释"
 },
 {
  "id": "c4",
  "n": "国家队外教",
  "style": "数据派",
  "bonus": {
   "tech": 1.06,
   "tac": 1.06
  },
  "d": "每堂训练后给你一张表"
 },
 {
  "id": "c5",
  "n": "老对手",
  "style": "退役名将",
  "bonus": {
   "psy": 1.12,
   "tac": 1.08
  },
  "d": "他曾输给过你，现在教你赢别人"
 }
]

var GEAR: Array = [
 {
  "id": "bl1",
  "cat": "blade",
  "n": "五夹纯木 · 入门",
  "tier": 1,
  "price": 260,
  "atk": 1,
  "ctrl": 3,
  "defn": 2,
  "mob": 0,
  "d": "教练给的第一块板，什么都能打，什么都不狠。"
 },
 {
  "id": "bl2",
  "cat": "blade",
  "n": "七夹纯木 · 快攻",
  "tier": 2,
  "price": 680,
  "atk": 3,
  "ctrl": 2,
  "defn": 1,
  "mob": 1,
  "d": "近台快，退台就有点空。"
 },
 {
  "id": "bl3",
  "cat": "blade",
  "n": "内置纤维 · 均衡",
  "tier": 3,
  "price": 1600,
  "atk": 4,
  "ctrl": 4,
  "defn": 2,
  "mob": 1,
  "d": "省队主力最常见的配置。"
 },
 {
  "id": "bl4",
  "cat": "blade",
  "n": "外置纤维 · 速度",
  "tier": 3,
  "price": 1900,
  "atk": 5,
  "ctrl": 2,
  "defn": 1,
  "mob": 2,
  "d": "借力极快，需要自己造弧线。"
 },
 {
  "id": "bl5",
  "cat": "blade",
  "n": "内置纤维 · 控制",
  "tier": 4,
  "price": 2800,
  "atk": 3,
  "ctrl": 6,
  "defn": 4,
  "mob": 1,
  "d": "台内球像粘在板上。"
 },
 {
  "id": "bl6",
  "cat": "blade",
  "n": "特制 · 国手版",
  "tier": 5,
  "price": 5200,
  "atk": 6,
  "ctrl": 5,
  "defn": 3,
  "mob": 2,
  "d": "队里发的，外面买不到。"
 },
 {
  "id": "bl7",
  "cat": "blade",
  "n": "老木 · 手感",
  "tier": 4,
  "price": 3400,
  "atk": 3,
  "ctrl": 7,
  "defn": 3,
  "mob": 0,
  "d": "二十年前的一块板，木头已经开了。"
 },
 {
  "id": "bl8",
  "cat": "blade",
  "n": "定制 · 签名款",
  "tier": 6,
  "price": 8800,
  "atk": 7,
  "ctrl": 6,
  "defn": 4,
  "mob": 3,
  "d": "你的名字刻在拍柄上。"
 },
 {
  "id": "fh1",
  "cat": "fh",
  "n": "粘性套胶 · 训练",
  "tier": 1,
  "price": 120,
  "atk": 2,
  "ctrl": 2,
  "defn": 1,
  "mob": 0,
  "d": "便宜、耐打、不怎么转。"
 },
 {
  "id": "fh2",
  "cat": "fh",
  "n": "粘性套胶 · 省队",
  "tier": 2,
  "price": 380,
  "atk": 3,
  "ctrl": 3,
  "defn": 1,
  "mob": 0,
  "d": "灌一次油，能多转两天。"
 },
 {
  "id": "fh3",
  "cat": "fh",
  "n": "涩性套胶 · 速度",
  "tier": 3,
  "price": 760,
  "atk": 4,
  "ctrl": 3,
  "defn": 2,
  "mob": 1,
  "d": "出球快，弧线低。"
 },
 {
  "id": "fh4",
  "cat": "fh",
  "n": "国狂 · 特制",
  "tier": 5,
  "price": 1600,
  "atk": 6,
  "ctrl": 4,
  "defn": 2,
  "mob": 1,
  "d": "队里统一发的，编号在侧面。"
 },
 {
  "id": "fh5",
  "cat": "fh",
  "n": "新世代 · 高弹",
  "tier": 6,
  "price": 2400,
  "atk": 7,
  "ctrl": 5,
  "defn": 3,
  "mob": 2,
  "d": "你不习惯，但对手更不习惯。"
 },
 {
  "id": "bh1",
  "cat": "bh",
  "n": "反手 · 训练套",
  "tier": 1,
  "price": 110,
  "atk": 1,
  "ctrl": 3,
  "defn": 1,
  "mob": 0,
  "d": "先把球放上台。"
 },
 {
  "id": "bh2",
  "cat": "bh",
  "n": "反手 · 涩性",
  "tier": 2,
  "price": 340,
  "atk": 3,
  "ctrl": 3,
  "defn": 2,
  "mob": 0,
  "d": "拧拉的第一块正经胶皮。"
 },
 {
  "id": "bh3",
  "cat": "bh",
  "n": "反手 · 高摩擦",
  "tier": 3,
  "price": 720,
  "atk": 4,
  "ctrl": 4,
  "defn": 2,
  "mob": 1,
  "d": "薄摩擦也能起球。"
 },
 {
  "id": "bh4",
  "cat": "bh",
  "n": "反手 · 弹击型",
  "tier": 4,
  "price": 1200,
  "atk": 5,
  "ctrl": 3,
  "defn": 1,
  "mob": 1,
  "d": "近台一板过，退台就难。"
 },
 {
  "id": "bh5",
  "cat": "bh",
  "n": "反手 · 特制",
  "tier": 5,
  "price": 1800,
  "atk": 6,
  "ctrl": 5,
  "defn": 3,
  "mob": 2,
  "d": "为你的反手拧拉调过海绵。"
 },
 {
  "id": "sh1",
  "cat": "shoe",
  "n": "训练鞋",
  "tier": 1,
  "price": 180,
  "atk": 0,
  "ctrl": 0,
  "defn": 1,
  "mob": 2,
  "d": "底薄，能感觉地面。"
 },
 {
  "id": "sh2",
  "cat": "shoe",
  "n": "专业乒乓鞋",
  "tier": 2,
  "price": 520,
  "atk": 0,
  "ctrl": 1,
  "defn": 2,
  "mob": 3,
  "d": "侧向支撑好，急停不滑。"
 },
 {
  "id": "sh3",
  "cat": "shoe",
  "n": "轻量比赛鞋",
  "tier": 4,
  "price": 1100,
  "atk": 0,
  "ctrl": 1,
  "defn": 2,
  "mob": 5,
  "d": "轻得像没穿。"
 },
 {
  "id": "sh4",
  "cat": "shoe",
  "n": "定制楦型",
  "tier": 5,
  "price": 2200,
  "atk": 0,
  "ctrl": 2,
  "defn": 3,
  "mob": 6,
  "d": "按你的脚型做的，只有一双。"
 },
 {
  "id": "sh5",
  "cat": "shoe",
  "n": "旧鞋",
  "tier": 3,
  "price": 0,
  "atk": 0,
  "ctrl": 0,
  "defn": 1,
  "mob": 2,
  "d": "穿了三年的那双，鞋头开了口，你舍不得扔。"
 },
 {
  "id": "cl1",
  "cat": "shirt",
  "n": "市体校队服",
  "tier": 1,
  "price": 0,
  "atk": 0,
  "ctrl": 0,
  "defn": 0,
  "mob": 0,
  "d": "背后印着体校的名字，洗得发白。"
 },
 {
  "id": "cl2",
  "cat": "shirt",
  "n": "省队队服",
  "tier": 2,
  "price": 300,
  "atk": 1,
  "ctrl": 0,
  "defn": 0,
  "mob": 0,
  "d": "第一次穿上它，你在镜子前站了一会儿。"
 },
 {
  "id": "cl3",
  "cat": "shirt",
  "n": "国家队队服",
  "tier": 4,
  "price": 900,
  "atk": 1,
  "ctrl": 1,
  "defn": 0,
  "mob": 0,
  "d": "胸口有国旗。重量和别的衣服不一样。"
 },
 {
  "id": "cl4",
  "cat": "shirt",
  "n": "个人赞助款",
  "tier": 5,
  "price": 1500,
  "atk": 1,
  "ctrl": 1,
  "defn": 1,
  "mob": 0,
  "d": "品牌给你做的，颜色是你选的。"
 },
 {
  "id": "cl5",
  "cat": "shirt",
  "n": "决赛 · 深色",
  "tier": 6,
  "price": 2600,
  "atk": 2,
  "ctrl": 1,
  "defn": 1,
  "mob": 0,
  "d": "你只在最重要的场次穿它。"
 }
]

var ACTIONS: Array = [
 {
  "k": "tech",
  "n": "技术训练",
  "ap": 1,
  "d": "打磨一项技术，推进当前小项",
  "icon": "技"
 },
 {
  "k": "fit",
  "n": "体能训练",
  "ap": 1,
  "d": "多球、折返、核心，长肌肉也长耐心",
  "icon": "体"
 },
 {
  "k": "psy",
  "n": "心理训练",
  "ap": 1,
  "d": "关键分模拟、呼吸、抗压",
  "icon": "心"
 },
 {
  "k": "tac",
  "n": "战术复盘",
  "ap": 1,
  "d": "看录像，记对手的落点习惯",
  "icon": "战"
 },
 {
  "k": "rest",
  "n": "休息",
  "ap": 1,
  "d": "恢复体力，降低疲劳与伤病风险",
  "icon": "息"
 },
 {
  "k": "study",
  "n": "文化课",
  "ap": 1,
  "d": "为退役后的那条路留一点余地",
  "icon": "学"
 }
]

var LADDER: Array = [
 "初学",
 "入门",
 "成型",
 "熟练",
 "精熟",
 "锋利",
 "一流",
 "顶尖",
 "世界级",
 "传奇",
 "无可复制"
]

var CAP_LADDER: Array = [
 60,
 70,
 78,
 85,
 91,
 96,
 100,
 106,
 112,
 118,
 124
]

var CAP_STAGE_MAX: Array = [
 60,
 70,
 85,
 100,
 124
]

var ATTR_CAP: Array = [
 42,
 56,
 70,
 86,
 100
]

var RANK_TITLES: Array = [
 {
  "max": 1,
  "t": "世界第一"
 },
 {
  "max": 3,
  "t": "世界前三"
 },
 {
  "max": 10,
  "t": "世界前十"
 },
 {
  "max": 30,
  "t": "世界前三十"
 },
 {
  "max": 64,
  "t": "世界前六十四"
 }
]

var POINTS: Dictionary = {
 "major": [
  2000,
  1400,
  900,
  580,
  380,
  100,
  20
 ],
 "finals": [
  1500,
  1050,
  680,
  450,
  0,
  0,
  0
 ],
 "worldcup": [
  1500,
  1050,
  680,
  450,
  300,
  0,
  0
 ],
 "champ": [
  1000,
  700,
  450,
  300,
  80,
  15,
  0
 ],
 "star": [
  600,
  420,
  270,
  175,
  115,
  30,
  5
 ],
 "asia": [
  500,
  350,
  175,
  90,
  45,
  0,
  0
 ],
 "cont": [
  400,
  280,
  180,
  120,
  30,
  4,
  0
 ],
 "feeder": [
  125,
  70,
  40,
  20,
  8,
  0,
  0
 ],
 "yw": [
  400,
  280,
  180,
  120,
  60,
  20,
  0
 ],
 "ynj": [
  300,
  210,
  135,
  90,
  45,
  15,
  0
 ],
 "ya": [
  250,
  175,
  110,
  70,
  35,
  10,
  0
 ],
 "ypy": [
  200,
  140,
  90,
  55,
  25,
  8,
  0
 ],
 "ync": [
  150,
  105,
  65,
  40,
  20,
  0,
  0
 ],
 "yp": [
  120,
  84,
  52,
  30,
  12,
  0,
  0
 ],
 "ych": [
  125,
  88,
  55,
  32,
  14,
  0,
  0
 ],
 "domestic": [
  0,
  0,
  0,
  0,
  0,
  0,
  0
 ]
}

var TIER_META: Dictionary = {
 "major": {
  "n": "大满贯 / 三大赛",
  "lv": 7,
  "ring": "l7",
  "short": "满"
 },
 "finals": {
  "n": "WTT 总决赛",
  "lv": 6,
  "ring": "l6",
  "short": "总"
 },
 "worldcup": {
  "n": "世界杯",
  "lv": 6,
  "ring": "l6",
  "short": "杯"
 },
 "champ": {
  "n": "WTT 冠军赛",
  "lv": 5,
  "ring": "l5",
  "short": "冠"
 },
 "star": {
  "n": "WTT 球星挑战赛",
  "lv": 4,
  "ring": "l4",
  "short": "星"
 },
 "asia": {
  "n": "洲际赛事",
  "lv": 4,
  "ring": "l4",
  "short": "洲"
 },
 "cont": {
  "n": "WTT 常规挑战赛",
  "lv": 3,
  "ring": "l3",
  "short": "常"
 },
 "feeder": {
  "n": "WTT 支线赛",
  "lv": 2,
  "ring": "l2",
  "short": "支"
 },
 "domestic": {
  "n": "国内赛事",
  "lv": 3,
  "ring": "l3",
  "short": "国"
 },
 "youth": {
  "n": "青少年赛事",
  "lv": 2,
  "ring": "l2",
  "short": "青"
 }
}

var TOURNEYS: Array = [
 {
  "id": "y_city",
  "n": "市少儿锦标赛",
  "tier": "ypy",
  "cat": "youth",
  "w": [
   12,
   13
  ],
  "draw": 32,
  "age": [
   8,
   10
  ],
  "stage": 0,
  "pts": 0,
  "prize": 300,
  "rep": 4,
  "fame": 2,
  "bo": 5,
  "noRank": true,
  "d": "全市同年龄的孩子挤在一间馆里。冠军有一张奖状，和教练的一句「还行」。"
 },
 {
  "id": "y_prov",
  "n": "省少儿杯",
  "tier": "yp",
  "cat": "youth",
  "w": [
   20,
   21
  ],
  "draw": 32,
  "age": [
   9,
   12
  ],
  "stage": 1,
  "pts": 120,
  "prize": 1500,
  "rep": 8,
  "fame": 4,
  "bo": 5,
  "d": "省队的球探坐在看台上，边看边在本子上写名字。"
 },
 {
  "id": "y_nat_child",
  "n": "全国少儿锦标赛",
  "tier": "ync",
  "cat": "youth",
  "w": [
   40,
   41
  ],
  "draw": 64,
  "age": [
   9,
   11
  ],
  "stage": 1,
  "pts": 150,
  "prize": 6000,
  "rep": 16,
  "fame": 8,
  "bo": 5,
  "d": "各省少儿冠军挤在一张签表里。有人打完全程没笑过一次。"
 },
 {
  "id": "y_prov_youth",
  "n": "省青少年锦标赛",
  "tier": "ypy",
  "cat": "youth",
  "w": [
   28,
   29
  ],
  "draw": 64,
  "age": [
   12,
   15
  ],
  "stage": 2,
  "pts": 200,
  "prize": 12000,
  "rep": 14,
  "fame": 8,
  "bo": 5,
  "d": "省内青年组的正式排名赛。你在名单上的位置，决定省队怎么用你。"
 },
 {
  "id": "y_nat_junior",
  "n": "全国青年锦标赛",
  "tier": "ynj",
  "cat": "youth",
  "w": [
   26,
   27
  ],
  "draw": 64,
  "age": [
   15,
   18
  ],
  "stage": 2,
  "pts": 300,
  "prize": 60000,
  "rep": 30,
  "fame": 16,
  "bo": 7,
  "d": "国家队的教练在看台上挑人。前八名会被记住。"
 },
 {
  "id": "y_asian",
  "n": "亚洲青年锦标赛",
  "tier": "ya",
  "cat": "youth",
  "w": [
   36,
   36
  ],
  "draw": 32,
  "age": [
   15,
   19
  ],
  "stage": 3,
  "pts": 250,
  "prize": 40000,
  "rep": 24,
  "fame": 14,
  "bo": 7,
  "d": "第一次在球台对面听到别的语言。"
 },
 {
  "id": "y_world",
  "n": "世界青年锦标赛",
  "tier": "yw",
  "cat": "youth",
  "w": [
   44,
   44
  ],
  "draw": 64,
  "age": [
   15,
   19
  ],
  "stage": 3,
  "pts": 400,
  "prize": 80000,
  "rep": 40,
  "fame": 24,
  "bo": 7,
  "d": "同龄人里的世界之巅。赢了它，成年组的门会开一条缝。"
 },
 {
  "id": "y_chall",
  "n": "青年挑战赛",
  "tier": "ych",
  "cat": "youth",
  "w": [
   8,
   8
  ],
  "draw": 32,
  "age": [
   14,
   19
  ],
  "stage": 3,
  "pts": 125,
  "prize": 12000,
  "rep": 8,
  "fame": 4,
  "bo": 5,
  "d": "WTT 青少年系列里最普通的一站，也是大多数人的第一站。"
 },
 {
  "id": "w_feed_1",
  "n": "WTT 支线赛 · 杜塞尔多夫",
  "tier": "feeder",
  "cat": "wtt",
  "w": [
   6,
   6
  ],
  "draw": 64,
  "age": [
   15,
   45
  ],
  "stage": 3,
  "pts": 125,
  "prize": 18000,
  "rep": 6,
  "fame": 4,
  "bo": 5,
  "d": "球馆不大，观众几十个人，但每一分都算进世界排名。"
 },
 {
  "id": "w_feed_2",
  "n": "WTT 支线赛 · 帕纳久里什泰",
  "tier": "feeder",
  "cat": "wtt",
  "w": [
   14,
   14
  ],
  "draw": 64,
  "age": [
   15,
   45
  ],
  "stage": 3,
  "pts": 125,
  "prize": 18000,
  "rep": 6,
  "fame": 4,
  "bo": 5,
  "d": "东欧的小城，住的地方离馆要走十五分钟。"
 },
 {
  "id": "w_feed_3",
  "n": "WTT 支线赛 · 曼谷",
  "tier": "feeder",
  "cat": "wtt",
  "w": [
   24,
   24
  ],
  "draw": 64,
  "age": [
   15,
   45
  ],
  "stage": 3,
  "pts": 125,
  "prize": 20000,
  "rep": 6,
  "fame": 5,
  "bo": 5,
  "d": "热。馆里的空调和没有一样。"
 },
 {
  "id": "w_feed_4",
  "n": "WTT 支线赛 · 突尼斯",
  "tier": "feeder",
  "cat": "wtt",
  "w": [
   32,
   32
  ],
  "draw": 64,
  "age": [
   15,
   45
  ],
  "stage": 3,
  "pts": 125,
  "prize": 18000,
  "rep": 6,
  "fame": 4,
  "bo": 5,
  "d": "打完这场，你的名字第一次出现在签表 PDF 的第二页。"
 },
 {
  "id": "w_feed_5",
  "n": "WTT 支线赛 · 利马",
  "tier": "feeder",
  "cat": "wtt",
  "w": [
   46,
   46
  ],
  "draw": 64,
  "age": [
   15,
   45
  ],
  "stage": 3,
  "pts": 125,
  "prize": 18000,
  "rep": 6,
  "fame": 4,
  "bo": 5,
  "d": "跨了半个地球，第一轮就遇到一个你从没见过的削球手。"
 },
 {
  "id": "w_cont_1",
  "n": "WTT 常规挑战赛 · 多哈",
  "tier": "cont",
  "cat": "wtt",
  "w": [
   10,
   10
  ],
  "draw": 32,
  "age": [
   16,
   45
  ],
  "stage": 3,
  "pts": 400,
  "prize": 70000,
  "rep": 14,
  "fame": 10,
  "bo": 5,
  "rankMax": 120,
  "d": "第一次进正赛，签表上有一半人你只在视频里见过。"
 },
 {
  "id": "w_cont_2",
  "n": "WTT 常规挑战赛 · 拉各斯",
  "tier": "cont",
  "cat": "wtt",
  "w": [
   18,
   18
  ],
  "draw": 32,
  "age": [
   16,
   45
  ],
  "stage": 3,
  "pts": 400,
  "prize": 70000,
  "rep": 14,
  "fame": 10,
  "bo": 5,
  "rankMax": 120,
  "d": "非洲的观众很吵，也很真。"
 },
 {
  "id": "w_cont_3",
  "n": "WTT 常规挑战赛 · 太原",
  "tier": "cont",
  "cat": "wtt",
  "w": [
   30,
   30
  ],
  "draw": 32,
  "age": [
   16,
   45
  ],
  "stage": 3,
  "pts": 400,
  "prize": 80000,
  "rep": 16,
  "fame": 12,
  "bo": 5,
  "rankMax": 100,
  "d": "主场。看台上有人举着写你名字的纸板。"
 },
 {
  "id": "w_cont_4",
  "n": "WTT 常规挑战赛 · 斯德哥尔摩",
  "tier": "cont",
  "cat": "wtt",
  "w": [
   42,
   42
  ],
  "draw": 32,
  "age": [
   16,
   45
  ],
  "stage": 3,
  "pts": 400,
  "prize": 70000,
  "rep": 14,
  "fame": 10,
  "bo": 5,
  "rankMax": 120,
  "d": "北欧的秋天，馆外很冷，馆里很静。"
 },
 {
  "id": "w_star_1",
  "n": "WTT 球星挑战赛 · 卢布尔雅那",
  "tier": "star",
  "cat": "wtt",
  "w": [
   16,
   16
  ],
  "draw": 32,
  "age": [
   16,
   45
  ],
  "stage": 3,
  "pts": 600,
  "prize": 220000,
  "rep": 26,
  "fame": 20,
  "bo": 5,
  "rankMax": 64,
  "d": "球星开始出现。你在餐厅排队时前面站着世界前十。"
 },
 {
  "id": "w_star_2",
  "n": "WTT 球星挑战赛 · 果阿",
  "tier": "star",
  "cat": "wtt",
  "w": [
   34,
   34
  ],
  "draw": 32,
  "age": [
   16,
   45
  ],
  "stage": 4,
  "pts": 600,
  "prize": 220000,
  "rep": 26,
  "fame": 20,
  "bo": 5,
  "rankMax": 64,
  "d": "湿热、嘈杂、球台有点潮。适应的人赢。"
 },
 {
  "id": "w_star_3",
  "n": "WTT 球星挑战赛 · 里约",
  "tier": "star",
  "cat": "wtt",
  "w": [
   48,
   48
  ],
  "draw": 32,
  "age": [
   16,
   45
  ],
  "stage": 4,
  "pts": 600,
  "prize": 220000,
  "rep": 26,
  "fame": 20,
  "bo": 5,
  "rankMax": 64,
  "d": "赛季末。有人在这里抢分，有人在这里告别。"
 },
 {
  "id": "w_champ_1",
  "n": "WTT 冠军赛 · 多哈",
  "tier": "champ",
  "cat": "wtt",
  "w": [
   22,
   22
  ],
  "draw": 32,
  "age": [
   17,
   45
  ],
  "stage": 4,
  "pts": 1000,
  "prize": 420000,
  "rep": 40,
  "fame": 30,
  "bo": 7,
  "rankMax": 30,
  "d": "只请世界前三十。没有资格赛，没有外卡。"
 },
 {
  "id": "w_champ_2",
  "n": "WTT 冠军赛 · 重庆",
  "tier": "champ",
  "cat": "wtt",
  "w": [
   38,
   38
  ],
  "draw": 32,
  "age": [
   17,
   45
  ],
  "stage": 4,
  "pts": 1000,
  "prize": 450000,
  "rep": 42,
  "fame": 34,
  "bo": 7,
  "rankMax": 30,
  "d": "主场冠军赛。赢了会被记住很久，输了也是。"
 },
 {
  "id": "w_champ_3",
  "n": "WTT 冠军赛 · 法兰克福",
  "tier": "champ",
  "cat": "wtt",
  "w": [
   50,
   50
  ],
  "draw": 32,
  "age": [
   17,
   45
  ],
  "stage": 4,
  "pts": 1000,
  "prize": 450000,
  "rep": 42,
  "fame": 34,
  "bo": 7,
  "rankMax": 30,
  "d": "赛季最后一站冠军赛。积分榜在这里定形。"
 },
 {
  "id": "w_smash_1",
  "n": "WTT 大满贯 · 新加坡",
  "tier": "major",
  "cat": "wtt",
  "w": [
   11,
   11
  ],
  "draw": 64,
  "age": [
   16,
   45
  ],
  "stage": 4,
  "pts": 2000,
  "prize": 1200000,
  "rep": 80,
  "fame": 60,
  "bo": 7,
  "rankMax": 64,
  "d": "灯光、入场音乐、四面看台。你走进去的时候，脚步会不自觉放慢。"
 },
 {
  "id": "w_smash_2",
  "n": "WTT 大满贯 · 中国",
  "tier": "major",
  "cat": "wtt",
  "w": [
   39,
   39
  ],
  "draw": 64,
  "age": [
   16,
   45
  ],
  "stage": 4,
  "pts": 2000,
  "prize": 1400000,
  "rep": 85,
  "fame": 70,
  "bo": 7,
  "rankMax": 64,
  "d": "家门口的大满贯。亲戚会问你要票。"
 },
 {
  "id": "w_finals",
  "n": "WTT 总决赛",
  "tier": "finals",
  "cat": "wtt",
  "w": [
   51,
   51
  ],
  "draw": 16,
  "age": [
   17,
   45
  ],
  "stage": 4,
  "pts": 1500,
  "prize": 900000,
  "rep": 70,
  "fame": 55,
  "bo": 7,
  "special": "wttBoard",
  "d": "只请全年 WTT 积分前十六。没有外卡，没有例外。"
 },
 {
  "id": "worldcup",
  "n": "世界杯",
  "tier": "worldcup",
  "cat": "major",
  "w": [
   31,
   31
  ],
  "draw": 48,
  "age": [
   18,
   45
  ],
  "stage": 4,
  "pts": 1500,
  "prize": 700000,
  "rep": 90,
  "fame": 60,
  "bo": 7,
  "special": "worldcup",
  "d": "48 人，16 组，只有小组第一出线。输一场就可能回家。"
 },
 {
  "id": "worlds",
  "n": "世界乒乓球锦标赛",
  "tier": "major",
  "cat": "major",
  "w": [
   35,
   35
  ],
  "draw": 128,
  "age": [
   18,
   45
  ],
  "stage": 4,
  "pts": 2000,
  "prize": 1000000,
  "rep": 120,
  "fame": 90,
  "bo": 7,
  "special": "oddYear",
  "d": "128 人的签表，七轮。世乒赛冠军的名字会被刻在杯子上。"
 },
 {
  "id": "olympic",
  "n": "奥运会",
  "tier": "major",
  "cat": "major",
  "w": [
   43,
   43
  ],
  "draw": 64,
  "age": [
   18,
   45
  ],
  "stage": 4,
  "pts": 2000,
  "prize": 0,
  "rep": 200,
  "fame": 200,
  "bo": 7,
  "special": "quad",
  "medal": true,
  "d": "四年一次。你从小在电视上看它，现在你站在里面。"
 },
 {
  "id": "asian_games",
  "n": "亚运会",
  "tier": "asia",
  "cat": "continental",
  "w": [
   33,
   33
  ],
  "draw": 32,
  "age": [
   18,
   45
  ],
  "stage": 4,
  "pts": 500,
  "prize": 0,
  "rep": 55,
  "fame": 40,
  "bo": 7,
  "special": "quad2",
  "cont": true,
  "d": "综合运动会。村里能遇到别的项目的冠军。"
 },
 {
  "id": "asian_champs",
  "n": "亚洲乒乓球锦标赛",
  "tier": "asia",
  "cat": "continental",
  "w": [
   25,
   25
  ],
  "draw": 64,
  "age": [
   16,
   45
  ],
  "stage": 4,
  "pts": 500,
  "prize": 120000,
  "rep": 45,
  "fame": 30,
  "bo": 5,
  "special": "oddYear",
  "cont": true,
  "d": "五局三胜。短赛制里，谁都可能赢谁。"
 },
 {
  "id": "asian_cup",
  "n": "亚洲杯",
  "tier": "asia",
  "cat": "continental",
  "w": [
   19,
   19
  ],
  "draw": 32,
  "age": [
   17,
   45
  ],
  "stage": 4,
  "pts": 500,
  "prize": 150000,
  "rep": 42,
  "fame": 28,
  "bo": 7,
  "cont": true,
  "d": "32 人 8 组。四强直通世界杯。"
 },
 {
  "id": "nat_champs",
  "n": "全国锦标赛",
  "tier": "domestic",
  "cat": "domestic",
  "w": [
   10,
   10
  ],
  "draw": 64,
  "age": [
   15,
   45
  ],
  "stage": 2,
  "pts": 0,
  "prize": 200000,
  "rep": 50,
  "fame": 25,
  "bo": 7,
  "domesticPts": 500,
  "d": "国内最难打的比赛。看台上坐着的都是熟人。"
 },
 {
  "id": "cttsl",
  "n": "乒超联赛",
  "tier": "domestic",
  "cat": "domestic",
  "w": [
   15,
   17
  ],
  "draw": 16,
  "age": [
   15,
   45
  ],
  "stage": 2,
  "pts": 0,
  "prize": 300000,
  "rep": 40,
  "fame": 30,
  "bo": 5,
  "domesticPts": 200,
  "team": true,
  "d": "俱乐部、赞助商、转播。你第一次靠打球挣到像样的钱。"
 },
 {
  "id": "team_trial",
  "n": "队内选拔赛",
  "tier": "domestic",
  "cat": "domestic",
  "w": [
   24,
   24
  ],
  "draw": 16,
  "age": [
   15,
   45
  ],
  "stage": 3,
  "pts": 0,
  "prize": 0,
  "rep": 30,
  "fame": 8,
  "bo": 7,
  "domesticPts": 150,
  "d": "一局定去留。教练组坐在场边，没人说话。"
 },
 {
  "id": "national_games",
  "n": "全运会",
  "tier": "domestic",
  "cat": "domestic",
  "w": [
   32,
   32
  ],
  "draw": 32,
  "age": [
   16,
   45
  ],
  "stage": 3,
  "pts": 0,
  "prize": 0,
  "rep": 90,
  "fame": 60,
  "bo": 7,
  "special": "quad3",
  "domesticPts": 400,
  "d": "四年一次，代表省队。省体育局的领导会来。"
 },
 {
  "id": "straight",
  "n": "直通赛",
  "tier": "domestic",
  "cat": "domestic",
  "w": [
   45,
   45
  ],
  "draw": 16,
  "age": [
   16,
   45
  ],
  "stage": 4,
  "pts": 0,
  "prize": 0,
  "rep": 35,
  "fame": 10,
  "bo": 7,
  "domesticPts": 250,
  "d": "赢下它，名额就是你的。没有第二种说法。"
 }
]

var PAIR_TOURNEYS: Array = [
 {
  "id": "p_smash_1",
  "n": "大满贯 · 双打",
  "w": [
   11,
   11
  ],
  "tier": "major",
  "age": [
   16,
   45
  ],
  "stage": 4,
  "prize": 180000,
  "rep": 30,
  "bo": 5
 },
 {
  "id": "p_smash_2",
  "n": "大满贯 · 混双",
  "w": [
   39,
   39
  ],
  "tier": "major",
  "age": [
   16,
   45
  ],
  "stage": 4,
  "prize": 180000,
  "rep": 30,
  "bo": 5
 },
 {
  "id": "p_worlds",
  "n": "世乒赛 · 双打",
  "w": [
   35,
   35
  ],
  "tier": "major",
  "age": [
   18,
   45
  ],
  "stage": 4,
  "prize": 200000,
  "rep": 40,
  "bo": 5
 },
 {
  "id": "p_asian",
  "n": "亚锦赛 · 混双",
  "w": [
   25,
   25
  ],
  "tier": "asia",
  "age": [
   16,
   45
  ],
  "stage": 4,
  "prize": 60000,
  "rep": 20,
  "bo": 5
 },
 {
  "id": "p_nat",
  "n": "全锦赛 · 双打",
  "w": [
   10,
   10
  ],
  "tier": "domestic",
  "age": [
   15,
   45
  ],
  "stage": 2,
  "prize": 50000,
  "rep": 15,
  "bo": 5
 },
 {
  "id": "p_finals",
  "n": "总决赛 · 混双",
  "w": [
   51,
   51
  ],
  "tier": "finals",
  "age": [
   17,
   45
  ],
  "stage": 4,
  "prize": 120000,
  "rep": 30,
  "bo": 5
 },
 {
  "id": "p_olympic",
  "n": "奥运会 · 混双",
  "w": [
   43,
   43
  ],
  "tier": "major",
  "age": [
   18,
   45
  ],
  "stage": 4,
  "prize": 0,
  "rep": 90,
  "bo": 7
 }
]

var NINE_SLOTS: Array = [
 {
  "k": "olympic",
  "n": "奥运会"
 },
 {
  "k": "worlds",
  "n": "世乒赛"
 },
 {
  "k": "worldcup",
  "n": "世界杯"
 },
 {
  "k": "finals",
  "n": "总决赛"
 },
 {
  "k": "national_games",
  "n": "全运会"
 },
 {
  "k": "nat_champs",
  "n": "全锦赛"
 },
 {
  "k": "asian_games",
  "n": "亚运会"
 },
 {
  "k": "asian_champs",
  "n": "亚锦赛"
 },
 {
  "k": "asian_cup",
  "n": "亚洲杯"
 }
]

var EVENT_TRAITS: Array = [
 {
  "k": "altitude",
  "n": "高海拔",
  "d": "球速比平原快，体力消耗更大",
  "adj": -0.006,
  "stam": 5
 },
 {
  "k": "noisy",
  "n": "观众嘈杂",
  "d": "关键分更容易听错自己的呼吸",
  "adj": -0.008,
  "stam": 0
 },
 {
  "k": "ball",
  "n": "用球不同",
  "d": "旋转弱一点，借力的人占便宜",
  "adj": -0.004,
  "stam": 0
 },
 {
  "k": "packed",
  "n": "连续作战",
  "d": "三天打五场，恢复跟不上",
  "adj": -0.006,
  "stam": 8
 },
 {
  "k": "first",
  "n": "首次举办",
  "d": "没有历史数据，谁都不熟",
  "adj": -0.004,
  "stam": 0
 },
 {
  "k": "home",
  "n": "主场",
  "d": "看台上有人喊你的名字",
  "adj": 0.012,
  "stam": 0
 }
]

var EVENT_CARDS: Array = [
 {
  "id": "e_bh_extra",
  "kind": "训练",
  "title": "加练反手",
  "text": "教练把你留下，说反手再不加就来不及了。桌上还摊着没写完的作业。",
  "cond": {
   "stageMax": 2
  },
  "opts": [
   {
    "t": "留下来加练",
    "e": "反手 +0.9 · 体力 −9",
    "fx": {
     "tech": {
      "bh": 0.9
     },
     "stam": -9,
     "fatigue": 6
    }
   },
   {
    "t": "回去写作业",
    "e": "学业 +1 · 教练信任 −1",
    "fx": {
     "study": 1,
     "trust": -1,
     "log": "你把作业写完了。教练没说什么。"
    }
   }
  ]
 },
 {
  "id": "e_double_invite",
  "kind": "生活",
  "title": "队友约你加练双打",
  "text": "他说反正你也没事，练两局。你其实想回去躺一会儿。",
  "cond": {
   "stageMin": 1
  },
  "opts": [
   {
    "t": "去打两局",
    "e": "双打默契 +4 · 体力 −8",
    "fx": {
     "pairChem": 4,
     "stam": -8,
     "fatigue": 5
    }
   },
   {
    "t": "回去休息",
    "e": "体力 +9 · 默契 −1",
    "fx": {
     "stam": 9,
     "pairChem": -1
    }
   }
  ]
 },
 {
  "id": "e_local_ad",
  "kind": "商业",
  "title": "地方品牌想找你拍广告",
  "text": "一个本地体育品牌，报价不高，但要占掉半天。",
  "cond": {
   "stageMin": 2,
   "moneyMax": 200000
  },
  "opts": [
   {
    "t": "接",
    "e": "资金 +3000 · 本周行动点 −1",
    "fx": {
     "money": 3000,
     "ap": -1,
     "fame": 2
    }
   },
   {
    "t": "不接",
    "e": "教练信任 +2",
    "fx": {
     "trust": 2
    }
   }
  ]
 },
 {
  "id": "e_knee",
  "kind": "伤病",
  "title": "膝盖有点酸",
  "text": "上楼的时候你能听见它响。不算疼，但你记住了这个声音。",
  "cond": {},
  "opts": [
   {
    "t": "这周减量",
    "e": "行动点 −1 · 伤病风险 −8%",
    "fx": {
     "ap": -1,
     "injuryRisk": -8,
     "stam": 6
    }
   },
   {
    "t": "忍着练",
    "e": "破格点 +1 · 伤病风险 +12%",
    "fx": {
     "breakPts": 1,
     "injuryRisk": 12,
     "fatigue": 8
    }
   }
  ]
 },
 {
  "id": "e_video_room",
  "kind": "训练",
  "title": "教练把录像调出来了",
  "text": "画面里你的反手一直在同一个位置被压住。教练按了暂停，看着你。",
  "opts": [
   {
    "t": "看完它",
    "e": "战术 +0.8 · 战术训练收益提升",
    "fx": {
     "attr": {
      "tactic": 0.8
     },
     "flag": "sawTape"
    }
   },
   {
    "t": "早点回去睡",
    "e": "体力 +10 · 状态 +0.2",
    "fx": {
     "stam": 10,
     "form": 0.2
    }
   }
  ]
 },
 {
  "id": "e_father_coach",
  "kind": "家庭",
  "title": "你爸问要不要换个教练",
  "text": "饭桌上他问得很随意，像是随口一提。你知道他想了很久。",
  "cond": {
   "stageMax": 1
  },
  "opts": [
   {
    "t": "换一个试试",
    "e": "战术 +1 · 教练信任 −5",
    "fx": {
     "attr": {
      "tactic": 1
     },
     "trust": -5,
     "log": "新教练话更少，但每句都在点上。"
    }
   },
   {
    "t": "就跟着现在的",
    "e": "教练信任 +3 · 家庭 +4",
    "fx": {
     "trust": 3,
     "family": 4
    }
   }
  ]
 },
 {
  "id": "e_scout",
  "kind": "机会",
  "title": "省队的人来看训练",
  "text": "场边多了两个陌生人，一直没坐下。教练让你打一场队内赛。",
  "cond": {
   "stageMin": 1
  },
  "opts": [
   {
    "t": "打给他们看",
    "e": "声望 +4 · 体力 −10",
    "fx": {
     "rep": 4,
     "stam": -10,
     "fatigue": 6
    }
   },
   {
    "t": "按平时练",
    "e": "教练信任 +2 · 状态 +0.3",
    "fx": {
     "trust": 2,
     "form": 0.3
    }
   }
  ]
 },
 {
  "id": "e_watch_night",
  "kind": "生活",
  "title": "手机里那场比赛",
  "text": "你本来只想看一局，抬头的时候已经两点。",
  "cond": {
   "stageMin": 1
  },
  "opts": [
   {
    "t": "看完",
    "e": "战术 +0.4 · 状态 −0.3 · 疲劳 +8",
    "fx": {
     "attr": {
      "tactic": 0.4
     },
     "form": -0.3,
     "fatigue": 8
    }
   },
   {
    "t": "关掉",
    "e": "体力 +7",
    "fx": {
     "stam": 7
    }
   }
  ]
 },
 {
  "id": "e_extra_meat",
  "kind": "生活",
  "title": "食堂多打了一份肉",
  "text": "阿姨说看你太瘦。旁边的队友在笑。",
  "cond": {
   "stageMax": 3
  },
  "opts": [
   {
    "t": "全吃了",
    "e": "体力 +8 · 体重 +?",
    "fx": {
     "stam": 8,
     "fatigue": -4
    }
   },
   {
    "t": "分给队友",
    "e": "队友关系 +2",
    "fx": {
     "trust": 1,
     "family": 1,
     "log": "他把肉夹走了，说下次他请。"
    }
   }
  ]
 },
 {
  "id": "e_tv_first",
  "kind": "舆论",
  "title": "第一次上电视",
  "text": "比赛被转播了。你搜自己的名字，搜到半夜。",
  "cond": {
   "stageMin": 3
  },
  "opts": [
   {
    "t": "把评论都看完",
    "e": "声望 +3 · 心理 −0.5",
    "fx": {
     "rep": 3,
     "attr": {
      "mental": -0.5
     }
    }
   },
   {
    "t": "关掉手机",
    "e": "心理 +0.4 · 状态 +0.2",
    "fx": {
     "attr": {
      "mental": 0.4
     },
     "form": 0.2
    }
   }
  ]
 },
 {
  "id": "e_rubber_shop",
  "kind": "器材",
  "title": "器材店老板推荐新胶皮",
  "text": "他说这是队里好多人都在用的型号，压着你的手不让走。",
  "cond": {
   "moneyMin": 800
  },
  "opts": [
   {
    "t": "买一块",
    "e": "资金 −800 · 手感 +0.6 · 本周适应期",
    "fx": {
     "money": -800,
     "attr": {
      "touch": 0.6
     },
     "form": -0.15,
     "flag": "newRubber"
    }
   },
   {
    "t": "先不换",
    "e": "状态 +0.2",
    "fx": {
     "form": 0.2
    }
   }
  ]
 },
 {
  "id": "e_night_before",
  "kind": "比赛",
  "title": "队内循环赛前夜",
  "text": "明天第一场对你来说很关键。走廊的灯还亮着。",
  "opts": [
   {
    "t": "再练半小时发球",
    "e": "发球 +0.6 · 体力 −8",
    "fx": {
     "tech": {
      "serve": 0.6
     },
     "stam": -8,
     "fatigue": 5
    }
   },
   {
    "t": "早点睡",
    "e": "状态 +0.4 · 体力 +6",
    "fx": {
     "form": 0.4,
     "stam": 6
    }
   }
  ]
 },
 {
  "id": "e_veteran_talk",
  "kind": "生活",
  "title": "老队员跟你说了一句话",
  "text": "他一边缠胶皮一边说：别老想着赢，先想怎么让他难受。",
  "cond": {
   "stageMin": 1
  },
  "opts": [
   {
    "t": "记住了",
    "e": "战术 +0.7",
    "fx": {
     "attr": {
      "tactic": 0.7
     }
    }
   },
   {
    "t": "没太听懂",
    "e": "心理 +0.3",
    "fx": {
     "attr": {
      "mental": 0.3
     }
    }
   }
  ]
 },
 {
  "id": "e_doc",
  "kind": "商业",
  "title": "有人想拍你的纪录片",
  "text": "摄制组想跟拍三周，包括训练、宿舍、回家。",
  "cond": {
   "stageMin": 4,
   "repMin": 300
  },
  "opts": [
   {
    "t": "同意",
    "e": "人气 +8 · 声望 +5 · 行动点 −1",
    "fx": {
     "fame": 8,
     "rep": 5,
     "ap": -1
    }
   },
   {
    "t": "拒绝",
    "e": "心理 +0.4",
    "fx": {
     "attr": {
      "mental": 0.4
     }
    }
   }
  ]
 },
 {
  "id": "e_injury_check",
  "kind": "伤病",
  "title": "复查结果出来了",
  "text": "医生说可以打，但最好别再打满七局。",
  "cond": {
   "injuryMin": 1
  },
  "opts": [
   {
    "t": "保守治疗",
    "e": "休养两周 · 伤病 −2",
    "fx": {
     "restWeeks": 2,
     "injury": -2,
     "ap": -1
    }
   },
   {
    "t": "打封闭上场",
    "e": "立刻能打 · 伤病风险 +18%",
    "fx": {
     "injuryRisk": 18,
     "form": 0.3,
     "rep": 2
    }
   }
  ]
 },
 {
  "id": "e_family_thing",
  "kind": "家庭",
  "title": "家里出了点事",
  "text": "你妈在电话里说没事，让你好好练。你听见背景里有别人的声音。",
  "cond": {
   "stageMin": 1
  },
  "opts": [
   {
    "t": "回去一趟",
    "e": "行动点 −1 · 家庭 +10 · 心理 +0.4",
    "fx": {
     "ap": -1,
     "family": 10,
     "attr": {
      "mental": 0.4
     }
    }
   },
   {
    "t": "不回去",
    "e": "心理 −0.5 · 训练 +0.4",
    "fx": {
     "attr": {
      "mental": -0.5,
      "tactic": 0.4
     },
     "family": -4
    }
   }
  ]
 },
 {
  "id": "e_coach_scold",
  "kind": "训练",
  "title": "教练说你态度有问题",
  "text": "他没提高声音，只是把训练计划拍在桌上。",
  "opts": [
   {
    "t": "认错",
    "e": "教练信任 +3 · 训练收益 +5%",
    "fx": {
     "trust": 3,
     "flag": "humble"
    }
   },
   {
    "t": "顶回去",
    "e": "教练信任 −4 · 心理 +0.4",
    "fx": {
     "trust": -4,
     "attr": {
      "mental": 0.4
     }
    }
   }
  ]
 },
 {
  "id": "e_teammate_left",
  "kind": "生活",
  "title": "队友被调走了",
  "text": "他的柜子空了，名牌还贴着。走之前没跟你告别。",
  "cond": {
   "stageMin": 2
  },
  "opts": [
   {
    "t": "给他发条消息",
    "e": "心理 +0.4 · 队友关系 +2",
    "fx": {
     "attr": {
      "mental": 0.4
     },
     "trust": 1
    }
   },
   {
    "t": "什么也没做",
    "e": "心理 −0.3 · 战术 +0.3",
    "fx": {
     "attr": {
      "mental": -0.3,
      "tactic": 0.3
     }
    }
   }
  ]
 },
 {
  "id": "e_sponsor_blade",
  "kind": "商业",
  "title": "赞助商要求你换底板",
  "text": "合同里写着要用他们的新款。你试了两天，手感不对。",
  "cond": {
   "stageMin": 4
  },
  "opts": [
   {
    "t": "换",
    "e": "资金 +12000 · 状态 −0.3 · 手感 −0.5",
    "fx": {
     "money": 12000,
     "form": -0.3,
     "attr": {
      "touch": -0.5
     }
    }
   },
   {
    "t": "坚持用旧的",
    "e": "声望 −2 · 心理 +0.5",
    "fx": {
     "rep": -2,
     "attr": {
      "mental": 0.5
     }
    }
   }
  ]
 },
 {
  "id": "e_rumor",
  "kind": "舆论",
  "title": "有人说你靠关系",
  "text": "帖子不长，但转得很快。你认识发帖的人，是同一个训练馆的。",
  "cond": {
   "breakLvMin": 1
  },
  "opts": [
   {
    "t": "在采访里回应",
    "e": "声望 +3 · 心理 −0.4",
    "fx": {
     "rep": 3,
     "attr": {
      "mental": -0.4
     }
    }
   },
   {
    "t": "不回应",
    "e": "心理 +0.5 · 舆论 4 周后自行沉底",
    "fx": {
     "attr": {
      "mental": 0.5
     },
     "flag": "silent"
    }
   }
  ]
 },
 {
  "id": "e_rain",
  "kind": "生活",
  "title": "下雨，没车去球馆",
  "text": "公交停运，打车要等四十分钟。训练七点开始。",
  "cond": {
   "stageMax": 2
  },
  "opts": [
   {
    "t": "跑过去",
    "e": "体力 −6 · 心理 +0.5",
    "fx": {
     "stam": -6,
     "attr": {
      "mental": 0.5
     }
    }
   },
   {
    "t": "请假",
    "e": "教练信任 −2",
    "fx": {
     "trust": -2
    }
   }
  ]
 },
 {
  "id": "e_doctor_cut",
  "kind": "伤病",
  "title": "队医让你减量",
  "text": "他把你这个月的训练量划掉了一半，说再练下去就是别人的事了。",
  "cond": {
   "stageMin": 2
  },
  "opts": [
   {
    "t": "听他的",
    "e": "疲劳 −20 · 本周训练收益 −20%",
    "fx": {
     "fatigue": -20,
     "flag": "lightWeek"
    }
   },
   {
    "t": "照练",
    "e": "破格点 +1 · 伤病风险 +10%",
    "fx": {
     "breakPts": 1,
     "injuryRisk": 10
    }
   }
  ]
 },
 {
  "id": "e_visit_school",
  "kind": "生活",
  "title": "少年宫请你回去讲一堂课",
  "text": "你小时候在那张台子上打过第一场比赛。",
  "cond": {
   "stageMin": 3
  },
  "opts": [
   {
    "t": "去",
    "e": "声望 +4 · 资金 +1000 · 行动点 −1",
    "fx": {
     "rep": 4,
     "money": 1000,
     "ap": -1
    }
   },
   {
    "t": "下次吧",
    "e": "体力 +5",
    "fx": {
     "stam": 5
    }
   }
  ]
 },
 {
  "id": "e_clutch_drill",
  "kind": "训练",
  "title": "关键分练习",
  "text": "教练把比分直接摆到 9 平，说：从现在开始。",
  "cond": {
   "stageMin": 2
  },
  "opts": [
   {
    "t": "练关键分",
    "e": "心理 +0.9 · 体力 −6",
    "fx": {
     "attr": {
      "mental": 0.9
     },
     "stam": -6
    }
   },
   {
    "t": "练体能",
    "e": "耐力 +0.7",
    "fx": {
     "attr": {
      "stamina": 0.7
     }
    }
   }
  ]
 },
 {
  "id": "e_opp_tape",
  "kind": "战术",
  "title": "对手的录像",
  "text": "三场比赛，同一个落点，他输了两次。",
  "cond": {
   "stageMin": 3
  },
  "opts": [
   {
    "t": "逐球看",
    "e": "战术 +1.0 · 状态 −0.1",
    "fx": {
     "attr": {
      "tactic": 1
     },
     "form": -0.1
    }
   },
   {
    "t": "只看比分",
    "e": "状态 +0.2",
    "fx": {
     "form": 0.2
    }
   }
  ]
 },
 {
  "id": "e_late_train",
  "kind": "训练",
  "title": "馆里只剩你一个人",
  "text": "十点半，灯灭了一半。你还有一筐球。",
  "opts": [
   {
    "t": "打完这筐",
    "e": "当前技术 +0.5 · 疲劳 +10",
    "fx": {
     "techAny": 0.5,
     "fatigue": 10
    }
   },
   {
    "t": "回去睡",
    "e": "体力 +8 · 状态 +0.2",
    "fx": {
     "stam": 8,
     "form": 0.2
    }
   }
  ]
 },
 {
  "id": "e_mother_visit",
  "kind": "家庭",
  "title": "你妈说要来看比赛",
  "text": "她问会不会影响你。你说不会。",
  "cond": {
   "stageMin": 2
  },
  "opts": [
   {
    "t": "让她来",
    "e": "心理 +0.6 · 声望 +1",
    "fx": {
     "attr": {
      "mental": 0.6
     },
     "rep": 1
    }
   },
   {
    "t": "让她别来",
    "e": "心理 +0.2 · 家庭 −3",
    "fx": {
     "attr": {
      "mental": 0.2
     },
     "family": -3
    }
   }
  ]
 },
 {
  "id": "e_biz_conflict",
  "kind": "商业",
  "title": "活动撞上了训练周",
  "text": "品牌方说只要半天，来回加路上要一整天。",
  "cond": {
   "stageMin": 4
  },
  "opts": [
   {
    "t": "去",
    "e": "资金 +8000 · 行动点 −1 · 教练信任 −2",
    "fx": {
     "money": 8000,
     "ap": -1,
     "trust": -2
    }
   },
   {
    "t": "不去",
    "e": "教练信任 +2 · 训练完整",
    "fx": {
     "trust": 2
    }
   }
  ]
 },
 {
  "id": "e_coach_rumor",
  "kind": "舆论",
  "title": "换教练的传闻",
  "text": "记者在混采区问你，你说不知道。你其实知道一点。",
  "cond": {
   "stageMin": 3
  },
  "opts": [
   {
    "t": "公开表态支持教练",
    "e": "教练信任 +4 · 声望 −1",
    "fx": {
     "trust": 4,
     "rep": -1
    }
   },
   {
    "t": "沉默",
    "e": "心理 +0.3",
    "fx": {
     "attr": {
      "mental": 0.3
     }
    }
   }
  ]
 },
 {
  "id": "e_old_rival_retire",
  "kind": "生活",
  "title": "老对手宣布退役",
  "text": "新闻很短，配了一张他年轻时的照片。",
  "cond": {
   "stageMin": 4
  },
  "opts": [
   {
    "t": "去现场",
    "e": "心理 +0.5 · 声望 +2 · 行动点 −1",
    "fx": {
     "attr": {
      "mental": 0.5
     },
     "rep": 2,
     "ap": -1
    }
   },
   {
    "t": "在训练馆里待着",
    "e": "体力 +4 · 训练 +0.3",
    "fx": {
     "stam": 4,
     "techAny": 0.3
    }
   }
  ]
 },
 {
  "id": "e_bad_call",
  "kind": "比赛",
  "title": "一个明显的误判",
  "text": "球擦边了，裁判没看见。比分变成 8 比 9。",
  "cond": {
   "stageMin": 1
  },
  "opts": [
   {
    "t": "争",
    "e": "心理 −0.3 · 声望 +1",
    "fx": {
     "attr": {
      "mental": -0.3
     },
     "rep": 1
    }
   },
   {
    "t": "不争，继续打",
    "e": "心理 +0.5",
    "fx": {
     "attr": {
      "mental": 0.5
     }
    }
   }
  ]
 },
 {
  "id": "e_new_kid",
  "kind": "生活",
  "title": "队里来了个小孩",
  "text": "十四岁，眼神和你当年一样，谁都不看。",
  "cond": {
   "stageMin": 4,
   "ageMin": 24
  },
  "opts": [
   {
    "t": "带他练两天",
    "e": "声望 +2 · 教练信任 +2 · 训练 −0.2",
    "fx": {
     "rep": 2,
     "trust": 2,
     "techAny": -0.2
    }
   },
   {
    "t": "各练各的",
    "e": "心理 +0.2",
    "fx": {
     "attr": {
      "mental": 0.2
     }
    }
   }
  ]
 },
 {
  "id": "e_physical",
  "kind": "伤病",
  "title": "赛季末体检",
  "text": "一整套检查下来，医生指着两张片子说：这里，还有这里。",
  "cond": {
   "stageMin": 2
  },
  "opts": [
   {
    "t": "全面处理",
    "e": "资金 −2000 · 伤病 −3 · 疲劳 −15",
    "fx": {
     "money": -2000,
     "injury": -3,
     "fatigue": -15
    }
   },
   {
    "t": "简单看看",
    "e": "体力 +5 · 伤病风险 +6%",
    "fx": {
     "stam": 5,
     "injuryRisk": 6
    }
   }
  ]
 },
 {
  "id": "e_contract",
  "kind": "商业",
  "title": "合同到期",
  "text": "经纪人把两份合同放在你面前，一份稳，一份赌。",
  "cond": {
   "stageMin": 4,
   "ageMin": 22
  },
  "opts": [
   {
    "t": "续约",
    "e": "资金 +20000 · 声望 +5 · 心理 −0.2",
    "fx": {
     "money": 20000,
     "rep": 5,
     "attr": {
      "mental": -0.2
     }
    }
   },
   {
    "t": "先观望",
    "e": "人气 +5 · 资金 +0",
    "fx": {
     "fame": 5
    }
   }
  ]
 },
 {
  "id": "e_broken_wall",
  "kind": "破格",
  "title": "墙上有道裂缝",
  "text": "你最近总能听见自己击球的声音变了。教练说，那是要长球了。",
  "cond": {
   "breakPtsMin": 4
  },
  "opts": [
   {
    "t": "加练，把这道缝砸开",
    "e": "破格点 +1 · 疲劳 +10",
    "fx": {
     "breakPts": 1,
     "fatigue": 10
    }
   },
   {
    "t": "稳住，别急",
    "e": "状态 +0.3 · 体力 +5",
    "fx": {
     "form": 0.3,
     "stam": 5
    }
   }
  ]
 }
]

var GOALS: Array = [
 {
  "id": "g01",
  "st": 0,
  "n": "第一次走进球馆",
  "d": "完成 1 次训练",
  "c": {
   "k": "trains",
   "v": 1
  }
 },
 {
  "id": "g02",
  "st": 0,
  "n": "正手能打上台",
  "d": "正手技术达到 18",
  "c": {
   "k": "tech",
   "t": "fh",
   "v": 18
  }
 },
 {
  "id": "g03",
  "st": 0,
  "n": "第一场正式比赛",
  "d": "参加 1 站比赛",
  "c": {
   "k": "matches",
   "v": 1
  }
 },
 {
  "id": "g04",
  "st": 0,
  "n": "市少儿赛四强",
  "d": "市少儿锦标赛进入四强",
  "c": {
   "k": "best",
   "e": "y_city",
   "v": 2
  }
 },
 {
  "id": "g05",
  "st": 0,
  "n": "被教练记住",
  "d": "教练信任度达到 55",
  "c": {
   "k": "trust",
   "v": 55
  }
 },
 {
  "id": "g06",
  "st": 0,
  "n": "坚持四周",
  "d": "累计训练 8 次",
  "c": {
   "k": "trains",
   "v": 8
  }
 },
 {
  "id": "g07",
  "st": 1,
  "n": "进省二队集训",
  "d": "身份达到省二队集训",
  "c": {
   "k": "stage",
   "v": 1
  }
 },
 {
  "id": "g08",
  "st": 1,
  "n": "省内积分上榜",
  "d": "进入国内青少年积分榜",
  "c": {
   "k": "poolRank",
   "p": "domestic"
  }
 },
 {
  "id": "g09",
  "st": 1,
  "n": "省少儿杯八强",
  "d": "省少儿杯进入八强",
  "c": {
   "k": "best",
   "e": "y_prov",
   "v": 3
  }
 },
 {
  "id": "g10",
  "st": 1,
  "n": "站上全国赛场",
  "d": "参加全国少儿锦标赛",
  "c": {
   "k": "played",
   "e": "y_nat_child"
  }
 },
 {
  "id": "g11",
  "st": 1,
  "n": "省内前十六",
  "d": "国内青少年排名前 16",
  "c": {
   "k": "poolRank",
   "p": "domestic",
   "v": 16
  }
 },
 {
  "id": "g12",
  "st": 1,
  "n": "第一次破格",
  "d": "完成任意一级破格",
  "c": {
   "k": "breakLv",
   "v": 1
  }
 },
 {
  "id": "g13",
  "st": 1,
  "n": "书也没落下",
  "d": "学业达到 25",
  "c": {
   "k": "study",
   "v": 25
  }
 },
 {
  "id": "g14",
  "st": 2,
  "n": "转正",
  "d": "获得省队正式编制",
  "c": {
   "k": "stage",
   "v": 2
  }
 },
 {
  "id": "g15",
  "st": 2,
  "n": "省青少年冠军",
  "d": "省青少年锦标赛夺冠",
  "c": {
   "k": "best",
   "e": "y_prov_youth",
   "v": 0
  }
 },
 {
  "id": "g16",
  "st": 2,
  "n": "全国青年前八",
  "d": "全国青年锦标赛进入八强",
  "c": {
   "k": "best",
   "e": "y_nat_junior",
   "v": 3
  }
 },
 {
  "id": "g17",
  "st": 2,
  "n": "省内前八",
  "d": "国内青少年排名前 8",
  "c": {
   "k": "poolRank",
   "p": "domestic",
   "v": 8
  }
 },
 {
  "id": "g18",
  "st": 2,
  "n": "赢一次宿敌",
  "d": "击败任意宿敌",
  "c": {
   "k": "beatRival"
  }
 },
 {
  "id": "g19",
  "st": 2,
  "n": "双打首胜",
  "d": "赢下一场双打",
  "c": {
   "k": "pairWins",
   "v": 1
  }
 },
 {
  "id": "g20",
  "st": 2,
  "n": "第二次破格",
  "d": "破格等级达到 2",
  "c": {
   "k": "breakLv",
   "v": 2
  }
 },
 {
  "id": "g21",
  "st": 2,
  "n": "进国青",
  "d": "入选国家青年队",
  "c": {
   "k": "stage",
   "v": 3
  }
 },
 {
  "id": "g22",
  "st": 3,
  "n": "WTT 首胜",
  "d": "在 WTT 赛事中赢一场",
  "c": {
   "k": "wttWins",
   "v": 1
  }
 },
 {
  "id": "g23",
  "st": 3,
  "n": "青少年世界排名",
  "d": "进入 ITTF 青少年排名榜",
  "c": {
   "k": "poolRank",
   "p": "youth"
  }
 },
 {
  "id": "g24",
  "st": 3,
  "n": "青年挑战赛冠军",
  "d": "青年挑战赛夺冠",
  "c": {
   "k": "best",
   "e": "y_chall",
   "v": 0
  }
 },
 {
  "id": "g25",
  "st": 3,
  "n": "世青赛四强",
  "d": "世青赛进入四强",
  "c": {
   "k": "best",
   "e": "y_world",
   "v": 2
  }
 },
 {
  "id": "g26",
  "st": 3,
  "n": "亚青赛决赛",
  "d": "亚青赛进入决赛",
  "c": {
   "k": "best",
   "e": "y_asian",
   "v": 1
  }
 },
 {
  "id": "g27",
  "st": 3,
  "n": "青少年世界前八",
  "d": "青少年世界排名前 8",
  "c": {
   "k": "poolRank",
   "p": "youth",
   "v": 8
  }
 },
 {
  "id": "g28",
  "st": 3,
  "n": "拿到成人赛外卡",
  "d": "通过青少年成绩获得成人赛资格",
  "c": {
   "k": "flag",
   "f": "adultCard"
  }
 },
 {
  "id": "g29",
  "st": 4,
  "n": "全锦赛前八",
  "d": "全国锦标赛进入八强",
  "c": {
   "k": "best",
   "e": "nat_champs",
   "v": 3
  }
 },
 {
  "id": "g30",
  "st": 4,
  "n": "乒超首胜",
  "d": "乒超联赛赢一场",
  "c": {
   "k": "played",
   "e": "cttsl"
  }
 },
 {
  "id": "g31",
  "st": 4,
  "n": "成人世界排名",
  "d": "进入成人世界排名榜",
  "c": {
   "k": "poolRank",
   "p": "adult"
  }
 },
 {
  "id": "g32",
  "st": 4,
  "n": "第一个 WTT 冠军",
  "d": "夺得任意 WTT 赛事冠军",
  "c": {
   "k": "wttTitles",
   "v": 1
  }
 },
 {
  "id": "g33",
  "st": 4,
  "n": "世界前三十",
  "d": "世界排名前 30",
  "c": {
   "k": "poolRank",
   "p": "adult",
   "v": 30
  }
 },
 {
  "id": "g34",
  "st": 4,
  "n": "三大赛冠军",
  "d": "奥运会 / 世乒赛 / 世界杯夺冠",
  "c": {
   "k": "majorTitles",
   "v": 1
  }
 },
 {
  "id": "g35",
  "st": 4,
  "n": "世界第一",
  "d": "世界排名第 1",
  "c": {
   "k": "poolRank",
   "p": "adult",
   "v": 1
  }
 },
 {
  "id": "g36",
  "st": 4,
  "n": "九大赛集齐",
  "d": "九大赛单打冠军全部拿到",
  "c": {
   "k": "nine"
  }
 },
 {
  "id": "g37",
  "st": 4,
  "n": "大满贯",
  "d": "奥运会 + 世乒赛 + 世界杯",
  "c": {
   "k": "grandSlam"
  }
 }
]

var ACHV: Array = [
 {
  "id": "a01",
  "n": "第一场球",
  "t": "bronze",
  "d": "完成一场比赛",
  "k": "matches",
  "v": 1
 },
 {
  "id": "a02",
  "n": "十场",
  "t": "bronze",
  "d": "累计 10 场比赛",
  "k": "matches",
  "v": 10
 },
 {
  "id": "a03",
  "n": "三十场",
  "t": "bronze",
  "d": "累计 30 场比赛",
  "k": "matches",
  "v": 30
 },
 {
  "id": "a04",
  "n": "第一次赢",
  "t": "bronze",
  "d": "赢下一场比赛",
  "k": "wins",
  "v": 1
 },
 {
  "id": "a05",
  "n": "五胜",
  "t": "bronze",
  "d": "累计 5 场胜利",
  "k": "wins",
  "v": 5
 },
 {
  "id": "a06",
  "n": "十五胜",
  "t": "bronze",
  "d": "累计 15 场胜利",
  "k": "wins",
  "v": 15
 },
 {
  "id": "a07",
  "n": "开练",
  "t": "bronze",
  "d": "完成第一次训练",
  "k": "trains",
  "v": 1
 },
 {
  "id": "a08",
  "n": "二十次训练",
  "t": "bronze",
  "d": "累计训练 20 次",
  "k": "trains",
  "v": 20
 },
 {
  "id": "a09",
  "n": "六十次训练",
  "t": "bronze",
  "d": "累计训练 60 次",
  "k": "trains",
  "v": 60
 },
 {
  "id": "a10",
  "n": "技术课",
  "t": "bronze",
  "d": "技术训练 10 次",
  "k": "techSessions",
  "v": 10
 },
 {
  "id": "a11",
  "n": "体能课",
  "t": "bronze",
  "d": "体能训练 10 次",
  "k": "fitSessions",
  "v": 10
 },
 {
  "id": "a12",
  "n": "心理课",
  "t": "bronze",
  "d": "心理训练 10 次",
  "k": "psySessions",
  "v": 10
 },
 {
  "id": "a13",
  "n": "录像课",
  "t": "bronze",
  "d": "战术复盘 10 次",
  "k": "tacSessions",
  "v": 10
 },
 {
  "id": "a14",
  "n": "会休息",
  "t": "bronze",
  "d": "休息 5 次",
  "k": "restWeeks",
  "v": 5
 },
 {
  "id": "a15",
  "n": "第一个冠军",
  "t": "bronze",
  "d": "赢得任意赛事冠军",
  "k": "champions",
  "v": 1
 },
 {
  "id": "a16",
  "n": "进过决赛",
  "t": "bronze",
  "d": "进入一次决赛",
  "k": "finals",
  "v": 1
 },
 {
  "id": "a17",
  "n": "进过四强",
  "t": "bronze",
  "d": "进入一次四强",
  "k": "semis",
  "v": 1
 },
 {
  "id": "a18",
  "n": "三连胜",
  "t": "bronze",
  "d": "连胜 3 场",
  "k": "maxWinStreak",
  "v": 3
 },
 {
  "id": "a19",
  "n": "五连胜",
  "t": "bronze",
  "d": "连胜 5 场",
  "k": "maxWinStreak",
  "v": 5
 },
 {
  "id": "a20",
  "n": "第一笔奖金",
  "t": "bronze",
  "d": "累计奖金 1 万",
  "k": "prize",
  "v": 10000
 },
 {
  "id": "a21",
  "n": "被人认识",
  "t": "bronze",
  "d": "声望达到 50",
  "k": "rep",
  "v": 50
 },
 {
  "id": "a22",
  "n": "有名字了",
  "t": "bronze",
  "d": "人气达到 10",
  "k": "fame",
  "v": 10
 },
 {
  "id": "a23",
  "n": "教练信你",
  "t": "bronze",
  "d": "教练信任度 60",
  "k": "coachTrust",
  "v": 60
 },
 {
  "id": "a24",
  "n": "攒了点",
  "t": "bronze",
  "d": "破格点累计 5 点",
  "k": "breakPtsEarned",
  "v": 5
 },
 {
  "id": "a25",
  "n": "上限 +1",
  "t": "bronze",
  "d": "完成一次技术突破",
  "k": "caps",
  "v": 1
 },
 {
  "id": "a26",
  "n": "五个小项",
  "t": "bronze",
  "d": "掌握 5 个技术小项",
  "k": "subs",
  "v": 5
 },
 {
  "id": "a27",
  "n": "三条目标",
  "t": "bronze",
  "d": "完成 3 条生涯目标",
  "k": "goals",
  "v": 3
 },
 {
  "id": "a28",
  "n": "论坛有人提你",
  "t": "bronze",
  "d": "论坛出现 5 条关于你的帖子",
  "k": "forumPosts",
  "v": 5
 },
 {
  "id": "a29",
  "n": "认识五个对手",
  "t": "bronze",
  "d": "解锁 5 位对手档案",
  "k": "oppMet",
  "v": 5
 },
 {
  "id": "a30",
  "n": "第一个赛季",
  "t": "bronze",
  "d": "打完一个完整赛季",
  "k": "seasons",
  "v": 1
 },
 {
  "id": "a31",
  "n": "学业及格",
  "t": "bronze",
  "d": "学业达到 20",
  "k": "study",
  "v": 20
 },
 {
  "id": "a32",
  "n": "省内有名",
  "t": "bronze",
  "d": "国内青少年排名进入前 32",
  "k": "bestDomestic",
  "v": 32
 },
 {
  "id": "a33",
  "n": "青少年上榜",
  "t": "bronze",
  "d": "青少年世界排名进入前 100",
  "k": "bestYouth",
  "v": 100
 },
 {
  "id": "a34",
  "n": "成人上榜",
  "t": "bronze",
  "d": "成人世界排名进入前 128",
  "k": "bestAdult",
  "v": 128
 },
 {
  "id": "a35",
  "n": "青少年第一冠",
  "t": "bronze",
  "d": "赢得一站青少年赛事",
  "k": "titlesYouth",
  "v": 1
 },
 {
  "id": "a36",
  "n": "国内第一冠",
  "t": "bronze",
  "d": "赢得一站国内赛事",
  "k": "titlesDomestic",
  "v": 1
 },
 {
  "id": "a37",
  "n": "一年十场",
  "t": "bronze",
  "d": "单赛季 10 场比赛",
  "k": "matchesInYear",
  "v": 10
 },
 {
  "id": "a38",
  "n": "一年一冠",
  "t": "bronze",
  "d": "单赛季 1 个冠军",
  "k": "championsInYear",
  "v": 1
 },
 {
  "id": "a39",
  "n": "第一次受伤",
  "t": "bronze",
  "d": "经历一次伤病",
  "k": "injuries",
  "v": 1
 },
 {
  "id": "a40",
  "n": "10 平之后",
  "t": "bronze",
  "d": "赢下一次 10 平后的局",
  "k": "deuceWins",
  "v": 1
 },
 {
  "id": "a41",
  "n": "零封一局",
  "t": "bronze",
  "d": "打出 11 比 0",
  "k": "perfectGames",
  "v": 1
 },
 {
  "id": "a42",
  "n": "双打首胜",
  "t": "bronze",
  "d": "赢下一场双打",
  "k": "pairWins",
  "v": 1
 },
 {
  "id": "a43",
  "n": "宿敌",
  "t": "bronze",
  "d": "与一位对手成为宿敌",
  "k": "maxRivalry",
  "v": 5
 },
 {
  "id": "a44",
  "n": "赢过前一百",
  "t": "bronze",
  "d": "击败一位世界前 100",
  "k": "winsVsTop100",
  "v": 1
 },
 {
  "id": "a45",
  "n": "市级冠军",
  "t": "bronze",
  "d": "赢得市少儿锦标赛",
  "k": "titlesCity",
  "v": 1
 },
 {
  "id": "a46",
  "n": "省级冠军",
  "t": "bronze",
  "d": "赢得省级赛事",
  "k": "titlesProv",
  "v": 1
 },
 {
  "id": "a47",
  "n": "第一次破格",
  "t": "bronze",
  "d": "完成一级破格",
  "k": "breakOk",
  "v": 1
 },
 {
  "id": "a48",
  "n": "破格未遂",
  "t": "bronze",
  "d": "经历一次破格失败",
  "k": "breakFail",
  "v": 1
 },
 {
  "id": "a49",
  "n": "见证退役",
  "t": "bronze",
  "d": "见证一位对手退役",
  "k": "retirements",
  "v": 1
 },
 {
  "id": "a50",
  "n": "三件器材",
  "t": "bronze",
  "d": "拥有 3 件器材",
  "k": "gearOwned",
  "v": 3
 },
 {
  "id": "b01",
  "n": "百场",
  "t": "silver",
  "d": "累计 100 场比赛",
  "k": "matches",
  "v": 100
 },
 {
  "id": "b02",
  "n": "五十胜",
  "t": "silver",
  "d": "累计 50 场胜利",
  "k": "wins",
  "v": 50
 },
 {
  "id": "b03",
  "n": "五冠",
  "t": "silver",
  "d": "累计 5 个冠军",
  "k": "champions",
  "v": 5
 },
 {
  "id": "b04",
  "n": "十次四强",
  "t": "silver",
  "d": "累计 10 次四强",
  "k": "semis",
  "v": 10
 },
 {
  "id": "b05",
  "n": "十连胜",
  "t": "silver",
  "d": "连胜 10 场",
  "k": "maxWinStreak",
  "v": 10
 },
 {
  "id": "b06",
  "n": "两百次训练",
  "t": "silver",
  "d": "累计训练 200 次",
  "k": "trains",
  "v": 200
 },
 {
  "id": "b07",
  "n": "二十个小项",
  "t": "silver",
  "d": "掌握 20 个技术小项",
  "k": "subs",
  "v": 20
 },
 {
  "id": "b08",
  "n": "三次突破",
  "t": "silver",
  "d": "完成 3 次技术突破",
  "k": "caps",
  "v": 3
 },
 {
  "id": "b09",
  "n": "十项成就",
  "t": "silver",
  "d": "解锁 10 项成就",
  "k": "achvCount",
  "v": 10
 },
 {
  "id": "b10",
  "n": "十条目标",
  "t": "silver",
  "d": "完成 10 条生涯目标",
  "k": "goals",
  "v": 10
 },
 {
  "id": "b11",
  "n": "奖金十万",
  "t": "silver",
  "d": "累计奖金 10 万",
  "k": "prize",
  "v": 100000
 },
 {
  "id": "b12",
  "n": "声望两百",
  "t": "silver",
  "d": "声望达到 200",
  "k": "rep",
  "v": 200
 },
 {
  "id": "b13",
  "n": "人气五十",
  "t": "silver",
  "d": "人气达到 50",
  "k": "fame",
  "v": 50
 },
 {
  "id": "b14",
  "n": "教练信任 75",
  "t": "silver",
  "d": "教练信任度 75",
  "k": "coachTrust",
  "v": 75
 },
 {
  "id": "b15",
  "n": "二十个对手",
  "t": "silver",
  "d": "解锁 20 位对手档案",
  "k": "oppMet",
  "v": 20
 },
 {
  "id": "b16",
  "n": "三个赛季",
  "t": "silver",
  "d": "打完 3 个赛季",
  "k": "seasons",
  "v": 3
 },
 {
  "id": "b17",
  "n": "学业四十",
  "t": "silver",
  "d": "学业达到 40",
  "k": "study",
  "v": 40
 },
 {
  "id": "b18",
  "n": "国内前十",
  "t": "silver",
  "d": "国内青少年排名前 10",
  "k": "bestDomestic",
  "v": 10
 },
 {
  "id": "b19",
  "n": "WTT 首胜",
  "t": "silver",
  "d": "在 WTT 赛事赢一场",
  "k": "wttWins",
  "v": 1
 },
 {
  "id": "b20",
  "n": "WTT 十胜",
  "t": "silver",
  "d": "在 WTT 赛事赢 10 场",
  "k": "wttWins",
  "v": 10
 },
 {
  "id": "b21",
  "n": "WTT 首冠",
  "t": "silver",
  "d": "赢得一站 WTT 赛事",
  "k": "wttTitles",
  "v": 1
 },
 {
  "id": "b22",
  "n": "青少年世界前五十",
  "t": "silver",
  "d": "青少年排名前 50",
  "k": "bestYouth",
  "v": 50
 },
 {
  "id": "b23",
  "n": "成人前一百",
  "t": "silver",
  "d": "成人世界排名前 100",
  "k": "bestAdult",
  "v": 100
 },
 {
  "id": "b24",
  "n": "一年三冠",
  "t": "silver",
  "d": "单赛季 3 个冠军",
  "k": "championsInYear",
  "v": 3
 },
 {
  "id": "b25",
  "n": "一年二十场",
  "t": "silver",
  "d": "单赛季 20 场比赛",
  "k": "matchesInYear",
  "v": 20
 },
 {
  "id": "b26",
  "n": "三次逆转",
  "t": "silver",
  "d": "落后两局以上完成逆转",
  "k": "comebacks",
  "v": 3
 },
 {
  "id": "b27",
  "n": "十次 10 平",
  "t": "silver",
  "d": "赢下 10 次 10 平后的局",
  "k": "deuceWins",
  "v": 10
 },
 {
  "id": "b28",
  "n": "三场零封",
  "t": "silver",
  "d": "打出 3 次 11 比 0",
  "k": "perfectGames",
  "v": 3
 },
 {
  "id": "b29",
  "n": "双打十胜",
  "t": "silver",
  "d": "双打累计 10 胜",
  "k": "pairWins",
  "v": 10
 },
 {
  "id": "b30",
  "n": "宿敌三级",
  "t": "silver",
  "d": "宿敌值达到 10",
  "k": "maxRivalry",
  "v": 10
 },
 {
  "id": "b31",
  "n": "赢过前五十",
  "t": "silver",
  "d": "击败一位世界前 50",
  "k": "winsVsTop50",
  "v": 1
 },
 {
  "id": "b32",
  "n": "全国冠军",
  "t": "silver",
  "d": "赢得全国级赛事",
  "k": "titlesNational",
  "v": 1
 },
 {
  "id": "b33",
  "n": "亚青冠军",
  "t": "silver",
  "d": "赢得亚青赛",
  "k": "titlesAsian",
  "v": 1
 },
 {
  "id": "b34",
  "n": "世青冠军",
  "t": "silver",
  "d": "赢得世青赛",
  "k": "titlesWorldYouth",
  "v": 1
 },
 {
  "id": "b35",
  "n": "破格三级",
  "t": "silver",
  "d": "破格等级达到 3",
  "k": "breakLv",
  "v": 3
 },
 {
  "id": "b36",
  "n": "十次破格尝试",
  "t": "silver",
  "d": "累计 10 次破格尝试",
  "k": "breakTry",
  "v": 10
 },
 {
  "id": "b37",
  "n": "五个赛季",
  "t": "silver",
  "d": "打完 5 个赛季",
  "k": "seasons",
  "v": 5
 },
 {
  "id": "b38",
  "n": "五件器材",
  "t": "silver",
  "d": "拥有 5 件器材",
  "k": "gearOwned",
  "v": 5
 },
 {
  "id": "b39",
  "n": "论坛二十帖",
  "t": "silver",
  "d": "论坛出现 20 条关于你的帖子",
  "k": "forumPosts",
  "v": 20
 },
 {
  "id": "b40",
  "n": "见证十次退役",
  "t": "silver",
  "d": "见证 10 位对手退役",
  "k": "retirements",
  "v": 10
 },
 {
  "id": "c01",
  "n": "三百场",
  "t": "gold",
  "d": "累计 300 场比赛",
  "k": "matches",
  "v": 300
 },
 {
  "id": "c02",
  "n": "两百胜",
  "t": "gold",
  "d": "累计 200 场胜利",
  "k": "wins",
  "v": 200
 },
 {
  "id": "c03",
  "n": "二十冠",
  "t": "gold",
  "d": "累计 20 个冠军",
  "k": "champions",
  "v": 20
 },
 {
  "id": "c04",
  "n": "二十连胜",
  "t": "gold",
  "d": "连胜 20 场",
  "k": "maxWinStreak",
  "v": 20
 },
 {
  "id": "c05",
  "n": "三十个小项",
  "t": "gold",
  "d": "掌握 30 个技术小项",
  "k": "subs",
  "v": 30
 },
 {
  "id": "c06",
  "n": "八次突破",
  "t": "gold",
  "d": "完成 8 次技术突破",
  "k": "caps",
  "v": 8
 },
 {
  "id": "c07",
  "n": "五十项成就",
  "t": "gold",
  "d": "解锁 50 项成就",
  "k": "achvCount",
  "v": 50
 },
 {
  "id": "c08",
  "n": "二十五条目标",
  "t": "gold",
  "d": "完成 25 条生涯目标",
  "k": "goals",
  "v": 25
 },
 {
  "id": "c09",
  "n": "奖金百万",
  "t": "gold",
  "d": "累计奖金 100 万",
  "k": "prize",
  "v": 1000000
 },
 {
  "id": "c10",
  "n": "声望六百",
  "t": "gold",
  "d": "声望达到 600",
  "k": "rep",
  "v": 600
 },
 {
  "id": "c11",
  "n": "人气两百",
  "t": "gold",
  "d": "人气达到 200",
  "k": "fame",
  "v": 200
 },
 {
  "id": "c12",
  "n": "教练信任 90",
  "t": "gold",
  "d": "教练信任度 90",
  "k": "coachTrust",
  "v": 90
 },
 {
  "id": "c13",
  "n": "五十个对手",
  "t": "gold",
  "d": "解锁 50 位对手档案",
  "k": "oppMet",
  "v": 50
 },
 {
  "id": "c14",
  "n": "八个赛季",
  "t": "gold",
  "d": "打完 8 个赛季",
  "k": "seasons",
  "v": 8
 },
 {
  "id": "c15",
  "n": "成人前十",
  "t": "gold",
  "d": "成人世界排名前 10",
  "k": "bestAdult",
  "v": 10
 },
 {
  "id": "c16",
  "n": "青少年世界第一",
  "t": "gold",
  "d": "青少年世界排名第 1",
  "k": "bestYouth",
  "v": 1
 },
 {
  "id": "c17",
  "n": "WTT 十冠",
  "t": "gold",
  "d": "累计 10 个 WTT 冠军",
  "k": "wttTitles",
  "v": 10
 },
 {
  "id": "c18",
  "n": "一年六冠",
  "t": "gold",
  "d": "单赛季 6 个冠军",
  "k": "championsInYear",
  "v": 6
 },
 {
  "id": "c19",
  "n": "一年五十场",
  "t": "gold",
  "d": "单赛季 50 场比赛",
  "k": "matchesInYear",
  "v": 50
 },
 {
  "id": "c20",
  "n": "十次逆转",
  "t": "gold",
  "d": "完成 10 次两局以上逆转",
  "k": "comebacks",
  "v": 10
 },
 {
  "id": "c21",
  "n": "关键分先生",
  "t": "gold",
  "d": "赢下 30 次 10 平后的局",
  "k": "deuceWins",
  "v": 30
 },
 {
  "id": "c22",
  "n": "五场零封",
  "t": "gold",
  "d": "打出 5 次 11 比 0",
  "k": "perfectGames",
  "v": 5
 },
 {
  "id": "c23",
  "n": "双打三十胜",
  "t": "gold",
  "d": "双打累计 30 胜",
  "k": "pairWins",
  "v": 30
 },
 {
  "id": "c24",
  "n": "宿敌满级",
  "t": "gold",
  "d": "宿敌值达到 20",
  "k": "maxRivalry",
  "v": 20
 },
 {
  "id": "c25",
  "n": "赢过前十",
  "t": "gold",
  "d": "击败一位世界前 10",
  "k": "winsVsTop10",
  "v": 1
 },
 {
  "id": "c26",
  "n": "三冠王赛季",
  "t": "gold",
  "d": "单赛季包揽三站以上高级别冠军",
  "k": "bigTitlesInYear",
  "v": 3
 },
 {
  "id": "c27",
  "n": "九大赛四席",
  "t": "gold",
  "d": "集齐九大赛中的 4 个冠军",
  "k": "nineCount",
  "v": 4
 },
 {
  "id": "c28",
  "n": "破格五级",
  "t": "gold",
  "d": "破格等级达到 5",
  "k": "breakLv",
  "v": 5
 },
 {
  "id": "c29",
  "n": "世界前十周数",
  "t": "gold",
  "d": "在世界前十停留 52 周",
  "k": "top10Weeks",
  "v": 52
 },
 {
  "id": "c30",
  "n": "百万奖金单站",
  "t": "gold",
  "d": "单站奖金超过 50 万",
  "k": "maxPrize",
  "v": 500000
 },
 {
  "id": "d01",
  "n": "五百场",
  "t": "platinum",
  "d": "累计 500 场比赛",
  "k": "matches",
  "v": 500
 },
 {
  "id": "d02",
  "n": "四百胜",
  "t": "platinum",
  "d": "累计 400 场胜利",
  "k": "wins",
  "v": 400
 },
 {
  "id": "d03",
  "n": "五十冠",
  "t": "platinum",
  "d": "累计 50 个冠军",
  "k": "champions",
  "v": 50
 },
 {
  "id": "d04",
  "n": "三十连胜",
  "t": "platinum",
  "d": "连胜 30 场",
  "k": "maxWinStreak",
  "v": 30
 },
 {
  "id": "d05",
  "n": "全部小项",
  "t": "platinum",
  "d": "掌握全部 35 个技术小项",
  "k": "subs",
  "v": 35
 },
 {
  "id": "d06",
  "n": "十一次突破",
  "t": "platinum",
  "d": "完成 11 次技术突破",
  "k": "caps",
  "v": 11
 },
 {
  "id": "d07",
  "n": "一百项成就",
  "t": "platinum",
  "d": "解锁 100 项成就",
  "k": "achvCount",
  "v": 100
 },
 {
  "id": "d08",
  "n": "三十七条目标",
  "t": "platinum",
  "d": "完成全部 37 条生涯目标",
  "k": "goals",
  "v": 37
 },
 {
  "id": "d09",
  "n": "奖金千万",
  "t": "platinum",
  "d": "累计奖金 1000 万",
  "k": "prize",
  "v": 10000000
 },
 {
  "id": "d10",
  "n": "声望一千二",
  "t": "platinum",
  "d": "声望达到 1200",
  "k": "rep",
  "v": 1200
 },
 {
  "id": "d11",
  "n": "世界第一",
  "t": "platinum",
  "d": "成人世界排名第 1",
  "k": "bestAdult",
  "v": 1
 },
 {
  "id": "d12",
  "n": "世界第一满一年",
  "t": "platinum",
  "d": "在世界第一停留 52 周",
  "k": "top1Weeks",
  "v": 52
 },
 {
  "id": "d13",
  "n": "九大赛六席",
  "t": "platinum",
  "d": "集齐九大赛中的 6 个冠军",
  "k": "nineCount",
  "v": 6
 },
 {
  "id": "d14",
  "n": "三满贯赛季",
  "t": "platinum",
  "d": "单赛季拿下三站大满贯级别冠军",
  "k": "bigTitlesInYear",
  "v": 5
 },
 {
  "id": "d15",
  "n": "破格者·极",
  "t": "platinum",
  "d": "完成六级破格",
  "k": "breakLv",
  "v": 6
 },
 {
  "id": "e01",
  "n": "六败六战",
  "t": "hidden",
  "d": "六级破格各失败一次",
  "k": "breakFailAll",
  "v": 1
 },
 {
  "id": "e02",
  "n": "大器晚成",
  "t": "hidden",
  "d": "25 岁后首次进入世界前十",
  "k": "lateBloom",
  "v": 1
 },
 {
  "id": "e03",
  "n": "最后一战",
  "t": "hidden",
  "d": "在宿敌退役前赢下他",
  "k": "beatRivalBeforeRetire",
  "v": 1
 },
 {
  "id": "e04",
  "n": "同年双榜",
  "t": "hidden",
  "d": "同一赛季同时拥有青少年与成人排名",
  "k": "dualBoard",
  "v": 1
 },
 {
  "id": "e05",
  "n": "从零开始",
  "t": "hidden",
  "d": "二周目重新打进世界前十",
  "k": "ngPlusTop10",
  "v": 1
 },
 {
  "id": "e06",
  "n": "没有名字的那年",
  "t": "hidden",
  "d": "在无排名阶段停留满 3 年",
  "k": "noRankYears",
  "v": 3
 },
 {
  "id": "e07",
  "n": "逆风球",
  "t": "hidden",
  "d": "在决胜局 6 比 10 落后时赢下比赛",
  "k": "greatEscape",
  "v": 1
 },
 {
  "id": "e08",
  "n": "一生之敌",
  "t": "hidden",
  "d": "与同一对手交手 20 次",
  "k": "rival20",
  "v": 1
 }
]

var ACHV_TIER_NAME: Dictionary = {
 "bronze": "铜",
 "silver": "银",
 "gold": "金",
 "platinum": "白金",
 "hidden": "隐藏"
}

var GRADE_RULES: Array = [
 {
  "g": "S",
  "n": "超级全满贯",
  "d": "九大赛单打冠军全部集齐"
 },
 {
  "g": "A",
  "n": "全满贯",
  "d": "三大赛 + 全运 + 全锦 + 总决赛"
 },
 {
  "g": "B",
  "n": "大满贯",
  "d": "奥运会、世乒赛、世界杯单打冠军"
 },
 {
  "g": "C",
  "n": "世界冠军",
  "d": "至少拿下一项三大赛冠军"
 },
 {
  "g": "D",
  "n": "职业选手",
  "d": "进入过成人世界排名"
 }
]

var COUNTRY_NAME: Dictionary = {
 "CHN": "中国",
 "JPN": "日本",
 "KOR": "韩国",
 "DEU": "德国",
 "FRA": "法国",
 "SWE": "瑞典",
 "TPE": "中国台北",
 "HKG": "中国香港",
 "BRA": "巴西",
 "SGP": "新加坡",
 "USA": "美国",
 "IND": "印度",
 "EGY": "埃及",
 "NGA": "尼日利亚",
 "AUS": "澳大利亚",
 "CAN": "加拿大",
 "AUT": "奥地利",
 "POR": "葡萄牙",
 "ROU": "罗马尼亚",
 "CRO": "克罗地亚",
 "POL": "波兰",
 "DEN": "丹麦",
 "ESP": "西班牙",
 "ITA": "意大利",
 "NED": "荷兰",
 "GRE": "希腊",
 "TUR": "土耳其"
}

var COUNTRY_ABBR: Dictionary = {
 "CHN": "CHN",
 "JPN": "JPN",
 "KOR": "KOR",
 "DEU": "GER",
 "FRA": "FRA",
 "SWE": "SWE",
 "TPE": "TPE",
 "HKG": "HKG",
 "BRA": "BRA",
 "SGP": "SGP",
 "USA": "USA",
 "IND": "IND",
 "EGY": "EGY",
 "NGA": "NGR",
 "AUS": "AUS",
 "CAN": "CAN",
 "AUT": "AUT",
 "POR": "POR",
 "ROU": "ROU",
 "CRO": "CRO",
 "POL": "POL",
 "DEN": "DEN",
 "ESP": "ESP",
 "ITA": "ITA",
 "NED": "NED",
 "GRE": "GRE",
 "TUR": "TUR"
}

var COUNTRY_WEIGHT: Array = [
 {
  "k": "CHN",
  "w": 34
 },
 {
  "k": "JPN",
  "w": 13
 },
 {
  "k": "KOR",
  "w": 8
 },
 {
  "k": "DEU",
  "w": 8
 },
 {
  "k": "FRA",
  "w": 7
 },
 {
  "k": "SWE",
  "w": 6
 },
 {
  "k": "TPE",
  "w": 6
 },
 {
  "k": "BRA",
  "w": 4
 },
 {
  "k": "HKG",
  "w": 3
 },
 {
  "k": "SGP",
  "w": 2
 },
 {
  "k": "USA",
  "w": 3
 },
 {
  "k": "IND",
  "w": 3
 },
 {
  "k": "EGY",
  "w": 2
 },
 {
  "k": "NGA",
  "w": 2
 },
 {
  "k": "AUS",
  "w": 2
 },
 {
  "k": "CAN",
  "w": 2
 },
 {
  "k": "AUT",
  "w": 2
 },
 {
  "k": "POR",
  "w": 2
 },
 {
  "k": "ROU",
  "w": 2
 },
 {
  "k": "CRO",
  "w": 2
 },
 {
  "k": "POL",
  "w": 2
 },
 {
  "k": "DEN",
  "w": 2
 },
 {
  "k": "ESP",
  "w": 1
 },
 {
  "k": "ITA",
  "w": 1
 },
 {
  "k": "NED",
  "w": 1
 },
 {
  "k": "GRE",
  "w": 1
 },
 {
  "k": "TUR",
  "w": 1
 }
]

var NAME_LIB: Dictionary = {
 "JPN": {
  "sur": [
   "佐藤",
   "铃木",
   "高桥",
   "田中",
   "渡边",
   "伊藤",
   "山本",
   "中村",
   "小林",
   "加藤",
   "吉田",
   "山田",
   "松本",
   "井上",
   "木村",
   "清水",
   "山口",
   "森",
   "池田",
   "桥本",
   "石川",
   "前田",
   "藤田",
   "冈田"
  ],
  "m": [
   "翔太",
   "大辉",
   "悠斗",
   "阳向",
   "拓海",
   "健太",
   "龙之介",
   "飒太",
   "悠真",
   "苍",
   "树",
   "奏多",
   "瑛太",
   "亮"
  ],
  "f": [
   "结衣",
   "美咲",
   "葵",
   "凛",
   "芽依",
   "遥",
   "枫",
   "千夏",
   "阳菜",
   "咲良",
   "美羽",
   "心春",
   "爱",
   "优花"
  ]
 },
 "KOR": {
  "sur": [
   "金",
   "李",
   "朴",
   "崔",
   "郑",
   "姜",
   "赵",
   "尹",
   "张",
   "林",
   "韩",
   "吴",
   "申",
   "徐",
   "权",
   "黄",
   "安",
   "宋",
   "柳",
   "洪"
  ],
  "m": [
   "敏俊",
   "志勋",
   "东贤",
   "俊浩",
   "在赫",
   "承宇",
   "道贤",
   "泰阳",
   "相民",
   "宇镇"
  ],
  "f": [
   "书妍",
   "智恩",
   "敏智",
   "秀彬",
   "河允",
   "彩英",
   "允熙",
   "多恩",
   "瑞贤",
   "智友"
  ]
 },
 "DEU": {
  "sur": [
   "穆勒",
   "施密特",
   "施耐德",
   "菲舍尔",
   "韦伯",
   "迈尔",
   "瓦格纳",
   "贝克尔",
   "霍夫曼",
   "科赫",
   "舒尔茨",
   "鲍尔"
  ],
  "m": [
   "卢卡斯",
   "约纳斯",
   "费利克斯",
   "蒂姆",
   "尼克拉斯",
   "莱昂",
   "保罗",
   "埃米尔"
  ],
  "f": [
   "安娜",
   "莱娜",
   "玛丽",
   "索菲",
   "汉娜",
   "尤利娅",
   "克拉拉",
   "莉亚"
  ]
 },
 "FRA": {
  "sur": [
   "马丁",
   "贝尔纳",
   "杜布瓦",
   "托马",
   "罗贝尔",
   "西蒙",
   "洛朗",
   "米歇尔",
   "勒鲁瓦",
   "加西亚"
  ],
  "m": [
   "雨果",
   "特奥",
   "纳坦",
   "恩佐",
   "朱尔",
   "阿德里安",
   "路易",
   "马蒂斯"
  ],
  "f": [
   "莱娅",
   "克洛艾",
   "玛侬",
   "卡米耶",
   "朱丽叶",
   "路易丝",
   "阿娜伊丝",
   "埃玛"
  ]
 },
 "SWE": {
  "sur": [
   "安德松",
   "约翰松",
   "卡尔松",
   "尼尔松",
   "埃里克松",
   "拉松",
   "奥尔松",
   "斯文松"
  ],
  "m": [
   "埃里克",
   "安东",
   "奥斯卡",
   "埃米尔",
   "维克托",
   "阿尔宾",
   "古斯塔夫",
   "菲利普"
  ],
  "f": [
   "埃尔莎",
   "阿尔娃",
   "英格丽",
   "莉娜",
   "萨拉",
   "埃琳"
  ]
 },
 "BRA": {
  "sur": [
   "席尔瓦",
   "桑托斯",
   "奥利维拉",
   "索萨",
   "科斯塔",
   "佩雷拉",
   "利马",
   "卡瓦略"
  ],
  "m": [
   "若昂",
   "佩德罗",
   "卢卡斯",
   "加布里埃尔",
   "拉斐尔",
   "蒂亚戈",
   "布鲁诺",
   "马特乌斯"
  ],
  "f": [
   "安娜",
   "贝阿特丽斯",
   "卡米拉",
   "拉里萨",
   "朱莉娅",
   "玛丽亚"
  ]
 },
 "TPE": {
  "sur": [
   "陈",
   "林",
   "黄",
   "张",
   "李",
   "王",
   "吴",
   "刘",
   "蔡",
   "杨",
   "许",
   "郑"
  ],
  "m": [
   "昀儒",
   "建安",
   "承睿",
   "柏睿",
   "彦诚",
   "冠宇",
   "子谦",
   "宥辰"
  ],
  "f": [
   "思羽",
   "怡静",
   "昱谆",
   "品瑄",
   "予涵",
   "语彤",
   "若涵",
   "安琪"
  ]
 },
 "HKG": {
  "sur": [
   "陈",
   "黄",
   "李",
   "梁",
   "何",
   "吴",
   "林",
   "张",
   "刘",
   "邓"
  ],
  "m": [
   "家豪",
   "俊贤",
   "志明",
   "柏霖",
   "天佑",
   "子轩",
   "浩轩",
   "铭轩"
  ],
  "f": [
   "雅婷",
   "嘉欣",
   "晓彤",
   "卓琳",
   "芷晴",
   "凯琳"
  ]
 },
 "SGP": {
  "sur": [
   "陈",
   "林",
   "黄",
   "李",
   "王",
   "吴",
   "周",
   "蔡"
  ],
  "m": [
   "伟杰",
   "俊豪",
   "志强",
   "嘉明",
   "宇轩",
   "凯文"
  ],
  "f": [
   "美玲",
   "慧敏",
   "嘉怡",
   "晓琳",
   "诗涵"
  ]
 },
 "USA": {
  "sur": [
   "史密斯",
   "约翰逊",
   "威廉姆斯",
   "布朗",
   "琼斯",
   "米勒",
   "戴维斯",
   "威尔逊"
  ],
  "m": [
   "杰克",
   "伊森",
   "诺亚",
   "利亚姆",
   "梅森",
   "卢克"
  ],
  "f": [
   "艾玛",
   "奥利维娅",
   "索菲亚",
   "格蕾丝",
   "克洛伊"
  ]
 },
 "IND": {
  "sur": [
   "夏尔马",
   "维尔马",
   "辛格",
   "古普塔",
   "梅赫塔",
   "拉奥",
   "帕特尔",
   "南比亚尔"
  ],
  "m": [
   "阿尔琼",
   "罗希特",
   "维克拉姆",
   "阿迪蒂亚",
   "拉胡尔",
   "卡兰"
  ],
  "f": [
   "阿南娅",
   "迪维娅",
   "普里娅",
   "伊莎",
   "梅拉"
  ]
 },
 "EGY": {
  "sur": [
   "哈桑",
   "易卜拉欣",
   "马哈茂德",
   "法鲁克",
   "萨利姆",
   "阿卜杜勒"
  ],
  "m": [
   "奥马尔",
   "卡里姆",
   "塔里克",
   "阿米尔",
   "约瑟夫"
  ],
  "f": [
   "玛丽亚姆",
   "努尔",
   "萨拉",
   "法蒂玛",
   "阿米娜"
  ]
 },
 "NGA": {
  "sur": [
   "奥科耶",
   "阿德巴约",
   "恩万科沃",
   "奥比",
   "埃泽",
   "阿金"
  ],
  "m": [
   "奇内杜",
   "埃马纽埃尔",
   "塞贡",
   "奇克",
   "奥卢"
  ],
  "f": [
   "阿玛卡",
   "奇奥玛",
   "富米",
   "阿约",
   "恩戈齐"
  ]
 },
 "AUS": {
  "sur": [
   "史密斯",
   "泰勒",
   "布朗",
   "威尔逊",
   "汤普森",
   "沃克"
  ],
  "m": [
   "杰克",
   "哈里",
   "奥利弗",
   "诺亚",
   "利亚姆"
  ],
  "f": [
   "露西",
   "艾拉",
   "夏洛特",
   "米娅",
   "格蕾丝"
  ]
 },
 "CAN": {
  "sur": [
   "特伦布莱",
   "加尼翁",
   "罗伊",
   "麦克唐纳",
   "坎贝尔",
   "贝内特"
  ],
  "m": [
   "利亚姆",
   "诺亚",
   "伊桑",
   "卢卡斯",
   "马修"
  ],
  "f": [
   "奥利维亚",
   "艾米丽",
   "克拉拉",
   "佐伊",
   "莉莉"
  ]
 },
 "AUT": {
  "sur": [
   "格鲁伯",
   "胡贝尔",
   "鲍尔",
   "施泰纳",
   "莫泽",
   "霍费尔"
  ],
  "m": [
   "菲利普",
   "西蒙",
   "大卫",
   "雅各布",
   "马库斯"
  ],
  "f": [
   "安娜",
   "莉娜",
   "索菲",
   "玛丽亚",
   "艾玛"
  ]
 },
 "POR": {
  "sur": [
   "席尔瓦",
   "桑托斯",
   "费雷拉",
   "佩雷拉",
   "科斯塔",
   "阿尔梅达"
  ],
  "m": [
   "若昂",
   "米格尔",
   "蒂亚戈",
   "鲁伊",
   "佩德罗"
  ],
  "f": [
   "安娜",
   "玛丽亚",
   "伊内斯",
   "莱昂诺尔",
   "贝阿特丽斯"
  ]
 },
 "ROU": {
  "sur": [
   "波佩斯库",
   "伊万",
   "拉杜",
   "斯坦",
   "杜米特鲁",
   "马林"
  ],
  "m": [
   "安德烈",
   "米哈伊",
   "亚历山德鲁",
   "维克托",
   "拉杜"
  ],
  "f": [
   "埃莱娜",
   "安德烈娅",
   "玛丽亚",
   "阿娜",
   "伊琳娜"
  ]
 },
 "CRO": {
  "sur": [
   "霍瓦特",
   "科瓦奇",
   "巴比奇",
   "马里奇",
   "诺瓦克",
   "尤里奇"
  ],
  "m": [
   "伊万",
   "马尔科",
   "卢卡",
   "安特",
   "菲利普"
  ],
  "f": [
   "伊万娜",
   "佩特拉",
   "玛丽娅",
   "露西亚",
   "安娜"
  ]
 },
 "POL": {
  "sur": [
   "诺瓦克",
   "科瓦尔斯基",
   "维希涅夫斯基",
   "莱万多夫斯基",
   "马祖尔"
  ],
  "m": [
   "雅库布",
   "彼得",
   "托马什",
   "马切伊",
   "帕维尔"
  ],
  "f": [
   "安娜",
   "卡塔日娜",
   "玛格达",
   "阿列克桑德拉",
   "尤莉娅"
  ]
 },
 "DEN": {
  "sur": [
   "尼尔森",
   "汉森",
   "延森",
   "彼得森",
   "拉森"
  ],
  "m": [
   "弗雷德里克",
   "马蒂亚斯",
   "安德斯",
   "埃米尔",
   "卡斯帕"
  ],
  "f": [
   "艾达",
   "弗雷娅",
   "索菲",
   "劳拉",
   "艾玛"
  ]
 },
 "ESP": {
  "sur": [
   "加西亚",
   "马丁内斯",
   "洛佩斯",
   "桑切斯",
   "罗梅罗"
  ],
  "m": [
   "阿尔瓦罗",
   "迭戈",
   "哈维尔",
   "塞尔吉奥",
   "巴勃罗"
  ],
  "f": [
   "露西亚",
   "玛尔塔",
   "保拉",
   "卡门",
   "艾琳娜"
  ]
 },
 "ITA": {
  "sur": [
   "罗西",
   "费拉里",
   "鲁索",
   "比安基",
   "科隆博"
  ],
  "m": [
   "马尔科",
   "卢卡",
   "安德烈亚",
   "马泰奥",
   "西蒙内"
  ],
  "f": [
   "朱莉娅",
   "索菲亚",
   "基亚拉",
   "艾丽莎",
   "玛蒂娜"
  ]
 },
 "NED": {
  "sur": [
   "德容",
   "扬森",
   "范德堡",
   "巴克",
   "维瑟"
  ],
  "m": [
   "丹尼尔",
   "卢卡斯",
   "蒂姆",
   "斯文",
   "诺亚"
  ],
  "f": [
   "朱莉娅",
   "安妮",
   "莉莎",
   "芬娜",
   "桑娜"
  ]
 },
 "GRE": {
  "sur": [
   "帕帕多普洛斯",
   "尼科劳",
   "乔治乌",
   "迪米特里乌",
   "安东努"
  ],
  "m": [
   "扬尼斯",
   "科斯塔斯",
   "尼科斯",
   "迪米特里斯",
   "斯皮罗斯"
  ],
  "f": [
   "玛丽亚",
   "埃莱尼",
   "索菲亚",
   "安娜",
   "卡捷琳娜"
  ]
 },
 "TUR": {
  "sur": [
   "耶尔马兹",
   "德米尔",
   "卡亚",
   "沙欣",
   "切利克"
  ],
  "m": [
   "埃姆雷",
   "穆拉特",
   "卡安",
   "奥赞",
   "布拉克"
  ],
  "f": [
   "泽伊内普",
   "埃利夫",
   "梅尔韦",
   "塞玛",
   "艾谢"
  ]
 }
}

var HANDLE_PREFIX: Array = [
 "反手",
 "正手",
 "台内",
 "中远台",
 "前三板",
 "削球",
 "直板",
 "横板",
 "弧圈",
 "快攻",
 "怪胶",
 "长胶",
 "生胶",
 "防弧",
 "拧拉",
 "爆冲",
 "摆短",
 "劈长",
 "侧切",
 "兜拐",
 "快撕",
 "弹击",
 "挑打",
 "晃撇"
]

var HANDLE_SUFFIX: Array = [
 "爱好者",
 "观察员",
 "老球迷",
 "小学生",
 "退役选手",
 "教练",
 "数据党",
 "路人",
 "键盘侠",
 "分析师",
 "搬运工",
 "看客",
 "粉丝",
 "黑粉",
 "路人甲",
 "不吹不黑",
 "只说事实",
 "看球二十年",
 "刚入坑",
 "求科普"
]

var CN_SURNAME: Array = [
 "陈",
 "林",
 "周",
 "吴",
 "郑",
 "许",
 "何",
 "罗",
 "高",
 "梁",
 "宋",
 "唐",
 "谢",
 "韩",
 "曹",
 "邓",
 "彭",
 "曾",
 "萧",
 "田",
 "董",
 "袁",
 "潘",
 "蒋",
 "蔡",
 "余",
 "杜",
 "叶",
 "程",
 "苏",
 "魏",
 "吕",
 "丁",
 "沈",
 "姚",
 "卢",
 "姜",
 "崔",
 "钟",
 "谭",
 "陆",
 "汪",
 "范",
 "金",
 "石",
 "廖",
 "贾",
 "夏",
 "韦",
 "付",
 "方",
 "白",
 "邹",
 "孟",
 "熊",
 "秦",
 "邱",
 "江",
 "尹",
 "薛",
 "闫",
 "段",
 "雷",
 "侯",
 "龙",
 "史",
 "陶",
 "黎",
 "贺",
 "顾",
 "毛",
 "郝",
 "龚",
 "邵",
 "万",
 "钱",
 "严",
 "覃",
 "武",
 "戴"
]

var CN_GIVEN_M: Array = [
 "砚舟",
 "一鸣",
 "承宇",
 "子昂",
 "浩然",
 "嘉树",
 "明远",
 "思齐",
 "景行",
 "知远",
 "修文",
 "亦辰",
 "书航",
 "予安",
 "清和",
 "维岳",
 "望舒",
 "叙白",
 "南乔",
 "少陵",
 "行简",
 "致远",
 "怀瑾",
 "慕白",
 "观澜",
 "琢玉",
 "问渠",
 "临川",
 "星野",
 "闻笛",
 "照野",
 "松寒",
 "逸尘",
 "青崖",
 "拾遗",
 "沉舟",
 "渡远",
 "既明",
 "执中",
 "守拙"
]

# ---------------- 索引与查询 ----------------
var TOURNEY_BY_ID: Dictionary = {}
var GEAR_MAP: Dictionary = {}
var ACHV_BY_ID: Dictionary = {}
var TECH_MAP: Dictionary = {}
var ATTR_MAP: Dictionary = {}
var STAGE_BY_ORG: Dictionary = {}

func _init() -> void:
	for t in TOURNEYS:
		TOURNEY_BY_ID[t["id"]] = t
	for g in GEAR:
		GEAR_MAP[g["id"]] = g
	for a in ACHV:
		ACHV_BY_ID[a["id"]] = a
	for t in TECHS:
		TECH_MAP[t["k"]] = t
	for a in ATTRS:
		ATTR_MAP[a["k"]] = a
	for st in STAGES:
		STAGE_BY_ORG[st["org"]] = st

func tourney(id: String) -> Dictionary:
	return TOURNEY_BY_ID.get(id, {})

func tier_meta(tier: String) -> Dictionary:
	return TIER_META.get(tier, TIER_META["cont"])

func points_for(tier: String, place: int) -> int:
	var arr: Array = POINTS.get(tier, POINTS["cont"])
	if place < 0 or place >= arr.size():
		return 0
	return int(arr[place])

func season_of(week: int) -> Dictionary:
	for se in SEASONS:
		var rg: Array = se["w"]
		if week >= int(rg[0]) and week <= int(rg[1]):
			return se
	return SEASONS[0]

func stage_at(i: int) -> Dictionary:
	return STAGES[clampi(i, 0, STAGES.size() - 1)]

func attr_cap(stage: int) -> int:
	return int(ATTR_CAP[clampi(stage, 0, ATTR_CAP.size() - 1)])

func tech_cap_max(stage: int) -> int:
	return int(CAP_STAGE_MAX[clampi(stage, 0, CAP_STAGE_MAX.size() - 1)])

# ---------------- 名字生成 ----------------
func gen_name(country: String, used: Dictionary, rng: RandomNumberGenerator) -> String:
	var first := ""
	var given := ""
	if country == "CHN":
		first = str(CN_SURNAME[rng.randi_range(0, CN_SURNAME.size() - 1)])
		given = str(CN_GIVEN_M[rng.randi_range(0, CN_GIVEN_M.size() - 1)])
	else:
		var lib: Dictionary = NAME_LIB.get(country, NAME_LIB.get("DEU", {}))
		var sur: Array = lib.get("sur", ["穆勒"])
		var giv: Array = lib.get("m", ["卢卡斯"])
		first = str(sur[rng.randi_range(0, sur.size() - 1)])
		given = str(giv[rng.randi_range(0, giv.size() - 1)])
	var full := first + given
	var guard := 0
	while used.has(full) and guard < 40:
		if country == "CHN":
			given = str(CN_GIVEN_M[rng.randi_range(0, CN_GIVEN_M.size() - 1)])
		else:
			var lib2: Dictionary = NAME_LIB.get(country, NAME_LIB.get("DEU", {}))
			var sur2: Array = lib2.get("sur", ["穆勒"])
			var giv2: Array = lib2.get("m", ["卢卡斯"])
			first = str(sur2[rng.randi_range(0, sur2.size() - 1)])
			given = str(giv2[rng.randi_range(0, giv2.size() - 1)])
		full = first + given
		guard += 1
	used[full] = true
	return full

# 协会配额：成人榜前 20 至少来自 8 个协会
var WORLD_PLAN: Array = [
	{"k": "CHN", "n": 60, "elite": 6, "peak": [50, 86], "ages": "chn"},
	{"k": "JPN", "n": 18, "elite": 4, "peak": [52, 86]},
	{"k": "KOR", "n": 12, "elite": 2, "peak": [50, 84]},
	{"k": "DEU", "n": 14, "elite": 3, "peak": [52, 85]},
	{"k": "FRA", "n": 13, "elite": 3, "peak": [50, 85]},
	{"k": "SWE", "n": 10, "elite": 2, "peak": [50, 85]},
	{"k": "TPE", "n": 10, "elite": 2, "peak": [48, 83]},
	{"k": "BRA", "n": 8, "elite": 1, "peak": [48, 82]},
	{"k": "HKG", "n": 8, "elite": 1, "peak": [46, 80]},
	{"k": "SGP", "n": 6, "elite": 0, "peak": [44, 78]},
	{"k": "USA", "n": 7, "elite": 0, "peak": [44, 78]},
	{"k": "IND", "n": 6, "elite": 0, "peak": [44, 78]},
	{"k": "EGY", "n": 5, "elite": 0, "peak": [42, 76]},
	{"k": "NGA", "n": 5, "elite": 0, "peak": [42, 76]},
	{"k": "AUS", "n": 4, "elite": 0, "peak": [42, 74]},
	{"k": "CAN", "n": 4, "elite": 0, "peak": [42, 74]},
	{"k": "AUT", "n": 4, "elite": 0, "peak": [44, 78]},
	{"k": "POR", "n": 4, "elite": 0, "peak": [44, 78]},
	{"k": "ROU", "n": 4, "elite": 0, "peak": [42, 76]},
	{"k": "CRO", "n": 4, "elite": 0, "peak": [42, 76]},
	{"k": "POL", "n": 4, "elite": 0, "peak": [42, 76]},
	{"k": "DEN", "n": 3, "elite": 0, "peak": [42, 76]},
	{"k": "ESP", "n": 3, "elite": 0, "peak": [40, 74]},
	{"k": "ITA", "n": 3, "elite": 0, "peak": [40, 72]},
	{"k": "NED", "n": 3, "elite": 0, "peak": [40, 72]},
	{"k": "GRE", "n": 2, "elite": 0, "peak": [40, 72]},
	{"k": "TUR", "n": 2, "elite": 0, "peak": [40, 72]},
]

var TAG_NAMES: Dictionary = {
	"speed": "速度型", "control": "控制型", "defense": "防守型", "power": "力量型", "trick": "怪胶型",
}

var INTENT_META: Dictionary = {
	"rush": {"n": "抢攻", "tag": "power", "d": "前三板压上，赢快也输快"},
	"rally": {"n": "相持", "tag": "speed", "d": "把球拖进多板，比谁先失误"},
	"control": {"n": "控制", "tag": "control", "d": "落点与旋转，磨掉对手的节奏"},
	"defend": {"n": "防守", "tag": "defense", "d": "退半步，等他先动手"},
}


# ---------------- 破格六级 ----------------
var BREAK_LEVELS: Array = [
	{"lv": 1, "n": "市队 → 省二队试训", "short": "省二队试训", "pts": 3, "weeks": [14, 16], "age": [10, 12], "stage": 0,
		"ovr": 26, "debuff": {"weeks": 8, "mul": 0.85}, "cool": 0, "target": "stage1",
		"d": "跳过试训的随机判定，直接拿到集训资格。身体会先跟不上。"},
	{"lv": 2, "n": "省二队 → 省队正式编", "short": "省队转正", "pts": 4, "weeks": [26, 28], "age": [12, 14], "stage": 1,
		"ovr": 42, "debuff": {"weeks": 12, "mul": 0.85}, "cool": 26, "target": "stage2",
		"d": "跳过转正评估里的稳定性权重。会有人在论坛问「这么小就转正？」"},
	{"lv": 3, "n": "省队 → 国青集训", "short": "进国青", "pts": 5, "weeks": [24, 26], "age": [13, 15], "stage": 2,
		"ovr": 56, "debuff": {"weeks": 16, "mul": 0.80}, "cool": 52, "target": "stage3",
		"d": "跳过国青选拔赛的单败淘汰。输了就没有第二次。"},
	{"lv": 4, "n": "国青 → 国家二队", "short": "进国家二队", "pts": 6, "weeks": [10, 12], "age": [15, 17], "stage": 3,
		"ovr": 72, "debuff": {"weeks": 20, "mul": 0.75}, "cool": 52, "target": "stage4",
		"d": "成人世界排名提前一年激活，从第 200 位起算。"},
	{"lv": 5, "n": "国家二队 → 国家一队", "short": "进一队", "pts": 7, "weeks": [34, 36], "age": [16, 18], "stage": 4,
		"ovr": 84, "debuff": {"weeks": 24, "mul": 0.70}, "cool": 52, "target": "oneTeam",
		"d": "跳过队内循环赛。此后每一场都有人盯着你的位置。"},
	{"lv": 6, "n": "直接进大赛名单", "short": "大赛名单", "pts": 8, "weeks": [36, 38], "age": [17, 45], "stage": 4,
		"ovr": 92, "debuff": {"weeks": 28, "mul": 0.65}, "cool": 104, "target": "majorSlot",
		"d": "跳过选拔赛，直接进世乒赛 / 世界杯名单。舆论会炸。"},
]
