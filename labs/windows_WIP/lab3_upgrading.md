# Lab 3: Upgrading your Kubernetes Cluster

## View available upgrade/downgrade options
To see available upgrade/downgrade options for Kubernetes:
```
dcos kubernetes manager update package-versions
```

## Upgrade Kubernetes cluster
Run the following command to upgrade your Kubernetes cluster:
```
dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster%CLUSTER% --package-version=2.3.0-1.14.1
```

## Watch your Kubernetes cluster upgrade
Watch your upgrade using the DC/OS Kubernetes CLI, if you try this in a new tab don't forget to set your variables again
```
CLUSTER=
dcos kubernetes cluster debug plan status deploy --cluster-name=training/prod/k8s/cluster%CLUSTER%
```

Output should look similar to below:
```
$ dcos kubernetes cluster debug plan status deploy --cluster-name=training/prod/k8s/cluster%CLUSTER%
Using Kubernetes cluster: training/prod/k8s/cluster01
deploy (serial strategy) (IN_PROGRESS)
├─ etcd (serial strategy) (STARTED)
│  └─ etcd-0:[peer] (STARTED)
├─ control-plane (parallel strategy) (PENDING)
│  └─ kube-control-plane-0:[instance] (PENDING)
├─ mandatory-addons (serial strategy) (PENDING)
│  └─ mandatory-addons-0:[instance] (PENDING)
├─ node (serial strategy) (PENDING)
│  ├─ mark-kube-node-0-unschedulable (PENDING)
│  ├─ drain-kube-node-0 (PENDING)
│  ├─ kube-node-0:[kubelet] (PENDING)
│  ├─ mark-kube-node-0-schedulable (PENDING)
│  ├─ mark-kube-node-1-unschedulable (PENDING)
│  ├─ drain-kube-node-1 (PENDING)
│  ├─ kube-node-1:[kubelet] (PENDING)
│  └─ mark-kube-node-1-schedulable (PENDING)
└─ public-node (parallel strategy) (COMPLETE)
```

## Validate Kubernetes upgrade
You can validate that the cluster has been updated using kubectl
```
kubectl --kubeconfig=./config.cluster%CLUSTER% get nodes
```

Output should look similar to below:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% get nodes
NAME                                                          STATUS   ROLES    AGE   VERSION
kube-control-plane-0-instance.trainingprodk8scluster%CLUSTER}.mesos   Ready    master   94m   v1.14.1
kube-node-0-kubelet.trainingprodk8scluster%CLUSTER}.mesos             Ready    <none>   92m   v1.14.1
kube-node-1-kubelet.trainingprodk8scluster%CLUSTER}.mesos             Ready    <none>   92m   v1.14.1
kube-node-2-kubelet.trainingprodk8scluster%CLUSTER}.mesos             Ready    <none>   36m   v1.14.1
```

You can also see in the UI that cluster01 has been upgraded to 1.13.5
![Upgrade](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab3_1.png)

## Finished with the Lab 3 - Upgrading

[Move to Lab 4 - Loadbalancing](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/lab4_loadbalancing.md)
