#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

version=${1:-v1.0.0}
release_dir="releases/$version/manifests"
rm -rf "$release_dir"

while read -r overlay_dir; do
    cluster_dir="${overlay_dir%/*}"
    cluster="${cluster_dir##*/}"
    foundation_dir="${cluster_dir%/*}"
    foundation="${foundation_dir##*/}"
    mkdir -p "$release_dir/$foundation/$cluster"
    echo -e "Writing manifests from $cluster_dir to $release_dir/$foundation/$cluster/allinone.yaml"
    kubectl kustomize --enable-helm --helm-command helm "$cluster_dir" > "$release_dir/$foundation/$cluster/allinone.yaml"
done < <(find overlays/foundations -depth 3)
