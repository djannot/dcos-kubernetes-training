# Lab 2: Scaling a Kubernetes Cluster

### Objectives
- Scale existing kubernetes cluster from 2 kubelet nodes to 3

### Why is this Important?
Often times we find that workloads can be intermittent in load. The ability to easily scale up and scale down resources allows operators the ability to dynamically scale workloads to meet expected demand.

## Edit your options.json
Edit the options-kubernetes-cluster${CLUSTER}.json file to set the private_node_count to 3.
```
{
  "service": {
    "name": "training/prod/k8s/cluster01",
    "service_account": "training-prod-k8s-cluster01",
    "service_account_secret": "/training/prod/k8s/cluster01/private-training-prod-k8s-cluster01"
  },
  "kubernetes": {
    "authorization_mode": "RBAC",
    "high_availability": false,
    "private_node_count": 3,
    "private_reserved_resources": {
      "kube_mem": 4096
    }
  }
}
```

## Scale your Kubernetes cluster
Run the following command to update your cluster
```
dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster${CLUSTER} --options=options-kubernetes-cluster${CLUSTER}.json --yes
```

Navigate to the UI --> services --> training --> prod --> k8s --> cluster${CLUSTER} to see the upgrade visually

![Scaling - DC/OS Services Console](https://github.com/ably77/dcos-kubernetes-training/blob/master/images/lab2_1.png)

Output should look similar to below once completed
```
Using Kubernetes cluster: training/prod/k8s/cluster1
2019/01/26 14:40:51 starting update process...
2019/01/26 14:40:58 waiting for update to finish...
2019/01/26 14:42:10 update complete!
```

## Validate Kubernetes update
You can also use the CLI to check the status of your update, if you try this in a new tab don't forget to set your variables again
```
dcos kubernetes cluster debug plan status deploy --cluster-name=${APPNAME}/prod/k8s/cluster${CLUSTER}
```

You can check that the new node is shown in the Kubernetes Dashboard:

![Kubernetes dashboard scaled](https://github.com/ably77/dcos-kubernetes-training/blob/master/images/lab2_2.png)

## Finished with the Lab 2 - Scaling

[Move to Lab 3 - Upgrading Kubernetes](https://github.com/ably77/dcos-kubernetes-training/blob/master/labs/linux-macOS/lab3_upgrading.md)
