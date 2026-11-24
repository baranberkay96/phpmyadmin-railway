"""Build the start commands and the phpMyAdmin config value in template.json
from the readable sources in this folder.

    python3 to-template.py            # print the values
    python3 to-template.py --check    # exit 1 if template.json differs
    python3 to-template.py --write    # update template.json in place

- startCommand of each service: its script joined into one line (comments and
  blank lines dropped, lines joined with "; " unless they end in then/do/else),
  wrapped as /bin/bash -c '<script>' <name>.
- PMA_USER_CONFIG_BASE64: phpmyadmin/config.user.inc.php, base64-encoded. The
  image's entrypoint decodes it into /etc/phpmyadmin/config.user.inc.php.
"""
import base64
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
TEMPLATE = HERE.parent / "template.json"
SCRIPTS = {"phpMyAdmin": (HERE / "phpmyadmin" / "pma-start.sh", "pma-start"),
           "MySQL": (HERE / "mysql" / "mysql-start.sh", "mysql-start")}
CONFIG = HERE / "phpmyadmin" / "config.user.inc.php"
OPENERS = ("then", "do", "else")


def one_line(script: pathlib.Path, name: str) -> str:
    lines = []
    for raw in script.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "'" in line or "\\" in line:
            raise SystemExit(f"single quote or backslash not allowed: {line}")
        lines.append(line)
    out = ""
    for i, line in enumerate(lines):
        out += line
        if i < len(lines) - 1:
            out += " " if line.split()[-1] in OPENERS else "; "
    return f"/bin/bash -c '{out}' {name}"


def values() -> dict:
    v = {svc: one_line(*src) for svc, src in SCRIPTS.items()}
    v["config"] = base64.b64encode(CONFIG.read_bytes()).decode("ascii")
    return v


def main() -> int:
    v = values()
    if "--check" not in sys.argv and "--write" not in sys.argv:
        print(json.dumps(v, indent=1))
        return 0
    template = json.loads(TEMPLATE.read_text(encoding="utf-8"))
    services = template["services"]
    current = {svc: services[svc]["startCommand"] for svc in SCRIPTS}
    current["config"] = services["phpMyAdmin"]["variables"]["PMA_USER_CONFIG_BASE64"]["defaultValue"]
    if "--write" in sys.argv:
        for svc in SCRIPTS:
            services[svc]["startCommand"] = v[svc]
        services["phpMyAdmin"]["variables"]["PMA_USER_CONFIG_BASE64"]["defaultValue"] = v["config"]
        TEMPLATE.write_text(json.dumps(template, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print("template.json updated")
        return 0
    stale = [key for key in v if v[key] != current[key]]
    print(f"out of date: {stale}" if stale else "OK: template.json matches the sources")
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main())
