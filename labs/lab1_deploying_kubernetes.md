# Lab 1: Deploy a Kubernetes cluster

## Install the DC/OS Kubernetes CLI:
The DC/OS Kubernetes CLI aims to help operators deploy, operate, maintain, and troubleshoot Kubernetes clusters running on DC/OS
```
dcos package install kubernetes --cli --yes
```

## Create Kubernetes cluster service account, assign permissions, and deploy a cluster
First we need to create and configure permissions for our kubernetes cluster to be deployed
```
./setup-kubernetes-cluster-permissions.sh
```

Note: Ignore the 204/404 and `Does not exist` errors, these are normal.

## Deploy Kubernetes
First modify the options-kubernetes-cluster${CLUSTER}.json to match your student ID number
```
sed "s/TOBEREPLACED/${CLUSTER}/g" options-kubernetes-cluster.json.template > options-kubernetes-cluster${CLUSTER}.json
```

To deploy your kubernetes cluster:
```
dcos kubernetes cluster create --yes --options=options-kubernetes-cluster${CLUSTER}.json --package-version=2.2.1-1.13.4
```

To see the status of your Kubernetes cluster deployment run:
```
dcos kubernetes cluster debug plan status deploy --cluster-name=${APPNAME}/prod/k8s/cluster${CLUSTER}
```

## Connect to Kubernetes cluster using kubectl
Configure the Kubernetes CLI using the following command:
```
dcos kubernetes cluster kubeconfig --context-name=${APPNAME}-prod-k8s-cluster${CLUSTER} --cluster-name=${APPNAME}/prod/k8s/cluster${CLUSTER} \
    --apiserver-url https://${APPNAME}.prod.k8s.cluster${CLUSTER}.mesos.lab:8443 \
    --insecure-skip-tls-verify
```

Change the name of the kubectl config file and copy to your local directory because this config is temporary
```
mv ~/.kube/config ./config.cluster${CLUSTER}
```

Run the following command to check that everything is working properly:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} get nodes
```

Output should look similar to below:
```
$ kubectl get nodes
NAME                                                           STATUS   ROLES    AGE   VERSION
kube-control-plane-0-instance.trainingprodk8scluster01.mesos   Ready    master   17m   v1.13.4
kube-node-0-kubelet.trainingprodk8scluster01.mesos             Ready    <none>   16m   v1.13.4
kube-node-1-kubelet.trainingprodk8scluster01.mesos             Ready    <none>   16m   v1.13.4
```

## Connect to the Kubernetes dashboard
Run the following command **in a different shell** to run a proxy that will allow you to access the Kubernetes Dashboard:

```
kubectl --kubeconfig=./config.cluster${CLUSTER} proxy
```

Open the following page in your web browser:

[http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/](http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/)

Login using the config file.

![Kubernetes dashboard](https://github.com/ably77/dcos-kubernetes-training/blob/master/images/lab1_1.png)

## Finished with the Lab 1 - Deploying Kubernetes

[Move to Lab 2 - Scaling](https://github.com/ably77/dcos-kubernetes-training/blob/master/labs/lab2_scaling.md)
