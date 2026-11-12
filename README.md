# 乒乓来福 v0.8

> 从市体校的水泥台，到世界赛场中央那张蓝色球台。
> 这一生，你会输给很多人，也会在某一天，输给时间。

Godot 4.7 实现的乒乓球生涯模拟。**文字内核 + 极简几何表现**：不画球、不画拍，用光点、拖尾和数据流承载比赛；用周报、论坛和事件卡承载人生。

---

## 一、如何运行

**方式 A：直接玩（Windows）**

如果本地已有构建产物，双击 `build/windows/PingPongLife.exe`。免安装，单文件，无需 Godot。该文件不随 Git 仓库提交。

**方式 B：Godot 编辑器**

用 Godot 4.7 打开 `project.godot`，按 `F5`。

**方式 C：命令行**

```bash
godot --path "D:/workbuddys/table tennis/PingPongLife"
```

> 字体使用系统中文字体（微软雅黑 / 苹方 / Noto），无需额外安装。
> 存档位于 `%APPDATA%/Godot/app_userdata/乒乓来福 v0.8/`。

### 方式 D：iPhone / iPad 使用 GitHub + Xogot

手机端直接运行 Godot 源码工程，不使用 `build/windows/PingPongLife.exe`。

1. 在 App Store 安装 **Xogot**。当前版本要求 iOS 18 或更高。
2. 安装 **Working Copy**，登录与 GitHub 仓库对应的账号。
3. 在 Working Copy 点 `+` → `Clone Repository`，粘贴仓库地址：
   `https://github.com/Moglass/PingPongLife.git`
4. 克隆时将 Files App 的目标位置设为 `On My iPhone` → `Xogot`。
5. 克隆完成后，在多任务界面彻底关闭 Xogot，再重新打开。
6. 在 Xogot 项目列表中选择 `PingPongLife`；若列表没有自动出现，使用 `Import` 定位到 `Xogot/PingPongLife/project.godot`。
7. 点击运行即可进入游戏。竖屏会自动切换单栏布局，触控映射已在工程中启用。

Working Copy 官方说明：将 Xogot 项目作为 linked repository 管理并回推修改需要 Working Copy Pro。仅在手机上拉取最新版本并在 Xogot 中运行，仍按 App 内实际权限提示操作。

GitHub 仓库不包含 `.godot/`、`shots/` 和 `build/`。这些是本机缓存、截图与平台构建产物；Xogot 首次打开工程时会自行生成导入缓存。

---

## 二、你会看到什么

| 页面 | 内容 |
|---|---|
| **标题** | 新生涯（姓名 + 四种出身）、读档 |
| **日常** | 左：Ovr / 五维雷达 / 体力 / 状态 / 里程碑；中：6 个行动卡 + 周报流；右：论坛热帖 |
| **赛事** | 团体赛（5 盘 3 胜）+ 个人赛、三条越级通道（排名直通 / 资格赛 / 外卡 / 队内直通） |
| **团体赛** | 教练排阵板、双方名单、逐盘推进、位置体验（一单体能 ×1.5 / 三单悬崖）、空砍两分 |
| **比赛** | 透视球台 + 光点轨迹 + 落点波纹 + 比分板 + 数据流 + 解说 + 关键分决策 + 四档速度 |
| **复盘** | 五维对比雷达、技术统计、**关键分回放**、教练点评、赛事结算 |
| **论坛** | 五大派系（数据帝 / 乐子人 / 理中客 / 黑粉 / 死忠）、楼中楼对线、排队道歉 |
| **档案** | 概览 / **器材** / **成就** 三个标签。143 个成就，28 件器材，五类槽位 |

**操作**：鼠标点击；`空格` 推进一周。
**移动端**：竖屏自动切换为单栏布局，安全区适配，触控目标 ≥ 46pt。

---

## 三、系统清单

| 系统 | 状态 | 落地位置 |
|---|---|---|
| 事件总线 / 资源驱动 / 场景树 | ✅ | `EventBus` / `DataManager` / `GameManager` |
| 成长：Resource + 指数曲线 + 年龄硬上限 | ✅ | `PlayerStats.ladder_cap()` / `add_attr()` |
| ITTF/WTT 规则引擎 | ✅ | `MatchEngine`：11 分制、10 平轮发、决胜局 5 分换边、每 6 分擦汗、1 次暂停、轮换发球法 |
| 四档速度（胜负与奖励完全一致） | ✅ | `MatchView` + 同一 RNG 序列 |
| 赛事三通道 + 体能惩罚 + 交学费 | ✅ | `TournamentSystem` |
| 团体赛排阵博弈（六阶段权重矩阵） | ✅ | `TeamSystem` + `TeamView` |
| 双轨 NPC 池 + 年度新陈代谢 | ✅ | `NPCWorld`：15 名 Tier1 + 220 人 Tier2 |
| 论坛：词库插槽 + 派系对撞 + 回旋镖 | ✅ | `ForumManager` |
| 随机事件：数值做减法 | ✅ | `EventPool`（35 张卡，效果 ×0.55 + 临时状态） |
| 生态挤压与非强制退役 | ✅ | `check_pressure()` + 四条路线 + 专属结局 |
| **器材系统** | ✅ 新增 | `GearSystem`：28 件 / 5 槽位 / 按阶段解锁 / 四维加成 |
| **成就系统** | ✅ 新增 | `AchievementSystem`：143 个 / 5 级 / 跨周目持久化 |
| **生涯里程碑** | ✅ 新增 | `GameManager.milestones`：首胜、首冠、世界第一、进队、100 胜 |
| 极简几何物理质感 | ✅ | `TableRenderer` + `paper.gdshader`，纯 `_draw` + Tween |
| 动态声效与环境音 | ✅ | `AudioDirector`：合成音，观众底噪随比分呼吸，关键分真空 + 心跳 |
| 响应式 / 移动端 | ✅ | 容器布局、竖屏单栏、安全区、46pt 触控 |

### 仍然没做

- **双打 / 混双**：`StaticDB.PAIR_TOURNEYS` 有赛事数据，但双打的跑位与默契模型没做。
- **多周目继承**：成就跨周目保留，但天赋继承和 "上一世" 叙事没做。
- **教练模式（退役后上帝视角）**：只到退役结局，没有后续玩法。

---

## 四、导出

### Windows exe（已验证）

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/PingPongLife.exe
```

产物：`build/windows/PingPongLife.exe`（单文件，内嵌 PCK，约 60–80 MB）。`build/` 已加入 `.gitignore`，需要时在本机或 CI 中重新导出。

### iOS（需 macOS）

`export_presets.cfg` 已配好 iOS 预设（Bundle ID `com.pingponglife.laifu`，arm64，iOS 13+，导出 Xcode 工程）。

**Windows 上无法产出 `.ipa`** —— 已实测：Godot 4.7.2 的 iOS 导出器在 Windows 上会直接拒绝导出（连 Xcode 工程骨架也不生成），因为 `xcodebuild`、证书链、Archive 全部依赖 macOS。这不是配置缺失——`export_presets.cfg` 里 Bundle ID、arm64、iOS 13+、全套图标都已配好。

在 Mac 上（工程根目录已备好脚本）：

```bash
./export_ios.sh YOUR_TEAM_ID     # 自动写入 Team ID 并导出 ipa
```

或手动：

```bash
godot --headless --path . --export-release "iOS" build/ios/PingPongLife.ipa
```

也可以把 `export_presets.cfg` 里的 `application/export_project_only` 改成 `true`，先导出 Xcode 工程，再用 Xcode 打开 → Product → Archive → Distribute App。

---

## 五、架构

```
PingPongLife/
├── project.godot
├── export_presets.cfg
├── scenes/Main.tscn
├── scripts/
│   ├── autoload/        EventBus / DataManager / GameManager / ForumManager / AudioDirector
│   ├── data/            PlayerStats（Resource）
│   ├── core/            MatchEngine / TournamentSystem / TeamSystem / NPCWorld
│   │                    CareerSystem / EventPool / GearSystem / AchievementSystem
│   ├── db/StaticDB.gd   6149 行静态数据（37 站赛事 / 35 事件卡 / 143 成就 / 28 器材 / 名字库）
│   └── ui/              UIKit / MainUI / 五个页面 / RadarChart / LineChart / TableRenderer
└── tools/               测试与截图（不参与导出）
```

**分层原则**

- `MatchEngine` 不 `emit`、不 `get_node`、不碰 Tween —— 只返回事件数组，可 headless 单测。
- 沉浸档与跳过档走同一条 RNG 序列，档位只影响呈现。
- 所有 UI 用 Container + 锚点，自绘图形才用相对坐标。

---

## 六、验收

```
生涯模拟 8→26 岁：Ovr 92.7 · 世界第一 · 1076 场 · 28 冠 · 胜率 73%
单分模型：同档 55.5% | +20 档 97% | -20 档 6%
规则事件：换发 / 擦汗 / 局末 / 场末 / 轮换发球 全部触发
UI 冒烟：26 周 + 四页切换 + 存档往返 + 比赛结算，零运行时错误
竖屏：900×1600 单栏，viewport 自动切换
```

```bash
godot --headless --path . tools/TestRunner.tscn     # 生涯集成测试
godot --headless --path . tools/Smoke.tscn          # UI 冒烟
godot --headless --script tools/test_match.gd       # 规则层单测
godot --path . tools/Shot.tscn                      # 批量截图
godot --path . tools/Portrait.tscn                  # 竖屏截图
```

---

## 七、扩展指南

- **加赛事**：`StaticDB.TOURNEYS` 追加（`id/n/tier/w/draw/age/stage/pts/prize/bo`）
- **加团体赛**：`TeamSystem.TEAM_EVENTS`（`n/w/stage/level/bo/prize/rep/fame`）
- **加事件**：`StaticDB.EVENT_CARDS`（`cond` 控阶段年龄，`opts[].fx` 通用解析）
- **加成就**：`StaticDB.ACHV`（`k` = 统计键，`v` = 阈值；键映射在 `AchievementSystem.stat_value`）
- **加器材**：`StaticDB.GEAR`（`cat` 决定槽位，`atk/ctrl/defn/mob` 为四维加成）
- **加论坛文案**：`ForumManager.TEMPLATES`，占位符 `{name} {nick} {opp} {score} {age} {place} {position}`
- **改配色**：`UIKit` 顶部色板

---

## 八、素材与版权

- 无第三方美术素材。视觉由 `_draw` / Shader / Tween 生成。
- 音效由 `AudioDirector` 实时合成（正弦/方波/噪声 + 包络），无采样音频。
- 数据层（赛事名、事件文案、成就、姓名库）来自本项目 v0.7 的自有内容。
- 中文字体使用系统字体，不随包分发，避免授权问题。

---

*Godot 4.7.2 · 1600×900（横）/ 900×1600（竖）· GL Compatibility*
