path=${APPNAME}/prod/k8s/cluster${1}
serviceaccount=${APPNAME}-prod-k8s-cluster${1}
underscore=${APPNAME}__prod__k8s__cluster${1}

dcos security org service-accounts keypair private-${serviceaccount}.pem public-${serviceaccount}.pem
dcos security org service-accounts delete ${serviceaccount}
dcos security org service-accounts create -p public-${serviceaccount}.pem -d /${path} ${serviceaccount}
dcos security secrets delete /${path}/private-${serviceaccount}
dcos security secrets create-sa-secret --strict private-${serviceaccount}.pem ${serviceaccount} /${path}/private-${serviceaccount}

dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:cluster${1}-role create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:${underscore}-role create
dcos security org users grant ${serviceaccount} dcos:mesos:master:task:user:root create
dcos security org users grant ${serviceaccount} dcos:mesos:agent:task:user:root create
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:role:${underscore}-role create
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:principal:${serviceaccount} delete
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:role:${underscore}-role create
dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:principal:${serviceaccount} delete
dcos security org users grant ${serviceaccount} dcos:secrets:default:/${path}/* full
dcos security org users grant ${serviceaccount} dcos:secrets:list:default:/${path} read
dcos security org users grant ${serviceaccount} dcos:secrets:default:/${underscore}/* full
dcos security org users grant ${serviceaccount} dcos:secrets:list:default:/${underscore} read
dcos security org users grant ${serviceaccount} dcos:adminrouter:ops:ca:rw full
dcos security org users grant ${serviceaccount} dcos:adminrouter:ops:ca:ro full
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public/${underscore}-role create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public/${underscore}-role read

dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:role:slave_public/${underscore}-role create
dcos security org users grant ${serviceaccount} dcos:mesos:master:reservation:role:slave_public/cluster${1}-role create


dcos security org users grant ${serviceaccount} dcos:mesos:master:volume:role:slave_public/${underscore}-role create
dcos security org users grant ${serviceaccount} dcos:mesos:master:framework:role:slave_public read
dcos security org users grant ${serviceaccount} dcos:mesos:agent:framework:role:slave_public read

dcos kubernetes cluster create --yes --options=options-kubernetes-cluster${1}.json --package-version=2.0.0-1.12.1
#dcos kubernetes cluster create --yes --options=options-kubernetes-cluster${1}.json --package-version=stub-universe
