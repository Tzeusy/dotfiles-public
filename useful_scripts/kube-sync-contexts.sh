#!/usr/bin/env bash
# Add a kubeconfig context per namespace of the current cluster, named
# <cluster>-<namespace>, so `kubectx` can jump straight into a namespace.
# Moved out of the retired bootstrap.sh: it needs a live cluster, so it is a
# runtime helper rather than machine setup.
set -euo pipefail

kubectl cluster-info >/dev/null 2>&1 || { echo "No reachable cluster in the current context" >&2; exit 1; }
KUBE_CURRENT_CTX="$(kubectl config current-context)"
KUBE_CLUSTER="$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$KUBE_CURRENT_CTX\")].context.cluster}")"
KUBE_USER="$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$KUBE_CURRENT_CTX\")].context.user}")"
if [ -z "$KUBE_CLUSTER" ] || [ -z "$KUBE_USER" ]; then
    echo "Could not determine cluster/user from context $KUBE_CURRENT_CTX" >&2
    exit 1
fi

created=0
while IFS= read -r ns; do
    [ -z "$ns" ] && continue
    ctx_name="${KUBE_CLUSTER}-${ns}"
    if ! kubectl config get-contexts -o name | grep -Fxq "$ctx_name"; then
        kubectl config set-context "$ctx_name" --cluster="$KUBE_CLUSTER" --user="$KUBE_USER" --namespace="$ns" >/dev/null
        created=$((created + 1))
    fi
done < <(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n')
echo "Created $created namespace context(s) for cluster $KUBE_CLUSTER"
