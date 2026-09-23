{ config, pkgs, lib, ... }:

let

  remoteAccessState = "/var/lib/remote-access/state.json";
  remoteAccessRoutesDir = "/var/lib/remote-access/routes";

  controllerScript = pkgs.writeText "remote-access-controller.py" ''
#!/usr/bin/env python3

import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, HTTPServer


STATE_FILE = "${remoteAccessState}"
ROUTES_DIR = "${remoteAccessRoutesDir}"

LISTEN = "127.0.0.1"
PORT = 8787

DEFAULT_STATE = {
    "lens": False,
    "octoprint": False,
    "trilium": False,
    "broadcast": False,
}


def run(cmd):
    return subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def load_state():
    try:
        with open(STATE_FILE, "r") as f:
            state = json.load(f)

        return {
            "lens": bool(state.get("lens", False)),
            "octoprint": bool(state.get("octoprint", False)),
            "trilium": bool(state.get("trilium", False)),
            "broadcast": bool(state.get("broadcast", False)),
        }

    except Exception:
        return DEFAULT_STATE.copy()


def save_state(state):
    tmp = STATE_FILE + ".tmp"

    with open(tmp, "w") as f:
        json.dump(state, f, indent=2)
        f.write("\n")

    os.replace(tmp, STATE_FILE)


def service_command(name, action):
    """
    Start or stop an application.

    Verify the OctoPrint and Trilium unit names against the
    NixOS configuration before using those toggles.
    """

    if name == "lens":
        if action == "start":
            return run([
                "${pkgs.docker-compose}/bin/docker-compose",
                "-f", "/home/Docker_Files/Lens/docker-compose.yml",
                "up", "-d",
            ])

        return run([
            "${pkgs.docker-compose}/bin/docker-compose",
            "-f", "/home/Docker_Files/Lens/docker-compose.yml",
            "down",
        ])

    if name == "octoprint":
        return run([
            "${pkgs.systemd}/bin/systemctl",
            action,
            "octoprint.service",
        ])

    if name == "trilium":
        return run([
            "${pkgs.systemd}/bin/systemctl",
            action,
            "trilium.service",
        ])

    return subprocess.CompletedProcess(
        [], 1, "", "Unknown service"
    )


def apply_services(old_state, new_state):
    """
    Make actual application state match requested state.
    """

    for name in ["lens", "octoprint", "trilium"]:
        if old_state.get(name, False) == new_state.get(name, False):
            continue

        action = "start" if new_state[name] else "stop"
        result = service_command(name, action)

        if result.returncode != 0:
            error = result.stderr.strip() or result.stdout.strip()
            return False, f"{name} {action} failed: {error}"

    return True, ""


def generate_routes(state):
    """
    Generate one Nginx server block per active service.
    """

    os.makedirs(ROUTES_DIR, exist_ok=True)

    routes = {
        "lens": r"""
server {
    listen 80;
    server_name lens.nixserver.tailnet;

    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/htpasswd;

    location / {
        proxy_pass http://127.0.0.1:3000;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_read_timeout 3600;
    }
}
""",

        "octoprint": r"""
server {
    listen 80;
    server_name octoprint.nixserver.tailnet;

    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/htpasswd;

    location / {
        proxy_pass http://127.0.0.1:5000;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_read_timeout 3600;
    }
}
""",

        "trilium": r"""
server {
    listen 80;
    server_name trilium.nixserver.tailnet;

    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/htpasswd;

    location / {
        proxy_pass http://127.0.0.1:8080;

        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_read_timeout 3600;
    }
}
""",
    }

    filenames = {
        "lens": "lens.conf",
        "octoprint": "octoprint.conf",
        "trilium": "trilium.conf",
    }

    for name, filename in filenames.items():
        path = os.path.join(ROUTES_DIR, filename)

        if state[name]:
            tmp = path + ".tmp"
            with open(tmp, "w") as f:
                f.write(routes[name].strip() + "\n")
            os.replace(tmp, path)
        else:
            try:
                os.remove(path)
            except FileNotFoundError:
                pass

def reload_nginx():
    result = run(
        [
            "${pkgs.nginx}/bin/nginx",
            "-t",
        ]
    )

    if result.returncode != 0:
        return False, result.stderr

    result = run(
        [
            "${pkgs.systemd}/bin/systemctl",
            "reload",
            "nginx.service",
        ]
    )

    if result.returncode != 0:
        return False, result.stderr

    return True, ""


def funnel_on():
    result = run(
        [
            "${pkgs.tailscale}/bin/tailscale",
            "funnel",
            "--bg",
            "--yes",
            "8088",
        ]
    )

    return result.returncode == 0, result.stderr


def funnel_off():
    result = run(
        [
            "${pkgs.tailscale}/bin/tailscale",
            "funnel",
            "reset",
        ]
    )

    return result.returncode == 0, result.stderr


def apply_state(state):
    old_state = load_state()

    # Start/stop the actual applications first.
    ok, error = apply_services(old_state, state)

    if not ok:
        return False, error

    # Only save the requested state after service changes succeeded.
    save_state(state)

    # Expose only active services through Nginx.
    generate_routes(state)

    ok, error = reload_nginx()

    if not ok:
        return False, "Nginx reload failed: " + error

    # Broadcast is independent of service activation.
    services_active = any(
        state[name]
        for name in ["lens", "octoprint", "trilium"]
    )

    if state["broadcast"] and services_active:
        ok, error = funnel_on()

        if not ok:
            return False, "Funnel enable failed: " + error
    else:
        ok, error = funnel_off()

        if not ok:
            return False, "Funnel disable failed: " + error

    return True, ""

HTML = r"""
<!doctype html>
<html>
<head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>NixServer Remote Access</title>

    <style>
        body {
            font-family: system-ui, sans-serif;
            max-width: 600px;
            margin: auto;
            padding: 20px;
            background: #111;
            color: #eee;
        }

        h1 {
            font-size: 1.5rem;
        }

        .service {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 18px;
            margin: 12px 0;
            border: 1px solid #444;
            border-radius: 10px;
            background: #1b1b1b;
        }

        .name {
            font-size: 1.2rem;
        }

        button {
            font-size: 1rem;
            padding: 10px 18px;
            border-radius: 8px;
            border: 0;
            cursor: pointer;
        }

        .on {
            background: #347a46;
            color: white;
        }

        .off {
            background: #555;
            color: white;
        }

        #status {
            margin: 20px 0;
            padding: 12px;
            border-radius: 8px;
            background: #222;
        }

        #url {
            margin-top: 15px;
            padding: 12px;
            background: #222;
            word-break: break-all;
        }
    </style>
</head>

<body>

    <h1>NixServer Remote Access</h1>

    <div id="status">Loading...</div>

    <div class="service">
        <div class="name">Lens</div>
        <button id="lens" onclick="toggle('lens')"></button>
    </div>

    <div class="service">
        <div class="name">OctoPrint</div>
        <button id="octoprint" onclick="toggle('octoprint')"></button>
    </div>

    <div class="service">
        <div class="name">Trilium</div>
        <button id="trilium" onclick="toggle('trilium')"></button>
    </div>

    <div class="service">
        <div class="name">Internet Access</div>
        <button id="broadcast" onclick="toggle('broadcast')"></button>
    </div>

    <div id="url"></div>

    <script>
    let state = {};

    async function load() {
        const response = await fetch("/api/state");
        state = await response.json();
        update();
    }

    function update() {
        for (const name of ["lens", "octoprint", "trilium", "broadcast"]) {
            const button = document.getElementById(name);

            if (state[name]) {
                button.textContent = "ON";
                button.className = "on";
            } else {
                button.textContent = "OFF";
                button.className = "off";
            }
        }

        const active =
            state.lens ||
            state.octoprint ||
            state.trilium;

        const status = document.getElementById("status");

        if (state.broadcast && active) {
            status.textContent = "Internet access ACTIVE";
        } else if (active) {
            status.textContent = "Services active — LAN/Tailscale only";
        } else {
            status.textContent = "All services OFF";
        }

        const url = document.getElementById("url");

        if (active) {
            url.textContent =
                "https://nixserver-1.tail90d1f7.ts.net";
        } else {
            url.textContent = "";
        }
    }

    async function toggle(name) {
        const newState = Object.assign({}, state);
        newState[name] = !newState[name];

        document.getElementById("status").textContent =
            "Applying...";

        const response = await fetch("/api/state", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(newState)
        });

        const result = await response.json();

        if (!result.ok) {
            alert(result.error || "Failed to apply state");
        }

        await load();
    }

    load();
    </script>

</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):

    def send_json(self, data, status=200):
        body = json.dumps(data).encode()

        self.send_response(status)
        self.send_header(
            "Content-Type",
            "application/json",
        )
        self.send_header(
            "Content-Length",
            str(len(body)),
        )
        self.end_headers()

        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/":
            body = HTML.encode()

            self.send_response(200)
            self.send_header(
                "Content-Type",
                "text/html; charset=utf-8",
            )
            self.send_header(
                "Content-Length",
                str(len(body)),
            )
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
            length = int(
                self.headers.get("Content-Length", "0")
            )

            body = self.rfile.read(length)
            requested = json.loads(body)

            state = {
                "lens": bool(requested.get("lens", False)),
                "octoprint": bool(
                    requested.get("octoprint", False)
                ),
                "trilium": bool(
                    requested.get("trilium", False)
                ),
                "broadcast": bool(
                    requested.get("broadcast", False)
                ),
            }

            ok, error = apply_state(state)

            if ok:
                self.send_json(
                    {
                        "ok": True,
                        "state": state,
                    }
                )
            else:
                self.send_json(
                    {
                        "ok": False,
                        "error": error,
                    },
                    500,
                )

        except Exception as e:
            self.send_json(
                {
                    "ok": False,
                    "error": str(e),
                },
                500,
            )

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    state = load_state()

    # Reconcile actual application state with saved controller state.
    ok, error = apply_services(DEFAULT_STATE, state)

    if not ok:
        print("Service startup reconciliation failed:", error)

    save_state(state)
    generate_routes(state)

    # Make sure Nginx reflects the stored state after boot.
    ok, error = reload_nginx()

    if not ok:
        print("Nginx reload failed:", error)

    services_active = any(
        state[name]
        for name in ["lens", "octoprint", "trilium"]
    )

    if state["broadcast"] and services_active:
        funnel_on()
    else:
        funnel_off()

    server = HTTPServer(
        (LISTEN, PORT),
        Handler,
    )

    server.serve_forever()

  '';
in
{

  # ---------------------------------------------------------------
  # Remote access state
  # ---------------------------------------------------------------

  systemd.tmpfiles.rules = [
    "d /var/lib/remote-access 0755 root root -"
    "d /var/lib/remote-access/routes 0755 root root -"
    "f /var/lib/remote-access/state.json 0600 root root -"
  ];


  # ---------------------------------------------------------------
  # Remote access controller
  # ---------------------------------------------------------------

  systemd.services.remote-access-controller = {

    description = "NixServer Remote Access Controller";

    wantedBy = [ "multi-user.target" ];

    after = [
      "network-online.target"
      "tailscaled.service"
      "nginx.service"
    ];

    requires = [
      "tailscaled.service"
      "nginx.service"
    ];

    serviceConfig = {

      Type = "simple";

      ExecStart =
        "${pkgs.python3}/bin/python3 ${controllerScript}";

      Restart = "on-failure";

      RestartSec = "5s";

      User = "root";

    };
  };

}
