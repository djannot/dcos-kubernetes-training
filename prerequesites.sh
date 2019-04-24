export APPNAME=training
export PUBLICIP=18.204.164.210
export CLUSTER=k8straining
export REGION=us-east-1
clusters=35

loadbalancer=ext-$CLUSTER
eval $(maws login 110465657741_Mesosphere-PowerUser)
# The group ID of the AWS Security Group of the DC/OS public nodes
group=$(aws --region=$REGION ec2 describe-instances |  jq --raw-output ".Reservations[].Instances[] | select((.Tags | length) > 0) | select(.Tags[].Value | test(\"${CLUSTER}-publicagent\")) | select(.State.Name | test(\"running\")) | .SecurityGroups[] | [.GroupName, .GroupId] | \"\(.[0]) \(.[1])\"" | grep public-agents-lb-firewall | awk '{ print $2 }' | sort -u)

./create-and-attach-volumes.sh
./create-csi-iam-policy.sh
./update-aws-network-configuration.sh ${clusters} ${loadbalancer} ${group}

dcos package install --yes --cli dcos-enterprise-cli

nodes=$(dcos node --json | jq --raw-output ".[] | select((.type | test(\"agent\")) and (.attributes.public_ip == null)) | .id" | wc -l | awk '{ print $1 }')
sed "s/NODES/${nodes}/g" options-portworx.json.template > options-portworx.json

./deploy-portworx.sh

./deploy-kubernetes-mke.sh
./check-kubernetes-mke-status.sh

./create-pool-edgelb-all.sh ${clusters}
./deploy-edgelb.sh
./check-app-status.sh infra/network/dcos-edgelb/pools/all

sed "/mesos.lab/d" /etc/hosts > ./hosts
awk -v clusters=${clusters} 'BEGIN { for (i=1; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  echo "$PUBLICIP ${APPNAME}.prod.k8s.cluster${i}.mesos.lab" >>./hosts
done
sudo mv hosts /etc/hosts
