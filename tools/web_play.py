#!/usr/bin/env python3
"""加载 Web 版，点击「开始新的生涯」，截图验证交互。"""
import json, sys, time, base64, subprocess, urllib.request
import websocket

EDGE = r"C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
OUT = sys.argv[1] if len(sys.argv) > 1 else "D:/workbuddys/table tennis/PingPongLife/shots/web_play.png"

proc = subprocess.Popen([
    EDGE, "--headless=new", "--remote-debugging-port=9223",
    "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
    "--window-size=1280,800", "--no-first-run",
    "about:blank",
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(2.5)
pages = json.load(urllib.request.urlopen("http://127.0.0.1:9223/json"))
page = [p for p in pages if p.get("type") == "page"][0]
ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=40)

mid = 0
def send(method, params=None, wait=False):
    global mid
    mid += 1
    ws.send(json.dumps({"id": mid, "method": method, "params": params or {}}))
    if not wait:
        return mid
    t0 = time.time()
    while time.time() - t0 < 10:
        try:
            ws.settimeout(1.0)
            msg = json.loads(ws.recv())
        except Exception:
            continue
        if msg.get("id") == mid:
            return msg.get("result", {})
    return {}

send("Runtime.enable")
send("Page.enable")
send("Page.navigate", {"url": "http://127.0.0.1:8080/index.html"})
print("waiting for boot...")
time.sleep(22)

def click(x, y):
    send("Input.dispatchMouseEvent", {"type": "mousePressed", "x": x, "y": y, "button": "left", "clickCount": 1})
    time.sleep(0.08)
    send("Input.dispatchMouseEvent", {"type": "mouseReleased", "x": x, "y": y, "button": "left", "clickCount": 1})

click(125, 254)
print("clicked start")
time.sleep(2.5)

# 新游戏弹窗：点「开始」（稍后按截图微调）
click(455, 410)
print("clicked confirm")
time.sleep(2.5)

r = send("Page.captureScreenshot", {"format": "png"}, wait=True)
data = r.get("data")
if data:
    open(OUT, "wb").write(base64.b64decode(data))
    print("SHOT", OUT)
ws.close()
proc.terminate()
