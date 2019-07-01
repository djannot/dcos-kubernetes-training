# Lab 6: Leverage persistent storage using Portworx
Portworx is a Software Defined Software that can use the local storage of the DC/OS nodes to provide High Available persistent storage to both Kubernetes pods and DC/OS services.

### Objectives
- Use the Portworx Storage Service on DC/OS to leverage persistent storage using a kubernetes StorageClass
- Create a PersistentVolumeClaim (pvc) to use volumes created in Portworx
- Create a Pod service that will consume this pvc, write data to the persistent volume, and delete the Pod
- Create a second Pod service that will consume the same pvc and validate that data persisted

### Why is this Important?
In recent years, containerization has become a popular way to bundle applications in a way that can be created and destroyed as often as needed. However, initially the containerization space did not support persistent storage, meaning that the data created within a container would disappear when the app finished its work and the container was destroyed. For many use-cases this is undesirable, and the industry has met the need by providing methods of retaining data created by storing them in persistent volumes. This allows for stateful applications such as databases to remain available even if a container goes down.

Mesosphere provides multiple ways to achieving persistent storage for containerized applications. Portworx has been a partner of Mesosphere for many years and is a leading solution for container-based storage on the market. The Portworx solution is well integrated with the Mesos, DC/OS, and the Kubernetes community.


## Deploy Portworx Stork service on your Kubernetes cluster

To be able to use Portworx persistent storage on your Kubernetes cluster, you need to deploy it in your Kubernetes cluster using the following command:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} apply -f "https://install.portworx.com/2.0?kbver=1.14.3&b=true&dcos=true&stork=true"
```

## Create Kubernetes StorageClass
Create the Kubernetes StorageClass using the following command. This will create volumes on Portworx with 2 replicas.
```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
   name: portworx-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "2"
EOF
```

## Set default StorageClass to Portworx
Run the following command to define this StorageClass as the default Storage Class in your Kubernetes cluster:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} patch storageclass portworx-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## Create Kubernetes PersistentVolumeClaim
Create the Kubernetes PersistentVolumeClaim using the following command:
```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc001
  annotations:
    volume.beta.kubernetes.io/storage-class: portworx-sc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
```

Check the status of the PersistentVolumeClaim using the following command:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} describe pvc pvc001
```

Wait as the PVC is being built, this may take a few moments. Output should looks similar to below:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} describe pvc pvc001
Name:          pvc001
Namespace:     default
StorageClass:  portworx-sc
Status:        Bound
Volume:        pvc-7db1c4d7-54c4-11e9-93d3-5aad8417b40e
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-class: portworx-sc
               volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/portworx-volume
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1Gi
Access Modes:  RWO
VolumeMode:    Filesystem
Events:
  Type       Reason                 Age   From                         Message
  ----       ------                 ----  ----                         -------
  Normal     ProvisioningSucceeded  7s    persistentvolume-controller  Successfully provisioned volume pvc-7db1c4d7-54c4-11e9-93d3-5aad8417b40e using kubernetes.io/portworx-volume
Mounted By:  <none>
```

## Create a Pod service that will use this PVC
Create a Kubernetes Pod that will use this PersistentVolumeClaim using the following command
```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
apiVersion: v1
kind: Pod
metadata:
  name: pvpod
spec:
  containers:
  - name: test-container
    image: alpine:latest
    command: [ "/bin/sh" ]
    args: [ "-c", "while true; do sleep 60;done" ]
    volumeMounts:
    - name: test-volume
      mountPath: /test-portworx-volume
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: pvc001
EOF
```

Check the status of the pod
```
kubectl --kubeconfig=./config.cluster${CLUSTER} get pods | grep pvpod
```

Create a file in the Volume using the following commands
```
kubectl --kubeconfig=./config.cluster${CLUSTER} exec -i pvpod -- /bin/sh -c "echo test > /test-portworx-volume/test"
```

Check to see that the entry was created in the file
```
kubectl --kubeconfig=./config.cluster${CLUSTER} exec -i pvpod -- /bin/sh -c "cat /test-portworx-volume/test"
```

Delete the Pod using the following command:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} delete pod pvpod
```

**NOTE** It may take a while to remove this pod, this may take a few moments.

## Deploy a second pod to demonstrate persistence
Create a Kubernetes Pod that will use the same PersistentVolumeClaim using the following command:

```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
apiVersion: v1
kind: Pod
metadata:
  name: pvpod2
spec:
  containers:
  - name: test-container
    image: alpine:latest
    command: [ "/bin/sh" ]
    args: [ "-c", "while true; do sleep 60;done" ]
    volumeMounts:
    - name: test-volume
      mountPath: /test-portworx-volume
  volumes:
  - name: test-volume
    persistentVolumeClaim:
      claimName: pvc001
EOF
```

Check the status of the pod
```
kubectl --kubeconfig=./config.cluster${CLUSTER} get pods | grep pvpod2
```

Validate that the file created in the previous Pod is still available:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} exec -i pvpod2 cat /test-portworx-volume/test
```

Delete the Pod using the following command:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} delete pod pvpod2
```

## Finished with the Lab 6 - Portworx Storage

[Move to Lab 7 - CSI Storage](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/linux-macOS/lab7_csi_storage.md)
