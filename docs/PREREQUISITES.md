# CRC prerequisites — Practice Test 3

## 1. Start CRC and expose `oc`
```bash
crc start
eval $(crc oc-env)
crc console --credentials
```
Log in as `kubeadmin` using the password CRC prints; do not store the password in this lab.

## 2. Bootstrap cluster-wide dependencies
From the extracted Practice Test 3 directory:
```bash
./scripts/bootstrap-crc.sh
```
This checks OperatorHub catalogs, installs/checks Red Hat OpenShift Pipelines and NGINX Gateway Fabric, verifies Build/ImageStream APIs and builders, and grants `developer` access only to the shared `lab-infra` project. It deliberately does **not** pre-create exam projects.

## 3. Switch to the exam user
```bash
oc login -u developer -p developer https://api.crc.testing:6443
oc whoami
```
Expected user: `developer`.

## 4. Create shared mock artifact infrastructure
```bash
./scripts/setup.sh
oc get deploy,svc -n lab-infra
```
Q2 uses this in-cluster artifact URL:
`http://artifact-mock.lab-infra.svc:8080/banner.txt`

This is a lightweight stand-in for a Nexus/Artifactory raw artifact endpoint so the exercise remains self-contained on CRC.

## 5. Git repositories
Create/push one reachable Git repository for every directory under `repos/pt3-*`. Preserve the directory contents exactly. Record a common base URL if your Git server layout permits it; the exam uses `<GIT_BASE>` as a placeholder.

Required repos: `pt3-q1-catalog`, `pt3-q2-container`, `pt3-q3-s2i`, `pt3-q4-config`, `pt3-q5-health`, `pt3-q6-templates`, `pt3-q7-helm`, `pt3-q8-pipelines`, `pt3-q9-kustomize`, `pt3-q10-hook`.

## 6. Verify tools/APIs
```bash
./scripts/verify-env.sh
oc get is nodejs python httpd -n openshift
oc api-resources --api-group=tekton.dev
oc api-resources --api-group=gateway.nginx.org
helm version
oc kustomize --help >/dev/null
```

## 7. Reset between attempts
```bash
./scripts/reset.sh
```
Reset deletes only Practice Test 3 exam projects. It leaves Pipelines, the Operator and `lab-infra` in place.
