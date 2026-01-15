#!/bin/bash

# Script to bring up kind clusters and install ArgoCD, Argo Workflows, and Argo Events

ARGO_WORKFLOWS_VERSION="v3.7.6"
ARGO_ROLLOUTS_VERSION="v1.8.3"

HUB_CLUSTER="argo-learning-hub"
SPOKE_CLUSTER="argo-learning-spoke"

function help() {
cat <<EOF
Usage:
  $0 up            Create hub cluster and install Argo components
  $0 up-multi      Create both hub and spoke clusters (multicluster learning)
  $0 down          Delete hub cluster
  $0 down-multi    Delete both hub and spoke clusters
  $0 info          Re-print URLs and admin password for hub
  $0 help          Show this help

Access (Hub):
  ArgoCD UI:         https://localhost:8080
  Argo Workflows UI: http://localhost:2746

Access (Spoke):
  Example app:       http://localhost:8888

Notes:
  - Ports are forwarded via the kind config files
  - 'info' only reads existing secrets (safe to run anytime)
  - Use 'up' for single-cluster learning, 'up-multi' for multicluster
  - After 'up-multi', run: argocd cluster add argo-learning-spoke

Examples:
  $0 up              # Single hub cluster
  $0 up-multi        # Hub + spoke for multicluster learning
  $0 info
  $0 down
  $0 down-multi
EOF
}


function print_info() {
    echo ""
    echo "---------------------------------------------------"
    echo ""
    echo "Hub Cluster: ${HUB_CLUSTER}"
    echo "ArgoCD UI:             https://localhost:8080"
    echo -n "ArgoCD Admin Password: "

    if kubectl -n argocd get secret argocd-initial-admin-secret >/dev/null 2>&1; then
        kubectl -n argocd get secret argocd-initial-admin-secret \
          -o jsonpath="{.data.password}" | base64 -d; echo
    else
        echo "<not found – is the cluster running?>"
    fi

    echo "Argo Workflows UI:     http://localhost:2746"
    echo ""
    echo "  Rollouts dashboard:"
    echo "  kubectl argo rollouts dashboard"
    echo ""
    echo "---------------------------------------------------"
}

function install_argocd() {
    # Install ArgoCD
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    # Patch ArgoCD for Port 8080 access
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"name": "https", "port": 443, "nodePort": 30443}]}}'
}

function install_workflows() {
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
}

function install_rollouts() {
    # Install Argo Rollouts
    kubectl create namespace argo-rollouts
    kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/${ARGO_ROLLOUTS_VERSION}/install.yaml
}

function up() {
    echo "Creating hub cluster: ${HUB_CLUSTER}"
    kind create cluster --name "${HUB_CLUSTER}" --config argo-kind-config-hub.yaml

    install_argocd
    install_workflows
    install_rollouts

    # Set current namespace to argocd
    kubectl config set-context --current --namespace=argocd

    # Output default password for UI access
    echo ""
    echo ""
    echo "---------------------------------------------------"
    echo ""
    echo "Hub Cluster: ${HUB_CLUSTER}"
    echo "ArgoCD UI:             https://localhost:8080"
    echo -n "ArgoCD Admin Password: "
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    echo "Argo Workflows UI:     http://localhost:2746"
    echo ""
    echo "  The Rollouts UI is a local dashboard."
    echo "  To start it, run: kubectl argo rollouts dashboard"
    echo ""
    echo "NOTE: Services may still be pulling images or starting up."
    echo "      Run 'kubectl get pods -A' to monitor status until everything is 'Running'."
    echo ""
    echo "---------------------------------------------------"
}

function up_multi() {
    echo "Creating hub cluster: ${HUB_CLUSTER}"
    kind create cluster --name "${HUB_CLUSTER}" --config argo-kind-config-hub.yaml

    install_argocd
    install_workflows
    install_rollouts

    # Set current namespace to argocd
    kubectl config set-context --current --namespace=argocd

    # Output hub info
    echo ""
    echo ""
    echo "====================================================="
    echo "Hub Cluster Created: ${HUB_CLUSTER}"
    echo "====================================================="
    echo ""
    echo "Hub ArgoCD UI:         https://localhost:8080"
    echo -n "Hub ArgoCD Password:   "
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    echo "Hub Argo Workflows UI: http://localhost:2746"
    echo ""
    echo "NOTE: Services may still be pulling images or starting up."
    echo "      Run 'kubectl get pods -A' to monitor status."
    echo ""
    echo "====================================================="
    echo ""

    # Create spoke cluster
    echo "Creating spoke cluster: ${SPOKE_CLUSTER}"
    kind create cluster --name "${SPOKE_CLUSTER}" --config argo-kind-config-spoke.yaml

    echo ""
    echo ""
    echo "====================================================="
    echo "Spoke Cluster Created: ${SPOKE_CLUSTER}"
    echo "====================================================="
    echo ""
    echo "Current kubectl context:"
    kubectl config current-context
    echo ""
    echo "Kubernetes contexts available:"
    kubectl config get-contexts
    echo ""
    echo "To register the spoke cluster with hub ArgoCD, run:"
    echo ""
    echo "  kubectl config use-context kind-${HUB_CLUSTER}"
    echo "  argocd cluster add kind-${SPOKE_CLUSTER}"
    echo ""
    echo "Or use the ArgoCD UI to add the cluster:"
    echo "  1. Go to https://localhost:8080/settings/clusters"
    echo "  2. Click 'Connect a cluster'"
    echo "  3. Select 'kind-${SPOKE_CLUSTER}' from the list"
    echo ""
    echo "====================================================="
}

case "$1" in
    up)
        up
        ;;
    up-multi)
        up_multi
        ;;
    down)
        echo "Deleting hub cluster '${HUB_CLUSTER}'"
        kind delete cluster --name "${HUB_CLUSTER}"
        ;;
    down-multi)
        echo "Deleting hub cluster '${HUB_CLUSTER}'"
        kind delete cluster --name "${HUB_CLUSTER}"
        echo "Deleting spoke cluster '${SPOKE_CLUSTER}'"
        kind delete cluster --name "${SPOKE_CLUSTER}"
        ;;
    info)
        print_info
        ;;
    help|-h|--help|"")
        help
        ;;
    *)
        echo "Unknown command: $1"
        help
        exit 1
esac
