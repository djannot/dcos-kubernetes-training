# Lab 6: Leverage persistent storage using CSI

### Objectives
- Deploy the AWS EBS CSI Driver on your existing kubernetes cluster
- Create a kubernetes StorageClass to use the AWS CSI driver
- Create a PersistentVolumeClaim (pvc) to use the AWS EBS CSI driver
- Create a service that will use this PVC and dynamically provision an EBS volume
- Validate persistence

### Why is this Important?
The goal of CSI is to establish a standardized mechanism for Container Orchestration Systems (COs) to expose arbitrary storage systems to their containerized workloads. The CSI specification emerged from cooperation between community members from various Container Orchestration Systems (COs)–including Kubernetes, Mesos, Docker, and Cloud Foundry.

By creating an industry standard interface, the CSI initiative sets ground rules in order to minimize user confusion. By providing a pluggable standardized interface, the community will be able to adopt and maintain new CSI-enabled storage drivers to their kubernetes clusters as they mature. Choosing a solution that supports CSI integration will allow your business to adopt the latest and greatest storage solutions with ease.

## Set up CSI driver for AWS
Unzip the archive containing the CSI driver for AWS:
```
unzip csi-driver-deployments-master.zip
```

## Deploy AWS CSI drivers
Deploy the Kubernetes manifests in your cluster using the following command
```
kubectl --kubeconfig=./config.cluster${CLUSTER} apply -f csi-driver-deployments-master/aws-ebs/kubernetes/latest/
```

## Create Kubernetes StorageClass
Create the Kubernetes StorageClass using the following command. This time we define the Storage Class as the default one while we create it.
```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: ebs-gp2
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp2
  fsType: ext4
  encrypted: "false"
EOF
```

## Create Kubernetes PersistentVolumeClaim
Create the Kubernetes PersistentVolumeClaim using the following command
```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-gp2
  resources:
    requests:
      storage: 1Gi
EOF
```

## Create a service that will use this PVC and dynamically provision an EBS volume
Create a Kubernetes Deployment that will use this PersistentVolumeClaim using the following command
```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ebs-dynamic-app
  labels:
    app: ebs-dynamic-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ebs-dynamic-app
  template:
    metadata:
      labels:
        app: ebs-dynamic-app
    spec:
      containers:
      - name: ebs-dynamic-app
        image: centos:7
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo \$(date -u) >> /data/out.txt; sleep 5; done"]
        volumeMounts:
        - name: persistent-storage
          mountPath: /data
      volumes:
      - name: persistent-storage
        persistentVolumeClaim:
          claimName: dynamic
EOF
```

**NOTE** This may take a few minutes to deploy

Describe the `ebs-dynamic app`
```
kubectl --kubeconfig=./config.cluster${CLUSTER} describe deployment ebs-dynamic-app
```

## What does this app do?
This app is pretty simple, it deploys a centOS7 image from dockerhub and dynamically creates and mounts an EBS volume using the AWS CSI storage plugin that we set up in prior steps!

## Check status of deployment
Check the status of the Deployment to make sure that the ebs-dynamic-app is up before continuing
```
kubectl --kubeconfig=./config.cluster${CLUSTER} get deployments
```

## Validate Persistence
Check the content of the file /data/out.txt and note the first timestamp:
```
pod=$(kubectl --kubeconfig=./config.cluster${CLUSTER} get pods | grep ebs-dynamic-app | awk '{ print $1 }')
kubectl --kubeconfig=./config.cluster${CLUSTER} exec -i $pod cat /data/out.txt
```

Delete the Pod using the following command. The Deployment will recreate the pod automatically since `replicas` was set to 1.
```
kubectl --kubeconfig=./config.cluster${CLUSTER} delete pod $pod
```
**NOTE** This may take a few minutes to delete and redeploy

Check the status of the Deployment to make sure that the ebs-dynamic-app is up
```
kubectl --kubeconfig=./config.cluster${CLUSTER} get deployments
```

Check the content of the file /data/out.txt and verify that the first timestamp is the same as the one noted previously:
```
pod=$(kubectl --kubeconfig=./config.cluster${CLUSTER} get pods | grep ebs-dynamic-app | awk '{ print $1 }')
kubectl --kubeconfig=./config.cluster${CLUSTER} exec -i $pod cat /data/out.txt
```

## Finished with the Lab 6 - CSI Storage

[Move to Lab 7 - Configuring Helm](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/linux-macOS/lab7_configure_helm.md)
