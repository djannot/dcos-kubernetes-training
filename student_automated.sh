## CHANGE THIS EVERY TIME!!!
export APPNAME=training
export PUBLICIP=54.162.3.167
export CLUSTER=djannot
export REGION=us-east-1
export clusters=2

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

# 2. Scale your Kubernetes cluster

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  sed "s/TOBEREPLACED/${i}/g" scripts/options-kubernetes-update-cluster.json.template > scripts/options-kubernetes-update-cluster${i}.json
  dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster${i} --options=scripts/options-kubernetes-update-cluster${i}.json --yes
done

# 3. Upgrade your Kubernetes cluster

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster${i} --package-version=2.3.2-1.14.1 --yes
done

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

# 4. Expose a Kubernetes Application using an Ingress (L7)

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

# 5. Leverage network policies to restrict access

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  curl -H "Host: http-echo-${i}-1.com" http://${PUBLICIP}:90${i}
  curl -H "Host: http-echo-${i}-2.com" http://${PUBLICIP}:90${i}
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  telnet ${PUBLICIP} 80${i}
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: access-redis
spec:
  podSelector:
    matchLabels:
      app: redis
  ingress:
  - from: []
EOF
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  telnet $PUBLICIP 80${i} << EOF
quit
EOF
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: access-http-echo-1
spec:
  podSelector:
    matchLabels:
      app: http-echo-1
  ingress:
  - from: []
EOF
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: access-http-echo-2
spec:
  podSelector:
    matchLabels:
      app: http-echo-2
  ingress:
  - from: []
EOF
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  curl -H "Host: http-echo-${i}-1.com" http://${PUBLICIP}:90${i}
  curl -H "Host: http-echo-${i}-2.com" http://${PUBLICIP}:90${i}
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} delete -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
done

# 6. Leverage persistent storage using Portworx

./scripts/check-status-with-name.sh portworx infra/storage/portworx

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  version=$(kubectl --kubeconfig=./config.cluster${i} version --short | awk -Fv '/Server Version: / {print $3}')
  kubectl --kubeconfig=./config.cluster${i} apply -f "https://install.portworx.com/2.0?kbver=1.13.3&b=true&dcos=true&stork=true"
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
   name: portworx-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "2"
EOF
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} patch storageclass portworx-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
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
done

## Sleeping 60 seconds to let the pvc spin up
sleep 60

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
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
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl get pods --kubeconfig=./config.cluster${i}
done

## Sleeping 20 seconds to let the pod spin up
sleep 20

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} exec pvpod -- /bin/sh -c "echo test > /test-portworx-volume/test"
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} delete pod pvpod
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
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
done

## Sleeping 20 seconds to let the pod spin up
sleep 20

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} exec pvpod cat /test-portworx-volume/test;
done

# 7. Leverage persistent storage using CSI

unzip scripts/csi-driver-deployments-master.zip

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} apply -f csi-driver-deployments-master/aws-ebs/kubernetes/latest/
done

## Sleeping 30 seconds to let the drivers spin up
sleep 30

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
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
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
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
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  cat <<EOF | kubectl --kubeconfig=./config.cluster${i} create -f -
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
done

## Sleeping 120 seconds to let the pod spin up
sleep 120

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  kubectl --kubeconfig=./config.cluster${i} get pods
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  pod=$(kubectl --kubeconfig=./config.cluster${i} get pods | grep ebs-dynamic-app | awk '{ print $1 }')
  kubectl --kubeconfig=./config.cluster${i} exec $pod cat /data/out.txt
done

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  pod=$(kubectl --kubeconfig=./config.cluster${i} get pods | grep ebs-dynamic-app | awk '{ print $1 }')
  kubectl --kubeconfig=./config.cluster${i} delete pod $pod
done

## Sleeping 60 seconds to let the pod spin up
sleep 60

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "Kubernetes cluster training/prod/k8s/cluster${i}:"
  pod=$(kubectl --kubeconfig=./config.cluster${i} get pods | grep ebs-dynamic-app | awk '{ print $1 }')
  kubectl --kubeconfig=./config.cluster${i} exec $pod cat /data/out.txt
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

# 9. Deploy an application on Istio

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

# 10. Enable the metrics_exporter

awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  sed "s/TOBEREPLACED/${i}/g" scripts/options-kubernetes-metrics-exporter.json.template > scripts/options-kubernetes-update-cluster${i}.json
  dcos kubernetes cluster update --cluster-name=training/prod/k8s/cluster${i} --options=scripts/options-kubernetes-update-cluster${i}.json --yes
done
