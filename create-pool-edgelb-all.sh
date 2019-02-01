clusters=$1
cat <<EOF > pool-edgelb-all.json
{
   "apiVersion":"V2",
   "name":"all",
   "namespace":"infra/network/dcos-edgelb/pools",
   "count":2,
   "autoCertificate":true,
   "haproxy":{
      "stats":{
         "bindPort":9091
      },
      "frontends":[
         {
            "bindPort":8443,
            "protocol":"HTTPS",
            "certificates":[
               "\$AUTOCERT"
            ],
            "linkBackend":{
               "map":[

                  {
                     "hostEq":"infra.storage.portworx.mesos.lab",
                     "backend":"infra-storage-portworx"
                  },
EOF
awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  cat <<EOF >> pool-edgelb-all.json
                  {
                     "hostEq":"training.prod.k8s.cluster${i}.mesos.lab",
                     "backend":"training-prod-k8s-cluster${i}-backend"
                  }
EOF
  if [ $i -ne $clusters ]; then
    printf "," >> pool-edgelb-all.json
  fi
done
cat <<EOF >> pool-edgelb-all.json
               ]
            }
         }
      ],
      "backends":[
         {
            "name":"infra-storage-portworx",
            "protocol":"HTTP",
            "services":[
               {
                  "endpoint":{
                     "type":"ADDRESS",
                     "address":"lighthouse-0-start.infrastorageportworx.autoip.dcos.thisdcos.directory",
                     "port":8085
                  }
               }
            ]
         },
EOF
awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  cat <<EOF >> pool-edgelb-all.json
         {
            "name":"training-prod-k8s-cluster${i}-backend",
            "protocol":"HTTPS",
            "services":[
               {
                  "mesos":{
                     "frameworkName":"training/prod/k8s/cluster${i}",
                     "taskNamePattern":"kube-control-plane"
                  },
                  "endpoint":{
                     "portName":"apiserver"
                  }
               }
            ]
         }
EOF
 if [ $i -ne $clusters ]; then
   printf "," >> pool-edgelb-all.json
 fi
done
cat <<EOF >> pool-edgelb-all.json
      ]
   }
}
EOF
