# Argo Learning Lab (Quick & Dirty)

This repo provides a "one-command" setup for a local Kubernetes environment running the full Argo suite (**ArgoCD**, **Workflows**, and **Rollouts**). It uses **Kind** (Kubernetes in Podman/Docker) and pre-configures port forwarding so you don't have to manage `kubectl port-forward` sessions.

## Prerequisites

* **Container Engine:** [Docker](https://docs.docker.com/get-docker/) **OR** [Podman](https://podman.io/getting-started/installation)
* [Kind](https://www.google.com/search?q=https://kind.sigs.k8s.io/docs/user/quick-start/%23installation)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

1. **Clone this repo:**
```bash
git clone <your-repo-url>
cd <your-repo-name>

```

2. **Spin up the lab:**
```bash
chmod +x argo-lab.sh
./argo-lab.sh up

```

3. **Access the UIs:**
* **ArgoCD:** [https://localhost:8080](https://www.google.com/search?q=https://localhost:8080) (User: `admin`)
* **Workflows:** [http://localhost:2746](https://www.google.com/search?q=http://localhost:2746)
* **Rollouts:** Run `kubectl argo rollouts dashboard`

##  Project Structure

* `kind-config.yaml`: Defines the cluster and "bakes in" the port mappings for your host machine.
* `argo-lab.sh`: The automation script that handles cluster creation, namespace setup, app installation, and service patching.

## Commands

| Command | Action |
| --- | --- |
| `./argo-lab.sh up` | Creates cluster and installs all Argo components. |
| `./argo-lab.sh down` | Completely deletes the cluster and cleans up Docker. |

## Notes

* **SSL Warning:** When opening ArgoCD, your browser will show an SSL warning (due to self-signed certs). Click **Advanced** -> **Proceed** (or type `thisisunsafe` in Chrome).
* **Auth:** Argo Workflows is configured in `server` auth mode for easy learning (no login token required).

**Note for Podman users:**  Ensure your Podman machine is started and the `KIND_EXPERIMENTAL_PROVIDER` env variable is set if using older versions of Kind.

```bash
podman machine start
export KIND_EXPERIMENTAL_PROVIDER=podman
```


