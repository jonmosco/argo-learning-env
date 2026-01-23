# Argo Workflows

To successfully deploy this Workflow we need to temporarily grant admin permissions to argo
ServiceAccount with the following command:

```sh
kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=argo:default -n argo
```
