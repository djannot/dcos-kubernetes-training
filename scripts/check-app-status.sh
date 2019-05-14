seconds=0
OUTPUT=0
sleep 5
while [ "$OUTPUT" -ne 1 ]; do
  OUTPUT=`dcos marathon app list | grep $1 | awk '{print $4}' | cut -c1`;
  seconds=$((seconds+5))
  printf "Waiting %s seconds for $1 to come up.\n" "$seconds"
  sleep 5
done
