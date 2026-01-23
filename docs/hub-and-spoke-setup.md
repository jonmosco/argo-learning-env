# Hub and Spoke Setup

Even once you get the correct server, kind usually gives `127.0.0.1:<port>` which works from your host, but won’t work from Argo pods inside the hub cluster. When you’re ready, we’ll swap that server to something reachable (e.g., spoke control-plane container IP or a shared network endpoint).

## Get the spoke cluster data

Get the server URL from the current context:

```sh
kubectl --context kind-argo-learning-spoke config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}{"\n"}'
```

Get the CA Bundle:

```sh
kubectl --context kind-argo-learning-spoke config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}{"\n"}'
```

Create a ServiceAccount on the spoke and get a token

```sh
kubectl --context kind-remote create sa argocd-manager -n kube-system

kubectl --context kind-remote create clusterrolebinding argocd-manager-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:argocd-manager
```

```sh
argocd cluster list
```

## least-privilege RBAC for ArgoCD Spoke Service Account

Least-privilege for an Argo CD “spoke” ServiceAccount usually ends up as two layers:

* Cluster-wide read-only (very small) so Argo can see the destination namespaces exist (and sometimes do basic discovery/health checks)
* Namespace-scoped write only in the namespaces you explicitly allow Argo to deploy into
