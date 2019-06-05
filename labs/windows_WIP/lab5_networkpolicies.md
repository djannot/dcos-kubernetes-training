# Lab 5: Leverage Network Policies to restrict access
By default, all the pods can access all the services inside and outside the Kubernetes clusters and services exposed to the external world can be accessed by anyone. Kubernetes Network Policies can be used to restrict access.

When a Kubernetes cluster is deployed on DC/OS, a Calico cluster is automatically deployed for this cluster. It allows a user to define network policies without any additional configuration.

### Objectives
- Create a network policy to deny any ingress
- Check that the Redis and the http-echo apps aren't accessible anymore
- Create network policies to allow ingress access to these apps only
- Check that the Redis and the http-echo apps are now accessible

### Why is this Important?
In many cases, you want to restrict communications between services. For example, you often want some micro services to be reachable only other specific micro services.

In this lab, we restrict access to ingresses, so you may thing that it's useless as we can simply not expose these apps if we want to restrict access. But, in fact, it makes sense to also create network policies to avoid cases where an app is exposed by mistake.

## Create a network policy to deny any ingress
```
set FILE=deny-ingress.yml
>%FILE% echo apiVersion: networking.k8s.io/v1
>>%FILE% echo kind: NetworkPolicy
>>%FILE% echo metadata:
>>%FILE% echo   name: default-deny
>>%FILE% echo spec:
>>%FILE% echo   podSelector: {}
>>%FILE% echo   policyTypes:
>>%FILE% echo   - Ingress
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f deny-ingress.yml
```

## Check that the Redis and the http-echo apps aren't accessible anymore

```
telnet %PUBLICIP% 80%CLUSTER%
```

```
curl -H "Host: http-echo-%CLUSTER%-1.com" http://%PUBLICIP%:90%CLUSTER%
curl -H "Host: http-echo-%CLUSTER%-2.com" http://%PUBLICIP%:90%CLUSTER%
```

## Create network policies to allow ingress access to these apps only

```
set FILE=access-redis.yml
>%FILE% echo apiVersion: networking.k8s.io/v1
>>%FILE% echo kind: NetworkPolicy
>>%FILE% echo metadata:
>>%FILE% echo   name: access-redis
>>%FILE% echo spec:
>>%FILE% echo   podSelector:
>>%FILE% echo     matchLabels:
>>%FILE% echo       app: redis
>>%FILE% echo   ingress:
>>%FILE% echo   - from: []
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f access-redis.yml
```

```
set FILE=access-http-echo-1.yml
>%FILE% echo apiVersion: networking.k8s.io/v1
>>%FILE% echo kind: NetworkPolicy
>>%FILE% echo metadata:
>>%FILE% echo   name: access-http-echo-1
>>%FILE% echo spec:
>>%FILE% echo   podSelector:
>>%FILE% echo     matchLabels:
>>%FILE% echo       app: http-echo-1
>>%FILE% echo   ingress:
>>%FILE% echo   - from: []
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f access-http-echo-1.yml
```

```
set FILE=access-http-echo-2.yml
>%FILE% echo apiVersion: networking.k8s.io/v1
>>%FILE% echo kind: NetworkPolicy
>>%FILE% echo metadata:
>>%FILE% echo   name: access-http-echo-2
>>%FILE% echo spec:
>>%FILE% echo   podSelector:
>>%FILE% echo     matchLabels:
>>%FILE% echo       app: http-echo-2
>>%FILE% echo   ingress:
>>%FILE% echo   - from: []
kubectl --kubeconfig=./config.cluster%CLUSTER% create -f access-http-echo-2.yml
```

## Check that the Redis and the http-echo apps are now accessible

```
telnet %PUBLICIP% 80%CLUSTER%
```

```
curl -H "Host: http-echo-%CLUSTER%-1.com" http://%PUBLICIP%:90%CLUSTER%
curl -H "Host: http-echo-%CLUSTER%-2.com" http://%PUBLICIP%:90%CLUSTER%
```

## Delete the network policy that denies any ingress
```
kubectl --kubeconfig=./config.cluster%CLUSTER% delete -f deny-ingress.yml
```

## Finished with the Lab 5 - Network Policies

[Move to Lab 6 - Portworx Storage](https://github.com/djannot/dcos-kubernetes-training/blob/master/labs/windows_WIP/lab5_portworxstorage.md)
