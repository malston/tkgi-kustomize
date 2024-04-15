#!/usr/bin/env bash

set -o errexit
set -o pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

usage() {
cat <<EOF
Usage: $0 [apply|build|diff|delete] overlay-dir

Examples:
    $0 apply dev-nas-performance
    $0 apply dev-nas-ultra
    $0 build dev-nas-performance
    $0 build dev-nas-ultra
    $0 delete dev-nas-ultra
    $0 diff dev-nas-performance dev-nas-ultra
    $0 diff base dev
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

function convert_to_overlay_dir {
  local overlay=$1
  if [[ ! $overlay == "./overlays/"* && \
      ! $overlay == "overlays/"* && \
      ! $overlay == "base" ]]; then
    overlay="overlays/$1"
  fi
  echo "$overlay"
}

function kustomizeIt {
  if [[ -z $CLUSTER_DOMAIN ]]; then
    CLUSTER_DOMAIN="$(kubectl config current-context)"
  fi
  XDG_CONFIG_HOME=$__DIR/../../plugins kubectl kustomize --enable-alpha-plugins --enable-helm "$__DIR/$1"
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
  printf "\nLogin to: %s\nUsername: %s\nPassword: %s\n" "https://wordpress.$(kubectl get cm --namespace "$namespace" parameters -ojsonpath='{.data.clusterDomain}')" "user" "$(kubectl get secret --namespace "$namespace" wordpress -o jsonpath='{.data.wordpress-password}' | base64 -d)"
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
