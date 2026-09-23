{ config, pkgs, lib, ... }:

let

  remoteAccessState = "/var/lib/remote-access/state.json";
  remoteAccessRoutes = "/var/lib/remote-access/routes.conf";

  controllerScript = pkgs.writeText "remote-access-controller.py" ''
#!/usr/bin/env python3

import json
import os
import subprocess
import time
from http.server import BaseHTTPRequestHandler, HTTPServer


STATE_FILE = "${remoteAccessState}"
ROUTES_FILE = "${remoteAccessRoutes}"

LISTEN = "127.0.0.1"
PORT = 8787

LENS_DIR = "/home/Docker_Files/Lens"
LENS_URL = "http://127.0.0.1:3000/"
OCTOPRINT_URL = "http://127.0.0.1:5000/"
TRILIUM_URL = "http://127.0.0.1:8080/"

DEFAULT_STATE = {
    "lens": False,
    "octoprint": False,
    "trilium": False,
    "broadcast": False,
}

SERVICES = {
    "lens": {
        "name": "Lens",
        "port": 3000,
        "access": ":3000",
        "route": "/",
    },
    "octoprint": {
        "name": "OctoPrint",
        "port": 5000,
        "access": "/octoprint/",
        "route": "/octoprint/",
    },
    "trilium": {
        "name": "Trilium",
        "port": 8080,
        "access": "/trilium/",
        "route": "/trilium/",
    },
}


def run(cmd, cwd=None):
    return subprocess.run(
        cmd,
        cwd=cwd,
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


def docker_start(name):
    result = run([
        "${pkgs.docker}/bin/docker",
        "start",
        name,
    ])

    return result.returncode == 0, result.stderr.strip()


def docker_stop(name):
    result = run([
        "${pkgs.docker}/bin/docker",
        "stop",
        name,
    ])

    # docker stop returns non-zero if the container was already stopped.
    # That is harmless for our desired-state controller.
    if result.returncode != 0 and "is not running" not in result.stderr:
        return False, result.stderr.strip()

    return True, ""


def lens_start():
    result = run(
        [
            "${pkgs.docker-compose}/bin/docker-compose",
            "up",
            "-d",
        ],
        cwd=LENS_DIR,
    )

    return result.returncode == 0, result.stderr.strip()


def lens_stop():
    result = run(
        [
            "${pkgs.docker-compose}/bin/docker-compose",
            "down",
        ],
        cwd=LENS_DIR,
    )

    return result.returncode == 0, result.stderr.strip()


def octoprint_start():
    result = run([
        "${pkgs.systemd}/bin/systemctl",
        "start",
        "octoprint.service",
    ])

    return result.returncode == 0, result.stderr.strip()


def octoprint_stop():
    result = run([
        "${pkgs.systemd}/bin/systemctl",
        "stop",
        "octoprint.service",
    ])

    return result.returncode == 0, result.stderr.strip()


def service_start(name):
    if name == "lens":
        return lens_start()

    if name == "octoprint":
        return octoprint_start()

    if name == "trilium":
        return docker_start("triliumnext-server")

    return False, "Unknown service: " + name


def service_stop(name):
    if name == "lens":
        return lens_stop()

    if name == "octoprint":
        return octoprint_stop()

    if name == "trilium":
        return docker_stop("triliumnext-server")

    return False, "Unknown service: " + name


def wait_for_url(url, attempts=60):
    for _ in range(attempts):
        result = run([
            "${pkgs.curl}/bin/curl",
            "-fsS",
            "--max-time",
            "2",
            url,
        ])

        if result.returncode == 0:
            return True

        time.sleep(1)

    return False


def service_ready(name):
    if name == "lens":
        return wait_for_url(LENS_URL)

    if name == "octoprint":
        return wait_for_url(OCTOPRINT_URL)

    if name == "trilium":
        return wait_for_url(TRILIUM_URL)

    return False


def generate_routes(state):
    routes = []

    # Lens owns the root URL.  Do not put it behind /lens/ because
    # Lens generates root-relative/websocket URLs.
    if state["lens"]:
        routes.append(
            r"""
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
"""
        )
    else:
        routes.append(
            r"""
location / {
    return 404;
}
"""
        )

    if state["octoprint"]:
        routes.append(
            r"""
location /octoprint/ {
    proxy_pass http://127.0.0.1:5000/;

    proxy_http_version 1.1;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_read_timeout 3600;
}
"""
        )

    if state["trilium"]:
        routes.append(
            r"""
location /trilium/ {
    proxy_pass http://127.0.0.1:8080/;

    proxy_http_version 1.1;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_read_timeout 3600;
}
"""
        )

    tmp = ROUTES_FILE + ".tmp"

    with open(tmp, "w") as f:
        f.write("\n".join(routes))
        f.write("\n")

    os.replace(tmp, ROUTES_FILE)


def reload_nginx():
    result = run([
        "${pkgs.nginx}/bin/nginx",
        "-t",
    ])

    if result.returncode != 0:
        return False, result.stderr.strip()

    result = run([
        "${pkgs.systemd}/bin/systemctl",
        "reload",
        "nginx.service",
    ])

    if result.returncode != 0:
        return False, result.stderr.strip()

    return True, ""


def funnel_on():
    result = run([
        "${pkgs.tailscale}/bin/tailscale",
        "funnel",
        "--bg",
        "--yes",
        "8088",
    ])

    return result.returncode == 0, result.stderr.strip()


def funnel_off():
    result = run([
        "${pkgs.tailscale}/bin/tailscale",
        "funnel",
        "reset",
    ])

    return result.returncode == 0, result.stderr.strip()


def apply_state(requested):
    old = load_state()

    # Service changes are applied first.  State is only committed after
    # the requested services have successfully reached their desired state.
    for name in SERVICES:
        wanted = requested[name]
        was = old[name]

        if wanted and not was:
            ok, error = service_start(name)

            if not ok:
                return False, "Could not start %s: %s" % (
                    SERVICES[name]["name"],
                    error or "unknown error",
                )

            if not service_ready(name):
                service_stop(name)
                return False, "%s started but did not become ready." % (
                    SERVICES[name]["name"],
                )

        elif not wanted and was:
            ok, error = service_stop(name)

            if not ok:
                return False, "Could not stop %s: %s" % (
                    SERVICES[name]["name"],
                    error or "unknown error",
                )

    generate_routes(requested)

    ok, error = reload_nginx()

    if not ok:
        return False, "Nginx reload failed: " + error

    # Broadcast is independent of the individual service switches.
    # Funnel is useful only when at least one application is active.
    if requested["broadcast"] and any(
        requested[name] for name in SERVICES
    ):
        ok, error = funnel_on()

        if not ok:
            return False, "Funnel enable failed: " + error

    else:
        ok, error = funnel_off()

        if not ok:
            return False, "Funnel disable failed: " + error

    save_state(requested)

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
            max-width: 650px;
            margin: auto;
            padding: 20px;
            background: #111;
            color: #eee;
        }

        h1 {
            font-size: 1.5rem;
            margin-bottom: 6px;
        }

        .subtitle {
            color: #aaa;
            margin-bottom: 20px;
        }

        .service {
            padding: 16px 18px;
            margin: 12px 0;
            border: 1px solid #444;
            border-radius: 10px;
            background: #1b1b1b;
        }

        .row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 15px;
        }

        .name {
            font-size: 1.15rem;
        }

        .access {
            color: #aaa;
            font-size: .9rem;
            margin-top: 5px;
            word-break: break-all;
        }

        button {
            min-width: 72px;
            font-size: 1rem;
            padding: 10px 16px;
            border-radius: 8px;
            border: 0;
            cursor: pointer;
        }

        button:disabled {
            opacity: .5;
            cursor: wait;
        }

        .on {
            background: #347a46;
            color: white;
        }

        .off {
            background: #555;
            color: white;
        }

        .broadcast {
            border-color: #765b25;
        }

        #status {
            margin: 20px 0;
            padding: 12px;
            border-radius: 8px;
            background: #222;
            white-space: pre-wrap;
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
    <div class="subtitle">
        Application power and network exposure control
    </div>

    <div id="status">Loading...</div>

    <div class="service">
        <div class="row">
            <div>
                <div class="name">Lens</div>
                <div class="access">LAN / Tailscale: :3000</div>
            </div>
            <button id="lens" onclick="toggle('lens')"></button>
        </div>
    </div>

    <div class="service">
        <div class="row">
            <div>
                <div class="name">OctoPrint</div>
                <div class="access">/octoprint/ → :5000</div>
            </div>
            <button id="octoprint" onclick="toggle('octoprint')"></button>
        </div>
    </div>

    <div class="service">
        <div class="row">
            <div>
                <div class="name">Trilium</div>
                <div class="access">/trilium/ → :8080</div>
            </div>
            <button id="trilium" onclick="toggle('trilium')"></button>
        </div>
    </div>

    <div class="service broadcast">
        <div class="row">
            <div>
                <div class="name">Internet Access</div>
                <div class="access">Tailscale Funnel</div>
            </div>
            <button id="broadcast" onclick="toggle('broadcast')"></button>
        </div>
    </div>

    <div id="url"></div>

    <script>
    let state = {};
    let busy = false;

    const names = [
        "lens",
        "octoprint",
        "trilium",
        "broadcast"
    ];

    async function load() {
        try {
            const response = await fetch(
                "/api/state",
                { cache: "no-store" }
            );

            if (!response.ok) {
                throw new Error(
                    "HTTP " + response.status
                );
            }

            state = await response.json();
            update();

        } catch (error) {
            document.getElementById("status").textContent =
                "Controller unavailable: " + error.message;
        }
    }

    function update() {
        for (const name of names) {
            const button = document.getElementById(name);

            if (state[name]) {
                button.textContent = "ON";
                button.className = "on";
            } else {
                button.textContent = "OFF";
                button.className = "off";
            }

            button.disabled = busy;
        }

        const active =
            state.lens ||
            state.octoprint ||
            state.trilium;

        const status = document.getElementById("status");

        if (state.broadcast && active) {
            status.textContent =
                "Internet access ACTIVE";
        } else if (active) {
            status.textContent =
                "Services active — LAN / Tailscale only";
        } else {
            status.textContent =
                "All application services stopped";
        }

        const url = document.getElementById("url");

        if (state.broadcast && active) {
            url.textContent =
                "https://nixserver-1.tail90d1f7.ts.net";
        } else {
            url.textContent = "";
        }
    }

    async function toggle(name) {
        if (busy) {
            return;
        }

        const newState = Object.assign({}, state);
        newState[name] = !newState[name];

        busy = true;
        update();

        document.getElementById("status").textContent =
            "Applying " + name + "...";

        try {
            const response = await fetch(
                "/api/state",
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify(newState)
                }
            );

            const text = await response.text();

            let result;

            try {
                result = JSON.parse(text);
            } catch (_) {
                throw new Error(
                    "Controller returned HTTP " +
                    response.status +
                    " without valid JSON."
                );
            }

            if (!response.ok || !result.ok) {
                throw new Error(
                    result.error ||
                    ("HTTP " + response.status)
                );
            }

            state = result.state;
            update();

        } catch (error) {
            alert(error.message);
            await load();

        } finally {
            busy = false;
            update();
        }
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
            "Cache-Control",
            "no-store",
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
                "Cache-Control",
                "no-store",
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

            if length <= 0 or length > 65536:
                raise ValueError("Invalid request size.")

            body = self.rfile.read(length)
            requested = json.loads(body)

            state = {
                "lens": bool(
                    requested.get("lens", False)
                ),
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
                        "state": load_state(),
                    },
                    500,
                )

        except Exception as e:
            self.send_json(
                {
                    "ok": False,
                    "error": str(e),
                    "state": load_state(),
                },
                500,
            )

    def log_message(self, format, *args):
        pass


def reconcile_startup():
    state = load_state()

    # Make sure application state agrees with the saved controller state.
    for name in SERVICES:
        if state[name]:
            ok, error = service_start(name)

            if not ok:
                state[name] = False
                continue

            if not service_ready(name):
                service_stop(name)
                state[name] = False

    generate_routes(state)
    reload_nginx()

    if state["broadcast"] and any(
        state[name] for name in SERVICES
    ):
        funnel_on()
    else:
        funnel_off()
        state["broadcast"] = False

    save_state(state)


if __name__ == "__main__":
    reconcile_startup()

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
    "f /var/lib/remote-access/state.json 0600 root root -"
    "f /var/lib/remote-access/routes.conf 0644 root root -"
  ];


  # ---------------------------------------------------------------
  # Nginx
  #
  # The controller owns the application locations.  Nginx itself
  # stays running even when every application is stopped.
  # ---------------------------------------------------------------

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "_" = {
        basicAuthFile = "/etc/nginx/htpasswd";

        locations = {
          "/remote-access/" = {
            proxyPass = "http://127.0.0.1:8787/";
            proxyWebsockets = true;
          };
        };

        extraConfig = ''
          include /var/lib/remote-access/routes.conf;
        '';
      };

      "remote-access-public" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = 8088;
          }
        ];

        serverName = "_";

        basicAuthFile = "/etc/nginx/htpasswd";

        extraConfig = ''
          include /var/lib/remote-access/routes.conf;
        '';
      };
    };
  };


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
      "docker.service"
    ];

    requires = [
      "tailscaled.service"
      "nginx.service"
      "docker.service"
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

  networking.firewall.allowedTCPPorts = [ 80 ];
}
