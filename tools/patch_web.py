#!/usr/bin/env python3
"""
导出后处理：把 Godot 默认的黑底加载页换成品牌加载页，并补齐 iOS PWA 元信息。

用法（每次 Web 导出后执行）：
    python tools/patch_web.py build/web

做的事：
  1. viewport 加 viewport-fit=cover（刘海屏全屏）
  2. 补 apple-mobile-web-app-* / theme-color / 中文 lang
  3. 黑底 -> 纸色，避免闪黑
  4. 加载页显示品牌、真实百分比、慢速网络提示
  5. 注入 iOS 适配 CSS（安全区、禁止回弹、禁用长按菜单）
"""
import io
import os
import re
import sys
import time

# 建筑号：每次导出都会变，用来让老用户自动跳出缓存
BUILD_TAG_PLACEHOLDER = "__BUILD_TAG__"

SW_SYNC_JS = """		<script>
/* 版本自愈：Service Worker 会把 index.html 一起缓存住，导致玩家永远看到旧壳子。
   这里在加载前比对构建号，发现新版本就注销 SW、清空 CacheStorage、强制重载一次。
   首次访问只记录不清除，避免多下一次 10MB。 */
(function () {
	var BUILD = "__BUILD_TAG__";
	var KEY = "ppl_build_tag";
	try {
		var seen = localStorage.getItem(KEY);
		if (seen && seen !== BUILD) {
			localStorage.setItem(KEY, BUILD);
			var jobs = [];
			if ("serviceWorker" in navigator) {
				jobs.push(navigator.serviceWorker.getRegistrations().then(function (rs) {
					return Promise.all(rs.map(function (r) { return r.unregister(); }));
				}));
			}
			if (window.caches) {
				jobs.push(caches.keys().then(function (ks) {
					return Promise.all(ks.map(function (k) { return caches.delete(k); }));
				}));
			}
			Promise.all(jobs).then(function () { location.reload(); }, function () { location.reload(); });
			return;
		}
		localStorage.setItem(KEY, BUILD);
	} catch (e) {}
})();
</script>
"""

HEAD_META = """		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
		<meta name="apple-mobile-web-app-capable" content="yes">
		<meta name="mobile-web-app-capable" content="yes">
		<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
		<meta name="apple-mobile-web-app-title" content="乒乓来福">
		<meta name="theme-color" content="#f4f1ea">
		<meta name="format-detection" content="telephone=no">
		<meta name="description" content="乒乓来福 v0.8 —— 文字内核、极简几何的乒乓球生涯模拟。">"""

STYLE = """<style>
:root {
	--paper: #f4f1ea;
	--ink: #1e1b17;
	--ink2: #4a4438;
	--ink3: #8a8175;
	--red: #b03a2e;
	--line: #d9d3c7;
}
html, body, #canvas {
	margin: 0;
	padding: 0;
	border: 0;
}
html {
	background: var(--paper);
	-webkit-text-size-adjust: 100%;
}
body {
	color: var(--ink);
	background: var(--paper);
	overflow: hidden;
	touch-action: none;
	overscroll-behavior: none;
	-webkit-tap-highlight-color: transparent;
	-webkit-touch-callout: none;
	-webkit-user-select: none;
	user-select: none;
	font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Hiragino Sans GB",
		"Microsoft YaHei", "Noto Sans SC", sans-serif;
}
#canvas {
	display: block;
	outline: none;
}
#canvas:focus {
	outline: none;
}
#status, #status-splash, #status-progress {
	position: absolute;
	left: 0;
	right: 0;
}
#status {
	top: 0;
	bottom: 0;
	background: var(--paper);
	display: flex;
	flex-direction: column;
	justify-content: center;
	align-items: center;
	visibility: hidden;
	z-index: 10;
}
#status-splash {
	display: none;
}
/* 引擎内联脚本会用 style.display='block' 打开原生 progress，
   这里必须 !important 才能压住它——否则蓝色原生态和自绘进度条会叠在一起。 */
#status-progress {
	display: none !important;
	width: 1px !important;
	height: 1px !important;
	opacity: 0;
	pointer-events: none;
}
#boot {
	display: flex;
	flex-direction: column;
	align-items: center;
	width: min(76vw, 300px);
	text-align: center;
}
#boot-brand {
	font-size: 38px;
	letter-spacing: 0.18em;
	color: var(--ink);
	font-weight: 500;
	line-height: 1.2;
	text-indent: 0.18em;
}
#boot-tag {
	margin-top: 12px;
	font-size: 9px;
	letter-spacing: 0.34em;
	color: var(--ink3);
	text-transform: uppercase;
	text-indent: 0.34em;
}
#boot-rule {
	margin: 30px 0 14px;
	width: 100%;
	height: 3px;
	background: var(--line);
	position: relative;
	overflow: hidden;
	border-radius: 2px;
}
#boot-fill {
	position: absolute;
	left: 0;
	top: 0;
	height: 3px;
	width: 0%;
	background: var(--red);
	border-radius: 2px;
	transition: width 0.3s cubic-bezier(0.22, 1, 0.36, 1);
}
#boot-pct {
	font-size: 13px;
	color: var(--ink2);
	font-variant-numeric: tabular-nums;
	letter-spacing: 0.08em;
	height: 18px;
}
#boot-hint {
	margin-top: 20px;
	font-size: 11px;
	line-height: 1.8;
	color: var(--ink3);
	max-width: 240px;
	min-height: 38px;
}
#status-notice {
	background: #fff;
	border: 1px solid var(--line);
	color: var(--ink);
	font-size: 13px;
	line-height: 1.6;
	margin: 0 1.6rem;
	overflow: hidden;
	padding: 1.1rem 1.3rem;
	text-align: center;
	z-index: 1;
	max-width: 460px;
}
@media (max-height: 520px) {
	#boot-brand { font-size: 30px; }
	#boot-rule { margin: 16px 0 12px; }
	#boot-hint { margin-top: 14px; }
}
</style>"""

BODY_STATUS = """		<div id="status">
			<img id="status-splash" class="show-image--true fullsize--true use-filter--true" src="index.png" alt="">
			<div id="boot">
				<div id="boot-brand">乒乓来福</div>
				<div id="boot-tag">A Table Tennis Life</div>
				<div id="boot-rule"><div id="boot-fill"></div></div>
				<div id="boot-pct">0%</div>
				<div id="boot-hint">正在装载球台</div>
			</div>
			<progress id="status-progress"></progress>
			<div id="status-notice"></div>
		</div>"""

# 在引擎启动脚本前插入：百分比驱动 + iOS 视觉视口修正
BRIDGE_JS = """		<script>
(function () {
	var fill = document.getElementById('boot-fill');
	var pct = document.getElementById('boot-pct');
	var hint = document.getElementById('boot-hint');
	var bar = document.getElementById('status-progress');
	if (!fill || !bar) { return; }

	var started = Date.now();
	var lastPct = -1;

	function tick() {
		var v = bar.value, m = bar.max;
		if (m > 0 && v >= 0) {
			var p = Math.max(0, Math.min(100, Math.round(v / m * 100)));
			if (p !== lastPct) {
				lastPct = p;
				fill.style.width = p + '%';
				pct.textContent = p + '%';
				var secs = (Date.now() - started) / 1000;
				if (p >= 100) {
					hint.textContent = '进入球馆';
				} else if (p < 30) {
					hint.textContent = '正在下载引擎';
				} else if (secs > 10) {
					hint.textContent = '首次加载约 10 MB，之后就快了';
				} else {
					hint.textContent = '正在装载球台';
				}
			}
		}
		requestAnimationFrame(tick);
	}
	requestAnimationFrame(tick);

	// iOS Safari：地址栏收起/展开会让 100vh 抖动，改用 visualViewport 实际高度
	function fit() {
		var h = (window.visualViewport && window.visualViewport.height) || window.innerHeight;
		document.documentElement.style.height = h + 'px';
		document.body.style.height = h + 'px';
	}
	window.addEventListener('resize', fit);
	window.addEventListener('orientationchange', function () { setTimeout(fit, 120); });
	if (window.visualViewport) {
		window.visualViewport.addEventListener('resize', fit);
	}
	fit();
})();
</script>
"""


def patch(root: str) -> None:
    page = os.path.join(root, "index.html")
    s = io.open(page, encoding="utf-8").read()

    # 1) lang
    s = s.replace('<html lang="en">', '<html lang="zh-CN">', 1)

    # 1.5) 版本自愈脚本（放在最前，早于引擎脚本）
    tag = str(int(time.time()))
    if "ppl_build_tag" not in s:
        js = SW_SYNC_JS.replace(BUILD_TAG_PLACEHOLDER, tag)
        s = s.replace("</head>", js + "\t</head>", 1)
    else:
        s = re.sub(r'var BUILD = "[^"]*";', 'var BUILD = "%s";' % tag, s, count=1)

    # 2) viewport + apple meta
    s = re.sub(r'\t*<meta name="viewport"[^>]*>', HEAD_META, s, count=1)

    # 3) 样式块
    s = re.sub(r"<style>.*?</style>", STYLE, s, count=1, flags=re.S)

    # 4) 加载页结构
    m = re.search(
        r'<div id="status">.*?<div id="status-notice"></div>\s*</div>',
        s,
        flags=re.S,
    )
    if not m:
        raise SystemExit("找不到 #status 结构，Godot 模板可能变了")
    s = s[: m.start()] + BODY_STATUS + s[m.end():]

    # 5) 桥接脚本（放在引擎脚本之前，确保 bar 已存在）
    if "<!-- ppl-bridge -->" not in s:
        s = s.replace('<script src="index.js"></script>',
                      BRIDGE_JS + '\t\t<!-- ppl-bridge -->\n\t\t<script src="index.js"></script>', 1)

    io.open(page, "w", encoding="utf-8", newline="\n").write(s)

    # 6) 404 兜底（Pages 子路径直接访问时回到首页）
    fallback = io.open(page, encoding="utf-8").read()
    io.open(os.path.join(root, "404.html"), "w", encoding="utf-8", newline="\n").write(fallback)

    # 6.5) 把 index.html 从 SW 预缓存里摘掉，否则玩家永远拿到旧壳子
    sw_path = os.path.join(root, "index.service.worker.js")
    if os.path.exists(sw_path):
        sw = io.open(sw_path, encoding="utf-8").read()
        if '"index.html",' in sw:
            sw = sw.replace('"index.html",', "", 1)
            io.open(sw_path, "w", encoding="utf-8", newline="\n").write(sw)
            print("[patch] service worker 不再缓存 index.html")

    # 7) .nojekyll：阻止 Pages 用 Jekyll 处理，否则带下划线/特殊字符的文件会被吞
    io.open(os.path.join(root, ".nojekyll"), "w", encoding="utf-8").write("")

    print("[patch] index.html 已注入 iOS/PWA 适配")
    print("[patch] 404.html / .nojekyll 已生成")


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "build/web"
    if not os.path.isdir(target):
        raise SystemExit(f"目录不存在：{target}")
    patch(target)
