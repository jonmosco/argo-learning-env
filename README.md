# Argo Learning Lab (Quick & Dirty)

This repo provides a "one-command" setup for a local Kubernetes environment running the full Argo suite (**ArgoCD**, **Workflows**, **Events**, and **Rollouts**). It uses **Kind** (Kubernetes in Podman/Docker) and pre-configures port forwarding so you don't have to manage `kubectl port-forward` sessions.

## Prerequisites

* **Container Engine:** [Docker](https://docs.docker.com/get-docker/) **OR** [Podman](https://podman.io/getting-started/installation)
* [Kind](https://www.google.com/search?q=https://kind.sigs.k8s.io/docs/user/quick-start/%23installation)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

### Single Cluster (Hub Only)

1. **Clone this repo:**

    ```bash
    git clone <your-repo-url>
    cd <your-repo-name>
    ```

2. **Spin up the hub cluster:**

    ```bash
    chmod +x argo-lab.sh
    ./argo-lab.sh up
    ```

3. **Access the UIs:**

* **ArgoCD:** [https://localhost:8080](https://localhost:8080) (User: `admin`)
* **Workflows:** [http://localhost:2746](http://localhost:2746)
* **Rollouts:** Run `kubectl argo rollouts dashboard`

### Multicluster (Hub + Spoke)

For learning multicluster deployments with ArgoCD:

1. **Spin up both hub and spoke clusters:**

    ```bash
    ./argo-lab.sh up-multi
    ```

2. **Register the spoke cluster with hub ArgoCD:**

    The script will print instructions. Either use the CLI:

    ```bash
    kubectl config use-context kind-argo-learning-hub
    argocd cluster add kind-argo-learning-spoke
    ```

    Or register via the ArgoCD UI at [https://localhost:8080/settings/clusters](https://localhost:8080/settings/clusters).

3. **Access the UIs:**

* **Hub ArgoCD:** [https://localhost:8080](https://localhost:8080) (controls both clusters)
* **Hub Workflows:** [http://localhost:2746](http://localhost:2746)
* **Spoke App:** [http://localhost:8888](http://localhost:8888) (example app port)

## Project Structure

* `argo-kind-config-hub.yaml`: Hub cluster definition with ArgoCD, Workflows, and Rollouts port mappings.
* `argo-kind-config-spoke.yaml`: Spoke cluster definition (no Argo components—managed by hub).
* `argo-lab.sh`: The automation script that handles cluster creation, namespace setup, app installation, and service patching.

## Commands

| Command | Action |
| --- | --- |
| `./argo-lab.sh up` | Creates hub cluster and installs all Argo components. |
| `./argo-lab.sh up-multi` | Creates hub and spoke clusters for multicluster learning. |
| `./argo-lab.sh down` | Deletes the hub cluster. |
| `./argo-lab.sh down-multi` | Deletes both hub and spoke clusters. |
| `./argo-lab.sh info` | Re-prints hub cluster connection info and password. |
| `./argo-lab.sh help` | Shows usage and available commands. |

## Notes

* **SSL Warning:** When opening ArgoCD, your browser will show an SSL warning (due to self-signed certs).
* **Auth:** Argo Workflows is configured in `server` auth mode for easy learning (no login token required).
* **For Podman users:**  Ensure your Podman machine is started and the `KIND_EXPERIMENTAL_PROVIDER` env variable is set if using older versions of Kind.

```bash
podman machine start
export KIND_EXPERIMENTAL_PROVIDER=podman
```
