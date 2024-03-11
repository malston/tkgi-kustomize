#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

rm -rf manifests

declare -A foundations

while read -r overlay_dir; do
    cluster_dir="${overlay_dir%/*}"
    cluster="${cluster_dir##*/}"
    foundation_dir="${cluster_dir%/*}"
    foundation="${foundation_dir##*/}"
    foundation_cluster="${foundation}-${cluster}"
    foundations["manifests/$foundation/$cluster"]="${foundation_cluster}"
    mkdir -p "manifests/$foundation/$cluster"
    echo -e "Writing manifests from $cluster_dir to manifests/$foundation/$cluster/allinone.yaml"
    kubectl kustomize --enable-helm --helm-command helm "$cluster_dir" > "manifests/$foundation/$cluster/allinone.yaml"
done < <(find overlays/foundations -depth 3)

for f in "${!foundations[@]}"; do
  echo kubectl apply -f "$f/allinone.yaml"
done