# Practice Exam 3 — Solutions

> Use these only after attempting the questions. Replace `<GIT_BASE>` with your reachable Git base URL.

## Q1
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
