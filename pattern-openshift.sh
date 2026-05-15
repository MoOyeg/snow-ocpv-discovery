#!/usr/bin/env bash
# Creates or updates the OpenShift Virtual Machines discovery pattern, then
# replaces sa_pattern.ndl with the full NDL from ./pattern-openshift.

set -euo pipefail

SCRIPT_XTRACE_ON=
case $- in
  *x*) SCRIPT_XTRACE_ON=1; set +x ;;
esac

INST="${SNOW_INSTANCE:?set SNOW_INSTANCE=https://devNNNNNN.service-now.com}"
INST="${INST#https://}"; INST="${INST%/}"
SNOW_USER="${SNOW_INSTANCE_USERNAME:?set SNOW_INSTANCE_USERNAME}"
SNOW_PASS="${SNOW_INSTANCE_PASSWORD:-}"
if [[ -z "$SNOW_PASS" ]]; then
  read -rsp "SNOW_INSTANCE_PASSWORD: " SNOW_PASS
  echo
fi

if [[ -n "$SCRIPT_XTRACE_ON" ]]; then
  set -x
fi

NDL_FILE="${NDL_FILE:-./pattern-openshift}"
PATTERN_NAME="${PATTERN_NAME:-OpenShift Virtual Machines}"
CI_TABLE="${CI_TABLE:-u_cmdb_ci_openshift_virtual_machines}"
# sa_pattern.cpattern_type integer codes:
#   1 = Application, 2 = Shared library, 3 = Infrastructure, 4 = Cloud Resource
CPATTERN_TYPE="${CPATTERN_TYPE:-4}"

BASE="https://${INST}/api/now/table"

snow_api() {
  local xtrace_on=
  case $- in
    *x*) xtrace_on=1; set +x ;;
  esac

  curl -sS -u "${SNOW_USER}:${SNOW_PASS}" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    "$@"
  local rc=$?

  if [[ -n "$xtrace_on" ]]; then
    set -x
  fi
  return "$rc"
}

[[ -r "$NDL_FILE" ]] || { echo "NDL file not readable: $NDL_FILE" >&2; exit 1; }

LOOKUP_RESPONSE=$(snow_api -G "${BASE}/sa_pattern" \
  --data-urlencode "sysparm_query=name=${PATTERN_NAME}" \
  --data-urlencode "sysparm_fields=sys_id,name" \
  --data-urlencode "sysparm_limit=1")

PATTERN_SYSID=$(LOOKUP_RESPONSE="$LOOKUP_RESPONSE" python3 - <<'PY'
import json, os, sys

response = json.loads(os.environ["LOOKUP_RESPONSE"])
if "error" in response:
    message = response["error"].get("message", response["error"])
    detail = response["error"].get("detail", "")
    if "not authenticated" in str(message).lower():
        detail = (str(detail) + " Check SNOW_INSTANCE_USERNAME/SNOW_INSTANCE_PASSWORD, rotate any password exposed by bash -x, and confirm Basic Auth/Table API access is allowed for this user.").strip()
    sys.exit(f"lookup failed: {message} {detail}".strip())

rows = response.get("result", [])
print(rows[0]["sys_id"] if rows else "")
PY
)

if [[ -z "$PATTERN_SYSID" ]]; then
  echo "pattern not found, creating: ${PATTERN_NAME}"
  CREATE_PAYLOAD=$(printf '{
  "name":"%s",
  "cpattern_type":"%s",
  "ci_type":"%s",
  "active":"true",
  "description":"Standalone discovery for KubeVirt VirtualMachines via the OCP API"
}' "$PATTERN_NAME" "$CPATTERN_TYPE" "$CI_TABLE")

  CREATE_RESPONSE=$(snow_api -X POST "${BASE}/sa_pattern" -d "$CREATE_PAYLOAD")
  PATTERN_SYSID=$(CREATE_RESPONSE="$CREATE_RESPONSE" python3 - <<'PY'
import json, os, sys

try:
    response = json.loads(os.environ["CREATE_RESPONSE"])
except json.JSONDecodeError as exc:
    sys.exit(f"create returned non-JSON response: {exc}")

if "error" in response:
    message = response["error"].get("message", response["error"])
    detail = response["error"].get("detail", "")
    sys.exit(f"create failed: {message} {detail}".strip())

result = response.get("result")
if not result or not result.get("sys_id"):
    sys.exit("create response did not include result.sys_id")

print(result["sys_id"])
PY
)
else
  echo "found pattern: ${PATTERN_NAME} (${PATTERN_SYSID})"
fi

echo "patching ndl on sa_pattern/${PATTERN_SYSID}"

# Send the NDL as a JSON string. python3 handles the quoting/escaping and
# stamps metadata.id to the target row before upload.
PATCH_RESPONSE=$(
  python3 - "$NDL_FILE" "$PATTERN_SYSID" <<'PY' | snow_api -X PATCH "${BASE}/sa_pattern/${PATTERN_SYSID}" -d @-
import json, re, sys

path, pattern_sysid = sys.argv[1], sys.argv[2]
with open(path) as f:
    ndl = f.read()

ndl, count = re.subn(r'id = "[0-9a-f]{32}"', f'id = "{pattern_sysid}"', ndl, count=1)
if count != 1:
    sys.exit("could not find metadata.id in NDL")

json.dump({"ndl": ndl}, sys.stdout)
PY
)

PATCH_RESPONSE="$PATCH_RESPONSE" python3 - <<'PY'
import json, os, sys

try:
    response = json.loads(os.environ["PATCH_RESPONSE"])
except json.JSONDecodeError as exc:
    sys.exit(f"PATCH returned non-JSON response: {exc}")

if "error" in response:
    message = response["error"].get("message", response["error"])
    detail = response["error"].get("detail", "")
    sys.exit(f"PATCH failed: {message} {detail}".strip())

result = response.get("result")
if not result or not result.get("sys_id"):
    sys.exit("PATCH response did not include result.sys_id")

print("patched:", result["sys_id"])
PY

echo
echo "open the pattern record:"
echo "  https://${INST}/sa_pattern.do?sys_id=${PATTERN_SYSID}"
echo "then open All > Pattern Designer > Discovery Patterns and select:"
echo "  ${PATTERN_NAME}"
