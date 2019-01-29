seconds=0
OUTPUT=0
sleep 5
while [ "$OUTPUT" -ne 1 ]; do
  OUTPUT=`dcos $1 --name $2 plan status deploy | head -1 | grep -c COMPLETE`;
  seconds=$((seconds+5))
  printf "Waiting %s seconds for $1 to come up.\n" "$seconds"
  sleep 5
done
