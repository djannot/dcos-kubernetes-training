# Lab 7: Leverage persistent storage using CSI
The goal of CSI is to establish a standardized mechanism for Container Orchestration Systems (COs) to expose arbitrary storage systems to their containerized workloads. The CSI specification emerged from cooperation between community members from various Container Orchestration Systems (COs)–including Kubernetes, Mesos, Docker, and Cloud Foundry.

## Set up CSI driver for AWS
Unzip the archive containing the CSI driver for AWS:
```
unzip csi-driver-deployments-master.zip
```

## Deploy AWS CSI drivers
Deploy the Kubernetes manifests in your cluster using the following command
```
kubectl --kubeconfig=./config.cluster%CLUSTER% apply -f csi-driver-deployments-master/aws-ebs/kubernetes/latest/
```

## Create Kubernetes StorageClass
Create the Kubernetes StorageClass using the following command. This time we define the Storage Class as the default one while we create it.
```
set FILE=storageclass.yml
>%FILE% echo kind: StorageClass
>>%FILE% echo apiVersion: storage.k8s.io/v1
>>%FILE% echo metadata:
>>%FILE% echo   name: ebs-gp2
>>%FILE% echo   annotations:
>>%FILE% echo     storageclass.kubernetes.io/is-default-class: "true"
>>%FILE% echo provisioner: ebs.csi.aws.com
>>%FILE% echo volumeBindingMode: WaitForFirstConsumer
>>%FILE% echo parameters:
>>%FILE% echo   type: gp2
>>%FILE% echo   fsType: ext4
>>%FILE% echo   encrypted: "false"
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f storageclass.yml
```

## Create Kubernetes PersistentVolumeClaim
Create the Kubernetes PersistentVolumeClaim using the following command
```
set FILE=pvc.yml
>%FILE% echo apiVersion: v1
>>%FILE% echo kind: PersistentVolumeClaim
>>%FILE% echo metadata:
>>%FILE% echo   name: dynamic
>>%FILE% echo spec:
>>%FILE% echo   accessModes:
>>%FILE% echo     - ReadWriteOnce
>>%FILE% echo   storageClassName: ebs-gp2
>>%FILE% echo   resources:
>>%FILE% echo     requests:
>>%FILE% echo       storage: 1Gi
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f pvc.yml
```

## Create a service that will use this PVC and dynamically provision an EBS volume
Create a Kubernetes Deployment that will use this PersistentVolumeClaim using the following command
```
set FILE=deployment.yml
>%FILE% echo apiVersion: apps/v1
>>%FILE% echo kind: Deployment
>>%FILE% echo metadata:
>>%FILE% echo   name: ebs-dynamic-app
>>%FILE% echo   labels:
>>%FILE% echo     app: ebs-dynamic-app
>>%FILE% echo spec:
>>%FILE% echo   replicas: 1
>>%FILE% echo   selector:
>>%FILE% echo     matchLabels:
>>%FILE% echo       app: ebs-dynamic-app
>>%FILE% echo   template:
>>%FILE% echo     metadata:
>>%FILE% echo       labels:
>>%FILE% echo         app: ebs-dynamic-app
>>%FILE% echo     spec:
>>%FILE% echo       containers:
>>%FILE% echo       - name: ebs-dynamic-app
>>%FILE% echo         image: centos:7
>>%FILE% echo         command: ["/bin/sh"]
>>%FILE% echo         args: ["-c", "while true; do echo \$(date -u) >> /data/out.txt; sleep 5; done"]
>>%FILE% echo         volumeMounts:
>>%FILE% echo         - name: persistent-storage
>>%FILE% echo           mountPath: /data
>>%FILE% echo       volumes:
>>%FILE% echo       - name: persistent-storage
>>%FILE% echo         persistentVolumeClaim:
>>%FILE% echo           claimName: dynamic
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f deployment.yml
```

**NOTE** This may take a few minutes to deploy

Describe the `ebs-dynamic app`
```
kubectl --kubeconfig=./config.cluster%CLUSTER% describe deployment ebs-dynamic-app
```

## What does this app do?
This app is pretty simple, it deploys a centOS7 image from dockerhub and dynamically creates and mounts an EBS volume using the AWS CSI storage plugin that we set up in prior steps!

## Check status of deployment
Check the status of the Deployment to make sure that the ebs-dynamic-app is up before continuing
```
kubectl --kubeconfig=./config.cluster%CLUSTER% get deployments
```

## Validate Persistence
Check the content of the file /data/out.txt and note the first timestamp:
```
@powershell "$pod = (.\kubectl get pods | findstr ebs-dynamic-app).split(\" \",3)[0]; .\kubectl exec -i $pod cat /data/out.txt"
```

Delete the Pod using the following command. The Deployment will recreate the pod automatically since `replicas` was set to 1.
```
kubectl --kubeconfig=./config.cluster%CLUSTER% delete pod $pod
```
**NOTE** This may take a few minutes to delete and redeploy

Check the status of the Deployment to make sure that the ebs-dynamic-app is up
```
kubectl --kubeconfig=./config.cluster%CLUSTER% get deployments
```

Check the content of the file /data/out.txt and verify that the first timestamp is the same as the one noted previously:
```
@powershell "$pod = (.\kubectl get pods | findstr ebs-dynamic-app).split(\" \",3)[0]; .\kubectl delete pod $pod
```

## Finished with the Lab 7 - CSI Storage

[Move to Lab 8 - Configuring Helm](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/windows_WIP/lab8_configure_helm.md)
