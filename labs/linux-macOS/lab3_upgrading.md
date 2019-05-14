# Lab 3: Upgrading your Kubernetes Cluster

### Objectives
- Upgrade existing kubernetes cluster v1.13.4 to v1.13.5

### Why is this Important?
Kubernetes is one of the largest community-driven Open Source projects in the industry with over 2100+ contributors to the project since it's inception in July 2015. Because of its following, new features are developed for the platform at a very fast pace. As developers continue to demand the latest and greatest technology, choosing a platform that allows you to easily upgrade your kubernetes cluster without any downtime is critical.

#### Security patches and bug fixes
On several occasions, the kubernetes community has found security issues (see [Kubernetes CVEs](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=kubernetes) which typically require an upgrade in order to resolve. Choosing a kubernetes provider that will provide an upgrade path along quickly along with guidance from enterprise support along the way is critical when running kubernetes in production.

## View available upgrade/downgrade options
To see available upgrade/downgrade options for Kubernetes:
```
dcos kubernetes manager update package-versions
```

## Upgrade Kubernetes cluster
Run the following command to upgrade your Kubernetes cluster:
```
dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster${CLUSTER} --package-version=2.2.2-1.13.5
```

## Watch your Kubernetes cluster upgrade
Watch your upgrade using the DC/OS Kubernetes CLI, if you try this in a new tab don't forget to set your variables again
```
CLUSTER=
dcos kubernetes cluster debug plan status deploy --cluster-name=training/prod/k8s/cluster${CLUSTER}
```

Output should look similar to below:
```
$ dcos kubernetes cluster debug plan status deploy --cluster-name=training/prod/k8s/cluster${CLUSTER}
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
kubectl get nodes
```

Output should look similar to below:
```
kubectl get nodes
NAME                                                          STATUS   ROLES    AGE   VERSION
kube-control-plane-0-instance.trainingprodk8scluster${CLUSTER}.mesos   Ready    master   94m   v1.13.5
kube-node-0-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   92m   v1.13.5
kube-node-1-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   92m   v1.13.5
kube-node-2-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   36m   v1.13.5
```

You can also see in the UI that cluster01 has been upgraded to 1.13.5
![Upgrade](https://github.com/ably77/dcos-kubernetes-training/blob/master/images/lab3_1.png)

## Finished with the Lab 3 - Upgrading

[Move to Lab 4 - Loadbalancing](https://github.com/ably77/dcos-kubernetes-training/blob/master/labs/linux-macOS/lab4_loadbalancing.md)
