# Lab 5: Leverage persistent storage using Portworx

Portworx is a Software Defined Software that can use the local storage of the DC/OS nodes to provide High Available persistent storage to both Kubernetes pods and DC/OS services.

To be able to use Portworx persistent storage on your Kubernetes cluster, you need to deploy it in your Kubernetes cluster using the following command:

## Deploy Portworx Stork service on your Kubernetes cluster
```
kubectl --kubeconfig=./config.cluster%CLUSTER% apply -f "https://install.portworx.com/2.0?kbver=1.13.3&b=true&dcos=true&stork=true"
```

## Create Kubernetes StorageClass
Create the Kubernetes StorageClass using the following command. This will create volumes on Portworx with 2 replicas.
```
set FILE=portworx.yml
>%FILE% echo kind: StorageClass
>>%FILE% echo apiVersion: storage.k8s.io/v1beta1
>>%FILE% echo metadata:
>>%FILE% echo    name: portworx-sc
>>%FILE% echo provisioner: kubernetes.io/portworx-volume
>>%FILE% echo parameters:
>>%FILE% echo   repl: "2"
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f portworx.yml
```

## Set default StorageClass to Portworx
Run the following command to define this StorageClass as the default Storage Class in your Kubernetes cluster:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% patch storageclass portworx-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## Create Kubernetes PersistentVolumeClaim
Create the Kubernetes PersistentVolumeClaim using the following command:
```
set FILE=portworx-pvc.yml
>%FILE% echo kind: PersistentVolumeClaim
>>%FILE% echo apiVersion: v1
>>%FILE% echo metadata:
>>%FILE% echo   name: pvc001
>>%FILE% echo   annotations:
>>%FILE% echo     volume.beta.kubernetes.io/storage-class: portworx-sc
>>%FILE% echo spec:
>>%FILE% echo   accessModes:
>>%FILE% echo     - ReadWriteOnce
>>%FILE% echo   resources:
>>%FILE% echo     requests:
>>%FILE% echo       storage: 1Gi
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f portworx-pvc.yml
```

Check the status of the PersistentVolumeClaim using the following command:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% describe pvc pvc001
```

Wait as the PVC is being built, this may take a few moments. Output should looks similar to below:
```
$ kubectl --kubeconfig=./config.cluster%CLUSTER% describe pvc pvc001
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
set FILE=test-container.yml
>%FILE% echo apiVersion: v1
>>%FILE% echo kind: Pod
>>%FILE% echo metadata:
>>%FILE% echo   name: pvpod
>>%FILE% echo spec:
>>%FILE% echo   containers:
>>%FILE% echo   - name: test-container
>>%FILE% echo     image: alpine:latest
>>%FILE% echo     command: [ "/bin/sh" ]
>>%FILE% echo     args: [ "-c", "while true; do sleep 60;done" ]
>>%FILE% echo     volumeMounts:
>>%FILE% echo     - name: test-volume
>>%FILE% echo       mountPath: /test-portworx-volume
>>%FILE% echo   volumes:
>>%FILE% echo   - name: test-volume
>>%FILE% echo     persistentVolumeClaim:
>>%FILE% echo       claimName: pvc001
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f test-container.yml
```

Check the status of the pod
```
kubectl --kubeconfig=./config.cluster%CLUSTER% get pods | grep pvpod
```

Create a file in the Volume using the following commands
```
kubectl --kubeconfig=./config.cluster%CLUSTER% exec -i pvpod -- /bin/sh -c "echo test > /test-portworx-volume/test"
```

Check to see that the entry was created in the file
```
kubectl --kubeconfig=./config.cluster%CLUSTER% exec -i pvpod -- /bin/sh -c "cat /test-portworx-volume/test"
```

Delete the Pod using the following command:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% delete pod pvpod
```

**NOTE** It may take a while to remove this pod, this may take a few moments.

## Deploy a second pod to demonstrate persistence
Create a Kubernetes Pod that will use the same PersistentVolumeClaim using the following command:

```
set FILE=test-container2.yml
>%FILE% echo apiVersion: v1
>>%FILE% echo kind: Pod
>>%FILE% echo metadata:
>>%FILE% echo   name: pvpod
>>%FILE% echo spec:
>>%FILE% echo   containers:
>>%FILE% echo   - name: test-container
>>%FILE% echo     image: alpine:latest
>>%FILE% echo     command: [ "/bin/sh" ]
>>%FILE% echo     args: [ "-c", "while true; do sleep 60;done" ]
>>%FILE% echo     volumeMounts:
>>%FILE% echo     - name: test-volume
>>%FILE% echo       mountPath: /test-portworx-volume
>>%FILE% echo   volumes:
>>%FILE% echo   - name: test-volume
>>%FILE% echo     persistentVolumeClaim:
>>%FILE% echo       claimName: pvc001
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f test-container2.yml
```

Check the status of the pod
```
kubectl --kubeconfig=./config.cluster%CLUSTER% get pods | grep pvpod2
```

Validate that the file created in the previous Pod is still available:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% exec -i pvpod2 cat /test-portworx-volume/test
```

Delete the Pod using the following command:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% delete pod pvpod2
```

## Finished with the Lab 5 - Portworx Storage

[Move to Lab 6 - CSI Storage](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/windows_WIP/lab6_csi_storage.md)
