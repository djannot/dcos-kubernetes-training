clusters=$1
group=sg-0586227e79540317c
eval $(maws login 110465657741_Mesosphere-PowerUser)
region=us-east-1
aws --region=$region elb create-load-balancer-listeners --load-balancer-name=ext-djannot --listeners Protocol=TCP,LoadBalancerPort=8443,InstanceProtocol=TCP,InstancePort=8443
awk -v clusters=${clusters} 'BEGIN { for (i=0; i<=clusters; i++) printf("%02d\n", i) }' | while read i; do
  aws --region=$region elb create-load-balancer-listeners --load-balancer-name=ext-djannot --listeners Protocol=TCP,LoadBalancerPort=80${i},InstanceProtocol=TCP,InstancePort=80${i}
  aws --region=$region elb create-load-balancer-listeners --load-balancer-name=ext-djannot --listeners Protocol=TCP,LoadBalancerPort=90${i},InstanceProtocol=TCP,InstancePort=90${i}
  aws --region=$region elb create-load-balancer-listeners --load-balancer-name=ext-djannot --listeners Protocol=TCP,LoadBalancerPort=100${i},InstanceProtocol=TCP,InstancePort=100${i}
done
aws --region=$region ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=8001-80${clusters} --cidr=0.0.0.0/0
aws --region=$region ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=9001-90${clusters} --cidr=0.0.0.0/0
aws --region=$region ec2 authorize-security-group-ingress --group-id=${group} --protocol=tcp --port=10001-100${clusters} --cidr=0.0.0.0/0
