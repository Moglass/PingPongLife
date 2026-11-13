# 部署指南 · Web / PWA

工程已经具备完整的 Web 发布能力：**本地导出已验证可运行**（Edge + WebGL 2.0 + Compatibility 渲染，标题页与新建生涯交互正常）。

缺的只有一步：**把仓库推上 GitHub 并开启 Pages**。这台机器到 `github.com:443` 的连接被阻断，但 `github.com:22`（SSH）是通的。

---

## 一、推送（三分钟）

### 方式 A：SSH key（推荐）

本机已生成密钥，公钥在：

```
~/.ssh/id_ed25519.pub
```

内容：

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6RsNKDTR1O2b/iM6OfOuYl6zrP0Dv5HyFFTm1waw+I pingponglife-web
```

1. 打开 https://github.com/settings/keys → **New SSH key**
2. Title 填 `pingponglife-web`，Key 粘贴上面整行
3. 回来执行：

```bash
cd "D:/workbuddys/table tennis/PingPongLife"
git remote set-url origin git@github.com:Moglass/PingPongLife.git
git push -u origin main
```

### 方式 B：GitHub Desktop

用已登录的 GitHub Desktop 打开本目录 → Publish / Push。

### 方式 C：代理

如果之后能连上 443，直接：

```bash
git push origin main
```

---

## 二、开启 Pages

推送成功后：

1. 仓库 → **Settings → Pages**
2. **Build and deployment → Source** 选 **GitHub Actions**
3. 回到 **Actions** 标签，等 `Build & Deploy Web` 跑完（首次约 4–6 分钟）
4. 访问 `https://moglass.github.io/PingPongLife/`

工作流文件：`.github/workflows/deploy-web.yml`

它做四件事：

- 下载 Godot 4.7.2 + 导出模板
- 跑 `tools/test_match.gd` 回归（规则层单测）
- 导出 Web（单线程 / Compatibility）
- 上传 `build/web` 到 Pages

> workflow 里额外写了 `_headers`（`Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy`）和 `404.html`。即使当前是单线程构建，加上这两个头不影响运行，未来切多线程时也不用改。

---

## 三、iPhone 上使用

1. Safari 打开 `https://moglass.github.io/PingPongLife/`
2. 等待首次加载（WASM 39.5MB，4G 下约 8–15 秒；之后走 PWA 缓存）
3. **分享 → 添加到主屏幕**
4. 从主屏幕启动即为全屏（`display: standalone`），无地址栏

竖屏会自动切到 900×1600 单栏布局；横屏时用 1600×900 三栏。

---

## 四、存档迁移

Web 端存档在浏览器的 IndexedDB，和 Windows 的 `%APPDATA%` 不互通。

游戏内：**菜单 → 导出存档（跨设备）**，会得到一段 `PPL1.xxxxx` 的文本码。

在另一台设备：**菜单 → 导入存档码**，粘贴即可。

> 浏览器清理站点数据会丢存档，务必定期导出存档码备份。

---

## 五、验收清单

在本机与 iPhone 上各跑一遍：

| 项目 | PC Chrome / Edge | iPhone Safari |
|---|---|---|
| 新建生涯 | ✅ 已验证 | 待真机 |
| 训练 / 周推进 | ✅ 桌面版已验证 | 待真机 |
| 单打比赛（球台动画） | ✅ 桌面版已验证 | 待真机 |
| 团体赛排阵 | ✅ 桌面版已验证 | 待真机 |
| 论坛 / 档案 / 成就 / 器材 | ✅ 桌面版已验证 | 待真机 |
| 音效 | ⚠️ 需真实点击解锁 | 待真机 |
| 存档持久化（刷新后仍在） | ⚠️ 需手动验证 | 待真机 |
| 横竖屏切换 | ✅ headless 已验证 layout | 待真机 |

**必须说明**：我只能在 Windows 上用 headless Edge 做自动化验证。iPhone Safari 的真机验收（尤其是 WebGL 性能、音频解锁、主屏幕启动、安全区）无法在这里完成，需要你拿 iPhone 跑一遍。

---

## 六、已知限制

- **首次加载 39.5MB WASM**。这是 Godot 4 单线程 Web 导出的常态；gzip 后约 10MB。多线程构建能更快，但需要 COOP/COEP 头，且 iOS Safari 对 SharedArrayBuffer 支持有版本要求，第一版不做。
- **PWA 更新有缓存**。Service Worker 会缓存旧版本，更新后用户可能要多刷一次。后续可加"有新版本"提示。
- **字体是子集**（3946 字）。玩家输入生僻字可能显示为方块，常见字已覆盖。
- **云端同步未做**。任务书里也建议先本地 + 迁移，云同步不应成为上线前置条件。

---

## 七、本地预览

```bash
cd "D:/workbuddys/table tennis/PingPongLife"
python tools/serve.py 8080
# 打开 http://localhost:8080
```

`tools/serve.py` 会补上 `application/wasm` MIME，直接双击 `index.html` 是跑不起来的。
