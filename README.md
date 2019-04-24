# Mesosphere DC/OS Kubernetes training

## Introduction

During this training, you'll learn how to use the main capabilities of Kubernetes on DC/OS:

- [Deploy a Kubernetes cluster](#deploy)
- [Scale a Kubernetes cluster](#scale)
- [Upgrade a Kubernetes cluster](#upgrade)
- [Expose a Kubernetes Application using a Service Type Load Balancer (L4)](#exposel4)
- [Expose a Kubernetes Application using an Ingress (L7)](#exposel7)
- [Leverage persistent storage using Portworx](#portworx)
- [Leverage persistent storage using CSI](#csi)
- [Configure Helm](#helm)
- [Deploy Istio using Helm](#deploy-istio)
- [Deploy an application on Istio](#deploy-app)

During the labs, replace XX by the number assigned by the instructor (starting with 01).

## Pre requisites

### For the instructor

You need to have access to a DC/OS Enteprise Edition cluster deployed in strict mode with 1.12.1 or later.

The DC/OS Kubernetes MKE package must be installed in the cluster. This package is used by DC/OS to manage multiple DC/OS clusters on the same DC/OS cluster.

The DC/OS EdgeLB package must be installed in the cluster. This package is used by DC/OS to expose the Kubernetes API server, the Portworx UI and the Kubernetes apps to the outside world.

Portworx must be deployed on the DC/OS cluster.

For CSI, you need to attach the following inline IAM policy to your AWS instance role:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume"
      ],
      "Resource": "*"
    }
  ]
}
```

You can use the `main.tf` file to deploy the DC/OS cluster in AWS using the following commands:

```
terraform init
terraform apply -auto-approve
```

The `prerequisites.sh` script can be used to deploy all the pre requisites in a few minutes.

You just need to update the 4 variables at the beginning of the file:

```
export APPNAME=training
export PUBLICIP=107.23.75.102
export CLUSTER=k8straining
export REGION=us-east-1
clusters=35
```

`PUBLICIP` is the IP of the AWS Load Balancer in front of the DC/OS public nodes.

`CLUSTER` is the name of the DC/OS cluster specified in the Terraform script.

`REGION` is the AWS region.

`clusters` is the maximum number of students you expect.

At the end of the training, after deleting your cluster using Terraform, use the `detach-and-delete-volumes.sh` script to delete the AWS EBS volumes created for Portworx and by CSI. Make sure you set the `CLUSTER` and `REGION` variables with the same values you set in the `prerequisites.sh` script

But you need to manually delete the CSI inline IAM policy before you destroy your DC/OS cluster.

### For the students

You need either a Linux, MacOS or Windows laptop with admin privileges.

>For Windows, if you don't have admin privileges, you can use the [Google Cloud Shell](https://console.cloud.google.com/cloudshell) and follow the instructions for Linux & MacOS.

Run the following command to export the environment variables needed during the labs:

For Linux & MacOS:

```
export APPNAME=training
export PUBLICIP=<IP provided by the instructor>
export CLUSTER=<the number assigned by the instructor: 01, 02, ..>
```
For Windows:

```
set APPNAME=training
set PUBLICIP=<IP provided by the instructor>
set CLUSTER=<the number assigned by the instructor: 01, 02, ..>
```

Log into the DC/OS cluster with the information provided by your instructor.

On the top right corner, click on the name of the cluster and then on `Install CLI`.

Copy and paste the instruction for your Operation System in your shell.

Run the following command to add the DC/OS Enterprise extensions to the DC/OS CLI:

```
dcos package install --yes --cli dcos-enterprise-cli
```

Install the kubectl CLI using the instructions available at the URL below:

[https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl)

Add the following line to your `/etc/hosts` (or `c:\Windows\System32\Drivers\etc\hosts`) file:

```
<PUBLICIP variable> training.prod.k8s.cluster<CLUSTER variable>.mesos.lab
```

## <a name="deploy"></a>1. Deploy a Kubernetes cluster

Create a file called `options-kubernetes-cluster${CLUSTER}.json` using the following commands:

For Linux & MacOS:

```
cat <<EOF > options-kubernetes-cluster${CLUSTER}.json
{
  "service": {
    "name": "training/prod/k8s/cluster${CLUSTER}",
    "service_account": "training-prod-k8s-cluster${CLUSTER}",
    "service_account_secret": "/training/prod/k8s/cluster${CLUSTER}/private-training-prod-k8s-cluster${CLUSTER}"
  },
  "kubernetes": {
    "authorization_mode": "RBAC",
    "high_availability": false,
    "private_node_count": 2,
    "private_reserved_resources": {
      "kube_mem": 4096
    }
  }
}
EOF
```

For Windows:

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

It will allow you to deploy a Kubernetes cluster with RBAC enabled, HA disabled (to limit the resource needed) and with 2 private nodes.

For Linux & MacOS:

Create a file called `deploy-kubernetes-cluster.sh` with the following content:

```
clusterpath=${APPNAME}/prod/k8s/cluster${1}

serviceaccount=$(echo $clusterpath | sed 's/\//-/g')
role=$(echo $clusterpath | sed 's/\//__/g')-role

dcos security org service-accounts keypair private-${serviceaccount}.pem public-${serviceaccount}.pem
dcos security org service-accounts delete ${serviceaccount}
dcos security org service-accounts create -p public-${serviceaccount}.pem -d /${clusterpath} ${serviceaccount}
dcos security secrets delete /${clusterpath}/private-${serviceaccount}
dcos security secrets create-sa-secret --strict private-${serviceaccount}.pem ${serviceaccount} /${clusterpath}/private-${serviceaccount}

dcos security org users grant ${serviceaccount} dcos:secrets:default:/${clusterpath}/* full
dcos security org users grant ${serviceaccount} dcos:secrets:list:default:/${clusterpath} full
dcos security org users grant ${serviceaccount} dcos:adminrouter:ops:ca:rw full
dcos security org users grant ${serviceaccount} dcos:adminrouter:ops:ca:ro full
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:role:${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:principal:${serviceaccount} delete
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:role:${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:principal:${serviceaccount} delete
dcos security org users grant ${serviceaccount} dcos:mesos:master:task:user:nobody create
dcos security org users grant ${serviceaccount} dcos:mesos:master:task:user:root create
dcos security org users grant ${serviceaccount} dcos:mesos:agent:task:user:root create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public/${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public/${role} read
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:role:slave_public/${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:role:slave_public/${role} create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public read
dcos security org users grant ${serviceaccount} dcos:mesos:agent:framework:role:slave_public read

dcos kubernetes cluster create --yes --options=options-kubernetes-cluster${1}.json --package-version=2.2.1-1.13.4
```

For Windows:

Create a file called `deploy-kubernetes-cluster.bat` with the following content:

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

dcos kubernetes cluster create --yes --options=options-kubernetes-cluster%1%.json --package-version=2.2.1-1.13.4
```

It will allow you to create the DC/OS service account with the right permissions and to deploy a Kubernetes cluster with the version 1.13.4.

Deploy your Kubernetes cluster using the following commands:

For Linux & MacOS:

```
dcos package install kubernetes --cli --yes
chmod +x deploy-kubernetes-cluster.sh
./deploy-kubernetes-cluster.sh ${CLUSTER}
```

For Windows:

```
dcos package install kubernetes --cli --yes
deploy-kubernetes-cluster.bat %CLUSTER%
```

Configure the Kubernetes CLI using the following command:

For Linux & MacOS:

```
dcos kubernetes cluster kubeconfig --context-name=${APPNAME}-prod-k8s-cluster${CLUSTER} --cluster-name=${APPNAME}/prod/k8s/cluster${CLUSTER} \
    --apiserver-url https://${APPNAME}.prod.k8s.cluster${CLUSTER}.mesos.lab:8443 \
    --insecure-skip-tls-verify
```
For Windows:

```
dcos kubernetes cluster kubeconfig --context-name=%APPNAME%-prod-k8s-cluster%CLUSTER% --cluster-name=%APPNAME%/prod/k8s/cluster%CLUSTER% \
    --apiserver-url https://%APPNAME%.prod.k8s.cluster%CLUSTER%.mesos.lab:8443 \
    --insecure-skip-tls-verify
```


Run the following command to check that everything is working properly:

```
kubectl get nodes
NAME                                                           STATUS   ROLES    AGE   VERSION
kube-control-plane-0-instance.trainingprodk8scluster${CLUSTER}.mesos   Ready    master   23m   v1.13.4
kube-node-0-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   21m   v1.13.4
kube-node-1-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   21m   v1.13.4
```

Copy the Kubernetes config file in your current directory

For Linux & MacOS:

```
cp ~/.kube/config .
```

For Windows:

```
copy "%USERPROFILE%"\.kube\config .
```

Run the following command **in a different shell** to run a proxy that will allow you to access the Kubernetes Dashboard:

```
kubectl proxy
```

Open the following page in your web browser:

[http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/](http://127.0.0.1:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/)

Login using the config file.

![Kubernetes dashboard](images/kubernetes-dashboard.png)

>If you are using the Google Cloud Shell, click on icon with the 3 dots on the top right corner and click on `Download file`.

>Indicate the path of the config file (`/home/<your user>/config`) and download it.

>Then, click on the `Web preview` icon on the top right corner and change the port to `8001`.

>Finally, click on the `Web preview` icon again and select `Preview on port 8001`.

>It will open a new tab. Keep the hostname and append `/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/` to it.

## <a name="scale"></a>2. Scale your Kubernetes cluster

Edit the `options-kubernetes-clusterXX.json` file to set the private_node_count to 3.

Run the following command to scale your Kubernetes cluster:

For Linux & MacOS:

```
dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster${CLUSTER} --options=options-kubernetes-cluster${CLUSTER}.json --yes
Using Kubernetes cluster: training/prod/k8s/clusterXX
2019/01/26 14:40:51 starting update process...
2019/01/26 14:40:58 waiting for update to finish...
2019/01/26 14:42:10 update complete!
```

For Windows:

```
dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster%CLUSTER% --options=options-kubernetes-cluster%CLUSTER%.json --yes
Using Kubernetes cluster: training/prod/k8s/clusterXX
2019/01/26 14:40:51 starting update process...
2019/01/26 14:40:58 waiting for update to finish...
2019/01/26 14:42:10 update complete!
```

You can check that the new node is shown in the Kubernetes Dashboard:

![Kubernetes dashboard scaled](images/kubernetes-dashboard-scaled.png)

## <a name="upgrade"></a>3. Upgrade your Kubernetes cluster

Run the following command to upgrade your Kubernetes cluster:

For Linux & MacOS:

```
dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster${CLUSTER} --package-version=2.2.2-1.13.5 --yes

```

For Windows:

```
dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster%CLUSTER% --package-version=2.2.2-1.13.5 --yes

```

You can check that the cluster has been updated using the Kubernete CLI:

```
kubectl get nodes
NAME                                                          STATUS   ROLES    AGE   VERSION
kube-control-plane-0-instance.trainingprodk8scluster${CLUSTER}.mesos   Ready    master   94m   v1.13.5
kube-node-0-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   92m   v1.13.5
kube-node-1-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   92m   v1.13.5
kube-node-2-kubelet.trainingprodk8scluster${CLUSTER}.mesos             Ready    <none>   36m   v1.13.5
```

## <a name="exposel4"></a>4. Expose a Kubernetes Application using a Service Type Load Balancer (L4)

This feature leverage the DC/OS EdgeLB and a new service called dklb.

To be able to use dklb, you need to deploy it in your Kubernetes cluster using the following commands:

```
kubectl create -f dklb-prereqs.yaml
kubectl create -f dklb-deployment.yaml
```

You can use the Kubernetes Dashboard to check that the deployment dklb is running in the kube-system namespace:

![Kubernetes dashboard dklb](images/kubernetes-dashboard-dklb.png)

You can now deploy a redis Pod on your Kubernetes cluster running the following command:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: redis
  name: redis
spec:
  containers:
  - name: redis
    image: redis:5.0.3
    ports:
    - name: redis
      containerPort: 6379
      protocol: TCP
EOF
```

For Windows:

```
set FILE=redis.yml
>%FILE% echo apiVersion: v1
>>%FILE% echo kind: Pod
>>%FILE% echo metadata:
>>%FILE% echo   labels:
>>%FILE% echo     app: redis
>>%FILE% echo   name: redis
>>%FILE% echo spec:
>>%FILE% echo   containers:
>>%FILE% echo   - name: redis
>>%FILE% echo     image: redis:5.0.3
>>%FILE% echo     ports:
>>%FILE% echo     - name: redis
>>%FILE% echo       containerPort: 6379
>>%FILE% echo       protocol: TCP
kubectl create -f redis.yml
```

Finally, to expose the service, you need to run the following command to create a Service Type Load Balancer:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  annotations:
    kubernetes.dcos.io/edgelb-pool-name: "dklb"
    kubernetes.dcos.io/edgelb-pool-size: "2"
    kubernetes.dcos.io/edgelb-pool-portmap.6379: "80${CLUSTER}"
  labels:
    app: redis
  name: redis
spec:
  type: LoadBalancer
  selector:
    app: redis
  ports:
  - protocol: TCP
    port: 6379
    targetPort: 6379
EOF
```

For Windows:

```
set FILE=edgelb-redis.yml
>%FILE% echo apiVersion: v1
>>%FILE% echo kind: Service
>>%FILE% echo metadata:
>>%FILE% echo   annotations:
>>%FILE% echo     kubernetes.dcos.io/edgelb-pool-name: "dklb"
>>%FILE% echo     kubernetes.dcos.io/edgelb-pool-size: "2"
>>%FILE% echo     kubernetes.dcos.io/edgelb-pool-portmap.6379: "80%cluster%"
>>%FILE% echo   labels:
>>%FILE% echo     app: redis
>>%FILE% echo   name: redis
>>%FILE% echo spec:
>>%FILE% echo   type: LoadBalancer
>>%FILE% echo   selector:
>>%FILE% echo     app: redis
>>%FILE% echo   ports:
>>%FILE% echo   - protocol: TCP
>>%FILE% echo     port: 6379
>>%FILE% echo     targetPort: 6379
kubectl create -f edgelb-redis.yml
```

A dklb EdgeLB pool is automatically created on DC/OS:

You can validate that you can access the redis Pod from your laptop using telnet:

For Linux & MacOS:

```
telnet ${PUBLICIP} 80${CLUSTER}
Trying 34.227.199.197...
Connected to ec2-34-227-199-197.compute-1.amazonaws.com.
Escape character is '^]'.
```

For Windows:

```
telnet %PUBLICIP% 80%CLUSTER%
Trying 34.227.199.197...
Connected to ec2-34-227-199-197.compute-1.amazonaws.com.
Escape character is '^]'.
```

If telnet is not enabled on your system, run Command Prompt as an administrator (Right click on the Command Prompt icon and select “Run as administrator”).

Then, run the following command and wait.

```
dism /online /Enable-Feature /FeatureName:TelnetClient
```

## <a name="exposel7"></a>5. Expose a Kubernetes Application using an Ingress (L7)

Update the PUBLICIP environment variable to use the Public IP of one of the DC/OS public node. It's needed because there is a limited number of listeners we can set on the AWS Load Balancer we use in front of the DC/OS public nodes.

This feature leverage the DC/OS EdgeLB and the dklb service that has been deployed in the previous section.

You can now deploy 2 web application Pods on your Kubernetes cluster running the following command:

```
kubectl run --restart=Never --image hashicorp/http-echo --labels app=http-echo-1,owner=dklb --port 80 http-echo-1 -- -listen=:80 --text="Hello from http-echo-1"
kubectl run --restart=Never --image hashicorp/http-echo --labels app=http-echo-2,owner=dklb --port 80 http-echo-2 -- -listen=:80 --text="Hello from http-echo-2"
```

Then, expose the Pods with a Service Type NodePort using the following commands:

```
kubectl expose pod http-echo-1 --port 80 --target-port 80 --type NodePort --name "http-echo-1"
kubectl expose pod http-echo-2 --port 80 --target-port 80 --type NodePort --name "http-echo-2"
```

Finally create the Ingress to expose the application to the ourside world using the following command:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: edgelb
    kubernetes.dcos.io/edgelb-pool-name: "dklb"
    kubernetes.dcos.io/edgelb-pool-size: "2"
    kubernetes.dcos.io/edgelb-pool-port: "90${CLUSTER}"
  labels:
    owner: dklb
  name: dklb-echo
spec:
  rules:
  - host: "http-echo-${CLUSTER}-1.com"
    http:
      paths:
      - backend:
          serviceName: http-echo-1
          servicePort: 80
  - host: "http-echo-${CLUSTER}-2.com"
    http:
      paths:
      - backend:
          serviceName: http-echo-2
          servicePort: 80
EOF
```

For Windows:

```
set FILE=ingress.yml
>%FILE% echo apiVersion: extensions/v1beta1
>>%FILE% echo kind: Ingress
>>%FILE% echo metadata:
>>%FILE% echo   annotations:
>>%FILE% echo     kubernetes.io/ingress.class: edgelb
>>%FILE% echo     kubernetes.dcos.io/edgelb-pool-name: "dklb"
>>%FILE% echo     kubernetes.dcos.io/edgelb-pool-size: "2"
>>%FILE% echo     kubernetes.dcos.io/edgelb-pool-port: "90%CLUSTER%"
>>%FILE% echo   labels:
>>%FILE% echo     owner: dklb
>>%FILE% echo   name: dklb-echo
>>%FILE% echo spec:
>>%FILE% echo   rules:
>>%FILE% echo   - host: "http-echo-%CLUSTER%-1.com"
>>%FILE% echo     http:
>>%FILE% echo       paths:
>>%FILE% echo       - backend:
>>%FILE% echo           serviceName: http-echo-1
>>%FILE% echo           servicePort: 80
>>%FILE% echo   - host: "http-echo-%CLUSTER%-2.com"
>>%FILE% echo     http:
>>%FILE% echo       paths:
>>%FILE% echo       - backend:
>>%FILE% echo           serviceName: http-echo-2
>>%FILE% echo           servicePort: 80
kubectl create -f ingress.yml
```

The dklb EdgeLB pool is automatically updated on DC/OS:

You can validate that you can access the web application PODs from your laptop using the following commands:

For Linux & MacOS:

```
curl -H "Host: http-echo-${CLUSTER}-1.com" http://${PUBLICIP}:90${CLUSTER}
curl -H "Host: http-echo-${CLUSTER}-2.com" http://${PUBLICIP}:90${CLUSTER}
```

For Windows: (only if your Windows version contains curl)

```
curl -H "Host: http-echo-%CLUSTER%-1.com" http://%PUBLICIP%:90%CLUSTER%
curl -H "Host: http-echo-%CLUSTER%-2.com" http://%PUBLICIP%:90%CLUSTER%
```

If you don't have curl, you can add the corresponding entries in your `hosts` file and access the web pages using your web browser.

## <a name="portworx"></a>6. Leverage persistent storage using Portworx

Portworx is a Software Defined Software that can use the local storage of the DC/OS nodes to provide High Available persistent storage to both Kubernetes pods and DC/OS services.

To be able to use Portworx persistent storage on your Kubernetes cluster, you need to deploy it in your Kubernetes cluster using the following command:

```
kubectl apply -f "https://install.portworx.com/2.0?kbver=1.13.5&b=true&dcos=true&stork=true"
```

Create the Kubernetes StorageClass using the following command:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
   name: portworx-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "2"
EOF
```

For Windows:

```
set FILE=portworx.yml
>%FILE% echo kind: StorageClass
>>%FILE% echo apiVersion: storage.k8s.io/v1beta1
>>%FILE% echo metadata:
>>%FILE% echo    name: portworx-sc
>>%FILE% echo provisioner: kubernetes.io/portworx-volume
>>%FILE% echo parameters:
>>%FILE% echo   repl: "2"
kubectl create -f portworx.yml
```

It will create volumes on Portworx with 2 replicas.

Run the following command to define this StorageClass as the default Storage Class in your Kubernetes cluster:

```
kubectl patch storageclass portworx-sc -p "{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}"
```

Create the Kubernetes PersistentVolumeClaim using the following command:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
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

For Windows:

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
kubectl create -f portworx-pvc.yml
```

Check the status of the PersistentVolumeClaim using the following command:

```
kubectl describe pvc pvc001
Name:          pvc001
Namespace:     default
StorageClass:  portworx-sc
Status:        Bound
Volume:        pvc-82a8c601-2183-11e9-8f3c-3efe47e3184c
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
  Normal     ProvisioningSucceeded  5s    persistentvolume-controller  Successfully provisioned volume pvc-82a8c601-2183-11e9-8f3c-3efe47e3184c using kubernetes.io/portworx-volume
Mounted By:  <none>
```

Create a Kubernetes Pod that will use this PersistentVolumeClaim using the following command:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
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

For Windows:

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
kubectl create -f test-container.yml
```

Create a file in the Volume using the following commands:

```
kubectl exec -i pvpod -- /bin/sh -c "echo test > /test-portworx-volume/test"
```

Delete the Pod using the following command:

```
kubectl delete pod pvpod
```

Create a Kubernetes Pod that will use the same PersistentVolumeClaim using the following command:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
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

For Windows:

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
kubectl create -f test-container2.yml
```


Validate that the file created in the previous Pod is still available:

```
kubectl exec -i pvpod cat /test-portworx-volume/test
```

## <a name="csi"></a>7. Leverage persistent storage using CSI

Unzip the archive containing the CSI driver for AWS:

```
unzip csi-driver-deployments-master.zip
```

Deploy the Kubernetes manifests in your cluster using the following command:

```
kubectl apply -f csi-driver-deployments-master/aws-ebs/kubernetes/latest/
```

Create the Kubernetes StorageClass using the following command:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
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

For Windows:

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
kubectl create -f storageclass.yml
```

This time we define the Storage Class as the default one while we create it.

Create the Kubernetes PersistentVolumeClaim using the following command:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
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

For Windows:

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
kubectl create -f pvc.yml
```

Create a Kubernetes Deployment that will use this PersistentVolumeClaim using the following command:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
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

For Windows:

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
>>%FILE% echo         args: ["-c", "while true; do echo $(date -u) >> /data/out.txt; sleep 5; done"]
>>%FILE% echo         volumeMounts:
>>%FILE% echo         - name: persistent-storage
>>%FILE% echo           mountPath: /data
>>%FILE% echo       volumes:
>>%FILE% echo       - name: persistent-storage
>>%FILE% echo         persistentVolumeClaim:
>>%FILE% echo           claimName: dynamic
kubectl create -f deployment.yml
```

Check the content of the file `/data/out.txt` and note the first timestamp:

For Linux & MacOS:

```
pod=$(kubectl get pods | grep ebs-dynamic-app | awk '{ print $1 }')
kubectl exec -i $pod cat /data/out.txt
```

For Windows:

```
@powershell "$pod = (.\kubectl get pods | findstr ebs-dynamic-app).split(\" \",3)[0]; .\kubectl exec -i $pod cat /data/out.txt"
```

Delete the Pod using the following command:

For Linux & MacOS:

```
kubectl delete pod $pod
```

For Windows:

```
@powershell "$pod = (.\kubectl get pods | findstr ebs-dynamic-app).split(\" \",3)[0]; .\kubectl delete pod $pod
```

The Deployment will recreate the pod automatically.

Check the content of the file `/data/out.txt` and verify that the first timestamp is the same as the one noted previously:

For Linux & MacOS:

```
pod=$(kubectl get pods | grep ebs-dynamic-app | awk '{ print $1 }')
kubectl exec -i $pod cat /data/out.txt
```

For Windows:

```
@powershell "$pod = (.\kubectl get pods | findstr ebs-dynamic-app).split(\" \",3)[0]; .\kubectl exec -i $pod cat /data/out.txt"
```

## <a name="helm"></a>8. Configure Helm

Helm is a package manager for Kubernetes. Helm Charts helps you define, install, and upgrade even the most complex Kubernetes application.

Intall Helm on your laptop using the instructions available at the URL below:

[https://docs.helm.sh/using_helm/#installing-helm](https://docs.helm.sh/using_helm/#installing-helm)

Tiller is the in-cluster component of Helm. It interacts directly with the Kubernetes API server to install, upgrade, query, and remove Kubernetes resources. It also stores the objects that represent releases.

Run the following command to create a Kubernetes ServiceAccount for the Helm Tiller:

For Linux & MacOS:

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: kube-system
EOF
```

For Windows:

```
set FILE=tiller.yml
>%FILE% echo apiVersion: v1
>>%FILE% echo kind: ServiceAccount
>>%FILE% echo metadata:
>>%FILE% echo   name: tiller
>>%FILE% echo   namespace: kube-system
>>%FILE% echo ---
>>%FILE% echo apiVersion: rbac.authorization.k8s.io/v1beta1
>>%FILE% echo kind: ClusterRoleBinding
>>%FILE% echo metadata:
>>%FILE% echo   name: tiller
>>%FILE% echo roleRef:
>>%FILE% echo   apiGroup: rbac.authorization.k8s.io
>>%FILE% echo   kind: ClusterRole
>>%FILE% echo   name: cluster-admin
>>%FILE% echo subjects:
>>%FILE% echo - kind: ServiceAccount
>>%FILE% echo   name: tiller
>>%FILE% echo   namespace: kube-system
kubectl create -f tiller.yml
```

Run the following command to install Tiller into your Kubernetes cluster:

```
helm init --service-account tiller
```

## <a name="deploy-istio"></a>9. Deploy Istio using Helm

PLEASE NOTE THAT THIS GUIDE CURRENTLY DOES NOT PROVIDE INSTRUCTIONS TO DEPLOY ISTIO ON WINDOWS WORKSTATIONS

Cloud platforms provide a wealth of benefits for the organizations that use them. There’s no denying, however, that adopting the cloud can put strains on DevOps teams. Developers must use microservices to architect for portability, meanwhile operators are managing extremely large hybrid and multi-cloud deployments. Istio lets you connect, secure, control, and observe services.

At a high level, Istio helps reduce the complexity of these deployments, and eases the strain on your development teams. It is a completely open source service mesh that layers transparently onto existing distributed applications. It is also a platform, including APIs that let it integrate into any logging platform, or telemetry or policy system. Istio’s diverse feature set lets you successfully, and efficiently, run a distributed microservice architecture, and provides a uniform way to secure, connect, and monitor microservices.

Download the latest release of Istio using the followig command:

For Linux & MacOS:

```
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.0.6 sh -
```

You can also download the releases for other Operating Systems using the URL below:

[https://github.com/istio/istio/releases](https://github.com/istio/istio/releases)

Run the following commands to go to the Istio directory and to install Istio using Helm:

```
cd istio-1.0.6
export PATH=$PWD/bin:$PATH
helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set gateways.istio-ingressgateway.serviceAnnotations."kubernetes\.dcos\.io/edgelb-pool-name"=dklb \
  --set gateways.istio-ingressgateway.serviceAnnotations."kubernetes\.dcos\.io/edgelb-pool-size"=\"2\" \
  --set gateways.istio-ingressgateway.ports[0].port=100${CLUSTER} \
  --set gateways.istio-ingressgateway.ports[0].targetPort=80 \
  --set gateways.istio-ingressgateway.ports[0].name=http2 \
  --set gateways.istio-ingressgateway.ports[0].nodePort=30000
```

## <a name="deploy-app"></a>10. Deploy an application on Istio

This example deploys a sample application composed of four separate microservices used to demonstrate various Istio features. The application displays information about a book, similar to a single catalog entry of an online book store. Displayed on the page is a description of the book, book details (ISBN, number of pages, and so on), and a few book reviews.

Run the following commands to deploy the bookinfo application:

```
kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml)
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

Go to the following URL to access the application:
[http://${PUBLICIP}:100${CLUSTER}/productpage](http://${PUBLICIP}:100${CLUSTER}/productpage)

You can then follow the other steps described in the Istio documentation to understand the different Istio features:

[https://istio.io/docs/examples/bookinfo/](https://istio.io/docs/examples/bookinfo/)
