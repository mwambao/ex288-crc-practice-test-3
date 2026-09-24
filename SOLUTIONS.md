# Practice Exam 3 — Solutions

> Use these only after attempting the questions. Replace `<GIT_BASE>` with your reachable Git base URL.

## Q1
### Option A — Web console
1. Create project **sapphire**. Use **Developer → +Add → Import from Git** with `<GIT_BASE>/pt3-q1-catalog.git`; select the Node.js builder if needed and name it **catalog**.
2. Add build environment `npm_config_registry=https://registry.npmjs.org/` before creating the application, or add it later to the BuildConfig environment.
3. In Topology create/open the Route. Inspect the BuildConfig/Build logs if the application does not deploy.
4. Open the Deployment and set CPU/memory requests and limits using the resource controls or YAML editor.
5. Scale the Deployment to **2** replicas from Topology/Deployment details and add the required workload labels in the Deployment YAML/metadata.
6. Verify both pods are Ready and open the Route.

### Option B — CLI
```bash
# Create the project required by the task.
oc new-project sapphire
# Create an S2I app from the Node.js builder and Git source, and pass the dependency registry to the build.
oc new-app nodejs:20-ubi9~<GIT_BASE>/pt3-q1-catalog.git --name=catalog --build-env=npm_config_registry=https://registry.npmjs.org/
# Follow the build so source/build failures are visible immediately.
oc logs -f bc/catalog
# Expose the Service through an OpenShift Route.
oc expose svc/catalog
# Apply CPU and memory requests/limits to the Deployment.
oc set resources deploy/catalog --requests=cpu=100m,memory=128Mi --limits=cpu=500m,memory=256Mi
# Run two application replicas.
oc scale deploy/catalog --replicas=2
# Add the required workload labels.
oc label deploy/catalog app.kubernetes.io/part-of=pt3 environment=practice
# Verify the route response.
curl http://$(oc get route catalog -o jsonpath='{.spec.host}')
# Verify the latest build status.
oc get builds --sort-by=.metadata.creationTimestamp
```
Reference: Red Hat OCP 4.18, Building applications / creating applications and S2I builds.

## Q2
### Option A — Web console / UI-assisted
1. Create project **bronze**. Go to **+Add → Import from Git**, enter `<GIT_BASE>/pt3-q2-container.git`, use **Edit import strategy**, and explicitly choose **Dockerfile**. Name it **container-web**.
2. Open **Builds → BuildConfigs → container-web → YAML**. Confirm `dockerStrategy`, set the required `ARTIFACT_URL` build argument, and ensure output targets ImageStreamTag `container-web:1.0`.
3. Start a build from the BuildConfig page and inspect logs. If it fails, check strategy, Git context, Containerfile path and artifact reachability before changing anything else.
4. Deploy the resulting ImageStreamTag from **+Add → Container images** (or from the ImageStream action) as `container-web`.
5. Inspect/edit the Deployment trigger so it tracks `container-web:1.0`; then create a Route from Topology.
6. Rebuild the image and use rollout/build pages to verify the image-change behavior.

### Option B — CLI
```bash
# Create an isolated project.
oc new-project bronze
# Create the destination ImageStream.
oc create is container-web
# Generate a Docker-strategy BuildConfig from Git without starting it yet.
oc new-build <GIT_BASE>/pt3-q2-container.git --name=container-web --strategy=docker --to=container-web:1.0
# Set the Docker build argument consumed by the Containerfile.
oc set env bc/container-web ARTIFACT_URL=http://artifact-mock.lab-infra.svc:8080/banner.txt
# Verify the selected build strategy before spending time on a build.
oc get bc container-web -o jsonpath='{.spec.strategy.type}{"\n"}'
# Start the build and stream its output.
oc start-build container-web --follow
# Deploy the resulting ImageStream tag.
oc new-app container-web:1.0 --name=container-web
# Configure deployment image-change tracking from the ImageStream.
oc set triggers deploy/container-web --from-image=container-web:1.0 -c container-web
# Expose the application.
oc expose svc/container-web
# Inspect build details when troubleshooting.
oc describe build $(oc get builds -o name | tail -1)
```
Reference: OCP 4.18 Building applications: Docker build strategy, BuildConfig, build inputs and ImageStreams.

## Q3
### Option A — Web console / UI-assisted
1. Create project **nebula**. Clone/edit/push the supplied custom S2I repository locally because `.s2i/bin/assemble` is source code.
2. Use **+Add → Import from Git**, select the HTTPD builder explicitly, and create **stellar**.
3. Open **Builds → BuildConfigs → stellar** and verify the strategy is Source/S2I. Inspect its triggers and ensure a ConfigChange trigger exists; use YAML editing if the form does not expose it.
4. Start a new build from the BuildConfig page and inspect logs for execution of the custom assemble script.
5. Create a Route from Topology.
6. Open `/` and `/build-info.html`, and use Build/Pod logs to troubleshoot missing generated content.

### Option B — CLI
```bash
# Create the project.
oc new-project nebula
# Create the S2I application using the explicit HTTPD builder.
oc new-app httpd:2.4-ubi9~<GIT_BASE>/pt3-q3-s2i.git --name=stellar
# Follow the S2I build and confirm the custom assemble script is executed.
oc logs -f bc/stellar
# Ensure a ConfigChange trigger exists.
oc set triggers bc/stellar --from-config
# Start another build manually.
oc start-build stellar --follow
# Expose the service.
oc expose svc/stellar
# Verify the main page.
curl http://$(oc get route stellar -o jsonpath='{.spec.host}')/
# Verify generated build-time content.
curl http://$(oc get route stellar -o jsonpath='{.spec.host}')/build-info.html
```
Reference: OCP 4.18 S2I build strategy and customizing S2I images.

## Q4
### Option A — Web console
1. Create project **indigo** and import the supplied Git application as **config-api**.
2. Create ConfigMap `runtime-config` from **Workloads → ConfigMaps** with the required `MESSAGE`.
3. Create Secret `api-credentials` from **Workloads → Secrets** with the required user/password values.
4. Edit the `config-api` Deployment to import the ConfigMap and Secret as environment variables. Also add a Secret volume and mount it at `/etc/app-secret`; the YAML editor is often the clearest UI route for the volume/mount.
5. Create/open the Route and verify the application.
6. Update `MESSAGE` in the ConfigMap, then use **Deployment → Actions → Restart rollout** and verify the new pods use the changed value.

### Option B — CLI
```bash
# Create the project.
oc new-project indigo
# Build/deploy the supplied Node application with S2I.
oc new-app nodejs:20-ubi9~<GIT_BASE>/pt3-q4-config.git --name=config-api
# Create non-sensitive configuration.
oc create configmap runtime-config --from-literal=MESSAGE='Configuration from ConfigMap'
# Create sensitive configuration as a Secret.
oc create secret generic api-credentials --from-literal=API_USER=examuser --from-literal=API_PASSWORD=change-me-288
# Inject the ConfigMap as environment variables.
oc set env deploy/config-api --from=configmap/runtime-config
# Inject Secret keys as environment variables.
oc set env deploy/config-api --from=secret/api-credentials
# Mount the Secret as files at the requested path.
oc set volume deploy/config-api --add --name=api-secret --type=secret --secret-name=api-credentials --mount-path=/etc/app-secret
# Expose the service.
oc expose svc/config-api
# Update the ConfigMap value.
oc create configmap runtime-config --from-literal=MESSAGE='Configuration updated' -o yaml --dry-run=client | oc apply -f -
# Restart pods because environment variables are evaluated when pods start.
oc rollout restart deploy/config-api
# Verify rollout completion.
oc rollout status deploy/config-api
```
Reference: OCP 4.18 ConfigMaps, Secrets, environment variables and volumes.

## Q5
### Option A — Web console
1. Create project **health-three** and import the Git application as **health-api**.
2. From **Topology → health-api → Actions → Add Health Checks**, configure the startup probe against `/startup:8080`; derive its period/failure threshold/timeout from the question.
3. Add the liveness HTTP probe against `/live:8080` with the requested delay, period and failure behavior.
4. Add the readiness HTTP probe against `/ready:8080` with the requested delay, period and success behavior.
5. Save and inspect Deployment/Pod events. If a deliberate probe error prevents readiness, edit only the incorrect setting and watch the rollout recover.
6. Confirm Ready replicas and Service endpoints from Topology/Resources.

### Option B — CLI
```bash
# Create the project and deploy the source.
oc new-project health-three
oc new-app nodejs:20-ubi9~<GIT_BASE>/pt3-q5-health.git --name=health-api
# Configure startup probe: 2s period, 10 failures ~= 20s allowance, 1s timeout.
oc set probe deploy/health-api --startup --get-url=http://:8080/startup --period-seconds=2 --failure-threshold=10 --timeout-seconds=1
# Configure liveness with the requested timing/failure behavior.
oc set probe deploy/health-api --liveness --get-url=http://:8080/live --initial-delay-seconds=10 --period-seconds=15 --failure-threshold=2
# Configure readiness with two required consecutive successes.
oc set probe deploy/health-api --readiness --get-url=http://:8080/ready --initial-delay-seconds=3 --period-seconds=5 --success-threshold=2
# Inspect probe configuration and events.
oc describe deploy/health-api
# Verify rollout health after correcting any deliberate error.
oc rollout status deploy/health-api
```
Reference: OCP 4.18 application health checks. Also inspect this workload once in Developer perspective > Topology.

## Q6
### Option A — Web console / UI-assisted
1. Create project **template-three**, clone the supplied repository, and use **+Add → Import YAML** to create both Template objects.
2. Inspect their parameter definitions in YAML. Template processing with exact `-p` and `-l` requirements is most reliable in the terminal, so use `oc process` for those portions.
3. Process `inventory-build` with the required `APP_NAME`, Git URL and builder, plus label `exercise=template3`, then apply the output.
4. In **Builds → BuildConfigs**, start/inspect the generated build.
5. Process `inventory-deploy` with its parameters and label `tier=application`, then inspect the resulting two-container Deployment in Topology.
6. Create/open the Route and verify replicas, labels and both container names.

### Option B — CLI
```bash
# Create the project.
oc new-project template-three
# Clone the supplied templates.
git clone <GIT_BASE>/pt3-q6-templates.git
# Import the build template.
oc apply -f pt3-q6-templates/build-template.yaml
# Import the deploy template.
oc apply -f pt3-q6-templates/deploy-template.yaml
# Review build-template parameters before processing.
oc process inventory-build --parameters
# Process/build resources and attach the required label.
oc process inventory-build -p APP_NAME=inventory -p GIT_URL=<GIT_BASE>/pt3-q1-catalog.git -p BUILDER=nodejs:20-ubi9 -l exercise=template3 | oc apply -f -
# Start the generated build.
oc start-build inventory --follow
# Process/deploy the two-container workload and label generated objects.
oc process inventory-deploy -p APP_NAME=inventory -p NAMESPACE=template-three -p REPLICAS=2 -l tier=application | oc apply -f -
# Expose the service.
oc expose svc/inventory
# Verify both containers in the pod template.
oc get deploy inventory -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'
```
Reference: OCP 4.18 Templates: parameters, processing and labels.

## Q7
### Option A — Web console / UI-assisted
1. Create project **helm-three** and clone the supplied chart. Run `helm lint`/`helm template` locally because these are Helm CLI validation operations.
2. Install release **telemetry** through **Developer → +Add → Helm Chart** when your console accepts the chart source; otherwise run `helm install` and then manage the release from **Helm → Releases**.
3. Supply `replicaCount=2` and `message=practice-three`. Verify both containers in Topology/Deployment details.
4. Use the release **Upgrade** action, when available, to set replicas to 3 and the new message; otherwise use `helm upgrade`.
5. Inspect revision history from the Helm release page (or `helm history`).
6. Roll back to revision 1 using the UI action if present; otherwise use `helm rollback`, then verify the workload and release history.

### Option B — CLI
```bash
# Create the project.
oc new-project helm-three
# Clone the supplied chart.
git clone <GIT_BASE>/pt3-q7-helm.git
# Validate chart structure.
helm lint pt3-q7-helm
# Preview the Kubernetes resources without installing them.
helm template telemetry pt3-q7-helm --set replicaCount=2 --set message=practice-three
# Install with required overrides.
helm install telemetry pt3-q7-helm --set replicaCount=2 --set message=practice-three
# Verify both containers.
oc get deploy telemetry -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'
# Upgrade values.
helm upgrade telemetry pt3-q7-helm --set replicaCount=3 --set message=practice-three-v2
# Inspect revision history.
helm history telemetry
# Roll back to revision 1.
helm rollback telemetry 1
# Verify rollback.
helm history telemetry
```
Reference: OCP 4.18 Helm charts and Helm CLI install/upgrade/rollback.

## Q8
### Option A — Web console
1. Create project **pipeline-three**. Import the application from Git as `pipe-app`, then use **+Add → Import YAML** to apply the supplied Tasks/Pipelines.
2. Open **Pipelines → Pipelines → build-pipeline** and inspect its parameters/tasks.
3. Use **Actions → Start**, set `APP=pipe-app`, and run the build Pipeline. Follow the PipelineRun graph and task logs.
4. After it succeeds, start `deploy-pipeline` with the same application parameter and inspect its run.
5. Open **Pipelines → PipelineRuns** and inspect associated TaskRuns/logs.
6. For the intentionally failed run, open the failed task, read its message/logs/events, correct the bad parameter/reference, and start a fresh PipelineRun.

### Option B — CLI
```bash
# Create the project.
oc new-project pipeline-three
# Prepare a normal S2I BuildConfig/Deployment for the supplied pipeline Tasks to operate on.
oc new-app nodejs:20-ubi9~<GIT_BASE>/pt3-q1-catalog.git --name=pipe-app
# Clone pipeline definitions.
git clone <GIT_BASE>/pt3-q8-pipelines.git
# Create the Tasks and Pipelines.
oc apply -f pt3-q8-pipelines/pipelines.yaml
# Inspect pipeline parameters.
oc describe pipeline build-pipeline
# Create a build PipelineRun from the Pipeline and parameter.
tkn pipeline start build-pipeline -p APP=pipe-app --showlog
# Create a deploy PipelineRun.
tkn pipeline start deploy-pipeline -p APP=pipe-app --showlog
# Inspect PipelineRun state.
tkn pipelinerun list
# Inspect TaskRuns created by the pipelines.
tkn taskrun list
# Use this pattern to diagnose a failed run.
oc describe pipelinerun <FAILED-RUN-NAME>
```
Reference: Red Hat OpenShift Pipelines 1.20+/OCP 4.18: Tekton Tasks, Pipelines and PipelineRuns.

## Q9
### Option A — Web console / UI-assisted
1. Create project **kustomize-three**. Kustomize rendering is a CLI/file operation, so first run `oc kustomize` locally to inspect the production overlay.
2. Apply the overlay with `oc apply -k`.
3. Use **Topology** and **Workloads → Deployments** to verify the generated name prefix, replicas and labels.
4. Open the Deployment YAML to confirm the overlay changes came from Kustomize rather than manual edits.
5. Inspect pods/events in the console if the overlay does not become Ready.

### Option B — CLI
```bash
# Create project.
oc new-project kustomize-three
# Render the production overlay before applying it.
oc kustomize repos/pt3-q9-kustomize/overlays/prod
# Apply the rendered overlay.
oc apply -k repos/pt3-q9-kustomize/overlays/prod
# Verify replicas and labels.
oc get deploy prod-report-api --show-labels
```

## Q10
### Option A — Web console / UI-assisted
1. Create project **hook-three** and import the supplied Python Git repository using the Python builder as **hook-app**.
2. Open **Builds → BuildConfigs → hook-app → YAML** and add the post-commit hook that runs `python verify.py`.
3. Inspect the BuildConfig triggers and ensure a ConfigChange trigger is present; edit YAML if needed.
4. Start a new build from the BuildConfig actions.
5. Inspect build logs/status and confirm the post-commit command ran successfully.
6. Return to the BuildConfig YAML to verify the hook is persistent for future builds.

### Option B — CLI
```bash
# Create project.
oc new-project hook-three
# Create a Python S2I build from Git.
oc new-app python:3.11-ubi9~<GIT_BASE>/pt3-q10-hook.git --name=hook-app
# Configure a post-commit hook using the supplied script.
oc set build-hook bc/hook-app --post-commit --command -- python verify.py
# Ensure ConfigChange trigger exists.
oc set triggers bc/hook-app --from-config
# Run and follow a new build.
oc start-build hook-app --follow
# Inspect hook configuration.
oc describe bc/hook-app
```

## Q11
### Option A — Web console / UI-assisted
1. Create project **registry-three** and create ImageStream `mirror-app` using **+Add → Import YAML** or the ImageStream resource view.
2. Switch to **Administrator** perspective and locate the integrated image-registry configuration. If your console exposes YAML editing for `configs.imageregistry.operator.openshift.io/cluster`, set `spec.defaultRoute: true`; otherwise use the CLI command below.
3. Inspect **Networking → Routes** in namespace `openshift-image-registry` to obtain the `default-route` hostname.
4. Podman login/tag/push/pull are workstation CLI operations and cannot be completed purely in the OpenShift console; use your OpenShift token with Podman.
5. Return to the console and inspect ImageStream `mirror-app` to verify the pushed tag appears.
6. If registry configuration is hidden by RBAC, do not waste time searching the UI—use the CLI with the privileges supplied by the lab.

### Option B — CLI
```bash
# Create project and destination ImageStream.
oc new-project registry-three
oc create is mirror-app
# Record current default-route state before changing it.
oc get configs.imageregistry.operator.openshift.io cluster -o jsonpath='{.spec.defaultRoute}{"\n"}'
# Enable the external default registry route as cluster admin.
oc patch configs.imageregistry.operator.openshift.io cluster --type=merge -p '{"spec":{"defaultRoute":true}}'
# Obtain the registry hostname.
REGISTRY=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}')
# Authenticate Podman with your OpenShift token.
podman login -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false $REGISTRY
# Push/pull using $REGISTRY/registry-three/mirror-app:v1 after tagging a harmless local image.
```
Reference: OCP 4.18 integrated image registry.

## Q12
### Option A — Web console
1. Create project **operator-three** and switch to **Administrator → Operators → Installed Operators**.
2. Open the installed NGINX Gateway Fabric Operator and inspect the APIs it provides. Choose **NginxGatewayFabric → Create instance**.
3. Use YAML view to create `practice-three-gateway` with the minimum valid `spec: {}` in the project.
4. Open the created custom resource and inspect its **Conditions/Status** until reconciliation succeeds.
5. Inspect **Workloads → Deployments**, **Networking → Services**, and service accounts/resources created by the Operator.
6. Use **Events** and the Operator pod logs if reconciliation fails.

### Option B — CLI
```bash
# Create the project.
oc new-project operator-three
# Discover the installed custom resource.
oc api-resources --api-group=gateway.nginx.org
# Inspect its schema.
oc explain nginxgatewayfabric.spec
# Create the minimum valid custom resource.
cat <<'YAML' | oc apply -f -
apiVersion: gateway.nginx.org/v1alpha1
kind: NginxGatewayFabric
metadata:
  name: practice-three-gateway
spec: {}
YAML
# Inspect reconciliation conditions.
oc get nginxgatewayfabric practice-three-gateway -o yaml
# Inspect Operator-created resources.
oc get deploy,svc,sa -n operator-three
# Inspect reconciliation events.
oc get events --sort-by=.lastTimestamp
```
Reference: OCP 4.18 Operators/OperatorHub and installed Operator applications.
