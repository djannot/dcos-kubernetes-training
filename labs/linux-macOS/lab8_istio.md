# Lab 8: Deploy Istio using Helm and Deploy Applications using Istio

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
For our labs today we will be using Istio 1.0.6 which already exists in the `student` directory to save time

Run the following commands to go to the Istio directory and to install Istio using Helm:
```
export PATH=$PWD/istio-1.0.6/bin:$PATH
helm --kubeconfig=./config.cluster${CLUSTER} install istio-1.0.6/install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set gateways.istio-ingressgateway.serviceAnnotations."kubernetes\.dcos\.io/edgelb-pool-name"=dklb${CLUSTER} \
  --set gateways.istio-ingressgateway.serviceAnnotations."kubernetes\.dcos\.io/edgelb-pool-size"=\"2\" \
  --set gateways.istio-ingressgateway.ports[0].port=100${CLUSTER} \
  --set gateways.istio-ingressgateway.ports[0].targetPort=80 \
  --set gateways.istio-ingressgateway.ports[0].name=http2 \
  --set gateways.istio-ingressgateway.ports[0].nodePort=30000
```

**NOTE** This will take a few minutes to deploy

The finished output should look similar to below:
```
$ helm --kubeconfig=./config.cluster${CLUSTER} install install/kubernetes/helm/istio --name istio --namespace istio-system \
>   --set gateways.istio-ingressgateway.serviceAnnotations."kubernetes\.dcos\.io/edgelb-pool-name"=dklb \
>   --set gateways.istio-ingressgateway.serviceAnnotations."kubernetes\.dcos\.io/edgelb-pool-size"=\"2\" \
>   --set gateways.istio-ingressgateway.ports[0].port=100${CLUSTER} \
>   --set gateways.istio-ingressgateway.ports[0].targetPort=80 \
>   --set gateways.istio-ingressgateway.ports[0].name=http2 \
>   --set gateways.istio-ingressgateway.ports[0].nodePort=30000
NAME:   istio
LAST DEPLOYED: Tue Apr  2 10:51:28 2019
NAMESPACE: istio-system
STATUS: DEPLOYED

RESOURCES:
==> v1alpha3/DestinationRule
NAME             AGE
istio-telemetry  50s
istio-policy     50s

==> v1alpha2/kubernetesenv
NAME     AGE
handler  50s

==> v1alpha2/prometheus
NAME     AGE
handler  50s

==> v1alpha2/stdio
NAME     AGE
handler  50s

==> v1/ServiceAccount
NAME                                    SECRETS  AGE
istio-galley-service-account            1        51s
istio-ingressgateway-service-account    1        51s
istio-egressgateway-service-account     1        51s
istio-mixer-service-account             1        51s
istio-pilot-service-account             1        51s
prometheus                              1        51s
istio-security-post-install-account     1        51s
istio-citadel-service-account           1        51s
istio-sidecar-injector-service-account  1        51s

==> v1/Service
NAME                    TYPE          CLUSTER-IP      EXTERNAL-IP  PORT(S)                                AGE
istio-galley            ClusterIP     10.100.60.94    <none>       443/TCP,9093/TCP                       51s
istio-egressgateway     ClusterIP     10.100.238.41   <none>       80/TCP,443/TCP                         51s
istio-ingressgateway    LoadBalancer  10.100.161.7    <pending>    10002:30000/TCP                        51s
istio-policy            ClusterIP     10.100.108.72   <none>       9091/TCP,15004/TCP,9093/TCP            51s
istio-telemetry         ClusterIP     10.100.38.169   <none>       9091/TCP,15004/TCP,9093/TCP,42422/TCP  51s
istio-pilot             ClusterIP     10.100.98.27    <none>       15010/TCP,15011/TCP,8080/TCP,9093/TCP  51s
prometheus              ClusterIP     10.100.103.125  <none>       9090/TCP                               51s
istio-citadel           ClusterIP     10.100.60.157   <none>       8060/TCP,9093/TCP                      51s
istio-sidecar-injector  ClusterIP     10.100.75.206   <none>       443/TCP                                51s

==> v1alpha2/kubernetes
NAME        AGE
attributes  50s

==> v1alpha2/metric
NAME             AGE
requestduration  50s
requestcount     50s
tcpbytesent      50s
responsesize     50s
tcpbytereceived  50s
requestsize      50s

==> v1/Pod(related)
NAME                                     READY  STATUS             RESTARTS  AGE
istio-galley-685bb48846-c2m7g            0/1    ContainerCreating  0         51s
istio-ingressgateway-5f55896cb-8jghq     1/1    Running            0         51s
istio-egressgateway-6d79447874-sh4qp     1/1    Running            0         51s
istio-policy-547d64b8d7-cqxg8            2/2    Running            0         51s
istio-telemetry-c5488fc49-5fr4f          2/2    Running            0         51s
istio-pilot-8645f5655b-xswkl             2/2    Running            0         50s
prometheus-76b7745b64-d28d4              1/1    Running            0         50s
istio-citadel-6f444d9999-7f565           1/1    Running            0         50s
istio-sidecar-injector-5d8dd9448d-tfh2t  0/1    ContainerCreating  0         50s

==> v1/ConfigMap
NAME                             DATA  AGE
istio-galley-configuration       1     51s
istio-statsd-prom-bridge         1     51s
prometheus                       1     51s
istio-security-custom-resources  2     51s
istio                            1     51s
istio-sidecar-injector           1     51s

==> v1beta1/ClusterRoleBinding
NAME                                                    AGE
istio-galley-admin-role-binding-istio-system            51s
istio-ingressgateway-istio-system                       51s
istio-egressgateway-istio-system                        51s
istio-mixer-admin-role-binding-istio-system             51s
istio-pilot-istio-system                                51s
prometheus-istio-system                                 51s
istio-citadel-istio-system                              51s
istio-security-post-install-role-binding-istio-system   51s
istio-sidecar-injector-admin-role-binding-istio-system  51s

==> v2beta1/HorizontalPodAutoscaler
NAME                  REFERENCE                        TARGETS        MINPODS  MAXPODS  REPLICAS  AGE
istio-ingressgateway  Deployment/istio-ingressgateway  <unknown>/80%  1        5        1         50s
istio-egressgateway   Deployment/istio-egressgateway   <unknown>/80%  1        5        1         50s
istio-policy          Deployment/istio-policy          <unknown>/80%  1        5        1         50s
istio-telemetry       Deployment/istio-telemetry       <unknown>/80%  1        5        1         50s
istio-pilot           Deployment/istio-pilot           <unknown>/80%  1        5        1         50s

==> v1alpha2/attributemanifest
NAME        AGE
istioproxy  50s
kubernetes  50s

==> v1alpha2/rule
NAME                    AGE
stdiotcp                50s
stdio                   50s
promtcp                 50s
kubeattrgenrulerule     50s
tcpkubeattrgenrulerule  50s
promhttp                50s

==> v1beta1/ClusterRole
NAME                                      AGE
istio-galley-istio-system                 51s
istio-ingressgateway-istio-system         51s
istio-egressgateway-istio-system          51s
istio-mixer-istio-system                  51s
istio-pilot-istio-system                  51s
prometheus-istio-system                   51s
istio-citadel-istio-system                51s
istio-security-post-install-istio-system  51s
istio-sidecar-injector-istio-system       51s

==> v1beta1/Deployment
NAME                    DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
istio-galley            1        1        1           0          51s
istio-ingressgateway    1        1        1           1          51s
istio-egressgateway     1        1        1           1          51s
istio-policy            1        1        1           1          51s
istio-telemetry         1        1        1           1          51s
istio-pilot             1        1        1           1          51s
prometheus              1        1        1           1          51s
istio-citadel           1        1        1           1          50s
istio-sidecar-injector  1        1        1           0          50s

==> v1alpha2/logentry
NAME          AGE
accesslog     50s
tcpaccesslog  50s

==> v1alpha3/Gateway
NAME                             AGE
istio-autogenerated-k8s-ingress  50s

==> v1beta1/MutatingWebhookConfiguration
NAME                    AGE
istio-sidecar-injector  50s
```

## Deploy an application on Istio

This example deploys a sample application composed of four separate microservices used to demonstrate various Istio features. The application displays information about a book, similar to a single catalog entry of an online book store. Displayed on the page is a description of the book, book details (ISBN, number of pages, and so on), and a few book reviews.

Run the following commands to deploy the bookinfo application:
```
kubectl --kubeconfig=./config.cluster${CLUSTER} apply -f <(istioctl --kubeconfig=./config.cluster${CLUSTER} kube-inject -f istio-1.0.6/samples/bookinfo/platform/kube/bookinfo.yaml)
kubectl --kubeconfig=./config.cluster${CLUSTER} apply -f istio-1.0.6/samples/bookinfo/networking/bookinfo-gateway.yaml
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

# Congrats! We are now done with all of the labs!
