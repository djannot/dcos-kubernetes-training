# Lab 10: Monitoring a Kubernetes Cluster

### Objectives
- Monitoring a Kubernetes Cluster with Grafana (part of the DC/OS Moniroring package)

### Why is this Important?
When a Kubernetes cluster doesn't behave well, it's important to check key metrics (like CPU usage, previous failures, ...).

## Edit your options.json
Edit the options-kubernetes-cluster${CLUSTER}.json file to set add the metrics_exporter parameter.
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
    },
    "metrics_exporter": {
      "enabled": true
    }
  }
}
```

## Update your Kubernetes cluster
Run the following command to update your cluster
```
dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster${CLUSTER} --options=options-kubernetes-cluster${CLUSTER}.json --yes
```

Output should look similar to below once completed
```
Using Kubernetes cluster: training/prod/k8s/cluster1
2019/01/26 14:40:51 starting update process...
2019/01/26 14:40:58 waiting for update to finish...
2019/01/26 14:42:10 update complete!
```

Navigate to the UI --> services --> training --> prod --> k8s --> cluster${CLUSTER} to see the update visually

![Monitoring - DC/OS Services Console](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab9_1.png)

## Access the Grafana UI

Navigate to the UI --> services --> infra --> monitoring and click on the small icon beside dcos-monitoring

![Monitoring - Grafana UI](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab9_2.png)

Select the DC/OS Defaults / DC/OS Overview top menu to show the DC/OS Defaults folder, click on the folder to expose the available pre-configured dashboards.  Select the Kubernetes: Cluster Health dashboard and then your Kubernetes cluster.

![Monitoring - Cluster Health dashboard](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab9_3.png)

Take a look at the other Dashboards available for Kubernetes and for DC/OS itself.

# Congrats! We are now done with all of the labs!
