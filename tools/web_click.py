import json, sys, time, base64, subprocess, urllib.request
import websocket
EDGE = r"C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
OUT = "D:/workbuddys/table tennis/PingPongLife/shots/web_click.png"
import tempfile, uuid
PROFILE = tempfile.gettempdir() + "/edge_probe_" + uuid.uuid4().hex[:8]
proc = subprocess.Popen([EDGE,"--headless=new","--remote-debugging-port=9225","--use-angle=swiftshader",
    "--enable-unsafe-swiftshader","--window-size=1280,800","--no-first-run",
    "--user-data-dir=" + PROFILE, "--disable-application-cache",
    "about:blank"],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(2.5)
pages = json.load(urllib.request.urlopen("http://127.0.0.1:9225/json"))
page = [p for p in pages if p.get("type")=="page"][0]
ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=40)
mid=0
def send(m,p=None,wait=False):
    global mid; mid+=1
    ws.send(json.dumps({"id":mid,"method":m,"params":p or {}}))
    if not wait: return
    t0=time.time()
    while time.time()-t0<12:
        try:
            ws.settimeout(1.0); msg=json.loads(ws.recv())
        except Exception: continue
        if msg.get("id")==mid: return msg.get("result",{})
    return {}

send("Page.enable"); send("Runtime.enable")
send("Page.navigate",{"url":"http://127.0.0.1:8080/index.html"})
time.sleep(24)

q = """(() => {
  const c = document.getElementById('canvas');
  const st = document.getElementById('status');
  c.focus();
  const el = document.elementFromPoint(183, 325);
  return JSON.stringify({status_display: st ? getComputedStyle(st).display : 'none',
    hit: el ? (el.id || el.tagName) : 'null',
    active: document.activeElement ? document.activeElement.id : 'none'});
})()"""
print("DOM:", send("Runtime.evaluate",{"expression":q,"returnByValue":True},wait=True).get("result",{}).get("value"))

script = """(() => {
  const c = document.getElementById('canvas');
  const x = 183, y = 325;
  const base = {bubbles:true, cancelable:true, clientX:x, clientY:y, screenX:x, screenY:y,
                button:0, buttons:1, view:window};
  const pe = Object.assign({pointerId:1, pointerType:'mouse', isPrimary:true, width:1, height:1, pressure:0.5}, base);
  c.dispatchEvent(new PointerEvent('pointerdown', pe));
  c.dispatchEvent(new MouseEvent('mousedown', base));
  c.dispatchEvent(new PointerEvent('pointerup', Object.assign({}, pe, {buttons:0})));
  c.dispatchEvent(new MouseEvent('mouseup', Object.assign({}, base, {buttons:0})));
  return 'dispatched';
})()"""
print("JS:", send("Runtime.evaluate",{"expression":script,"returnByValue":True},wait=True).get("result",{}).get("value"))
time.sleep(1.2)
# 点弹窗里的「开始」
send("Input.dispatchMouseEvent", {"type":"mouseMoved","x":670,"y":423,"button":"none"})
time.sleep(0.2)
send("Input.dispatchMouseEvent", {"type":"mousePressed","x":670,"y":423,"button":"left","clickCount":1})
time.sleep(0.1)
send("Input.dispatchMouseEvent", {"type":"mouseReleased","x":670,"y":423,"button":"left","clickCount":1})
print("clicked confirm")
time.sleep(3.0)
# 把鼠标移开，让按钮回到 normal 状态
send("Input.dispatchMouseEvent", {"type":"mouseMoved","x":40,"y":40,"button":"none"})
time.sleep(0.8)

r = send("Page.captureScreenshot",{"format":"png"},wait=True)
if r.get("data"):
    open(OUT,"wb").write(base64.b64decode(r["data"]))
    print("SHOT", OUT)
ws.close(); proc.terminate()
