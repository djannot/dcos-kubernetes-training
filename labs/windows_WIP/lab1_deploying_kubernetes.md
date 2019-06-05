# Lab 1: Deploy a Kubernetes cluster

## Install the DC/OS Kubernetes CLI:
The DC/OS Kubernetes CLI aims to help operators deploy, operate, maintain, and troubleshoot Kubernetes clusters running on DC/OS
```
dcos package install kubernetes --cli --yes
```

## Create an options.json for your Kubernetes deployment
```
set FILE=options-kubernetes-cluster%CLUSTER%.json
>%FILE% echo {
>>%FILE% echo   "service": {
>>%FILE% echo     "name": "training/prod/k8s/cluster%CLUSTER%",
>>%FILE% echo     "service_account": "training-prod-k8s-cluster%CLUSTER%",
>>%FILE% echo     "service_account_secret": "/training/prod/k8s/cluster%CLUSTER%/private-training-prod-k8s-cluster%CLUSTER%"
>>%FILE% echo   },
>>%FILE% echo   "kubernetes": {
>>%FILE% echo     "authorization_mode": "RBAC",
>>%FILE% echo     "high_availability": false,
>>%FILE% echo     "private_node_count": 2,
>>%FILE% echo     "private_reserved_resources": {
>>%FILE% echo     "kube_mem": 4096
>>%FILE% echo     }
>>%FILE% echo   }
>>%FILE% echo }
```

## Create Kubernetes cluster service account, assign permissions, and deploy a cluster
Create a file called deploy-kubernetes-cluster.bat with the following content:
```
set clusterpath=%APPNAME%/prod/k8s/cluster%1%
set serviceaccount=%APPNAME%-prod-k8s-cluster%1%
set role=%APPNAME%__prod__k8s__cluster%1%-role

dcos security org service-accounts keypair private-%serviceaccount%.pem public-%serviceaccount%.pem
dcos security org service-accounts delete %serviceaccount%
dcos security org service-accounts create -p public-%serviceaccount%.pem -d /%clusterpath% %serviceaccount%
dcos security secrets delete /%clusterpath%/private-%serviceaccount%
dcos security secrets create-sa-secret --strict private-%serviceaccount%.pem %serviceaccount% /%clusterpath%/private-%serviceaccount%

dcos security org users grant %serviceaccount% dcos:secrets:default:/%clusterpath%/* full
dcos security org users grant %serviceaccount% dcos:secrets:list:default:/%clusterpath% full
dcos security org users grant %serviceaccount% dcos:adminrouter:ops:ca:rw full
dcos security org users grant %serviceaccount% dcos:adminrouter:ops:ca:ro full
dcos security org users grant %serviceaccount% dcos:mesos:master:framework:role:%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:reservation:role:%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:reservation:principal:%serviceaccount% delete
dcos security org users grant %serviceaccount% dcos:mesos:master:volume:role:%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:volume:principal:%serviceaccount% delete
dcos security org users grant %serviceaccount% dcos:mesos:master:task:user:nobody create
dcos security org users grant %serviceaccount% dcos:mesos:master:task:user:root create
dcos security org users grant %serviceaccount% dcos:mesos:agent:task:user:root create
dcos security org users grant %serviceaccount% dcos:mesos:master:framework:role:slave_public/%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:framework:role:slave_public/%role% read
dcos security org users grant %serviceaccount% dcos:mesos:master:reservation:role:slave_public/%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:volume:role:slave_public/%role% create
dcos security org users grant %serviceaccount% dcos:mesos:master:framework:role:slave_public read
dcos security org users grant %serviceaccount% dcos:mesos:agent:framework:role:slave_public read

dcos kubernetes cluster create --yes --options=options-kubernetes-cluster%1%.json --package-version=2.2.2-1.13.5
```

## Deploy Kubernetes

To deploy your kubernetes cluster:
```
deploy-kubernetes-cluster.bat %CLUSTER%
```

Note: Ignore the 204/404 and `Does not exist` errors, these are normal.

To see the status of your Kubernetes cluster deployment run:
```
dcos kubernetes cluster kubeconfig --context-name=%APPNAME%-prod-k8s-cluster%CLUSTER% --cluster-name=%APPNAME%/prod/k8s/cluster%CLUSTER% \
    --apiserver-url https://%APPNAME%.prod.k8s.cluster%CLUSTER%.mesos.lab:8443 \
    --insecure-skip-tls-verify
```

## Connect to Kubernetes cluster using kubectl
Configure the Kubernetes CLI using the following command:
```
dcos kubernetes cluster kubeconfig --context-name=%APPNAME%-prod-k8s-cluster%CLUSTER% --cluster-name=%APPNAME%/prod/k8s/cluster%CLUSTER% \
    --apiserver-url https://%APPNAME%.prod.k8s.cluster%CLUSTER%.mesos.lab:8443 \
    --insecure-skip-tls-verify
```

Change the name of the kubectl config file and copy to your local directory because this config is temporary
```
copy "%USERPROFILE%"\.kube\config .
```

Run the following command to check that everything is working properly:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% get nodes
```

Output should look similar to below:
```
$ kubectl --kubeconfig=./config.cluster%CLUSTER% get nodes
NAME                                                           STATUS   ROLES    AGE   VERSION
kube-control-plane-0-instance.trainingprodk8scluster01.mesos   Ready    master   17m   v1.13.5
kube-node-0-kubelet.trainingprodk8scluster01.mesos             Ready    <none>   16m   v1.13.5
kube-node-1-kubelet.trainingprodk8scluster01.mesos             Ready    <none>   16m   v1.13.5
```

## Connect to the Kubernetes dashboard
Run the following command **in a different shell** to run a proxy that will allow you to access the Kubernetes Dashboard:

```
kubectl --kubeconfig=./config.cluster%CLUSTER% proxy
```

Open the following page in your web browser:

[http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/](http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/)

Login using the config file.

![Kubernetes dashboard](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab1_1.png)

## Finished with the Lab 1 - Deploying Kubernetes

[Move to Lab 2 - Scaling](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/windows_WIP/lab2_scaling.md)
