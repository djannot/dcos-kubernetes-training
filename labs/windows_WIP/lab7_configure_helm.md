# Lab 7: Configure Helm

Helm is a package manager for Kubernetes. Helm Charts helps you define, install, and upgrade even the most complex Kubernetes applications.

## Install Helm on your local machine
Intall Helm on your local machine using the instructions available at the URL below:

[https://docs.helm.sh/using_helm/#installing-helm](https://github.com/helm/helm)
[https://docs.helm.sh/using_helm/#using-helm](https://docs.helm.sh/using_helm/#installing-helm)

Chocolatey users:
```
choco install kubernetes-helm
```

## Install Tiller
Tiller is the in-cluster component of Helm. It interacts directly with the Kubernetes API server to install, upgrade, query, and remove Kubernetes resources. It also stores the objects that represent releases.

Run the following command to create a Kubernetes ServiceAccount for the Helm Tiller:
```
set FILE=tiller.yml
>%FILE% echo apiVersion: v1
>>%FILE% echo kind: ServiceAccount
>>%FILE% echo metadata:
>>%FILE% echo   name: tiller
>>%FILE% echo   namespace: kube-system
>>%FILE% echo ---
>>%FILE% echo apiVersion: rbac.authorization.k8s.io/v1beta1
>>%FILE% echo kind: ClusterRoleBinding
>>%FILE% echo metadata:
>>%FILE% echo   name: tiller
>>%FILE% echo roleRef:
>>%FILE% echo   apiGroup: rbac.authorization.k8s.io
>>%FILE% echo   kind: ClusterRole
>>%FILE% echo   name: cluster-admin
>>%FILE% echo subjects:
>>%FILE% echo - kind: ServiceAccount
>>%FILE% echo   name: tiller
>>%FILE% echo   namespace: kube-system
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f tiller.yml
```

Run the following command to install Tiller into your Kubernetes cluster:
```
helm --kubeconfig=./config.cluster%CLUSTER% init --service-account tiller
```

## Finished with the Lab 7 - Configure Helm

[Move to Lab 8 - Istio](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/windows_WIP/lab8_istio.md)
