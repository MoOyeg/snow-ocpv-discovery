# snow-ocpv-discovery

Companion code for discovering **OpenShift Virtualization (KubeVirt) virtual
machines** in a **ServiceNow CMDB** via an in-cluster MID Server and a custom
Discovery Pattern.

This repository holds the original scripts and pattern definitions referenced
by the walkthrough in
[`servicenow-australia-ocpv-inventory.md`](servicenow-australia-ocpv-inventory.md).
It deliberately does **not** redistribute ServiceNow's signed MID Server
container recipe (Dockerfile recipe, stock `asset/` scripts, `META-INF/`
signature, EULA, install ZIPs) — you download those from ServiceNow yourself,
as described in §3.1 of the doc.

For the narrative version of the same material, see the walkthrough:
[part 1 — deploying the in-cluster MID Server](blog-part1-DRAFT.md) and
[part 2 — the custom CI class and Discovery Pattern](blog-part2-DRAFT.md).

## Contents

| File | Purpose |
|------|---------|
| `servicenow-australia-ocpv-inventory.md` | The full end-to-end walkthrough (start here). |
| `kube_snow_disc.md` | Reference snapshot of ServiceNow's Kubernetes Discovery docs. |
| `pattern-openshift` | The full Discovery Pattern NDL for KubeVirt VMs. |
| `pattern-openshift.sh` | Create/update the pattern and PATCH the NDL into the instance. |
| `schedule-openshift.sh` | Create/update the Discovery Schedule that runs the pattern. |
| `pattern-openstack` | Reference OpenStack pattern NDL (unrelated, kept for comparison). |
| `ca.sh` | Manual MID JVM truststore import / Java TLS validation. |
| `mid_kubevirt_preflight.sh` | Verify MID pod CA trust, SA token, and KubeVirt API reachability. |
| `asset/import_ocp_service_ca.sh` | MID pod startup hook that trusts the OpenShift service-network CA. |
| `snow-mid.yaml` | MID Server Secret + Deployment **template** (placeholder credentials). |
| `Dockerfile` | The recipe Dockerfile with the §3.2.3 customizations applied. |
| `blog-part1-DRAFT.md` | Blog draft, part 1: deploy a CA-trusted in-cluster MID Server. |
| `blog-part2-DRAFT.md` | Blog draft, part 2: custom VM CI class, Discovery Pattern, schedule, verify. |
| `images/` | Screenshots used by the walkthrough. |

## Credentials

No real credentials live in this repository. `snow-mid.yaml` and
`mid.env` carry placeholders only — supply your own instance URL, MID user
password, and image reference at deploy time. `.gitignore` blocks the
secret-bearing and cluster-specific runtime artifacts from ever being
committed.

## Usage

Follow [`servicenow-australia-ocpv-inventory.md`](servicenow-australia-ocpv-inventory.md)
top to bottom. The download snippets in the doc pull these scripts straight
from this repo, e.g.:

```bash
REPO_RAW=https://raw.githubusercontent.com/MoOyeg/snow-ocpv-discovery/main
curl -fL -o pattern-openshift     "${REPO_RAW}/pattern-openshift"
curl -fL -o pattern-openshift.sh  "${REPO_RAW}/pattern-openshift.sh"
chmod 755 pattern-openshift.sh
```

## License

MIT — see [LICENSE](LICENSE). ServiceNow's MID Server recipe and the
OpenShift cluster certificates are **not** covered by this license and are
not included here.
