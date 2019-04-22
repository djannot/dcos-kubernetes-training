name=$CLUSTER
region=$REGION
maws=$1
eval $(maws login ${maws})

aws --region=$region iam put-role-policy --role-name dcos-${CLUSTER}-instance_role --policy-name CSI --policy-document file://csi-iam-policy.json
