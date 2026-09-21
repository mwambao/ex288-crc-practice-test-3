#!/usr/bin/env bash
set -u
pass=0; fail=0
check(){ local m=$1; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $m"; pass=$((pass+1)); else echo "FAIL  $m"; fail=$((fail+1)); fi; }
mark(){ case "$1" in
1) check 'Q1 project' oc get project sapphire; check 'Q1 BuildConfig' oc get bc catalog -n sapphire; check 'Q1 Route' oc get route catalog -n sapphire; check 'Q1 two replicas' bash -c "[ \"\$(oc get deploy catalog -n sapphire -o jsonpath='{.spec.replicas}' 2>/dev/null)\" = 2 ]";;
2) check 'Q2 Docker BuildConfig' bash -c "[ \"\$(oc get bc container-web -n bronze -o jsonpath='{.spec.strategy.type}' 2>/dev/null)\" = Docker ]"; check 'Q2 image output' oc get istag container-web:1.0 -n bronze; check 'Q2 Route' oc get route container-web -n bronze;;
3) check 'Q3 S2I BuildConfig' oc get bc stellar -n nebula; check 'Q3 Route' oc get route stellar -n nebula;;
4) check 'Q4 ConfigMap' oc get cm runtime-config -n indigo; check 'Q4 Secret' oc get secret api-credentials -n indigo; check 'Q4 Deployment' oc get deploy config-api -n indigo;;
5) check 'Q5 Deployment' oc get deploy health-api -n health-three; check 'Q5 startup probe' bash -c "oc get deploy health-api -n health-three -o jsonpath='{.spec.template.spec.containers[0].startupProbe}' | grep -q startup"; check 'Q5 liveness probe' bash -c "oc get deploy health-api -n health-three -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}' | grep -q live"; check 'Q5 readiness probe' bash -c "oc get deploy health-api -n health-three -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' | grep -q ready";;
6) check 'Q6 build template' oc get template inventory-build -n template-three; check 'Q6 deploy template' oc get template inventory-deploy -n template-three; check 'Q6 two-container Deployment' bash -c "[ \"\$(oc get deploy inventory -n template-three -o jsonpath='{.spec.template.spec.containers[*].name}' 2>/dev/null | wc -w | tr -d ' ')\" -eq 2 ]";;
7) check 'Q7 Helm release' helm status telemetry -n helm-three; check 'Q7 two containers' bash -c "[ \"\$(oc get deploy telemetry -n helm-three -o jsonpath='{.spec.template.spec.containers[*].name}' 2>/dev/null | wc -w | tr -d ' ')\" -eq 2 ]";;
8) check 'Q8 build Pipeline' oc get pipeline build-pipeline -n pipeline-three; check 'Q8 deploy Pipeline' oc get pipeline deploy-pipeline -n pipeline-three; check 'Q8 PipelineRuns' bash -c "[ \"\$(oc get pipelinerun -n pipeline-three --no-headers 2>/dev/null | wc -l | tr -d ' ')\" -ge 2 ]";;
9) check 'Q9 prod Deployment' oc get deploy prod-report-api -n kustomize-three;;
10) check 'Q10 hook BuildConfig' oc get bc hook-app -n hook-three;;
11) check 'Q11 ImageStream tag' oc get istag mirror-app:v1 -n registry-three;;
12) check 'Q12 Operator CR' oc get nginxgatewayfabric practice-three-gateway -n operator-three;;
esac; }
arg=${1:-all}; if [ "$arg" = all ]; then for i in $(seq 1 12); do echo "=== Q$i ==="; mark "$i"; done; else mark "$arg"; fi
echo "SUMMARY: $pass PASS, $fail FAIL"; [ "$fail" -eq 0 ]
