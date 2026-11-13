#!/usr/bin/env python3
"""
用 iPhone 视口 + 触摸模拟打开线上站点，抓控制台与截图。

用法：python tools/web_ios_probe.py <url> <out.png> [等待秒数]
"""
import base64
import json
import subprocess
import sys
import tempfile
import time
import urllib.request
import uuid

import websocket

EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
URL = sys.argv[1] if len(sys.argv) > 1 else "https://moglass.github.io/PingPongLife/"
OUT = sys.argv[2] if len(sys.argv) > 2 else "shots/ios_probe.png"
WAIT = float(sys.argv[3]) if len(sys.argv) > 3 else 40.0

PROFILE = tempfile.gettempdir() + "/edge_ios_" + uuid.uuid4().hex[:8]
proc = subprocess.Popen([
    EDGE, "--headless=new", "--remote-debugging-port=9231",
    "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
    "--window-size=390,844", "--no-first-run", "--no-default-browser-check",
    "--user-data-dir=" + PROFILE, "--disable-application-cache",
    "about:blank",
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

time.sleep(2.5)
pages = json.load(urllib.request.urlopen("http://127.0.0.1:9231/json"))
page = [p for p in pages if p.get("type") == "page"][0]
ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=60)

msg_id = 0


def send(method, params=None, wait=False, timeout=15):
    global msg_id
    msg_id += 1
    ws.send(json.dumps({"id": msg_id, "method": method, "params": params or {}}))
    if not wait:
        return None
    t0 = time.time()
    while time.time() - t0 < timeout:
        try:
            ws.settimeout(1.0)
            msg = json.loads(ws.recv())
        except Exception:
            continue
        if msg.get("id") == msg_id:
            return msg.get("result", {})
    return {}


send("Runtime.enable")
send("Log.enable")
send("Page.enable")

# iPhone 14 Pro 视口
send("Emulation.setDeviceMetricsOverride", {
    "width": 393, "height": 852, "deviceScaleFactor": 3, "mobile": True,
    "screenOrientation": {"type": "portraitPrimary", "angle": 0},
})
send("Emulation.setTouchEmulationEnabled", {"enabled": True, "maxTouchPoints": 5})
send("Emulation.setUserAgentOverride", {
    "userAgent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) "
                 "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
})

send("Page.navigate", {"url": URL})

logs = []
start = time.time()
while time.time() - start < WAIT:
    try:
        ws.settimeout(0.5)
        msg = json.loads(ws.recv())
    except Exception:
        continue
    m = msg.get("method")
    if m == "Runtime.consoleAPICalled":
        args = " ".join(str(a.get("value", a.get("description", ""))) for a in msg["params"]["args"])
        logs.append(("console." + msg["params"]["type"], args))
    elif m == "Runtime.exceptionThrown":
        d = msg["params"]["exceptionDetails"]
        logs.append(("exception", d.get("text", "") + " " + str(d.get("exception", {}).get("description", ""))))
    elif m == "Log.entryAdded":
        e = msg["params"]["entry"]
        logs.append((e.get("level", ""), e.get("text", "")))

for lvl, txt in logs[-30:]:
    print(f"[{lvl}] {txt[:260]}")

# 页面状态
q = """(() => {
  const c = document.getElementById('canvas');
  const boot = document.getElementById('boot');
  const status = document.getElementById('status');
  return JSON.stringify({
    canvas: c ? [c.width, c.height, c.getBoundingClientRect().width|0, c.getBoundingClientRect().height|0] : null,
    boot_visible: boot ? getComputedStyle(boot).display !== 'none' : false,
    status_visibility: status ? getComputedStyle(status).visibility : 'gone',
    dpr: window.devicePixelRatio,
    vv: window.visualViewport ? [window.visualViewport.width|0, window.visualViewport.height|0] : null,
  });
})()"""
state = send("Runtime.evaluate", {"expression": q, "returnByValue": True}, wait=True)
print("STATE:", state.get("result", {}).get("value"))

shot = send("Page.captureScreenshot", {"format": "png", "captureBeyondViewport": False}, wait=True)
if shot.get("data"):
    open(OUT, "wb").write(base64.b64decode(shot["data"]))
    print("SHOT", OUT)

ws.close()
proc.terminate()
