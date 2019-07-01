# Lab 4: Expose a Kubernetes Application using a Service Type Load Balancer (L4) and Ingress (L7)

To expose your applications using running on Kubernetes using L4/L7 we can use DC/OS EdgeLB and a new service called dklb. To be able to use dklb, you need to deploy it in your Kubernetes cluster

## Install Edge-LB CLI
```
dcos package install edgelb --cli --yes
```

## Create a secret for the DC/OS Service account
```
FOR /F "tokens=* USEBACKQ" %%F IN (`dcos security secrets get /dklb`) DO (
SET SERVICE_ACCOUNT_SECRET=%%F
)

set FILE=sa.yml
>%FILE% echo apiVersion: v1
>>%FILE% echo kind: Secret
>>%FILE% echo metadata:
>>%FILE% echo   name: dklb-dcos-config
>>%FILE% echo   namespace: kube-system
>>%FILE% echo type: Opaque
>>%FILE% echo data:
>>%FILE% echo   serviceAccountSecret: "%SERVICE_ACCOUNT_SECRET%"
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f sa.yml
```

## Install dklb in your Kubernetes cluster
First deploy the dklb prerequisites
```
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f dklb-prereqs.yaml
```

Next install dklb on your kubernetes cluster
```
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f dklb-deployment.yaml
```

You can use the Kubernetes Dashboard to check that the deployment dklb is running in the kube-system namespace

![Kubernetes dashboard dklb](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab4_1.png)

## Deploy a Redis Pod
You can now deploy a redis Pod on your Kubernetes cluster running the following command
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
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f redis.yml
```

Validate that your redis pod was deployed:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% get pods
```

## Deploy a Redis Service to expose Redis
To expose the service using (L4) Service Type Load Balancer, you need to run the following command
```
set FILE=edgelb-redis.yml
>%FILE% echo apiVersion: v1
>>%FILE% echo kind: Service
>>%FILE% echo metadata:
>>%FILE% echo   annotations:
>>%FILE% echo     kubernetes.dcos.io/dklb-config: |
>>%FILE% echo       name: dklb%CLUSTER%
>>%FILE% echo       size: 2
>>%FILE% echo       frontends:
>>%FILE% echo       - port: 80%CLUSTER%
>>%FILE% echo         servicePort: 6379
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
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f edgelb-redis.yml
```

Validate that your redis service was created:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% get services
```

A dklb EdgeLB pool is automatically created on DC/OS:
```
dcos edgelb list
```

Output should look similar to below:
```
$ dcos edgelb list
  NAME    APIVERSION  COUNT  ROLE          PORTS
  all     V2          2      slave_public  9091, 8443
  dklb01  V2          2      slave_public  0, 8001
  ```

You can also see pools being dynamically created in the UI:
![dklb pool](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab4_2.png)

## Validate Redis connection
You can validate that you can access the redis POD from your laptop using telnet:
```
telnet %PUBLICIP% 80%CLUSTER%
```

Output should look similar to below:
```
Trying 34.227.199.197...
Connected to ec2-34-227-199-197.compute-1.amazonaws.com.
Escape character is '^]'.
```

If telnet is not enabled on your system, run Command Prompt as an administrator (Right click on the Command Prompt icon and select “Run as administrator”).

Then, run the following command and wait.

```
dism /online /Enable-Feature /FeatureName:TelnetClient
```

## L7 Ingress

Expose a Kubernetes Application using an Ingress (L7)

This feature leverages the DC/OS EdgeLB and the dklb service that has been deployed in the previous section.

## Deploy two hello-world pods
You can now deploy 2 web application Pods on your Kubernetes cluster running the following command:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% run --restart=Never --image hashicorp/http-echo --labels app=http-echo-1,owner=dklb --port 80 http-echo-1 -- -listen=:80 --text='Hello from http-echo-1!'
kubectl --kubeconfig=./config.cluster%CLUSTER% run --restart=Never --image hashicorp/http-echo --labels app=http-echo-2,owner=dklb --port 80 http-echo-2 -- -listen=:80 --text='Hello from http-echo-2!'
```

## Expose the hello-world pods
Then, expose the Pods with a Service Type NodePort using the following commands:
```
kubectl --kubeconfig=./config.cluster%CLUSTER% expose pod http-echo-1 --port 80 --target-port 80 --type NodePort --name "http-echo-1"
kubectl --kubeconfig=./config.cluster%CLUSTER% expose pod http-echo-2 --port 80 --target-port 80 --type NodePort --name "http-echo-2"
```

## Create and Ingress service to expose the hello-world pods using L7
Finally create the Ingress to expose the application to the outside world using the following command:
```
set FILE=ingress.yml
>%FILE% echo apiVersion: extensions/v1beta1
>>%FILE% echo kind: Ingress
>>%FILE% echo metadata:
>>%FILE% echo   annotations:
>>%FILE% echo     kubernetes.io/ingress.class: edgelb
>>%FILE% echo     kubernetes.dcos.io/dklb-config: |
>>%FILE% echo       name: dklb%CLUSTER%
>>%FILE% echo       size: 2
>>%FILE% echo       frontends:
>>%FILE% echo         http:
>>%FILE% echo           mode: enabled
>>%FILE% echo           port: 90%CLUSTER%
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
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f ingress.yml
```

kubernetes.io/ingress.class: edgelb
kubernetes.dcos.io/dklb-config: |
  name: dklb${CLUSTER}
  size: 2
  frontends:
    http:
      mode: enabled
      port: 90${CLUSTER}

The dklb EdgeLB pool is automatically updated on DC/OS:
```
dcos edgelb list
```

Output should look like below:
```
$ dcos edgelb list
  NAME    APIVERSION  COUNT  ROLE          PORTS
  all     V2          2      slave_public  9091, 8443
  dklb01  V2          2      slave_public  0, 8001, 9001
  ```

## Validate Ingress connection
You can validate that you can access the web application PODs from your laptop using the following commands (only if your Windows version contains curl):
```
curl -H "Host: http-echo-%CLUSTER%-1.com" http://%PUBLICIP%:90%CLUSTER%
curl -H "Host: http-echo-%CLUSTER%-2.com" http://%PUBLICIP%:90%CLUSTER%
```

## Remove the Redis Pod/Service
```
kubectl --kubeconfig=./config.cluster%CLUSTER% delete pod redis
kubectl --kubeconfig=./config.cluster%CLUSTER% delete service redis
```

## Optional: Remove the hello-world Pod/Service/Ingress

Remove the http-echo pods
```
kubectl --kubeconfig=./config.cluster%CLUSTER% delete pod http-echo-1
kubectl --kubeconfig=./config.cluster%CLUSTER% delete pod http-echo-2
```

Remove the http-echo services
```
kubectl --kubeconfig=./config.cluster%CLUSTER% delete service http-echo-1
kubectl --kubeconfig=./config.cluster%CLUSTER% delete service http-echo-2
```

Remove the dklb-echo ingress
```
kubectl --kubeconfig=./config.cluster%CLUSTER% delete ingress dklb-echo
```

## Finished with the Lab 4 - Load Balancing

[Move to Lab 5 - Network policies](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/windows_WIP/lab5_networkpolicies.md)
