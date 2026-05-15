#!/usr/bin/env bash
set -euo pipefail

echo "ca.sh version: 2026-05-14-mid-jvm-service-network-ca"

NS="${NS:-servicenow-discovery}"
DEPLOY="${DEPLOY:-snow-mid}"
ALIAS="${KUBERNETES_SERVICE_CA_ALIAS:-openshift-service-ca}"
STOREPASS="${MID_TRUSTSTORE_PASSWORD:-changeit}"
TRUSTSTORE="${TRUSTSTORE:-/opt/snc_mid_server/agent/jre/lib/security/cacerts}"
KEYTOOL="${KEYTOOL:-/opt/snc_mid_server/agent/jre/bin/keytool}"
JAVA="${JAVA:-/opt/snc_mid_server/agent/jre/bin/java}"
TOKEN_FILE="${TOKEN_FILE:-/var/run/secrets/kubernetes.io/serviceaccount/token}"
CA_BUNDLE_FILE="${CA_BUNDLE_FILE:-ocp-kubernetes-service-ca.pem}"
SELECTED_CA_FILE="${SELECTED_CA_FILE:-ocp-kubernetes-service-ca-selected.pem}"
URL="${URL:-https://kubernetes.default.svc}"
PATH_TO_CHECK="${PATH_TO_CHECK:-/apis/kubevirt.io/v1/virtualmachines}"

POD=$(oc -n "${NS}" get pod -l app=snow-mid -o jsonpath='{.items[0].metadata.name}')

oc -n "${NS}" exec "${POD}" -- \
  cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt > "${CA_BUNDLE_FILE}"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

awk -v dir="${TMP_DIR}" '
  /-----BEGIN CERTIFICATE-----/ {
    n++
    file = sprintf("%s/cert-%02d.pem", dir, n)
  }
  n > 0 {
    print > file
  }
' "${CA_BUNDLE_FILE}"

SELECTED_CA=""
for cert in "${TMP_DIR}"/cert-*.pem; do
  if openssl x509 -in "${cert}" -noout -subject |
    grep -q 'kube-apiserver-service-network-signer'; then
    SELECTED_CA="${cert}"
    break
  fi
done

if [[ -z "${SELECTED_CA}" ]]; then
  SELECTED_CA=$(find "${TMP_DIR}" -name 'cert-*.pem' | sort | head -n 1)
  echo "WARNING: kube-apiserver-service-network-signer was not found; falling back to ${SELECTED_CA}" >&2
fi

cp "${SELECTED_CA}" "${SELECTED_CA_FILE}"

echo "Selected CA for ${URL}:"
openssl x509 -in "${SELECTED_CA_FILE}" -noout -subject -issuer -fingerprint -sha256

oc -n "${NS}" exec -i "${POD}" -- sh -lc "
  set -e
  cat > /tmp/${ALIAS}.pem
  '${KEYTOOL}' \
    -delete \
    -alias '${ALIAS}' \
    -keystore '${TRUSTSTORE}' \
    -storepass '${STOREPASS}' >/dev/null 2>&1 || true
  '${KEYTOOL}' \
    -importcert \
    -noprompt \
    -trustcacerts \
    -alias '${ALIAS}' \
    -file /tmp/${ALIAS}.pem \
    -keystore '${TRUSTSTORE}' \
    -storepass '${STOREPASS}' >/dev/null
  '${KEYTOOL}' \
    -list \
    -alias '${ALIAS}' \
    -keystore '${TRUSTSTORE}' \
    -storepass '${STOREPASS}'
" < "${SELECTED_CA_FILE}"

oc -n "${NS}" exec "${POD}" -- sh -lc "
  set -e
  cat > /tmp/TestKubeTLS.java <<'EOF'
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;

public class TestKubeTLS {
  public static void main(String[] args) throws Exception {
    String token = Files.readString(Path.of(\"${TOKEN_FILE}\")).trim();
    HttpRequest request = HttpRequest.newBuilder(URI.create(\"${URL}${PATH_TO_CHECK}\"))
      .header(\"Authorization\", \"Bearer \" + token)
      .header(\"Accept\", \"application/json\")
      .GET()
      .build();
    HttpResponse<String> response = HttpClient.newHttpClient().send(request, HttpResponse.BodyHandlers.ofString());
    System.out.println(\"JAVA_HTTP_STATUS=\" + response.statusCode());
    String body = response.body();
    System.out.println(body.substring(0, Math.min(160, body.length())));
  }
}
EOF
  '${JAVA}' /tmp/TestKubeTLS.java
"

echo "Imported ${ALIAS} into the MID JVM truststore on pod ${POD}."
echo "For durable fresh pods, rebuild the MID image with the updated import_ocp_service_ca.sh startup hook."
