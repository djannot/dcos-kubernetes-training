## CHANGE THIS EVERY TIME!!!
export APPNAME=training
export PUBLICIP=34.221.178.85
export CLUSTER=alexly-cluster
export REGION=us-west-2
clusters=2

# 1. Deploy a Kubernetes cluster

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  sed "s/TOBEREPLACED/${i}/g" scripts/options-kubernetes-cluster.json.template > scripts/options-kubernetes-cluster${i}.json
  ./scripts/deploy-kubernetes-cluster.sh ${i}
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  ./scripts/check-kubernetes-cluster-status.sh ${APPNAME}/prod/k8s/cluster${i}
done

if [ -f ~/.kube/config ]; then
  mv ~/.kube/config ~/.kube/config.ori
fi
awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  dcos kubernetes cluster kubeconfig --context-name=${APPNAME}-prod-k8s-cluster${i} --cluster-name=${APPNAME}/prod/k8s/cluster${i} \
    --apiserver-url https://${APPNAME}.prod.k8s.cluster${i}.mesos.lab:8443 \
    --insecure-skip-tls-verify
  mv ~/.kube/config ./config.cluster${i}
done
if [ -f ~/.kube/config.ori ]; then
  mv ~/.kube/config.ori ~/.kube/config
fi

## DCOS Authentication (not part of the training)

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: aly@mesosphere.com
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: User
  name: aly@mesosphere.com
  namespace: kube-system
EOF
done

kubectl --kubeconfig=./config.cluster${i} get pods --token=$(dcos config show core.dcos_acs_token)

kubectl --kubeconfig=./config.cluster${i} --token=$(dcos config show core.dcos_acs_token) proxy

# 4. Expose a Kubernetes Application using a Service Type Load Balancer (L4)

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} create -f scripts/dklb-prereqs.yaml
  kubectl --kubeconfig=./config.cluster${i} create -f scripts/dklb-deployment.yaml
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
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
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
apiVersion: v1
kind: Service
metadata:
  annotations:
    kubernetes.dcos.io/edgelb-pool-name: "dklb${i}"
    kubernetes.dcos.io/edgelb-pool-size: "2"
    kubernetes.dcos.io/edgelb-pool-portmap.6379: "80${i}"
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
done

sleep 30

# Sample Configurations

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  telnet $PUBLICIP 80${i} << EOF
quit
EOF
done

#test=0
#while [ $test -lt $clusters ]; do
#  test=$(nc -z -v -w 1 $PUBLICIP 8001-80${clusters} 2>&1 | wc -l | awk '{print $1}')
#  echo $test
#done

# 5. Expose a Kubernetes Application using an Ingress (L7)

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} run --restart=Never --image hashicorp/http-echo --labels app=http-echo-1,owner=dklb --port 80 http-echo-1 -- -listen=:80 --text='Hello from http-echo-1!'
  kubectl --kubeconfig=./config.cluster${i} run --restart=Never --image hashicorp/http-echo --labels app=http-echo-2,owner=dklb --port 80 http-echo-2 -- -listen=:80 --text='Hello from http-echo-2!'
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} expose pod http-echo-1 --port 80 --target-port 80 --type NodePort --name "http-echo-1"
  kubectl --kubeconfig=./config.cluster${i} expose pod http-echo-2 --port 80 --target-port 80 --type NodePort --name "http-echo-2"
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: edgelb
    kubernetes.dcos.io/edgelb-pool-name: "dklb${i}"
    kubernetes.dcos.io/edgelb-pool-size: "2"
    kubernetes.dcos.io/edgelb-pool-port: "90${i}"
  labels:
    owner: dklb${i}
  name: dklb-echo
spec:
  rules:
  - host: "http-echo-${i}-1.com"
    http:
      paths:
      - backend:
          serviceName: http-echo-1
          servicePort: 80
  - host: "http-echo-${i}-2.com"
    http:
      paths:
      - backend:
          serviceName: http-echo-2
          servicePort: 80
EOF
done

sleep 30

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  curl -H "Host: http-echo-${i}-1.com" http://${PUBLICIP}:90${i}
  curl -H "Host: http-echo-${i}-2.com" http://${PUBLICIP}:90${i}
done

# 8. Configure Helm

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
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
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  helm --kubeconfig=./config.cluster${i} init --service-account tiller
done

## Sleeping 120 seconds to let the tiller spin up
sleep 120

# 9. Deploy Istio using Helm

curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.0.6 sh -

export PATH=$PWD/istio-1.0.6/bin:$PATH
awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  helm --kubeconfig=./config.cluster${i} install istio-1.0.6/install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set gateways.istio-ingressgateway.serviceAnnotations."kubernetes\.dcos\.io/edgelb-pool-name"=dklb${i} \
  --set gateways.istio-ingressgateway.serviceAnnotations."kubernetes\.dcos\.io/edgelb-pool-size"=\"2\" \
  --set gateways.istio-ingressgateway.ports[0].port=100${i} \
  --set gateways.istio-ingressgateway.ports[0].targetPort=80 \
  --set gateways.istio-ingressgateway.ports[0].name=http2 \
  --set gateways.istio-ingressgateway.ports[0].nodePort=30000
done

# 10. Deploy an application on Istio

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} apply -f <(istioctl --kubeconfig=./config.cluster${i} kube-inject -f istio-1.0.6/samples/bookinfo/platform/kube/bookinfo.yaml)
  kubectl --kubeconfig=./config.cluster${i} apply -f istio-1.0.6/samples/bookinfo/networking/bookinfo-gateway.yaml
done

## Sleeping 30 seconds to let the Istio application spin up
sleep 30

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  curl -I http://${PUBLICIP}:100${i}/productpage
done

# 11. Deploy Knative

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} apply --filename https://github.com/knative/serving/releases/download/v0.4.0/serving.yaml \
     --filename https://github.com/knative/build/releases/download/v0.4.0/build.yaml \
     --filename https://github.com/knative/eventing/releases/download/v0.4.0/release.yaml \
     --filename https://github.com/knative/eventing-sources/releases/download/v0.4.0/release.yaml \
     --filename https://github.com/knative/serving/releases/download/v0.4.0/monitoring.yaml \
     --filename https://raw.githubusercontent.com/knative/serving/v0.4.0/third_party/config/build/clusterrole.yaml
done

## Sleeping 150 seconds to let knative spin up
sleep 150

# 11. Deploy an application on Knative

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} apply -f -
apiVersion: serving.knative.dev/v1alpha1 # Current version of Knative
kind: Service
metadata:
  name: helloworld-go # The name of the app
  namespace: default # The namespace the app will use
spec:
  runLatest:
    configuration:
      revisionTemplate:
        spec:
          container:
            image: gcr.io/knative-samples/helloworld-go # The URL to the image of the app
            env:
              - name: TARGET # The environment variable printed out by the sample app
                value: "Go Sample v1"
EOF
done

## Sleeping 60 seconds to let the knative application spin up
sleep 60

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  curl -H "Host: helloworld-go.default.example.com" http://${PUBLICIP}:100${i}
done
