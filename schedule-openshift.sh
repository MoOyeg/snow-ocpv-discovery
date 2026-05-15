#!/usr/bin/env bash
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

SCHEDULE_NAME="${SCHEDULE_NAME:-ocp-virtualmachines-discovery}"
PATTERN_NAME="${PATTERN_NAME:-OpenShift Virtual Machines}"
MID_SERVER_NAME="${MID_SERVER_NAME:-ocp-mid-01}"
CLUSTER_URL="${CLUSTER_URL:-https://kubernetes.default.svc}"
CLUSTER_NAME="${CLUSTER_NAME:-ocp-prod-1}"
NAMESPACE="${NAMESPACE:-*}"

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

json_get_first_sys_id() {
  RESPONSE="$1" python3 - <<'PY'
import json, os, sys

response = json.loads(os.environ["RESPONSE"])
if "error" in response:
    message = response["error"].get("message", response["error"])
    detail = response["error"].get("detail", "")
    sys.exit(f"query failed: {message} {detail}".strip())

rows = response.get("result", [])
print(rows[0]["sys_id"] if rows else "")
PY
}

json_require_sys_id() {
  local action="$1"
  RESPONSE="$2" ACTION="$action" python3 - <<'PY'
import json, os, sys

action = os.environ["ACTION"]
response = json.loads(os.environ["RESPONSE"])
if "error" in response:
    message = response["error"].get("message", response["error"])
    detail = response["error"].get("detail", "")
    sys.exit(f"{action} failed: {message} {detail}".strip())

result = response.get("result")
if not result or not result.get("sys_id"):
    sys.exit(f"{action} response did not include result.sys_id")

print(result["sys_id"])
PY
}

lookup_sys_id() {
  local table="$1"
  local query="$2"
  local fields="${3:-sys_id}"
  local response
  response=$(snow_api -G "${BASE}/${table}" \
    --data-urlencode "sysparm_query=${query}" \
    --data-urlencode "sysparm_fields=${fields}" \
    --data-urlencode "sysparm_limit=1")
  json_get_first_sys_id "$response"
}

upsert_record() {
  local table="$1"
  local sys_id="$2"
  local payload="$3"
  local response

  if [[ -n "$sys_id" ]]; then
    response=$(snow_api -X PATCH "${BASE}/${table}/${sys_id}" -d "$payload")
    json_require_sys_id "PATCH ${table}/${sys_id}" "$response"
  else
    response=$(snow_api -X POST "${BASE}/${table}" -d "$payload")
    json_require_sys_id "POST ${table}" "$response"
  fi
}

PATTERN_SYSID=$(lookup_sys_id "sa_pattern" "name=${PATTERN_NAME}" "sys_id,name")
[[ -n "$PATTERN_SYSID" ]] || { echo "pattern not found: ${PATTERN_NAME}" >&2; exit 1; }

MID_SYSID=$(lookup_sys_id "ecc_agent" "name=${MID_SERVER_NAME}" "sys_id,name,status,validated")
[[ -n "$MID_SYSID" ]] || { echo "MID server not found: ${MID_SERVER_NAME}" >&2; exit 1; }

SCHEDULE_SYSID=$(lookup_sys_id "discovery_schedule" "name=${SCHEDULE_NAME}" "sys_id,name")
SCHEDULE_PAYLOAD=$(jq -n \
  --arg name "$SCHEDULE_NAME" \
  --arg mid "$MID_SYSID" \
  '{
    name: $name,
    active: "true",
    discover: "Hostless",
    disco_run_type: "on_demand",
    run_type: "on_demand",
    mid_select_method: "specific_mid",
    mid_server: $mid
  }')
SCHEDULE_SYSID=$(upsert_record "discovery_schedule" "$SCHEDULE_SYSID" "$SCHEDULE_PAYLOAD")

LAUNCHER_SYSID=$(lookup_sys_id \
  "discovery_ptrn_hostless_lchr" \
  "schedule=${SCHEDULE_SYSID}^pattern=${PATTERN_SYSID}" \
  "sys_id,name,schedule,pattern")
LAUNCHER_PAYLOAD=$(jq -n \
  --arg name "$PATTERN_NAME" \
  --arg schedule "$SCHEDULE_SYSID" \
  --arg pattern "$PATTERN_SYSID" \
  '{
    name: $name,
    active: "true",
    schedule: $schedule,
    pattern: $pattern,
    run_child_patterns: "false"
  }')
LAUNCHER_SYSID=$(upsert_record "discovery_ptrn_hostless_lchr" "$LAUNCHER_SYSID" "$LAUNCHER_PAYLOAD")

upsert_param_def() {
  local key="$1"
  local def_sysid payload
  def_sysid=$(lookup_sys_id \
    "discovery_ptrn_lnch_param_def" \
    "pattern=${PATTERN_SYSID}^key=${key}" \
    "sys_id,key,pattern")
  payload=$(jq -n \
    --arg key "$key" \
    --arg pattern "$PATTERN_SYSID" \
    '{key: $key, pattern: $pattern, is_global: "false"}')
  upsert_record "discovery_ptrn_lnch_param_def" "$def_sysid" "$payload"
}

upsert_param() {
  local key="$1"
  local value="$2"
  local def_sysid param_sysid payload

  def_sysid=$(upsert_param_def "$key")
  param_sysid=$(lookup_sys_id \
    "discovery_ptrn_lnch_param" \
    "pattern_launcher=${LAUNCHER_SYSID}^param=${def_sysid}" \
    "sys_id,param,pattern_launcher")
  payload=$(jq -n \
    --arg launcher "$LAUNCHER_SYSID" \
    --arg param "$def_sysid" \
    --arg value "$value" \
    '{pattern_launcher: $launcher, param: $param, value: $value}')
  upsert_record "discovery_ptrn_lnch_param" "$param_sysid" "$payload" >/dev/null
}

upsert_param "url" "$CLUSTER_URL"
upsert_param "cluster_name" "$CLUSTER_NAME"
upsert_param "namespace" "$NAMESPACE"

cat <<EOF
schedule: ${SCHEDULE_NAME} (${SCHEDULE_SYSID})
pattern:  ${PATTERN_NAME} (${PATTERN_SYSID})
launcher: ${LAUNCHER_SYSID}
mid:      ${MID_SERVER_NAME} (${MID_SYSID})
params:
  url=${CLUSTER_URL}
  cluster_name=${CLUSTER_NAME}
  namespace=${NAMESPACE}

open the schedule:
  https://${INST}/discovery_schedule.do?sys_id=${SCHEDULE_SYSID}
EOF
