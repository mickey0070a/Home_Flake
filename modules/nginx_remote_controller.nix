{ config, pkgs, lib, ... }:

let
  stateFile = "/var/lib/remote-access/state.json";

  controllerScript = pkgs.writeText "remote-access-controller.py" ''
#!/usr/bin/env python3
import json
import os
import subprocess
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

STATE_FILE = "${stateFile}"
LISTEN = "127.0.0.1"
PORT = 8787
LENS_DIR = "/home/Docker_Files/Lens"

DEFAULT_STATE = {
    "lens": False,
    "octoprint": False,
    "trilium": False,
    "broadcast": False,
}

SERVICES = {
    "lens": ("Lens", "http://127.0.0.1:3000/"),
    "octoprint": ("OctoPrint", "http://127.0.0.1:5000/"),
    "trilium": ("Trilium", "http://127.0.0.1:8080/"),
}


def run(cmd, cwd=None):
    return subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True)


def load_state():
    try:
        with open(STATE_FILE) as f:
            state = json.load(f)
        return {name: bool(state.get(name, False))
                for name in DEFAULT_STATE}
    except Exception:
        return DEFAULT_STATE.copy()


def save_state(state):
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f, indent=2)
        f.write("\n")
    os.replace(tmp, STATE_FILE)


def service_command(name, action):
    if name == "lens":
        return run([
            "${pkgs.docker-compose}/bin/docker-compose",
            action if action == "down" else "up",
            "-d" if action == "start" else "" if action == "down" else "-d",
        ], cwd=LENS_DIR) if action == "start" else run([
            "${pkgs.docker-compose}/bin/docker-compose", "down"
        ], cwd=LENS_DIR)

    if name == "octoprint":
        return run([
            "${pkgs.systemd}/bin/systemctl", action, "octoprint.service"
        ])

    if name == "trilium":
        docker_action = "start" if action == "start" else "stop"
        return run([
            "${pkgs.docker}/bin/docker", docker_action, "triliumnext-server"
        ])

    return subprocess.CompletedProcess([], 1, "", "Unknown service")


def service_start(name):
    result = service_command(name, "start")
    return result.returncode == 0, result.stderr.strip()


def service_stop(name):
    result = service_command(name, "stop")
    if result.returncode != 0 and name == "trilium" and "is not running" in result.stderr:
        return True, ""
    return result.returncode == 0, result.stderr.strip()


def service_ready(name):
    _, url = SERVICES[name]
    for _ in range(60):
        result = run([
            "${pkgs.curl}/bin/curl", "-fsS", "--max-time", "2", url
        ])
        if result.returncode == 0:
            return True
        time.sleep(1)
    return False


def funnel_on():
    result = run([
        "${pkgs.tailscale}/bin/tailscale", "funnel", "--bg", "--yes", "8088"
    ])
    return result.returncode == 0, result.stderr.strip()


def funnel_off():
    result = run([
        "${pkgs.tailscale}/bin/tailscale", "funnel", "reset"
    ])
    return result.returncode == 0, result.stderr.strip()


def apply_state(requested):
    old = load_state()

    for name in SERVICES:
        if requested[name] == old[name]:
            continue

        if requested[name]:
            ok, error = service_start(name)
            if not ok:
                return False, f"Could not start {SERVICES[name][0]}: {error or 'unknown error'}"
            if not service_ready(name):
                service_stop(name)
                return False, f"{SERVICES[name][0]} started but did not become ready."
        else:
            ok, error = service_stop(name)
            if not ok:
                return False, f"Could not stop {SERVICES[name][0]}: {error or 'unknown error'}"

    active = any(requested[name] for name in SERVICES)

    if requested["broadcast"] and active:
        ok, error = funnel_on()
        if not ok:
            return False, "Funnel enable failed: " + (error or "unknown error")
    else:
        ok, error = funnel_off()
        if not ok:
            return False, "Funnel disable failed: " + (error or "unknown error")
        requested["broadcast"] = False

    save_state(requested)
    return True, ""


HTML = r'''<!doctype html>
<html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>NixServer Remote Access</title>
<style>
body{font-family:system-ui,sans-serif;max-width:650px;margin:auto;padding:20px;background:#111;color:#eee}
h1{font-size:1.5rem;margin-bottom:6px}.subtitle{color:#aaa;margin-bottom:20px}
.service{padding:16px 18px;margin:12px 0;border:1px solid #444;border-radius:10px;background:#1b1b1b}
.row{display:flex;justify-content:space-between;align-items:center;gap:15px}.name{font-size:1.15rem}
.access{color:#aaa;font-size:.9rem;margin-top:5px;word-break:break-all}
button{min-width:72px;font-size:1rem;padding:10px 16px;border-radius:8px;border:0;cursor:pointer}
button:disabled{opacity:.5;cursor:wait}.on{background:#347a46;color:white}.off{background:#555;color:white}
.broadcast{border-color:#765b25}#status{margin:20px 0;padding:12px;border-radius:8px;background:#222;white-space:pre-wrap}
#url{margin-top:15px;padding:12px;background:#222;word-break:break-all}
</style></head><body>
<h1>NixServer Remote Access</h1>
<div class="subtitle">Application power and network exposure control</div>
<div id="status">Loading...</div>
<div class="service"><div class="row"><div><div class="name">Lens</div><div class="access">/ → :3000</div></div><button id="lens" onclick="toggle('lens')"></button></div></div>
<div class="service"><div class="row"><div><div class="name">OctoPrint</div><div class="access">/octoprint/ → :5000</div></div><button id="octoprint" onclick="toggle('octoprint')"></button></div></div>
<div class="service"><div class="row"><div><div class="name">Trilium</div><div class="access">/trilium/ → :8080</div></div><button id="trilium" onclick="toggle('trilium')"></button></div></div>
<div class="service broadcast"><div class="row"><div><div class="name">Internet Access</div><div class="access">Tailscale Funnel — all active services</div></div><button id="broadcast" onclick="toggle('broadcast')"></button></div></div>
<div id="url"></div>
<script>
let state={},busy=false;const names=['lens','octoprint','trilium','broadcast'];
async function load(){try{const r=await fetch('api/state',{cache:'no-store'});if(!r.ok)throw Error('HTTP '+r.status);state=await r.json();update()}catch(e){document.getElementById('status').textContent='Controller unavailable: '+e.message}}
function update(){for(const n of names){const b=document.getElementById(n);b.textContent=state[n]?'ON':'OFF';b.className=state[n]?'on':'off';b.disabled=busy}const active=state.lens||state.octoprint||state.trilium;document.getElementById('status').textContent=state.broadcast&&active?'Internet access ACTIVE':active?'Services active — LAN / Tailscale only':'All application services stopped';document.getElementById('url').textContent=state.broadcast&&active?'https://nixserver-1.tail90d1f7.ts.net':''}
async function toggle(name){if(busy)return;const next=Object.assign({},state);next[name]=!next[name];busy=true;update();document.getElementById('status').textContent='Applying '+name+'...';try{const r=await fetch('api/state',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(next)});const text=await r.text();let result;try{result=JSON.parse(text)}catch(_){throw Error('Controller returned HTTP '+r.status+' without valid JSON.')}if(!r.ok||!result.ok)throw Error(result.error||('HTTP '+r.status));state=result.state;update()}catch(e){alert(e.message);await load()}finally{busy=false;update()}}
load();
</script></body></html>'''


class Handler(BaseHTTPRequestHandler):
    def send_json(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path in ["/", "/index.html"]:
            body = HTML.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if self.path == "/api/state":
            self.send_json(load_state())
            return
        self.send_error(404)

    def do_POST(self):
        if self.path != "/api/state":
            self.send_error(404)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length <= 0 or length > 65536:
                raise ValueError("Invalid request size.")
            requested = json.loads(self.rfile.read(length))
            state = {name: bool(requested.get(name, False)) for name in DEFAULT_STATE}
            ok, error = apply_state(state)
            if ok:
                self.send_json({"ok": True, "state": state})
            else:
                self.send_json({"ok": False, "error": error, "state": load_state()}, 500)
        except Exception as e:
            self.send_json({"ok": False, "error": str(e), "state": load_state()}, 500)

    def log_message(self, format, *args):
        pass


def reconcile_startup():
    state = load_state()
    for name in SERVICES:
        if not state[name]:
            continue
        ok, _ = service_start(name)
        if not ok or not service_ready(name):
            service_stop(name)
            state[name] = False

    if state["broadcast"] and any(state[name] for name in SERVICES):
        ok, _ = funnel_on()
        if not ok:
            state["broadcast"] = False
    else:
        funnel_off()
        state["broadcast"] = False

    save_state(state)


if __name__ == "__main__":
    reconcile_startup()
    HTTPServer((LISTEN, PORT), Handler).serve_forever()
  '';

in
{
  # ---------------------------------------------------------------
  # Persistent controller state
  # ---------------------------------------------------------------

  systemd.tmpfiles.rules = [
    "d /var/lib/remote-access 0755 root root -"
    "f /var/lib/remote-access/state.json 0600 root root -"
  ];

  # ---------------------------------------------------------------
  # Nginx owns ALL network addresses and routes.
  # Python never writes or reloads Nginx configuration.
  # ---------------------------------------------------------------

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "_" = {
        serverName = "_";
        basicAuthFile = "/etc/nginx/htpasswd";

        locations = {
          "/remote-access/" = {
            proxyPass = "http://127.0.0.1:8787/";
            proxyWebsockets = true;
          };

          "/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_read_timeout 3600;
            '';
          };

          "/octoprint/" = {
            proxyPass = "http://127.0.0.1:5000/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_read_timeout 3600;
            '';
          };

          "/trilium/" = {
            proxyPass = "http://127.0.0.1:8080/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_read_timeout 3600;
            '';
          };
        };
      };

      # Tailscale Funnel targets this localhost-only listener.
      "remote-access-public" = {
        listen = [{ addr = "127.0.0.1"; port = 8088; }];
        serverName = "_";
        basicAuthFile = "/etc/nginx/htpasswd";

        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:3000";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_read_timeout 3600;
            '';
          };

          "/octoprint/" = {
            proxyPass = "http://127.0.0.1:5000/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_read_timeout 3600;
            '';
          };

          "/trilium/" = {
            proxyPass = "http://127.0.0.1:8080/";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_read_timeout 3600;
            '';
          };
        };
      };
    };
  };

  # ---------------------------------------------------------------
  # Controller service
  # ---------------------------------------------------------------

  systemd.services.remote-access-controller = {
    description = "NixServer Remote Access Controller";

    wantedBy = [ "multi-user.target" ];

    after = [
      "network-online.target"
      "tailscaled.service"
      "nginx.service"
      "docker.service"
    ];

    requires = [
      "tailscaled.service"
      "nginx.service"
      "docker.service"
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 ${controllerScript}";
      Restart = "on-failure";
      RestartSec = "5s";
      User = "root";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}