#!/usr/bin/env python3
"""
iPhone 视口下模拟点击，验证线上 Web 版可玩性。

用法：python tools/web_ios_play.py <url> <out_prefix> [步骤...]
步骤示例：start  (点开始新的生涯)  confirm  (点弹窗的开始)
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
PREFIX = sys.argv[2] if len(sys.argv) > 2 else "shots/ios_play"
STEPS = sys.argv[3:] if len(sys.argv) > 3 else []

PROFILE = tempfile.gettempdir() + "/edge_iosplay_" + uuid.uuid4().hex[:8]
proc = subprocess.Popen([
    EDGE, "--headless=new", "--remote-debugging-port=9232",
    "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
    "--window-size=393,852", "--no-first-run", "--no-default-browser-check",
    "--user-data-dir=" + PROFILE, "--disable-application-cache",
    "about:blank",
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

time.sleep(2.5)
pages = json.load(urllib.request.urlopen("http://127.0.0.1:9232/json"))
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


def tap(x, y):
    """在 canvas 上派发指针事件。headless 下 CDP 的鼠标事件不总是进 canvas，
    直接构造 PointerEvent 最可靠（Godot Web 用 pointerdown/pointerup）。"""
    js = """(() => {
      const c = document.getElementById('canvas');
      if (!c) return 'no canvas';
      c.focus();
      const x = %d, y = %d;
      const r = c.getBoundingClientRect();
      const base = {bubbles: true, cancelable: true, composed: true,
                    clientX: x, clientY: y, screenX: x, screenY: y,
                    button: 0, buttons: 1, view: window};
      const pe = Object.assign({pointerId: 1, pointerType: 'touch', isPrimary: true,
                                width: 12, height: 12, pressure: 0.5}, base);
      c.dispatchEvent(new PointerEvent('pointerdown', pe));
      c.dispatchEvent(new MouseEvent('mousedown', base));
      c.dispatchEvent(new PointerEvent('pointerup', Object.assign({}, pe, {buttons: 0, pressure: 0})));
      c.dispatchEvent(new MouseEvent('mouseup', Object.assign({}, base, {buttons: 0})));
      c.dispatchEvent(new MouseEvent('click', Object.assign({}, base, {buttons: 0})));
      return JSON.stringify([r.width, r.height]);
    })()""" % (x, y)
    r = send("Runtime.evaluate", {"expression": js, "returnByValue": True}, wait=True)
    print(f"  tap ({x},{y}) -> {r.get('result',{}).get('value')}")


def shot(name):
    r = send("Page.captureScreenshot", {"format": "png"}, wait=True)
    if r.get("data"):
        path = f"{PREFIX}_{name}.png"
        open(path, "wb").write(base64.b64decode(r["data"]))
        print(f"  SHOT {path}")


send("Runtime.enable")
send("Page.enable")
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
print("booting...")
time.sleep(38)
shot("boot")

COORDS = {
    "start": (196, 272),
    "confirm": (225, 640),
    "next": (300, 800),
}

for step in STEPS:
    if step in COORDS:
        tap(*COORDS[step])
        time.sleep(2.6)
        shot(step)
    else:
        print("unknown step", step)

ws.close()
proc.terminate()
