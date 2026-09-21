#!/usr/bin/env bash
set -u
for p in sapphire bronze nebula indigo health-three template-three helm-three pipeline-three kustomize-three hook-three registry-three operator-three; do
  oc delete project "$p" --ignore-not-found=true
 done
