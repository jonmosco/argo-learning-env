#!/bin/bash

# Script to bring up the kind cluster and install ArgoCD, Argo Workflows, and Argo Events

ARGO_WORKFLOWS_VERSION="v3.7.6"
ARGO_ROLLOUTS_VERSION="v1.8.3"

# Cluster name is in the kind config yaml
CLUSTER_NAME="argo-learning"

function up() {
    kind create cluster --name "${CLUSTER_NAME}" --config argo-kind-config.yaml

    # Install ArgoCD
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    # Patch ArgoCD for Port 8080 access
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"name": "https", "port": 443, "nodePort": 30443}]}}'

    # Install Argo Workflows
    kubectl create namespace argo
    kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/${ARGO_WORKFLOWS_VERSION}/install.yaml

    # Wait for services and CRDs to initialize
    echo ""
    echo "Waiting 45 seconds for CRDs and Controllers to finish installing"
    sleep 45

    # Patch Argo Workflows for Port 2746 access (NodePort 32746)
    # Also switches auth-mode to 'server' so you can skip local login tokens
    kubectl patch svc argo-server -n argo -p '{"spec": {"type": "NodePort", "ports": [{"name": "web", "port": 2746, "targetPort": 2746, "nodePort": 32746}]}}'
    kubectl patch deployment argo-server -n argo --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["server", "--auth-mode=server"]}]'

    # Install Argo Rollouts
    kubectl create namespace argo-rollouts
    kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/${ARGO_ROLLOUTS_VERSION}/install.yaml

    # Set current namespace to argocd
    kubectl config set-context --current --namespace=argocd

    # Output default password for UI access
    echo ""
    echo ""
    echo "---------------------------------------------------"
    echo ""
    echo "ArgoCD UI:             https://localhost:8080"
    echo -n "ArgoCD Admin Password: "
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    echo "Argo Workflows UI:     http://localhost:2746"
    echo ""
    echo "Argo Rollouts UI:"
    echo ""
    echo "  Note: The Rollouts UI is a local dashboard."
    echo "  To start it, run: kubectl argo rollouts dashboard"
    echo "  Then visit: http://localhost:3100"
    echo ""
    echo "NOTE: Services may still be pulling images or starting up."
    echo "      Run 'kubectl get pods -A' to monitor status until everything is 'Running'."
    echo ""
    echo "---------------------------------------------------"
}

case "$1" in
    up)
        up
        ;;
    down)
        echo "Deleting cluster '$CLUSTER_NAME'"
        kind delete cluster --name $CLUSTER_NAME
        ;;
    *)
        echo "Usage: $0 {up|down}"
        exit 1
esac
