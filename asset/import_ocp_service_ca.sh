#!/bin/bash
set -euo pipefail

MID_BASE="/opt/snc_mid_server"
KEYTOOL="${MID_BASE}/agent/jre/bin/keytool"
TRUSTSTORE="${MID_BASE}/agent/jre/lib/security/cacerts"
CA="${KUBERNETES_SERVICE_CA_FILE:-/var/run/secrets/kubernetes.io/serviceaccount/ca.crt}"
ALIAS="${KUBERNETES_SERVICE_CA_ALIAS:-openshift-service-ca}"
STOREPASS="${MID_TRUSTSTORE_PASSWORD:-changeit}"
LOG_FILE="${MID_BASE}/mid-container.log"
MID_CONTAINER_DIR="${MID_BASE}/mid_container"
SELECTED_CA_SUBJECT="${KUBERNETES_SERVICE_CA_SUBJECT:-kube-apiserver-service-network-signer}"

if [[ -d "$MID_CONTAINER_DIR" ]]; then
  LOG_FILE="${MID_CONTAINER_DIR}/mid-container.log"
fi

logInfo () {
  msg="$(date '+%Y-%m-%dT%T.%3N') ${1}"
  echo "$msg" | tee -a "$LOG_FILE"
}

if [[ ! -r "$CA" ]]; then
  logInfo "DOCKER: Kubernetes service CA not found at ${CA}; skipping OCP service CA import"
  exit 0
fi

if [[ ! -x "$KEYTOOL" ]]; then
  logInfo "DOCKER: keytool not executable at ${KEYTOOL}; cannot import OCP service CA"
  exit 1
fi

if [[ ! -w "$TRUSTSTORE" ]]; then
  logInfo "DOCKER: MID JVM truststore is not writable: ${TRUSTSTORE}"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

awk -v dir="$TMP_DIR" '
  /-----BEGIN CERTIFICATE-----/ {
    n++
    file = sprintf("%s/cert-%02d.pem", dir, n)
  }
  n > 0 {
    print > file
  }
' "$CA"

SELECTED_CA=""
for cert in "$TMP_DIR"/cert-*.pem; do
  if "$KEYTOOL" -printcert -file "$cert" 2>/dev/null | grep -q "$SELECTED_CA_SUBJECT"; then
    SELECTED_CA="$cert"
    break
  fi
done

if [[ -z "$SELECTED_CA" ]]; then
  SELECTED_CA="$(find "$TMP_DIR" -name 'cert-*.pem' | sort | head -n 1)"
  logInfo "DOCKER: ${SELECTED_CA_SUBJECT} not found in Kubernetes service CA bundle; falling back to first certificate"
fi

SELECTED_SUBJECT="$("$KEYTOOL" -printcert -file "$SELECTED_CA" 2>/dev/null | awk -F': ' '/Owner:/ {print $2; exit}')"

if "$KEYTOOL" -list -alias "$ALIAS" -keystore "$TRUSTSTORE" -storepass "$STOREPASS" >/dev/null 2>&1; then
  "$KEYTOOL" -delete -alias "$ALIAS" -keystore "$TRUSTSTORE" -storepass "$STOREPASS" >/dev/null
fi

"$KEYTOOL" \
  -importcert \
  -noprompt \
  -trustcacerts \
  -alias "$ALIAS" \
  -file "$SELECTED_CA" \
  -keystore "$TRUSTSTORE" \
  -storepass "$STOREPASS" >/dev/null

"$KEYTOOL" -list -alias "$ALIAS" -keystore "$TRUSTSTORE" -storepass "$STOREPASS" >/dev/null
logInfo "DOCKER: imported Kubernetes service CA into MID JVM truststore as ${ALIAS}: ${SELECTED_SUBJECT}"
