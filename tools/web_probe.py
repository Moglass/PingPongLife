#!/usr/bin/env python3
"""用 CDP 加载首页，抓 console / 异常 / 截图。"""
import json, sys, time, base64, subprocess, urllib.request
import websocket

EDGE = r"C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8080/index.html"
OUT = sys.argv[2] if len(sys.argv) > 2 else "D:/workbuddys/table tennis/PingPongLife/shots/web_probe.png"
WAIT = float(sys.argv[3]) if len(sys.argv) > 3 else 12.0

proc = subprocess.Popen([
    EDGE, "--headless=new", "--remote-debugging-port=9222",
    "--use-angle=swiftshader", "--enable-unsafe-swiftshader",
    "--window-size=1280,800", "--no-first-run", "--no-default-browser-check",
    "about:blank",
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

time.sleep(2.5)
pages = json.load(urllib.request.urlopen("http://127.0.0.1:9222/json"))
page = [p for p in pages if p.get("type") == "page"][0]
ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=30)

mid = 0
def send(method, params=None):
    global mid
    mid += 1
    ws.send(json.dumps({"id": mid, "method": method, "params": params or {}}))
    return mid

send("Runtime.enable")
send("Log.enable")
send("Page.enable")
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

for lvl, txt in logs[-40:]:
    print(f"[{lvl}] {txt[:300]}")

r = send("Page.captureScreenshot", {"format": "png"})
shot = None
t0 = time.time()
while time.time() - t0 < 8:
    try:
        ws.settimeout(1.0)
        msg = json.loads(ws.recv())
    except Exception:
        continue
    if msg.get("id") == r:
        shot = msg["result"]["data"]
        break
if shot:
    open(OUT, "wb").write(base64.b64decode(shot))
    print("SHOT", OUT)
ws.close()
proc.terminate()
