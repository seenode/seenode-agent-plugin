#!/usr/bin/env bash
# Validate Seenode Agent Plugin manifests, skills, sync, and secret heuristics.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Prefer GitHub raw mirrors — agent-plugins.org may 403 automated clients.
PLUGIN_SCHEMA_URL="https://raw.githubusercontent.com/agentplugins/agent-plugins-spec/main/schemas/1.0.0/plugin.schema.json"
MCP_SCHEMA_URL="https://raw.githubusercontent.com/agentplugins/agent-plugins-spec/main/schemas/1.0.0/mcp.schema.json"
EXPECTED_NAME="seenode"
EXPECTED_MCP_URL="https://mcp.seenode.com/mcp"
# Version is sourced from plugin.json so bumps stay in one place.
EXPECTED_VERSION="$(python3 -c 'import json; print(json.load(open("plugin.json"))["version"])')"

RED=$'\033[31m'
GRN=$'\033[32m'
YLW=$'\033[33m'
RST=$'\033[0m'

FAILURES=0
pass() { echo "${GRN}PASS${RST} $*"; }
fail() { echo "${RED}FAIL${RST} $*"; FAILURES=$((FAILURES + 1)); }
warn() { echo "${YLW}WARN${RST} $*"; }

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required"
  exit 1
fi

echo "==> JSON parse"
JSON_FILES="plugin.json mcp.json .mcp.json .claude-plugin/plugin.json .claude-plugin/marketplace.json .codex-plugin/plugin.json .app.json.example"
for f in $JSON_FILES; do
  if [[ ! -f "$f" ]]; then
    fail "missing $f"
    continue
  fi
  if python3 -c "import json; json.load(open('$f'))"; then
    pass "parse $f"
  else
    fail "invalid JSON: $f"
  fi
done

echo "==> Agent Plugins schema validation"
SCHEMA_DIR="${SCHEMA_DIR:-$ROOT/schemas}"
mkdir -p "$SCHEMA_DIR"
PLUGIN_SCHEMA="$SCHEMA_DIR/plugin.schema.json"
MCP_SCHEMA="$SCHEMA_DIR/mcp.schema.json"

download_schema() {
  local url="$1" dest="$2"
  if [[ -f "$dest" ]]; then
    return 0
  fi
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    return 1
  fi
}

SCHEMA_OK=1
if ! download_schema "$PLUGIN_SCHEMA_URL" "$PLUGIN_SCHEMA"; then
  warn "could not download plugin schema; skipping schema validation"
  SCHEMA_OK=0
fi
if ! download_schema "$MCP_SCHEMA_URL" "$MCP_SCHEMA"; then
  warn "could not download mcp schema; skipping schema validation"
  SCHEMA_OK=0
fi

if [[ "$SCHEMA_OK" -eq 1 ]]; then
  if command -v check-jsonschema >/dev/null 2>&1; then
    if check-jsonschema --schemafile "$PLUGIN_SCHEMA" plugin.json; then
      pass "plugin.json schema (check-jsonschema)"
    else
      fail "plugin.json schema (check-jsonschema)"
    fi
    if check-jsonschema --schemafile "$MCP_SCHEMA" mcp.json; then
      pass "mcp.json schema (check-jsonschema)"
    else
      fail "mcp.json schema (check-jsonschema)"
    fi
  else
    set +e
    SCHEMA_OUT="$(python3 - "$PLUGIN_SCHEMA" "$MCP_SCHEMA" <<'PY'
import json
import sys
from pathlib import Path

plugin_schema_path = Path(sys.argv[1])
mcp_schema_path = Path(sys.argv[2])
plugin = json.loads(Path("plugin.json").read_text())
mcp = json.loads(Path("mcp.json").read_text())

try:
    from jsonschema import Draft202012Validator
except ImportError:
    errors = []
    if plugin.get("$schema") != "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json":
        errors.append("plugin.json $schema mismatch")
    if "name" not in plugin:
        errors.append("plugin.json missing name")
    if mcp.get("$schema") != "https://agent-plugins.org/schemas/1.0.0/mcp.schema.json":
        errors.append("mcp.json $schema mismatch")
    servers = mcp.get("mcpServers") or {}
    if "seenode" not in servers:
        errors.append("mcp.json missing seenode server")
    else:
        s = servers["seenode"]
        if s.get("type") != "streamable-http":
            errors.append("mcp.json type must be streamable-http")
        if s.get("url") != "https://mcp.seenode.com/mcp":
            errors.append("mcp.json url mismatch")
    if errors:
        print("; ".join(errors))
        sys.exit(2)
    print("structural ok")
    sys.exit(0)

Draft202012Validator(json.loads(plugin_schema_path.read_text())).validate(plugin)
Draft202012Validator(json.loads(mcp_schema_path.read_text())).validate(mcp)
print("schema ok")
PY
)"
    SCHEMA_RC=$?
    set -e
    if [[ $SCHEMA_RC -eq 0 ]]; then
      pass "plugin.json + mcp.json schema/structure ($SCHEMA_OUT)"
    else
      fail "plugin.json / mcp.json schema: $SCHEMA_OUT"
    fi
  fi
fi

echo "==> Skills structure"
set +e
python3 - <<'PY'
import re
import sys
from pathlib import Path

expected = [
    "deploy",
    "troubleshoot",
    "applications",
    "environment",
    "databases",
    "domains",
    "projects",
]
skills_root = Path("skills")
failures = 0
seen = []

if not skills_root.is_dir():
    print("FAIL skills/ directory missing")
    sys.exit(1)

for child in sorted(skills_root.iterdir()):
    if not child.is_dir() or child.name.startswith("."):
        continue
    skill_md = child / "SKILL.md"
    if not skill_md.is_file():
        print(f"FAIL skills/{child.name} missing SKILL.md")
        failures += 1
        continue
    text = skill_md.read_text()
    if not text.startswith("---"):
        print(f"FAIL skills/{child.name} missing frontmatter")
        failures += 1
        continue
    parts = text.split("---", 2)
    if len(parts) < 3:
        print(f"FAIL skills/{child.name} unclosed frontmatter")
        failures += 1
        continue
    fm = parts[1]
    name_m = re.search(r"(?m)^name:\s*[\"']?([^\"'\n]+)[\"']?\s*$", fm)
    desc_m = re.search(r"(?m)^description:\s*.+$", fm)
    if not name_m:
        print(f"FAIL skills/{child.name} missing name")
        failures += 1
        continue
    if not desc_m:
        print(f"FAIL skills/{child.name} missing description")
        failures += 1
        continue
    name = name_m.group(1).strip()
    if name != child.name:
        print(f"FAIL skills/{child.name} name mismatch file={name}")
        failures += 1
        continue
    if name in seen:
        print(f"FAIL duplicate skill name: {name}")
        failures += 1
        continue
    seen.append(name)
    print(f"PASS skill {name}")

for name in expected:
    if name not in seen:
        print(f"FAIL expected skill missing: {name}")
        failures += 1

sys.exit(1 if failures else 0)
PY
SKILLS_RC=$?
set -e
if [[ $SKILLS_RC -ne 0 ]]; then
  FAILURES=$((FAILURES + 1))
fi

echo "==> Relative path checks"
set +e
python3 - <<'PY'
import json
import sys
from pathlib import Path

failures = 0

def check_exists(label, rel):
    global failures
    p = Path(rel)
    if not p.exists():
        print(f"FAIL {label} → {rel}")
        failures += 1
    else:
        print(f"PASS {label} → {rel}")

claude = json.loads(Path(".claude-plugin/plugin.json").read_text())
mcp_ref = claude.get("mcpServers")
if isinstance(mcp_ref, str):
    check_exists(".claude-plugin/plugin.json mcpServers", mcp_ref)
else:
    print("FAIL .claude-plugin/plugin.json mcpServers should be a path string")
    failures += 1

codex = json.loads(Path(".codex-plugin/plugin.json").read_text())
for key in ("skills", "mcpServers"):
    rel = codex.get(key)
    if isinstance(rel, str):
        check_exists(f".codex-plugin/plugin.json {key}", rel)
    else:
        print(f"FAIL .codex-plugin/plugin.json {key} should be a path string")
        failures += 1

iface = codex.get("interface") or {}
for key in ("logo", "composerIcon"):
    rel = iface.get(key)
    if rel:
        check_exists(f"interface.{key}", rel)

if "apps" in codex:
    print("FAIL .codex-plugin/plugin.json must not set apps until .app.json exists")
    failures += 1
else:
    print("PASS .codex-plugin/plugin.json has no apps key (example only)")

mp = json.loads(Path(".claude-plugin/marketplace.json").read_text())
plugins = mp.get("plugins") or []
if len(plugins) != 1:
    print("FAIL marketplace.json should list exactly one plugin")
    failures += 1
else:
    src = plugins[0].get("source")
    if src != ".":
        print(f"FAIL marketplace plugin source should be '.', got {src!r}")
        failures += 1
    else:
        print("PASS marketplace.json source .")

sys.exit(1 if failures else 0)
PY
PATHS_RC=$?
set -e
if [[ $PATHS_RC -ne 0 ]]; then
  FAILURES=$((FAILURES + 1))
fi

echo "==> Metadata sync"
set +e
python3 - <<PY
import json
import sys
from pathlib import Path

expected_name = "$EXPECTED_NAME"
expected_version = "$EXPECTED_VERSION"
expected_url = "$EXPECTED_MCP_URL"
failures = 0

def load(p):
    return json.loads(Path(p).read_text())

plugin = load("plugin.json")
claude = load(".claude-plugin/plugin.json")
codex = load(".codex-plugin/plugin.json")
mcp = load("mcp.json")
dot_mcp = load(".mcp.json")

checks = [
    ("plugin.json name", plugin.get("name"), expected_name),
    ("plugin.json version", plugin.get("version"), expected_version),
    ("claude name", claude.get("name"), expected_name),
    ("claude version", claude.get("version"), expected_version),
    ("codex name", codex.get("name"), expected_name),
    ("codex version", codex.get("version"), expected_version),
]
for label, got, exp in checks:
    if got != exp:
        print(f"FAIL {label}: got {got!r} expected {exp!r}")
        failures += 1
    else:
        print(f"PASS {label}={got}")

server = (mcp.get("mcpServers") or {}).get("seenode") or {}
if server.get("type") != "streamable-http" or server.get("url") != expected_url:
    print(f"FAIL mcp.json seenode server {server!r}")
    failures += 1
else:
    print(f"PASS mcp.json url={expected_url}")

if "seenode" in dot_mcp and isinstance(dot_mcp["seenode"], dict):
    s = dot_mcp["seenode"]
elif "mcpServers" in dot_mcp:
    s = (dot_mcp.get("mcpServers") or {}).get("seenode") or {}
else:
    s = {}

if s.get("type") != "http" or s.get("url") != expected_url:
    print(f"FAIL .mcp.json seenode server {s!r}")
    failures += 1
else:
    print(f"PASS .mcp.json url={expected_url} type=http")

if "headers" in server or (isinstance(s, dict) and "headers" in s):
    print("FAIL MCP configs must not set headers")
    failures += 1
else:
    print("PASS no MCP auth headers in manifests")

if Path(".cursor-plugin").exists():
    print("FAIL .cursor-plugin/ must not exist")
    failures += 1
else:
    print("PASS no .cursor-plugin/")

sys.exit(1 if failures else 0)
PY
SYNC_RC=$?
set -e
if [[ $SYNC_RC -ne 0 ]]; then
  FAILURES=$((FAILURES + 1))
fi

echo "==> Secret heuristics"
set +e
SECRET_HITS="$(
  grep -RInE \
    --exclude-dir=.git \
    --exclude-dir=node_modules \
    --exclude-dir=schemas \
    --exclude='*.png' \
    --exclude='*.jpg' \
    --exclude='validate.sh' \
    -e 'Bearer[[:space:]]+[A-Za-z0-9._\-]+' \
    -e 'api[_-]?key[[:space:]]*[:=][[:space:]]*['\''\"]?[A-Za-z0-9]{16,}' \
    -e 'client_secret[[:space:]]*[:=]' \
    -e 'BEGIN[[:space:]]+(RSA[[:space:]]+)?PRIVATE[[:space:]]+KEY' \
    -e 'sk_live_[A-Za-z0-9]+' \
    -e 'sk-[A-Za-z0-9]{20,}' \
    . 2>/dev/null
)"
SECRET_RC=$?
set -e
# grep exit 1 means no matches
if [[ $SECRET_RC -eq 0 && -n "$SECRET_HITS" ]]; then
  echo "$SECRET_HITS"
  fail "secret-like patterns found"
elif [[ $SECRET_RC -gt 1 ]]; then
  fail "secret grep failed"
else
  pass "no secret-like patterns in text files"
fi

if grep -q 'plugin_asdk_app_REPLACE_ME' .app.json.example; then
  pass ".app.json.example still uses placeholder ID"
else
  fail ".app.json.example should contain plugin_asdk_app_REPLACE_ME"
fi

echo "==> Optional claude plugin validate"
if command -v claude >/dev/null 2>&1; then
  set +e
  claude plugin validate .
  CLAUDE_RC=$?
  set -e
  if [[ $CLAUDE_RC -eq 0 ]]; then
    pass "claude plugin validate ."
  else
    warn "claude plugin validate . failed (non-fatal)"
  fi
else
  warn "claude CLI not on PATH — skipping claude plugin validate"
fi

echo "==> Assets"
for asset in assets/icon.png assets/logo.png; do
  if [[ -f "$asset" ]]; then
    pass "$asset present"
  else
    fail "$asset missing"
  fi
done

echo
if [[ "$FAILURES" -gt 0 ]]; then
  echo "${RED}Validation failed with $FAILURES error(s).${RST}"
  exit 1
fi
echo "${GRN}All validation checks passed.${RST}"
