import json, time, subprocess, urllib.request
import websocket
EDGE = r"C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
proc = subprocess.Popen([EDGE,"--headless=new","--remote-debugging-port=9224","--use-angle=swiftshader",
    "--enable-unsafe-swiftshader","--window-size=1280,800","--no-first-run","about:blank"],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(2.5)
pages = json.load(urllib.request.urlopen("http://127.0.0.1:9224/json"))
page = [p for p in pages if p.get("type")=="page"][0]
ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=40)
mid=0
def send(m,p=None,wait=False):
    global mid; mid+=1
    ws.send(json.dumps({"id":mid,"method":m,"params":p or {}}))
    if not wait: return
    t0=time.time()
    while time.time()-t0<10:
        try:
            ws.settimeout(1.0); msg=json.loads(ws.recv())
        except Exception: continue
        if msg.get("id")==mid: return msg.get("result",{})
    return {}
send("Page.enable")
send("Page.navigate",{"url":"http://127.0.0.1:8080/index.html"})
time.sleep(20)
expr = """(() => {
  const c = document.querySelector('canvas');
  if (!c) return 'no canvas';
  const r = c.getBoundingClientRect();
  return JSON.stringify({rect:[r.x,r.y,r.width,r.height], dpr:window.devicePixelRatio,
    inner:[window.innerWidth,window.innerHeight],
    cw:c.width, ch:c.height, style:c.getAttribute('style')});
})()"""
res = send("Runtime.evaluate",{"expression":expr,"returnByValue":True},wait=True)
print(res.get("result",{}).get("value"))
ws.close(); proc.terminate()
