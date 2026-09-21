# EX288 CRC Practice Exam 3

**Target:** EX288 / OCP 4.18 style. **Time:** 3 hours for Q1-Q8. Q9-Q12 are supplemental but required for full objective coverage.

Do not open `SOLUTIONS.md` during the timed attempt. Replace `<GIT_BASE>` with URLs for the supplied repos after pushing them to a Git server reachable by CRC.

## Q1 — S2I deployment from Git
Create project `sapphire` yourself.
- Deploy `catalog` from `<GIT_BASE>/pt3-q1-catalog.git` with the `nodejs:20-ubi9` S2I builder and source strategy.
- Set build environment `npm_config_registry=https://registry.npmjs.org/` without changing application code.
- Output the build to ImageStream `catalog:latest` and make the application run from that image.
- Expose it through a Route and verify the response contains `Catalog service - Practice Test 3`.
- Configure requests of `100m/128Mi` and limits of `500m/256Mi`, then run 2 replicas.
- Label the workload `app.kubernetes.io/part-of=pt3` and `environment=practice` and prove the latest build completed.

## Q2 — Containerfile, Docker strategy and build troubleshooting
Create project `bronze` yourself. The source is `<GIT_BASE>/pt3-q2-container.git` and the build-time artifact is available from `http://artifact-mock.lab-infra.svc:8080/banner.txt`.
- Create ImageStream `container-web` and BuildConfig `container-web` using **Docker strategy**, not source strategy.
- Configure the Git source and explicitly configure the build to use `Containerfile`.
- Supply the artifact URL as Docker build argument `ARTIFACT_URL`; diagnose the build if the wrong strategy or missing argument causes failure.
- Publish the result to `container-web:1.0` in the integrated registry.
- Deploy the resulting ImageStream tag and configure an ImageChange trigger so a new image can roll out automatically.
- Expose the service and verify the route; inspect build logs and BuildConfig YAML to prove the strategy/output are correct.

## Q3 — Customize an existing S2I workflow
Create project `nebula` yourself and use `<GIT_BASE>/pt3-q3-s2i.git`.
- Use the OpenShift `httpd:2.4-ubi9` builder with source strategy and name the application `stellar`.
- Ensure the supplied `.s2i/bin/assemble` is used so HTML source is copied during assemble.
- The build must generate `build-info.html` containing the build date and `Ad astra per scientiam`.
- Configure a ConfigChange build trigger and start a fresh build manually.
- Deploy the resulting ImageStream and expose it with a Route.
- Verify both `/` and `/build-info.html`; use build logs/`oc describe build` to diagnose any S2I failure.

## Q4 — ConfigMaps and Secrets
Create project `indigo` yourself. Deploy `config-api` from `<GIT_BASE>/pt3-q4-config.git` using S2I.
- Create ConfigMap `runtime-config` with `MESSAGE=Configuration from ConfigMap`.
- Create Secret `api-credentials` with `API_USER=examuser` and `API_PASSWORD=change-me-288`.
- Inject `MESSAGE` and `API_USER` into the Deployment from the correct resources without hard-coding their values in the pod specification.
- Mount the Secret as files at `/etc/app-secret` while retaining the environment injection.
- Expose the application and verify its output contains `Configuration from ConfigMap|examuser`.
- Change `MESSAGE` to `Configuration updated`, restart/roll out the workload, and prove the new pod uses the changed value.

## Q5 — Health monitoring and deployment troubleshooting
Create project `health-three` and deploy `health-api` from `<GIT_BASE>/pt3-q5-health.git`.
- Configure a startup HTTP probe against `/startup` on port 8080 that checks every 2 seconds, permits enough failures for roughly 20 seconds of startup time, and times out each check after 1 second.
- Configure a liveness HTTP probe against `/live`; wait 10 seconds before first check, check every 15 seconds, and allow 2 consecutive failures.
- Configure a readiness HTTP probe against `/ready`; begin after 3 seconds, check every 5 seconds, and require 2 consecutive successful checks.
- All three probes must survive pod replacement and future rollouts.
- Introduce/diagnose one minor deployment issue by temporarily setting the readiness path incorrectly, use events/describe/logs to identify it, then restore the correct configuration.
- Use the **OpenShift web console** at least once to inspect the workload health, then verify from CLI that the Deployment is Available.

## Q6 — Customize two supplied templates
Create project `template-three`. Templates are in `<GIT_BASE>/pt3-q6-templates.git` as `build-template.yaml` and `deploy-template.yaml`.
- Import both templates into the project and keep the names `inventory-build` and `inventory-deploy`.
- Process the build template with `APP_NAME=inventory`, the Q1 Git URL, and the Node.js builder; add label `exercise=template3` to generated resources using `oc process -l`.
- Process the deploy template with `APP_NAME=inventory`, `NAMESPACE=template-three`, and 2 replicas; add label `tier=application` during processing.
- Ensure the deployment template produces a **two-container pod** (`web` and `helper`).
- Verify the build completes and the Deployment consumes the built image.
- Expose the service, verify both template parameter lists with `oc process --parameters`, and show the requested labels on generated resources.

## Q7 — Multi-container application with Helm
Create project `helm-three`. The supplied chart is `<GIT_BASE>/pt3-q7-helm.git`.
- Clone the chart, inspect it with `helm lint` and `helm template`, and install release `telemetry`.
- The resulting pod must contain the `writer` and `reader` containers sharing the same `emptyDir` volume.
- Override values at install time so there are 2 replicas and the message is `practice-three`.
- Verify the reader sees data written by the writer using container logs/exec.
- Upgrade the release to 3 replicas and message `practice-three-v2`; inspect `helm history` and the rendered manifest.
- Roll back to the previous revision and prove the replica/message configuration reverted.

## Q8 — OpenShift Pipelines: build and deploy
Create project `pipeline-three`. Pipeline definitions are supplied at `<GIT_BASE>/pt3-q8-pipelines.git`.
- Prepare an S2I application named `pipe-app` from the Q1 source so a BuildConfig and Deployment exist in this project.
- Apply the supplied Tasks and the two Pipelines named `build-pipeline` and `deploy-pipeline`; inspect their parameters before running them.
- Create a PipelineRun for `build-pipeline` with `APP=pipe-app` and verify its TaskRun and the resulting OpenShift Build succeed.
- Create a PipelineRun for `deploy-pipeline` with `APP=pipe-app` and verify rollout succeeds.
- Deliberately create one PipelineRun with a wrong `APP` value, diagnose the failure using PipelineRun/TaskRun status and logs, then run it correctly.
- List PipelineRuns and TaskRuns and show the successful conditions for the final build and deploy runs.

# Supplemental — complete these for full published-objective coverage

## Q9 — Kustomize
- Create project `kustomize-three`.
- Use the supplied base and `overlays/prod` from `pt3-q9-kustomize`.
- Render the overlay with `oc kustomize` before applying it.
- Apply the production overlay and ensure the name is prefixed with `prod-`.
- Verify 3 replicas and label `environment=production`.
- Make one overlay-only change without editing the base, re-render, apply and verify it.

## Q10 — Build hooks and triggers
- Create project `hook-three` and an S2I Python BuildConfig named `hook-app` from `pt3-q10-hook`.
- Configure a post-commit build hook that runs the supplied `verify.py` with Python.
- Configure a ConfigChange trigger and inspect the BuildConfig triggers/hooks.
- Start a build manually and follow the logs.
- Prove the most recent build succeeded and the post-commit script printed `POST_COMMIT_OK`.
- Trigger another build without modifying application source and verify the hook runs again.

## Q11 — Integrated image registry
- Create project `registry-three` and ImageStream `mirror-app`.
- As a cluster administrator, enable the default external route for the OpenShift image registry if it is disabled.
- Obtain the registry route and authenticate Podman using an OpenShift token.
- Tag a harmless local test image for `<registry-route>/registry-three/mirror-app:v1` and push it.
- Verify ImageStream tag `mirror-app:v1` appears in OpenShift, then pull it back with Podman.
- Return the registry default-route setting to its original state when finished.

## Q12 — Application from an installed Operator
Use the installed NGINX Gateway Fabric Operator from the CRC prerequisites.
- Create project `operator-three`.
- Discover the `NginxGatewayFabric` API using `oc api-resources` and `oc explain`, rather than copying a hidden solution.
- Create a minimal `NginxGatewayFabric` named `practice-three-gateway`.
- Verify its `Initialized` and `Deployed` conditions become True.
- Identify at least three resources created/managed by the Operator and verify the controller Deployment is Available.
- Use `oc describe` and project events to demonstrate how you would diagnose failed reconciliation.
