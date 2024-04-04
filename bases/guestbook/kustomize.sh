#!/usr/bin/env bash

set -o errexit
set -o pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

usage() {
cat <<EOF
Usage: $0 [apply|build|diff|delete] overlay-dir

Examples:
    $0 apply dev-nas-performance/mongo
    $0 apply dev-nas-ultra/redis
    $0 build dev-nas-performance/mongo
    $0 build dev-nas-ultra/redis
    $0 delete dev-nas-ultra/redis
    $0 diff dev-nas-performance/redis dev-nas-ultra/redis 
EOF
}

function create_registry_secret() {
  namespace="${1:?"Namespace is required"}"
  secret_name="${2:-registry-credentials}"
  server="${3:-https://docker.io}"
  username="${4:-$DOCKER_USERNAME}"
  password="${5:-$DOCKER_PASSWORD}"

  if [[ -z $username ]]; then
      echo -n "Enter username for $server: "
      read -r username
      echo
  fi

  if [[ -z $password ]]; then
      echo -n "Enter password for $server: "
      read -rs password
      echo
  fi

  echo "Creating docker-registry secret for $secret_name"
  kubectl create secret "docker-registry" "$secret_name" \
      --docker-username="$username" \
      --docker-password="$password" \
      --docker-server="$server" \
      --namespace "$namespace"
}

function set_cluster_domain() {
  local overlay=$1
  export CLUSTER
  CLUSTER="$(kubectl config current-context)"

  # Loop through params.env files
  while IFS= read -r -d '' file; do
    if [ -f "$file" ]; then
      # Perform variable substitution using envsubst
      envsubst < "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
  done <   <(find "$overlay" -name '*.env' -print0)
}

function convert_to_overlay_dir {
  local overlay=$1
  if [[ ! $overlay == "./overlays/"* && \
      ! $overlay == "./overlays/"* && \
      ! $overlay == "base" ]]; then
    overlay="overlays/$1"
  fi
  echo "$overlay"
}

function kustomizeIt {
  set_cluster_domain "$__DIR/$1" &>/dev/null
  kubectl kustomize --enable-helm "$__DIR/$1"
}

function build {
  kustomizeIt "$1"
}

function delete {
  kustomizeIt "$1" | kubectl delete -f -
}

function apply {
  kustomizeIt "$1" | kubectl apply -f -
  namespace="$(yq .metadata.name "$__DIR/base/namespace.yaml")"
  create_registry_secret "$namespace"
  kubectl patch serviceaccount "default" -n "$namespace" -p "{\"imagePullSecrets\": [{\"name\": \"registry-credentials\"}]}"
  printf "\nOpen: %s\n" "https://guestbook.$(kubectl get cm --namespace "$namespace" parameters -ojsonpath='{.data.clusterDomain}')"
}

function validate_overlay_arg {
  if [[ ! -f "$1/kustomization.yaml" ]]; then
    echo "You must specify an overlay directory with kustomization.yaml"
    exit 1
  fi
}

if [[ $# -eq 0 || $1 = "--help" || $1 == "-h" ]]; then
  usage
  exit 1
fi

COMMAND=$1
OVERLAY=$(convert_to_overlay_dir "$2")

case "$COMMAND" in
  diff)
    validate_overlay_arg "$OVERLAY"
    OVERLAY_TO_COMPARE=$(convert_to_overlay_dir "$3")
    validate_overlay_arg "$OVERLAY_TO_COMPARE"
    diff <(kustomizeIt "$OVERLAY_TO_COMPARE") <(kustomizeIt "$OVERLAY") | more
    ;;
  build)
    validate_overlay_arg "$OVERLAY"
    build "$OVERLAY"
    ;;
  apply)
    validate_overlay_arg "$OVERLAY"
    apply "$OVERLAY"
    ;;
  delete)
    validate_overlay_arg "$OVERLAY"
    delete "$OVERLAY"
    ;;
  *) echo "Please specify a command to run: (diff, build, apply, delete)"
  ;;
esac
