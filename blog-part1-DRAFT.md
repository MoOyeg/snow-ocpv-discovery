Title: How to set up OpenShift Virtualization ServiceNow CMDB discovery: deploying an in-cluster MID Server (part 1)
Meta title: OpenShift Virtualization ServiceNow CMDB: MID setup
Meta description: Why stock Kubernetes discovery misses KubeVirt VMs, and how to deploy a least-privilege, CA-trusted in-cluster MID Server for ServiceNow CMDB discovery.
URL slug: openshift-virtualization-servicenow-cmdb-mid-server-setup

---

A virtual machine (VM) that is missing from the configuration management database (CMDB) is invisible to the rest of IT. Change management never sees it. Incident routing cannot find its owner. License reconciliation skips it. That matters right now, because Red Hat OpenShift Virtualization is increasingly the landing zone for VMware migrations. Teams expect migrated VMs to show up in ServiceNow the way the old hypervisor VMs always did.

Here is the trap I keep running into. When you point ServiceNow stock Kubernetes discovery at an OpenShift Virtualization cluster, it imports pods, deployments, and nodes. KubeVirt VMs, however, only ever land as virt-launcher pod rows. They never become VM configuration items (CIs).

By the end of this article, I will have a registered ServiceNow MID Server (Management, Instrumentation, and Discovery) running inside the cluster. It will be trusted by the right certificate authority (CA) and scoped to least-privilege access. This is part 1 (setup) of a two-part series. Part 2, ["How to discover OpenShift Virtualization VMs as ServiceNow CMDB configuration items with a custom Discovery Pattern (part 2)"](PUBLISH_URL_PART2), builds the pattern on this foundation.

## Why stock Kubernetes discovery fails for KubeVirt VMs

The stock ServiceNow Kubernetes pattern is broad and noisy. It pulls every pod, deployment, replicaset, service, and node into CMDB, far more than I want if I only care about VMs. Worse, KubeVirt (the upstream project behind OpenShift Virtualization) runs each VM inside a virt-launcher pod, so those VMs map to virt-launcher pod CI rows and never get classified as a VM CI. The surgical alternative is to skip the stock pattern entirely. Instead, I create a custom VM CI class and a purpose-built Discovery Pattern that calls the KubeVirt application programming interface (API) directly and creates exactly one VM CI per VirtualMachine object. I build that pattern in part 2. The architecture at a glance: an in-cluster MID Server uses its pod-mounted service account token to call the KubeVirt API, and the custom pattern turns each VirtualMachine into a custom VM CI.

## Prerequisites

Before I start, I confirm the following are in place:

- OpenShift 4.14 or later, with the Red Hat OpenShift Virtualization operator healthy and at least one running VirtualMachine to inventory.
- The OpenShift command-line interface (oc), logged in as cluster-admin.
- A ServiceNow instance on the Australia release family (ServiceNow names releases alphabetically) with admin or equivalent Discovery and CMDB access.
- Outbound HTTPS connectivity from the cluster to the ServiceNow instance.
- The Discovery plugin activated, which provides the Pattern engine and Pattern Designer.

I tested this against the ServiceNow Australia release. For the full plugin table, including the optional Certificate Management plugin, see sections 0 and 1 of the runbook.

## Deploy a CA-trusted in-cluster MID Server

### Step 1 — create a least-privilege service account and role-based access control (RBAC)

On the cluster, I create a servicenow-discovery project and a snow-discovery service account inside it. Then I bind only the kubevirt.io:view ClusterRole to that service account. This pattern reads kubevirt.io/v1 resources and nothing else, so kubevirt.io:view is the minimum viable permission. I deliberately avoid cluster-reader, which grants read access to every other resource I never touch here. Because the MID Server runs inside the cluster, it authenticates with the pod-mounted service account token automatically, so I never copy a Kubernetes bearer token into ServiceNow. See runbook section 2 for the exact commands and validation checks.

### Step 2 — create the MID Server user in ServiceNow

A MID Server needs an instance account to connect back. In ServiceNow, I create a user named mid.user, set and record a strong password, then add the mid_server role to that user. As a sanity check, I confirm mid.user appears under MID Server users.

![ServiceNow user administration form creating the mid.user MID Server account](images/mid-user-create.png)

![Adding the mid_server role to the mid.user account in the ServiceNow Roles related list](images/mid-rbac.png)

See runbook section 3.1 for the field-by-field walkthrough.

### Step 3 — build the MID Server image with the OpenShift service-CA startup hook

ServiceNow ships a container recipe that I build into my own image. There is one load-bearing problem to solve while building it. The bundled Java runtime carries its own truststore, which has no reason to trust the OpenShift internal kube-apiserver-service-network-signer CA. So out of the box, every fresh MID pod fails TLS to the in-cluster Kubernetes API, and the discovery probes never connect. I could fix one pod by hand with a keytool import, but that trust lives in the pod ephemeral filesystem and evaporates the moment the pod is rescheduled, scaled, or rolled. Instead, I add a startup hook that re-imports the correct CA on every pod start, before the MID wrapper runs. Restarted pods then come up already trusting the API server. Runbook section 3.2 covers this and the import_ocp_service_ca.sh companion script that performs the import.

![ServiceNow MID Server download page showing the Linux Docker container recipe for the Australia release](images/mid-download.png)

### Step 4 — deploy the MID Server and confirm CA trust

The critical field in the Deployment is serviceAccountName set to snow-discovery. That single line gives the MID pod the kubevirt.io:view permission from step 1 through the pod-mounted token, so the part 2 pattern can read the KubeVirt API with no credential record in ServiceNow. I set imagePullPolicy to Always, or use immutable image tags, so a rollout restart never comes back on a cached image missing the startup hook. Before I touch ServiceNow Pattern Designer, I run the mid_kubevirt_preflight.sh companion script from a machine with oc access. It uses the running pod token and CA, then checks the MID Java truststore alias. The preflight must print a VirtualMachineList with HTTP_STATUS=200 and JAVA_HTTP_STATUS=200. That Java check matters: the pod-mounted ca.crt is a bundle, and the Java runtime must trust the service-network-signer certificate specifically. A plain curl can succeed while the Java runtime still fails, so I trust the JAVA_HTTP_STATUS line, not curl. See runbook section 3.3 and the preflight script.

![ServiceNow MID Server record detail view with the Validate action for the in-cluster OpenShift MID Server](images/mid-server-detail.png)

## Common issues and troubleshooting

A few failures come up often. Each one has a clear cause and fix:

- The MID pod is in CrashLoopBackOff: the instance URL or credentials in the Secret are wrong. Fix the Secret and restart.
- The MID Server shows Down after roughly five minutes: outbound port 443 is blocked or a proxy is in the way. Open the egress path.
- The log shows SSLPeerUnverifiedException or PKIX path building failed: the Java runtime does not trust the service-network CA. Confirm the in-cluster endpoint is used, then re-run the CA import or rebuild with the hook.
- The preflight reports "alias does not exist": the image lacks the hook, or the pod did not restart onto the rebuilt image.

The full symptom matrix lives in the runbook troubleshooting cheatsheet.

## Tips and best practices

Keep RBAC minimal. Only widen it to a pod-list view later if you want the virt-launcher pod name column in part 2. Bake CA trust into the image rather than patching a live pod, so the trust survives every reschedule. Pin the recipe revision to the ServiceNow release you tested against.

## Wrap up

At this point I have a least-privilege service account, a MID Server user, a CA-trusted image, and a running in-cluster MID Server. The success check is twofold: in ServiceNow, MID Server > Servers shows the server Up and Validated, and the cluster-side preflight returns JAVA_HTTP_STATUS=200 along with a VirtualMachineList.

![ServiceNow MID Server record showing status Up and Validated true for the in-cluster MID Server](images/mid-server-validated.png)

## Next steps

Clone and follow [the full runbook on GitHub](https://github.com/MoOyeg/snow-ocpv-discovery). To learn more about the platform behind these VMs, explore [Red Hat OpenShift Virtualization](https://www.redhat.com/en/technologies/cloud-computing/openshift/virtualization). With the MID Server registered and trusted, continue with [part 2, "How to discover OpenShift Virtualization VMs as ServiceNow CMDB configuration items with a custom Discovery Pattern"](PUBLISH_URL_PART2), which builds the custom CI class and pattern on this foundation.
