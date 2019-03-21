eval $(maws login 110465657741_Mesosphere-PowerUser)
name=$CLUSTER
region=$REGION

aws --region=$region iam put-role-policy --role-name dcos-${CLUSTER}-instance_role --policy-name CSI --policy-document file://csi-iam-policy.json
