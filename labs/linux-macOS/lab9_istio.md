# Lab 9: Deploy Istio using Helm and Deploy Applications using Istio

### Objectives
- Install Istio on your kubernetes cluster using Helm
- Deploy and expose an application on Istio
- Validate access to your application

### Why is this Important?
Cloud platforms provide a wealth of benefits for the organizations that use them. There’s no denying, however, that adopting the cloud can put strain on DevOps teams. Developers must use microservices to architect for portability, meanwhile operators are managing extremely large hybrid and multi-cloud deployments. Istio lets you connect, secure, control, and observe services.

At a high level, Istio helps reduce the complexity of these deployments, and eases the strain on your development teams. It is a completely open source service mesh that layers transparently onto existing distributed applications. It is also a platform, including APIs that let it integrate into any logging platform, or telemetry or policy system. Istio’s diverse feature set lets you successfully, and efficiently, run a distributed microservice architecture, and provides a uniform way to secure, connect, and monitor microservices.

You can download/explore the latest releases using the URL below:
[https://github.com/istio/istio/releases](https://github.com/istio/istio/releases)

## Install Istio using Helm
For our labs today we will be using Istio 1.2.2 which already exists in the `student` directory to save time

Run the following commands to go to install the prerequisites and to create the isntallation template with Helm:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} create namespace istio-system
helm template istio-1.2.2/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl --kubeconfig=./config.cluster${CLUSTER} apply -f -
helm template istio-1.2.2/install/kubernetes/helm/istio --name istio --namespace istio-system > istio.yaml
```

Edit the `istio.yaml` file as follow:

```
...
apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway
  namespace: istio-system
  annotations:
    kubernetes.dcos.io/dklb-config: |
      name: dklb${CLUSTER}
      size: 2
      frontends:
      - port: 100${CLUSTER}
        servicePort: 80
  labels:
    chart: gateways
    heritage: Tiller
    release: istio
    app: istio-ingressgateway
    istio: ingressgateway
spec:
  type: LoadBalancer
...
```

Don't forget to replace `${CLUSTER}` by the value of the variable

Now, you can deploy Istio from the template:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} create -f istio.yaml
```

**NOTE** This will take a few minutes to deploy

## Deploy an application on Istio

This example deploys a sample application composed of four separate microservices used to demonstrate various Istio features. The application displays information about a book, similar to a single catalog entry of an online book store. Displayed on the page is a description of the book, book details (ISBN, number of pages, and so on), and a few book reviews.

Run the following commands to deploy the bookinfo application:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} apply -f <(istioctl --kubeconfig=./config.cluster${CLUSTER} kube-inject -f istio-1.2.2/samples/bookinfo/platform/kube/bookinfo.yaml)
kubectl --kubeconfig=./config.cluster${CLUSTER} apply -f istio-1.2.2/samples/bookinfo/networking/bookinfo-gateway.yaml
```

## Validate that your services are running
```
kubectl --kubeconfig=./config.cluster${CLUSTER} get pods
```

## Accessing the application
Go to the following URL to access the application through your web browser:
```
open http://${PUBLICIP}:100${CLUSTER}/productpage
```

![Istio - bookstore app](https://github.com/djannot/dcos-kubernetes-training/blob/master/images/lab8_1.png)

## Other Istio Features
You can then follow the other steps described in the Istio documentation to understand the different Istio features:

[https://istio.io/docs/examples/bookinfo/](https://istio.io/docs/examples/bookinfo/)

## Finished with the Lab 9 - Istio

[Move to Lab 10 - Monitoring](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/linux-macOS/lab10_monitoring.md)
