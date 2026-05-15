 Updated March 23, 2026 24 minutes to read
The ServiceNow ITOM Visibility finds Kubernetes and OpenShift components using patterns and creates application services containing them. Discovery also finds Kubernetes events and frequently updates the CMDB to reflect the dynamic Kubernetes environment.

Discovery uses the Kubernetes pattern and its extension sections to discover Kubernetes components:
The Collect OpenShift info extension section of the Kubernetes pattern discovers the OpenShift components of the Kubernetes deployment. The OpenShift Build Config extension section is available from Store version 1.0.53.
The Service Mesh extension discovers service mesh details. This information enables the pattern to create service-to-service relations, shown as Connects to::Connected. Service mesh discovery requires deploying Istio on your K8s (Kubernetes) cluster. The Service Mesh extension section is available from Kubernetes extension classes. It’s supported on the ServiceNow AI Platform using the Madrid release or later.
The Collect Container Repository and extension section finds container registries and images in these registries.
In addition, Discovery uses the Kubernetes Event pattern to discover events for Kubernetes components.

From the 1.0.68 release on ServiceNow Store, Service Mapping can use CI relationships to add the Kubernetes components to application services during tag-based discovery.

Discovery uses the following patterns to discover the entire Kubernetes infrastructure deployed on GCP, AWS, and Azure:
Google Cloud Platform (GCP) – Get Kubernetes Clusters.
Amazon AWS Cloud - Get Kubernetes Clusters.
Microsoft Azure - Get Kubernetes Clusters.
These patterns query the Cloud, collect data on all Kubernetes clusters, and create a serverless schedule for each cluster. When the cluster is deleted, the schedule is marked as inactive. This feature eliminates the overhead of creating and managing multiple credentials and serverless discovery schedules per cluster. The Cloud infrastructure patterns are triggered through standard Cloud discovery.
Supported versions
The patterns have been validated with the following Kubernetes and Red Hat OpenShift versions:
Validated Kubernetes and OpenShift versions
Platform/pattern	Validated version
On-Premises Kubernetes	1.34
Google Kubernetes Engine (GKE)	1.34
Azure Kubernetes Engine (AKS)	1.34
Amazon Elastic Kubernetes Service (EKS)	1.34
Kubernetes Event patterns	1.34
OpenShift	4.19.20
Request apps on the Store
Visit the ServiceNow Store to view all the available apps, and for information about submitting requests to the store. For cumulative release notes information for all released apps, see the ServiceNow Store version history release notes.

Prerequisites
Note:
For prerequisites for Kubernetes Cloud infrastructure discovery, see below.
Note:
Running automatic serverless Kubernetes schedules fetches the Bearer token. Adding credentials is unnecessary.
Perform the following steps so that Discovery can use the pattern to successfully find Kubernetes.
Deploy the latest Discovery and Service Mapping Patterns application from ServiceNow Store.
On the Kubernetes platform, find the parameters to set up Kubernetes discovery:
Find the URL of the kubeapi server:
On the Kubernetes platform, run the following command:
kubectl cluster-info

In the output, find the line that states the URL of the kubeapi server. For example, Kubernetes control plane is running at
https://10.154.144.146:443

Find the namespaces of the kubeapi server:
On the Kubernetes platform, run this command:
kubectl get namespaces

In the output, find the line that states the namespaces. For example, kube-system.
Find the Kubernetes username and password:
On the Kubernetes platform, run this command:
kubectl config view

In the output, find the username and password.Locate the lines that contain information on password and username.
Note:
If in a certain environment, kubectl config view command is not showing the expected details, use the supported command from the Kubernetes admin to fetch the user name and password details.
Find the valid Bearer token with the proper permissions:
If you know the default token name, use the command in the following format: kubectl describe secret <default-token-token name>.

For example: kubectl describe secret default-token-g6pwc.

If you don't know the default token name, use the command: kubectl describe secret.
Verify that the API Server is reachable from the MID Server for successful Kubernetes discovery.
Verify that the user configured on the Kubernetes platform has GET permissions to run the following /api/v1 elements:
https://<url>/api/v1/namespaces/
https://<url>/api/v1/namespaces/<namespace>
https://<url>/api/v1/namespaces/kube-system/endpoints/kube-controller-manager
https://<url>/api/v1/services
https://<url>/api/v1/pods
https://<url>/api/v1/nodes
https://<url>/api/v1/replicationcontrollers
https://<url>/apis/networking.k8s.io/v1/ingresses
https://<url>/apis/apps/v1/deployments
https://<url>/apis/apps/v1/statefulsets
https://<url>/apis/apps/v1/daemonsets
https://<url>/apis/apps/v1/replicasets
https://<url>/apis/batch/v1/cronjobs
https://<url>/apis/batch/v1/jobs
To discover the OpenShift components of the Kubernetes deployment, verify that the user configured on the Kubernetes platform has GET permissions to run the following /api/v1 elements:
/apis/apps.openshift.io/v1/deploymentconfigs
​/apis/build.openshift.io/v1/buildconfigs​
/apis/route.openshift.io/v1/routes​
/apis/user.openshift.io/v1/groups​
/apis/user.openshift.io/v1/users​
/apis/project.openshift.io/v1/projects​
/apis/image.openshift.io/v1/images​
/apis/image.openshift.io/v1/imagestreams
To discover service mesh information:
Deploy Istio on your K8s cluster.
Provide the Prometheus URL.
Configure Prometheus to scrape metrics from Istio.
Activate Get Kubernetes Config Files extension to:
Discover configuration files.
Create tracked configuration files.
Map the configuration files workloads and services with a relationship.
Note:
Tracked files content is in the JSON format from version 1.0.92. Tracked files content is in YAML format in version 1.0.91 and earlier.
Create the Kubernetes credentials on the ServiceNow platform:
On the ServiceNow AI Platform, navigate to All > Discovery > Credentials.
Select New.
Select Kubernetes Credentials.
On the form, fill in the fields.
Field	Description
Name	Unique and descriptive name for this credential.
User name	User name associated with this credential. Leading or trailing spaces should be avoided; if any are detected, a warning will appear.
Only one authentication method should be used: either a user name and password or a Bearer token. Don't use both.

Password	Password associated with this credential.
Only one authentication method should be used: either a user name and password or a Bearer token. Don't use both.

Bearer Token Authentication	This option enables advanced authentication using a Bearer token.
When the check box is selected, the Bearer Token field is displayed.

Bearer Token	Discovery uses the Bearer token for advanced authentication when accessing Kubernetes.
The Bearer token should be in BASE64 encoded format, using the character sequence as the token. For example: 31ada4fd-adec-460c-809a-9e56ceb75269.

Only one authentication method should be used: either a user name and password or a Bearer token. Don't use both.

Credential alias	An alias is configured to use the Kubernetes credential for devices and applications other than Kubernetes. This alias is also used when defining a serverless discovery schedule for discovering the Kubernetes deployment.
Select the padlock icon, and then select the search icon.
On the Connection & Credential Aliases form, select New.
Specify a name for the credential alias record.
Define attributes for the alias. Set the Type to Credential.
Select and hold (or right-click) the form header and select Save, then select Update.
On the Connection & Credential Aliases form, select the newly added alias.
The alias appears in the Credential alias field.

On the Kubernetes credentials form, select Update.
Create a serverless discovery schedule for the Kubernetes pattern.
Create and define the serverless execution pattern as described in the product documentation. Configure the parameters required by the Kubernetes pattern as follows:
Configuring execution pattern attributes
Field	Description
url	The identifier for the hostname, IP, or FQDN and the port of the Kubernetes apiserver. Use the following format: example_hostname:example_port or xample_ip:example_port. Provide the correct protocol (HTTP or HTTPS) in the URL.
namespace	The namespaces that the system passes in the Kubernetes Discovery Configuration. Enter one of the following values:
Individual namespace: enter the namespace and then "kube-system". For example: dev,kube-system
The default value: enter default, kube-system
Multipile namespaces: enter the namespaces, use a comma (,) to separate the values, and then enter "kube-system". For example: automation,application,test,kube-system
All namespaces: Use an asterisk (*) to enter all namespaces
credentials alias	The alias associated with the previously created Kubernetes credentials.
cluster name	The name of the Kubernetes cluster, in the following format: <serviceaccountid><space><clustername>.
provider	The cloud provider: GCP or AWS or Azure.
cluster_resource_id	Cluster resource ID example:
Azure Kubernetes clusters- Resource ID.
AWS- cluster ARN.
GCP- cluster global name.
Create a serverless discovery schedule for the Kubernetes Event pattern. Configure the schedule to run every 5 or 10 minutes.
Note:
When the pattern is run for the first time, it stores an event_timestamp. Later on it collects only the delta events based on the timestamp. The more often the pattern is run, the fewer updates to the CMDB IRE are needed.
Create a serverless execution pattern for the discovery schedule and assign it to the Kubernetes Events pattern. Configure the parameters required by the Kubernetes pattern as described in Configuring execution pattern attributes.

To include discovered components into service instances, enable CI relationships used in tag-based discovery by Service Mapping. These CI relationships are available from the 1.0.68 release on the ServiceNow Store. For operational steps, see Tag-based discovery configuration.
Prerequisites for Kubernetes Cloud infrastructure discovery
For the Google Cloud Platform (GCP) – Get Kubernetes Clusters pattern, perform the following:

In the ServiceNow instance, set up a Google Cloud Platform (GCP) service account with valid credentials and permissions.
On the GCP infrastructure, set up the MID Server with full access to all Cloud APIs: Set Cloud API access scopes to "Allow full access to all Cloud APIs". The MID Server instance can access only the Clusters specific to the project.
Navigate to sys_properties.list and configure the following properties:
sn_itom_pattern.k8s_midserver: Specify a valid MID Server name.
sn_itom_pattern.k8s_create_schedule_enabled: Set the value to true.
Note:
Enabling the sn_itom_pattern.k8s_create_schedule_enabled property automatically creates a serverless schedule for your cloud clusters, eliminating the need for manual scheduling. If you have an existing manual schedule and want to convert it to an automatic one, enable the property. Your manual schedule will be updated; no additional schedule will be created.
Create and run Google Cloud Discovery
Note:
To fetch the Bearer token, while running GKE Kubernetes schedule, use the gcloud command:

gcloud config config-helper --format="value(credential.access_token)"

Configuring gcloud in the MID Server instance grants access to the GKE cluster to fetch the token.

For the Amazon Elastic Kubernetes Service (EKS) cluster discovery, perform the following:

In the ServiceNow instance, set an AWS service account with valid management account credentials and permissions.
Verify that the Amazon Elastic Kubernetes Service (EKS) Cluster has a cluster role with the read-only access to all resources.
Create cluster role binding between the cluster role and a Kubernetes user. For example, read-onlyuser.
Create an AWS IAM role with the policy EKSReadOnly.
Associate the IAM role with the Kubernetes user in one of the following ways:
In the cluster, edit the aws-auth ConfigMap.
Run the command:
eksctl create iamidentitymapping --cluster yourClusterName --arnarn:aws:iam::yourAccountID:role/yourIAMRoleName --username read-only-user

Run Amazon Elastic Kubernetes Service (EKS) cluster discovery in one of two ways: Using the AWS Command Line Interface (CLI) or without using the AWS CLI. First, set the system property sn_itom_pattern.k8s_aws_cli_to_generate_token to use the model you choose. This system property is set to true by default.

Set this system property to true to use AWS CLI to generate a token.

Set this system property to false to use Assume Roles to generate a token.

Run Amazon Elastic Kubernetes Service (EKS) cluster discovery using AWS CLI:

Set up the MID Server with the AWS CLI configured. Configuring AWS CLI credentials grants access to the Amazon Elastic Kubernetes Service (EKS) cluster.

Note:
The user logged in to the system must be the same as the MID Server user.
To generate the Bearer token, While running the Amazon Elastic Kubernetes Service (EKS) schedule, use the AWS CLI command:aws eks get-token --cluster-name <cluster_name>.

Configuring the AWS CLI user/role in the MID Server instance grants access to the Amazon Elastic Kubernetes Service (EKS) cluster to generate the token.

Run Amazon Elastic Kubernetes Service (EKS) cluster discovery without using AWS CLI:

Note:
This feature is supported from Discovery and Service Mapping Patterns version 1.0.96 - December 2022.

Refer to the following KB for detailed instructions: KB1182188: EKS cluster discovery using STS AssumeRoles (Without AWS CLI)

Navigate to sys_properties.list and configure the following properties:
sn_itom_pattern.k8s_midserver: Specify a valid MID Server name.
sn_itom_pattern.k8s_create_schedule_enabled: Set the value to true.
Note:
Enabling the sn_itom_pattern.k8s_create_schedule_enabled property automatically creates a serverless schedule for your cloud clusters, eliminating the need for manual scheduling. If you have an existing manual schedule and want to convert it to an automatic one, enable the property. Your manual schedule will be updated; no additional schedule will be created.
Create and run an AWS Cloud Discovery schedule.

For Microsoft Azure Kubernetes Services (AKS)- Kubernetes cluster discovery, perform the following:

Update to the latest Discovery and Service Mapping Patterns version.
In the ServiceNow instance, configure the Azure Service Account with valid Azure credentials and permission.
Navigate to sys_properties.list and configure the following properties:
sn_itom_pattern.k8s_midserver: Specify a valid MID Server name.
sn_itom_pattern.k8s_create_schedule_enabled: Set the value to true.
Note:
Enabling the sn_itom_pattern.k8s_create_schedule_enabled property automatically creates a serverless schedule for your cloud clusters, eliminating the need for manual scheduling. If you have an existing manual schedule and want to convert it to an automatic one, enable the property. Your manual schedule will be updated; no additional schedule will be created.
.
If you don't have local accounts with Kubernetes RBAC and want to improve pattern efficiency, navigate to MID Server > Properties and set the sn_itom_pattern.aks_fetch_local_ad_token property to false.
Run an Azure cloud discovery schedule.
Configure the MID Server in the Discovery schedules according to the cluster account type. If you don't have Local accounts with RBAC, you can ignore this step.

Cluster account type	Discovery schedule MID Server
MS Entra ID auth with Kubernetes RBAC.

Any MID Server.

MS Entra ID authentication with Azure RBAC.

Any MID Server.

Local accounts with Kubernetes RBAC.

Select the MID Server with the Azure Command Line Interface (CLI) configured. Configuring the Azure CLI credentials grants access to the AKS cluster.

To fetch the Bearer token while running the AKS Kubernetes schedule, use the Azure CLI command: az aks get-credentials --name <cluster_name> --overwrite-existing --resource-group <resourceGroup_name> --file -.

Note:
The user logged in to the system must be the same as the MID Server user.
For detailed information about AKS Cluster Discovery configuration, see the AKS Cluster Discovery Configuration Details [KB1220553] article in the Now Support Knowledge Base.
Other Supported System configuration
Property name	Property description	Type	Default value
sn_itom_pattern.manifest_digest_image_id

Boolean	
false

Note:
Before setting this property to true and running discovery: avoid duplicate records from being created by deleting all Docker image records.
sn_itom_pattern.k8s_create_schedule_enabled

The feature flag that can be enabled/disabled under the system properties, which is responsible to control the pattern execution. When enabled, it creates discovery schedules despite the new property value.

Boolean	false
sn_itom_k8s_run_cloud_discovery	When enabled, this property executes cloud Kubernetes patterns, discovering Kubernetes clusters without creating auto schedules.	Boolean	false
MID Server	
sn_itom_pattern.k8s_midserver

[Default]

Example- Valid MID Server name

String	
sn_itom_pattern.k8s_<service_account_id>_midserver

[Based on Service Account Level]

Example- Valid MID Server name

String	
sn_itom_pattern.k8s_<service_account_id>_<clustername>_midserver

[Based on Cluster name]

Example- Valid MID Server name

String	
sn_itom_pattern.kubernetes_collect_volume

When the property is set to True, the data for Kubernetes Volume [cmdb_ci_kubernetes_volume] gets populated.

String	false
sn_itom_pattern.k8s_add_workload_to_image_relation

Starting from Discovery and Service Mapping Patterns version 1.30.2, the Kubernetes patterns create an indirect-only relationship between Docker Image and workload CIs through Kubernetes Pods. Setting the property to true also creates direct relationships between Docker Image and the following workload CI types: Deployment, DaemonSet, ReplicaSet, StatefulSet, and ReplicationController.	Boolean	false
Credential Alias	
sn_itom_pattern.k8s_ cred_alias

[Default]

Example- credential alias name

String	
sn_itom_pattern.k8s_<service_account_id>_alias

[Based on Service Account Level]

Example- Valid credential alias name.

String	
sn_itom_pattern.k8s_<service_account_id>_<clustername>_alias

[Based on Cluster name]

Example- Valid credential alias name.

String	
Prometheus Url	
sn_itom_pattern.k8s_ prometheusUrl

[Default]

Example- Valid Prometheus Url

String	
sn_itom_pattern.k8s_<service_account_id>_prometheusUrl

[Based on Service Account Level]

Example- Valid Prometheus Url

String	
sn_itom_pattern.k8s_<service_account_id>_<clustername>_prometheusUrl

[Based on Cluster name]

Example- Valid Prometheus URL

String	
sn_itom_pattern.k8s_ run

[Supported Discovery Schedule run- Daily, On Demand, Weekdays, Weekends, Month Last Day, Calendar Quarter End]

Example- Daily

String	
sn_itom_pattern.k8s_batch_count

[Refers how many schedules to run in batch – default set to 5]

Example- 5 (Number of schedules to run in on batch)

Integer	5
sn_itom_pattern.k8s_schedule_batch_delay

[keeps tracks of the time difference between two batches value contains in sec]

Example- 300 (in seconds)

Integer	
sn_itom_pattern.k8s_run_time

[keeps tracks of the current time for a batch]

If this property is set, then you can use the same or you can use the dynamic timing, which will be 5 min after the system current timing. Values contains in HH:MM:SS format

Example- 10:11:12 (HH:MM:SS )

String	
Note:
<service_account_id> is the account ID name under Cloud Service Accounts. For more information, see: Create Discovery schedules for cloud resources
Kubernetes Credential-less or mid-in-cluster discovery
Prerequisites for Kubernetes Credentials-less discovery:

Deploy the containerized MID Server to the Kubernetes cluster. Configuring Kubernetes credentials is unnecessary since the MID Server in Kubernetes cluster automatically discovers the API server and authenticate.

Configuring execution pattern attributes for Credentials-less discovery
Field	Description
URL	
Enter any one the of following value in URL field:

https://cluster

Or

https://kubernetes.default.svc

namespace	
The namespaces that the system passes in the Kubernetes Discovery Configuration. Enter one of the following values:

Individual namespace: enter the namespace and then "kube-system". For example: dev,kube-system
The default value. Enter:default,kube-system
Multipile namespaces: enter the namespaces, use a comma (,) to separate the values, and then enter "kube-system". For example: automation,application,test,kube-system
All namespaces: Use an asterisk (*) to enter all namespaces.
cluster_name	Enter Unique name.
Data collected by Discovery during horizontal discovery
Table and field	Description
Kubernetes Cluster [cmdb_ci_kubernetes_cluster]
Name	The name of the kube-controller-manager leader.
K8s_uid	The kube-system namespace UID [supported versions: 1.0.92 and later]
ip_address	The identifier for the host_ip of the Kubernetes apiserver.
port	
The identifier for the Kubernetes apiserver port.

namespace	This value shows the namespaces the system passed in the Kubernetes Discovery Configuration.
event_timestamp	The timestamp of the latest event created on this Kubernetes cluster at the time of the discovery.
Kubernetes Node [cmdb_ci_kubernetes_node]	The virtual aspect of the Kubernetes node. Data relating to the physical aspect of the Kubernetes node is stored under Linux server.
name	The name of the Kubernetes node. The format can be only the name of the machine or the full name consisting of the name and the hostname: <name>.<hostname> .
k8s_uid	The identifier for the Kubernetes node UUID.
cluster	The name of the cluster that contains this resource.
operational_status	The operational status of the Kubernetes node.
Kubernetes Service [cmdb_ci_kubernetes_service]
name	The name of the Kubernetes service.
selector	A comma delimited list of the label selectors specified in the Kubernetes configuration that are used to select target pods.
namespace	The Kubernetes namespace to which this Kubernetes service belongs.
k8s_uid	The Kubernetes service UUID.
cluster	The name of the cluster that contains this resource.
Kubernetes Pod [cmdb_ci_kubernetes_pod]
name	The name of the Kubernetes pod.
k8s_uid	The Kubernetes pod UUID.
resourceVersion	The resource version of the Kubernetes pod.
namespace	The Kubernetes namespace to which this Kubernetes pod belongs.
cluster	The name of the cluster that contains this resource.
state	
The Kubernetes pod status: Pending, Running, Succeeded, Failed, and Unknown.

Kubernetes Cronjob [cmdb_ci_kubernetes_cronjob]
name	The name of the Kubernetes cronjob
namespace	The Kubernetes namespace to which this Kubernetes pod belongs.
k8s_uid	The Kubernetes cronjob UUID.
cluster	The name of the cluster that contains this resource.
Kubernetes Job [cmdb_ci_kubernetes_job]
name	The name of the Kubernetes Job
namespace	The Kubernetes namespace to which this Kubernetes job belongs.
k8s_uid	The Kubernetes job UUID
cluster	The name of the cluster that contains Kubernetes job.
Kubernetes Daemonset [cmdb_ci_kubernetes_daemonset]
name	The name of the Kubernetes daemonset.
namespace	The Kubernetes namespace to which this Kubernetes daemonset belongs.
k8s_uid	The Kubernetes daemonset UUID.
cluster	The name of the cluster that contains this resource.
pods_avail	The number of pods Available.
pods_failed	The number of pods in Failed phase.
pods_running	The Number of pods in the Running phase.
pods_succeeded	The number of pods in the Succeeded phase.
pods_waiting	The number of pods in the Waiting phase.
Kubernetes Ingress [cmdb_ci_kubernetes_ingress]
name	The name of the Kubernetes ingress
namespace	The Kubernetes namespace to which this Kubernetes ingress belongs.
k8s_uid	The Kubernetes ingress UID
cluster	The name of the cluster that contains this resource.
Kubernetes Deployment [cmdb_ci_kubernetes_deployment]

Kubernetes Replicaset [cmdb_ci_kubernetes_replicaset]

Kubernetes Replication controller [cmdb_ci_kubernetes_replicationcontroller]

Kubernetes Statefulset [cmdb_ci_kubernetes_statefulset]

name	The name of this resource
namespace	The Kubernetes namespace to which this resource belongs.
K8s_uid	The Kubernetes UID of this resource
cluster	The name of the cluster that contains this resource.
total_replicas	Number of replicas in this resource
desired_replicas	The number of replicas in desired phase
available_replicas	Number of replicas available
unavailable_replicas	Number of replicas in unavailable phase
updated_replicas	Number of replicas updated
Docker Container [cmdb_ci_docker_container]	The component that runs the docker image.
container_id	The unique identifier for the Kubernetes docker container
In cases where duplicate records are created, deduplication tasks appear once discovery runs. For information on how to resolve these tasks, see the Making docker container identifier independent [KB1443042] article in the ServiceNow® Knowledge Base.

namespace	The Kubernetes namespace to which this Kubernetes docker container belongs
Docker Image [cmdb_ci_docker_image]	An executable package of an application and its related software that can be instantiated by a docker container
image_id	The identifier for the Kubernetes docker image
name	The name of the Kubernetes docker image.
image_url	The URL for downloading the docker image.
namespace	The Kubernetes namespace to which this Kubernetes docker image belongs.
Linux Server [cmdb_ci_linux_server]	The server that hosts the Kubernetes node.
name	The name of the Linux server powering the Kubernetes node.
hostname	The hostname of the Linux server.
os	The operating system deployed on this Linux server.
kernel_release	The version of the Linux kernel operating system deployed on this Linux server.
ram	The size of RAM installed on this Linux server.
ip_address	The IP address of the Linux server.
cpu_type	The CPU architecture of the Linux server hosting the Kubernetes node.
cpu_count	The number of CPUs on the Linux server hosting the Kubernetes node.
serial_number	The serial number of the Linux server hosting the Kubernetes node.
Key Value [cmdb_key_value]	This configuration item contains Kubernetes labels. Labels are key/value pairs that are attached to objects, such as pods.
key	The key of the Kubernetes pod or Kubernetes service Key Value parameter.
value	The value of the Kubernetes pod or Kubernetes service Key Value parameter.
Kubernetes Volume [cmdb_ci_kubernetes_volume]
k8s_uid	The Kubernetes volume UUID.
mount_path	The path for accessing this Kubernetes volume.
name	The name of the Kubernetes volume.
namespace	The Kubernetes namespace to which this Kubernetes volume belongs.
cluster	The name of the cluster that contains this resource.
volume_id	The ID of the Kubernetes volume.
OpenShift Deployed Configuration [cmdb_ci_openshift_dep_conf]​
name	The name of the OpenShift Deployment configuration.
namespace	The name of the namespace containing the deployment configuration.
k8s_uid	The Kubernetes volume UUID.
url	The URL of the OpenShift deployed configuration, available only for Kubernetes versions earlier than 1.16.
OpenShift Build Config [cmdb_ci_openshift_build_conf]
name	The name of the OpenShift build configuration.
namespace	The name of the OpenShift namespace containing the build configuration.
k8s	The Kubernetes volume UUID.
url	The URL of the OpenShift build configuration, available only for Kubernetes versions earlier than 1.16.
OpenShift Source2Image [cmdb_ci_openshift_source_2_image]
name	The name of the OpenShift source image.
to	Related image.
parent_id	The ID of the OpenShift source image.
OpenShift Route [cmdb_ci_openshift_route]
name	The name of the OpenShift route.
namespace	The name of the namespace containing the OpenShift route.
k8s_uid	The Kubernetes volume UUID.
url	The URL of the OpenShift Route, available only for Kubernetes versions earlier than 1.16.
host	The target host of the OpenShift route.
port	The target port of the OpenShift route.
OpenShift Group [cmdb_ci_openshift_group]
name	The name of the OpenShift Group.
k8s_uid	The Kubernetes volume UUID.
url	The URL of the OpenShift Group, available only for Kubernetes versions earlier than 1.16.
OpenShift User [cmdb_ci_openshift_user]
name	The name of the OpenShift user.
k8s_uid	The Kubernetes volume UUID.
url	The URL of the OpenShift user, available only for Kubernetes versions earlier than 1.16.
full_name	The full name of the OpenShift user.
OpenShift Project [cmdb_ci_openshift_project]
name	The name of the OpenShift project.
k8s_uid	The Kubernetes volume UUID.
url	The URL of the OpenShift Project, available only for Kubernetes versions earlier than 1.16.
OpenShift Image [cmdb_ci_openshift_images]
name	The name of the OpenShift Image.
k8s_uid	The Kubernetes volume UUID.
url	The URL of the OpenShift Image, available only for Kubernetes versions earlier than 1.16.
docker_image_metadata_id	The ID of the docker image.
docker_image_metadata_parent_id	The ID of the image parent ID.
arch	Architecture of the image.
size	The image size.
hostname	The hostname related to the image.
OpenShift Image Stream [cmdb_ci_openshift_images_stream]
name	The name of the OpenShift Image Stream.
k8s_uid	The Kubernetes volume UUID.
url	The URL of the OpenShift Image Stream, available only for Kubernetes versions earlier than 1.16.
namespace	The name of the namespace containing the OpenShift image stream.
OpenShift Docker Image Repository [cmdb_ci_openshift_docker_images_repository]
name	The name of the OpenShift docker image repository.
parent_ID	The ID of the parent system.
Namespace [cmdb_ci_kubernetes_namespace]
name	The name of the Kubernetes Namespace.
state	
The Kubernetes namespace phases: Active or Terminating.

This data is collected by the Collect Container Repository extension section.
Table and field	Description
Container Repository [cmdb_ci_container_repository]
Name [name]	The name of the container repository.
Container Repository Entry [cmdb_ci_container_repository_entry]
Name [name]	The name of the container repository entry.
Category [category]	The category of the container repository entry.
The graphic illustrates CIs that are part of Kubernetes discovery.
Note:
This Dependency Views map was simplified for clarity. Your Kubernetes deployments may contain many more CIs.
Components of the Kubernetes deployment

Relationships between Kubernetes configuration items and Kubernetes workload tables
Components of the Kubernetes deployment including OpenShift

Namespace contains OpenShift configuration items
CI relationships collected by the Kubernetes pattern
These relationships are created by Kubernetes pattern:
CI	Relationship	CI
Kubernetes Cluster [cmdb_ci_kubernetes_cluster]	Contains::Contained By	
Kubernetes Service [cmdb_ci_kubernetes_service]

Contains::Contained By	Kubernetes Pod [cmdb_ci_kubernetes_pod]
Contains::Contained By	Kubernetes Ingress [cmdb_ci_kubernetes_ingress]
Contains::Contained By	
Kubernetes Namespace [cmdb_ci_kubernetes_namespace]

Contains::Contained By	[cmdb_ci_openshift_source_2_image]
Contains::Contained By	OpenShift Group [cmdb_ci_openshift_group]
Contains::Contained By	OpenShift User [cmdb_ci_openshift_user]
Contains::Contained By	OpenShift Project [cmdb_ci_openshift_project]
Contains::Contained By	OpenShift Image [cmdb_ci_openshift_images]
Contains::Contained By	OpenShift Docker Image Repository [cmdb_ci_openshift_docker_images_repository]
Cluster of::Cluster	Kubernetes Node [cmdb_ci_kubernetes_node]
Manages::Managed by	Linux Server [cmdb_ci_linux_server]
Contained by::Contains	Resource Group [cmdb_ci_resource_group]
Kubernetes Pod [cmdb_ci_kubernetes_pod]	Contains::Contained By	Docker Container [cmdb_ci_docker_container]
Contains::Contained By	Docker Image [cmdb_ci_docker_image]
Contains::Contained By	Kubernetes Volume [cmdb_ci_kubernetes_volume]
Kubernetes Workload [cmdb_ci_kubernetes_workload]

Hosted on::Hosts	Kubernetes Cluster [cmdb_ci_kubernetes_cluster]
Kubernetes Service [cmdb_ci_kubernetes_service]	Provides::Provided By	
Kubernetes Workload [cmdb_ci_kubernetes_workload]

Kubernetes Deployment [cmdb_ci_kubernetes_deployment]

Owns::Owned By	
Kubernetes Replicaset [cmdb_ci_kubernetes_replicaset]

Kubernetes Replicaset [cmdb_ci_kubernetes_replicaset]

iInstantiates:: Instantiated By	Kubernetes Pod [cmdb_ci_kubernetes_pod]
Kubernetes Workload [cmdb_ci_kubernetes_workload]	Provided By::Provides To	Kubernetes Service [cmdb_ci_kubernetes_service]
Kubernetes Deployment [cmdb_ci_kubernetes_deployment]	Hosted on::Hosts	Kubernetes Cluster [cmdb_ci_kubernetes_cluster]
Kubernetes Daemonset [cmdb_ci_kubernetes_daemonset]	Hosted on::Hosts	Kubernetes Cluster [cmdb_ci_kubernetes_cluster]
Kubernetes Statefulset [cmdb_ci_kubernetes_statefulset]	Hosted on::Hosts	Kubernetes Cluster [cmdb_ci_kubernetes_cluster]
Kubernetes Namespace [cmdb_ci_kubernetes_namespace]​	Contains::Contained By	OpenShift Deployed Config [cmdb_ci_openshift_dep_conf​]
Contains::Contained By	OpenShift Build Config [cmdb_ci_openshift_build_conf]
Contains::Contained By	OpenShift Route [cmdb_ci_openshift_route]
Contains::Contained By	OpenShift Image Stream [cmdb_ci_openshift_images_stream]
Docker Image [cmdb_ci_docker_image]	Instantiates::Instantiated by	Docker Container [cmdb_ci_docker_container]
Linux Server [cmdb_ci_linux_server]	Contains::Contained By	Kubernetes Pod [cmdb_ci_kubernetes_pod]
Runs::Runs on	Docker Container [cmdb_ci_docker_container]
Hosts::Hosted on	Kubernetes Node [cmdb_ci_kubernetes_node]
OpenShift Deploy Config [cmdb_ci_openshift_dep_conf​]	Contains::Contained By	[cmdb_ci_config_file_tracked​]
The Collect Container Repository extension section of the Kubernetes pattern identifies these relationships.
CI	Relationship	CI
Docker Image [cmdb_ci_docker_image]	Provisioned From::Provisioned	Container Repository Entry [cmdb_ci_container_repository_entry]
Container Repository Entry [cmdb_ci_container_repository_entry]	Hosted on::Hosts	Container Repository [cmdb_ci_container_repository]
CI relationships collected by the Istio Service Mesh extension
Prerequisites for Istio Service Mesh extension:

Ensure that Istio Service Mesh and Prometheus components are configured on the Kubernetes cluster.
Ensure that Prometheus discovers the service connection information using the queryistio_requests_total command.
Ensure that the application services are connected, and verify service-to-service traffic flow in Kiali graph.
For more information on the Bookinfo application, see: https://istio.io/latest/docs/examples/bookinfo/

CI	Relationship	CI
Kubernetes Service [cmdb_ci_kubernetes_servi ce]	Connects to::Connected by	Kubernetes Service [cmdb_ci_kubernetes_servi ce]
CI relationships collected by the Kubernetes Event pattern
These relationships are created to support the Kubernetes event discovery:
CI	Relationship	CI
Kubernetes Cluster [cmdb_ci_kubernetes_cluster]	Contains::Contained By	
Kubernetes Service [cmdb_ci_kubernetes_service]

Contains::Contained By	Kubernetes Pod [cmdb_ci_kubernetes_pod]
Cluster of::Cluster	Kubernetes Node [cmdb_ci_kubernetes_node]
Manages::Managed by	[cmdb_ci_linux_server]
Kubernetes Pod [cmdb_ci_kubernetes_pod]	Contains::Contained By	Docker Container [cmdb_ci_docker_container]
Contains::Contained By	Docker Image [cmdb_ci_docker_image]
Contains::Contained By	Kubernetes Volume [cmdb_ci_kubernetes_volume]
Docker Image [cmdb_ci_docker_image]	Instantiates::Instantiated by	Docker Container [cmdb_ci_docker_container]
Linux Server [cmdb_ci_linux_server]	Contains::Contained By	Kubernetes Pod [cmdb_ci_kubernetes_pod]
Runs::Runs on	Docker Container [cmdb_ci_docker_container]
Hosts::Hosted on	Kubernetes Node [cmdb_ci_kubernetes_node]
Data collected by Service Mapping during tag-based discovery
Service Mapping uses tag-based discovery to create application service maps including the Kubernetes components. Service Mapping comes with the following preconfigured CI relationships used for tag-based discovery. These CI relationships are available from the 1.0.68 release on ServiceNow Store.
CI	Relationship	CI
Kubernetes Service [cmdb_ci_kubernetes_service]	Contained By::Contains	Kubernetes Cluster [cmdb_ci_kubernetes_cluster]
OpenShift Project [cmdb_ci_openshift_project]	Contained by::Contains	Kubernetes Cluster [cmdb_ci_kubernetes_cluster]
Kubernetes Pod [cmdb_ci_kubernetes_pod]	Contained by::Contains	Kubernetes Cluster [cmdb_ci_kubernetes_cluster]
Kubernetes Pod [cmdb_ci_kubernetes_pod]	Cluster::Cluster of	Kubernetes Service [cmdb_ci_kubernetes_service]
Kubernetes Namespace [cmdb_ci_kubernetes_namespace]​	Contains::Contained By	OpenShift Deployed Config [cmdb_ci_openshift_dep_conf​]
Kubernetes Namespace [cmdb_ci_kubernetes_namespace]​	Contains::Contained By	OpenShift Build Config [cmdb_ci_openshift_build_conf]
Kubernetes Namespace [cmdb_ci_kubernetes_namespace]​	Contains::Contained By	OpenShift Route [cmdb_ci_openshift_route]
Kubernetes Namespace [cmdb_ci_kubernetes_namespace]​	Contains::Contained By	OpenShift Image Stream [cmdb_ci_openshift_images_stream]
Kubernetes dashboard
After Discovery finishes discovering components of the Kubernetes deployment, you can navigate to Workspaces > Discovery Admin Workspace > Insights and use the Kubernetes Explorer dashboard to view the Kubernetes environments and resources of your organization. To use the enhanced Kubernetes dashboard, verify you have Discovery Admin Workspace starting from version 1.3.1 (August 2024 Store). For more information about Kubernetes Explorer, see Kubernetes Explorer.

Troubleshooting
If the mapping process does not proceed as you expected, follow the following suggestions.
Symptom	Cause	Solution
Discovery fails. The discovery message contains the information about an error caused by the REST timeout.	There are many CIs sending the REST call response in the deployment. The MID Server cannot process the REST call response without exceeding the time limit controlled by the mid.sa.cloud.request_timeout parameter.	By default, the mid.sa.cloud.request_timeout parameter is set to 30000 milliseconds.
Increase the value of this parameter on the relevant MID Server and run discovery again.
Note:
If the Configuration Parameters related list for the relevant MID Server does not show this parameter, you may need to add it.
Pattern Designer fails during a debug session. The Pattern Designer message contains information about an error caused by a timeout.	The Pattern Designer fails because of a timeout during pattern debugging (and not during discovery).	By default, the sa.debugger.max_timeoutparameter is set to 240 seconds.
Increase the value of this parameter on the relevant MID Server.

To run the Kubernetes pattern in Debug mode, refer to KB0832567 for operational information.

Container image scanning for software decomposition
The ITOM Visibility apps, Discovery and Service Mapping Patterns and Kubernetes Visibility Agent integrate with Aqua Trivy to collect data on container images and OS packages. You can increase your control over container deployment by having visibility to the container components.