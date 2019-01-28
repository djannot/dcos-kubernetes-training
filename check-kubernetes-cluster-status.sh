seconds=0
OUTPUT=0
sleep 5
while [ "$OUTPUT" -ne 1 ]; do
  OUTPUT=`dcos kubernetes cluster debug plan status deploy --cluster-name=$1 | head -2 | tail -1 | grep -c COMPLETE`;
  seconds=$((seconds+5))
  printf "Waiting %s seconds for kubernetes cluster $1 to come up.\n" "$seconds"
  sleep 5
done
