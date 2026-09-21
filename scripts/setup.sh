#!/usr/bin/env bash
set -euo pipefail
# Shared dependency only. Exam projects are intentionally NOT pre-created.
oc project lab-infra >/dev/null
cat <<'YAML' | oc apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: artifact-mock}
spec:
  replicas: 1
  selector: {matchLabels: {app: artifact-mock}}
  template:
    metadata: {labels: {app: artifact-mock}}
    spec:
      containers:
      - name: server
        image: python:3.12-alpine
        command: ["/bin/sh","-c"]
        args: ["mkdir -p /data; echo 'Practice Test 3 artifact from repository service' > /data/banner.txt; cd /data; python -m http.server 8080"]
        ports: [{containerPort: 8080}]
---
apiVersion: v1
kind: Service
metadata: {name: artifact-mock}
spec: {selector: {app: artifact-mock}, ports: [{port: 8080, targetPort: 8080}]}
YAML
oc rollout status deploy/artifact-mock --timeout=120s >/dev/null
echo 'Practice Test 3 shared infrastructure ready.'
echo 'Push repos/pt3-* directories to Git repositories reachable by CRC before the timed attempt.'
