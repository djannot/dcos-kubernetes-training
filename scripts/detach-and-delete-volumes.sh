eval $(maws login 110465657741_Mesosphere-PowerUser)
name=djannot
region=us-east-1

aws --region=$region ec2 describe-volumes |  jq --raw-output '.Volumes[] | select(.Tags[0].Value == "djannot") | .VolumeId' | while read volume; do
  instance=$(aws --region=$region ec2 describe-volumes --volume-ids $volume | jq --raw-output .Volumes[0].Attachments[0].InstanceId)
  aws --region=$region ec2 detach-volume --force --device=/dev/xvdb --instance-id=$instance --volume-id=$volume
done
sleep 15
aws --region=$region ec2 describe-volumes |  jq --raw-output '.Volumes[] | select(.Tags[0].Value == "djannot") | .VolumeId' | while read volume; do
  aws --region=$region ec2 delete-volume --volume-id=$volume
done
