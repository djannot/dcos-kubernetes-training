# Lab 8: Configure Helm

### Objectives
- Install helm on your local machine
- Install tiller on your kubernetes cluster to interact with helm

### Why is this Important?
Helm is a package manager for kubernetes. Helm Charts helps you define, install, and upgrade even the most complex kubernetes applications. Helm also allows you to provide application configuration during deployment. It lowers the bar of entry for coders not yet familiar with kubernetes by providing a yum-like user experience with an intuitive CLI that is familiar.

## Install Helm on your local machine
Intall Helm on your local machine using the instructions available at the URL below:

[https://docs.helm.sh/using_helm/#installing-helm](https://github.com/helm/helm)
[https://docs.helm.sh/using_helm/#using-helm](https://docs.helm.sh/using_helm/#installing-helm)

Homebrew users:
```
brew install kubernetes-helm
```

Chocolatey users:
```
choco install kubernetes-helm
```

## Install Tiller
Tiller is the in-cluster component of Helm. It interacts directly with the Kubernetes API server to install, upgrade, query, and remove Kubernetes resources. It also stores the objects that represent releases.

Run the following command to create a Kubernetes ServiceAccount for the Helm Tiller:
```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: kube-system
EOF
```

Run the following command to install Tiller into your Kubernetes cluster:
```
helm --kubeconfig=./config.cluster${CLUSTER} init --service-account tiller
```

## Finished with the Lab 8 - Configure Helm

[Move to Lab 9 - Istio](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/linux-macOS/lab9_istio.md)
