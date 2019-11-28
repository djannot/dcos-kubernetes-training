# Lab 4: Expose a Kubernetes Application using a Service Type Load Balancer (L4) and Ingress (L7)
To expose your applications using running on Kubernetes using L4/L7 we can use DC/OS EdgeLB and a new service called dklb. To be able to use dklb, you need to deploy it in your Kubernetes cluster

### Objectives
- Install dklb (DC/OS kubernetes load balancer) on your kubernetes cluster
- Deploy a Redis pod and expose it using a Service Type Load Balancer (L4) and validate that the connection is exposed to the outside
- Deploy a couple hello-world applications and expose using type NodePort. Then expose your applications using an Ingress service (L7) and validate that the connection is exposed to the outside

### Why is this Important?
Exposing your application on a kubernetes cluster in an Enterprise-grade environment can be challenging to set up. Cloud providers allow for integrations to their load balancing services, but also at a separate cost. DC/OS provides a clean, self-service integration to our load balancing service Edge-LB that allows users to easily expose their applications using just a few annotations. Submit your typical Pod, Service, and Ingress manifests and DKLB will do the rest - dynamically build a load balanced pool and expose your applications for both L4 (TCP) and L7 (HTTP) connections.

## Install Edge-LB CLI
```
dcos package install edgelb --cli --yes
```

## Create a secret for the DC/OS Service account
```
SERVICE_ACCOUNT_SECRET=$(dcos security secrets get /dklb-principal/sa --json | jq -r .value | base64 ${BASE64_ARGS} -)

cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
apiVersion: v1
kind: Secret
metadata:
  name: dklb-dcos-config
  namespace: kube-system
type: Opaque
data:
  serviceAccountSecret: "${SERVICE_ACCOUNT_SECRET}"
EOF
```

## Install dklb in your Kubernetes cluster
First deploy the dklb prerequisites
```
kubectl --kubeconfig=./config.cluster${CLUSTER} create -f dklb-prereqs.yaml
```

Next install dklb on your kubernetes cluster
```
kubectl --kubeconfig=./config.cluster${CLUSTER} create -f dklb-deployment.yaml
```

You can use the Kubernetes Dashboard to check that the deployment dklb is running in the kube-system namespace

![Kubernetes dashboard dklb](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab4_1.png)

## Deploy a Redis Pod
You can now deploy a redis Pod on your Kubernetes cluster running the following command
```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
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

Validate that your redis pod was deployed:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} get pods
```

## Deploy a Redis Service to expose Redis
To expose the service using (L4) Service Type Load Balancer, you need to run the following command
```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
apiVersion: v1
kind: Service
metadata:
  annotations:
    kubernetes.dcos.io/dklb-config: |
      name: dklb${CLUSTER}
      size: 2
      frontends:
      - port: 80${CLUSTER}
        servicePort: 6379
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

Validate that your redis service was created:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} get services
```

A dklb EdgeLB pool is automatically created on DC/OS:
```
dcos edgelb show dklb${CLUSTER}
```

Output should look similar to below:
```
Summary:
  NAME         dklb01           
  APIVERSION   V2               
  COUNT        2                
  ROLE         slave_public     
  CONSTRAINTS  hostname:UNIQUE  
  STATSPORT    0                

Frontends:
  NAME                                            PORT  PROTOCOL  
  training.prod.k8s.cluster01:default:redis:6379  8001  TCP       

Backends:
  FRONTEND                                        NAME                                            PROTOCOL  BALANCE    
  training.prod.k8s.cluster01:default:redis:6379  training.prod.k8s.cluster01:default:redis:6379  TCP       leastconn  

Marathon Services:
  BACKEND  TYPE  SERVICE  CONTAINER  PORT  CHECK  

Mesos Services:
  BACKEND                                         TYPE          FRAMEWORK                    TASK            PORT   CHECK    
  training.prod.k8s.cluster01:default:redis:6379  CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  30898  enabled
```

You can also see pools being dynamically created in the UI:
![dklb pool](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab4_2.png)

## Validate Redis connection
You can validate that you can access the redis POD from your laptop using telnet:
```
telnet ${PUBLICIP} 80${CLUSTER}
```

Output should look similar to below:
```
Trying 34.227.199.197...
Connected to ec2-34-227-199-197.compute-1.amazonaws.com.
Escape character is '^]'.
```

## L7 Ingress

Expose a Kubernetes Application using an Ingress (L7)

This feature leverages the DC/OS EdgeLB and the dklb service that has been deployed in the previous section.

## Deploy two hello-world pods
You can now deploy 2 web application Pods on your Kubernetes cluster running the following command:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} run --restart=Never --image hashicorp/http-echo --labels app=http-echo-1,owner=dklb --port 80 http-echo-1 -- -listen=:80 --text='Hello from http-echo-1!'
kubectl --kubeconfig=./config.cluster${CLUSTER} run --restart=Never --image hashicorp/http-echo --labels app=http-echo-2,owner=dklb --port 80 http-echo-2 -- -listen=:80 --text='Hello from http-echo-2!'
```

## Expose the hello-world pods
Then, expose the Pods with a Service Type NodePort using the following commands:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} expose pod http-echo-1 --port 80 --target-port 80 --type NodePort --name "http-echo-1"
kubectl --kubeconfig=./config.cluster${CLUSTER} expose pod http-echo-2 --port 80 --target-port 80 --type NodePort --name "http-echo-2"
```

## Create and Ingress service to expose the hello-world pods using L7
Finally create the Ingress to expose the application to the outside world using the following command:
```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: edgelb
    kubernetes.dcos.io/dklb-config: |
      name: dklb${CLUSTER}
      size: 2
      frontends:
        http:
          mode: enabled
          port: 90${CLUSTER}
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

The dklb EdgeLB pool is automatically updated on DC/OS:
```
dcos edgelb show dklb${CLUSTER}
```

Output should look like below:
```
Summary:
  NAME         dklb01           
  APIVERSION   V2               
  COUNT        2                
  ROLE         slave_public     
  CONSTRAINTS  hostname:UNIQUE  
  STATSPORT    0                

Frontends:
  NAME                                                PORT  PROTOCOL  
  training.prod.k8s.cluster01:default:dklb-echo:http  9001  HTTP      
  training.prod.k8s.cluster01:default:redis:6379      8001  TCP       

Backends:
  FRONTEND                                            NAME                                                             PROTOCOL  BALANCE    
  training.prod.k8s.cluster01:default:redis:6379      training.prod.k8s.cluster01:default:redis:6379                   TCP       leastconn  
  training.prod.k8s.cluster01:default:dklb-echo:http  training.prod.k8s.cluster01:default:dklb-echo:default-backend:0  HTTP      leastconn  
  training.prod.k8s.cluster01:default:dklb-echo:http  training.prod.k8s.cluster01:default:dklb-echo:http-echo-1:80     HTTP      leastconn  
  training.prod.k8s.cluster01:default:dklb-echo:http  training.prod.k8s.cluster01:default:dklb-echo:http-echo-2:80     HTTP      leastconn  

Marathon Services:
  BACKEND  TYPE  SERVICE  CONTAINER  PORT  CHECK  

Mesos Services:
  BACKEND                                                          TYPE          FRAMEWORK                    TASK            PORT   CHECK    
  training.prod.k8s.cluster01:default:redis:6379                   CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  30898  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:default-backend:0  CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  31317  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:default-backend:0  CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  31317  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:http-echo-1:80     CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  30995  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:http-echo-1:80     CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  30995  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:http-echo-2:80     CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  32006  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:http-echo-2:80     CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  32006  enabled
```

## Validate Ingress connection
You can validate that you can access the web application PODs from your laptop using the following commands:
```
curl -H "Host: http-echo-${CLUSTER}-1.com" http://${PUBLICIP}:90${CLUSTER}
curl -H "Host: http-echo-${CLUSTER}-2.com" http://${PUBLICIP}:90${CLUSTER}
```

## Create and Ingress service to expose the hello-world pods using L7 and TLS

First of all, delete the current ingress:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} delete ingress dklb-echo
```

Create signed certificates:
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout http-echo-${CLUSTER}-1-tls.key -out http-echo-${CLUSTER}-1-tls.crt -subj "/CN=http-echo-${CLUSTER}-1.com"
kubectl --kubeconfig=./config.cluster${CLUSTER} create secret tls http-echo-${CLUSTER}-1 --key http-echo-${CLUSTER}-1-tls.key --cert http-echo-${CLUSTER}-1-tls.crt

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout http-echo-${CLUSTER}-2-tls.key -out http-echo-${CLUSTER}-2-tls.crt -subj "/CN=http-echo-${CLUSTER}-2.com"
kubectl --kubeconfig=./config.cluster${CLUSTER} create secret tls http-echo-${CLUSTER}-2 --key http-echo-${CLUSTER}-2-tls.key --cert http-echo-${CLUSTER}-2-tls.crt
```

Finally create the Ingress to expose the application to the outside world using the following command:

```
cat <<EOF | kubectl --kubeconfig=./config.cluster${CLUSTER} create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: edgelb
    kubernetes.dcos.io/dklb-config: |
      name: dklb${CLUSTER}
      size: 2
      frontends:
        http:
          mode: enabled
          port: 90${CLUSTER}
        https:
          port: 91${CLUSTER}
  labels:
    owner: dklb
  name: dklb-echo
spec:
  tls:
  - hosts:
    - http-echo-${CLUSTER}-1.com
    secretName: http-echo-${CLUSTER}-1
  - hosts:
    - http-echo-${CLUSTER}-2.com
    secretName: http-echo-${CLUSTER}-2
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

The dklb EdgeLB pool is automatically updated on DC/OS:
```
dcos edgelb show dklb${CLUSTER}
```

Output should look like below:
```
Summary:
  NAME         dklb01           
  APIVERSION   V2               
  COUNT        2                
  ROLE         slave_public     
  CONSTRAINTS  hostname:UNIQUE  
  STATSPORT    0                

Frontends:
  NAME                                                 PORT  PROTOCOL  
  training.prod.k8s.cluster01:default:dklb-echo:http   9001  HTTP      
  training.prod.k8s.cluster01:default:dklb-echo:https  9101  HTTPS     
  training.prod.k8s.cluster01:default:redis:6379       8001  TCP       

Backends:
  FRONTEND                                            NAME                                                             PROTOCOL  BALANCE    
  training.prod.k8s.cluster01:default:redis:6379      training.prod.k8s.cluster01:default:redis:6379                   TCP       leastconn  
  training.prod.k8s.cluster01:default:dklb-echo:http  training.prod.k8s.cluster01:default:dklb-echo:default-backend:0  HTTP      leastconn  
  training.prod.k8s.cluster01:default:dklb-echo:http  training.prod.k8s.cluster01:default:dklb-echo:http-echo-1:80     HTTP      leastconn  
  training.prod.k8s.cluster01:default:dklb-echo:http  training.prod.k8s.cluster01:default:dklb-echo:http-echo-2:80     HTTP      leastconn  

Marathon Services:
  BACKEND  TYPE  SERVICE  CONTAINER  PORT  CHECK  

Mesos Services:
  BACKEND                                                          TYPE          FRAMEWORK                    TASK            PORT   CHECK    
  training.prod.k8s.cluster01:default:redis:6379                   CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  30898  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:default-backend:0  CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  31317  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:default-backend:0  CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  31317  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:http-echo-1:80     CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  30995  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:http-echo-1:80     CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  30995  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:http-echo-2:80     CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  32006  enabled  
  training.prod.k8s.cluster01:default:dklb-echo:http-echo-2:80     CONTAINER_IP  training/prod/k8s/cluster01  ^kube-node-.*$  32006  enabled
```

## Validate Ingress connection
You can validate that you can access the web application PODs from your laptop using the following commands:
```
curl -k --resolve http-echo-${CLUSTER}-1.com:91${CLUSTER}:${PUBLICIP} https://http-echo-${CLUSTER}-1.com:91${CLUSTER}
curl -k --resolve http-echo-${CLUSTER}-2.com:91${CLUSTER}:${PUBLICIP} https://http-echo-${CLUSTER}-2.com:91${CLUSTER}
```

## Finished with the Lab 4 - Load Balancing

[Move to Lab 5 - Network policies](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/linux-macOS/lab5_networkpolicies.md)
