#!/usr/bin/env bash
set -euo pipefail

NS="${NS:-servicenow-discovery}"
DEPLOY="${DEPLOY:-snow-mid}"
URL="${URL:-https://kubernetes.default.svc}"
ALIAS="${KUBERNETES_SERVICE_CA_ALIAS:-openshift-service-ca}"
TRUSTSTORE="${TRUSTSTORE:-/opt/snc_mid_server/agent/jre/lib/security/cacerts}"
KEYTOOL="${KEYTOOL:-/opt/snc_mid_server/agent/jre/bin/keytool}"
STOREPASS="${MID_TRUSTSTORE_PASSWORD:-changeit}"
TOKEN_FILE="${TOKEN_FILE:-/var/run/secrets/kubernetes.io/serviceaccount/token}"
CA_FILE="${CA_FILE:-/var/run/secrets/kubernetes.io/serviceaccount/ca.crt}"
PATH_TO_CHECK="${PATH_TO_CHECK:-/apis/kubevirt.io/v1/virtualmachines}"

echo "== MID pod =="
oc -n "$NS" get deploy "$DEPLOY" -o wide

echo
echo "== Startup CA import log =="
oc -n "$NS" logs "deploy/${DEPLOY}" --tail=500 |
  grep -E "imported Kubernetes service CA|Kubernetes service CA|truststore|PKIX|SSL|certificate|kubernetes.default.svc" || true

echo
echo "== Startup hook wiring =="
oc -n "$NS" exec "deploy/${DEPLOY}" -- sh -lc "
  set +e
  echo 'script:'
  ls -l /opt/snc_mid_server/import_ocp_service_ca.sh
  echo
  echo 'init hook:'
  grep -n 'import_ocp_service_ca' /opt/snc_mid_server/init
  echo
  echo 'truststore perms:'
  ls -l '${TRUSTSTORE}'
  echo
  echo 'current user:'
  id
"

echo
echo "== Truststore alias =="
if ! oc -n "$NS" exec "deploy/${DEPLOY}" -- sh -lc "
  set +e
  '${KEYTOOL}' -list \
    -alias '${ALIAS}' \
    -keystore '${TRUSTSTORE}' \
    -storepass '${STOREPASS}'
"; then
  echo
  echo "MISSING: truststore alias ${ALIAS} is not present in the running MID pod."
  echo "The image probably was not rebuilt/redeployed with import_ocp_service_ca.sh wired into /opt/snc_mid_server/init,"
  echo "or the startup hook failed before MID startup. Rebuild/push the image and rollout restart the deployment."
fi

echo
echo "== Service-account token and CA files =="
oc -n "$NS" exec "deploy/${DEPLOY}" -- sh -lc "
  set -e
  test -s '${TOKEN_FILE}'
  test -s '${CA_FILE}'
  printf 'token_length='
  wc -c < '${TOKEN_FILE}'
  tmp=\$(mktemp -d)
  awk -v dir=\"\$tmp\" '
    /-----BEGIN CERTIFICATE-----/ {
      n++
      file = sprintf(\"%s/cert-%02d.pem\", dir, n)
    }
    n > 0 {
      print > file
    }
  ' '${CA_FILE}'
  for cert in \"\$tmp\"/cert-*.pem; do
    openssl x509 -in \"\$cert\" -noout -subject -fingerprint -sha256
  done
  rm -rf \"\$tmp\"
"

echo
echo "== Kubernetes API curl from MID pod =="
oc -n "$NS" exec "deploy/${DEPLOY}" -- sh -lc "
  set -e
  TOKEN=\$(cat '${TOKEN_FILE}')
  body=\$(mktemp)
  status=\$(curl -sS \
    --cacert '${CA_FILE}' \
    -H \"Authorization: Bearer \${TOKEN}\" \
    -H 'Accept: application/json' \
    -o \"\$body\" \
    -w '%{http_code}' \
    '${URL}${PATH_TO_CHECK}')
  sed -n '1,40p' \"\$body\"
  rm -f \"\$body\"
  echo
  echo \"HTTP_STATUS=\${status}\"
"

echo
echo "== Kubernetes API Java TLS from MID JVM =="
oc -n "$NS" exec "deploy/${DEPLOY}" -- sh -lc "
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
  /opt/snc_mid_server/agent/jre/bin/java /tmp/TestKubeTLS.java
"
