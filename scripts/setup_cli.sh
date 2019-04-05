#!/bin/bash

OUTPUT=1
while [ "$OUTPUT" != 0 ]; do

  if dcos cluster list | grep -q "AVAILABLE"; then
      OUTPUT=0
  else
    echo
    echo "**** Running command: dcos cluster setup"
    #echo
    dcos cluster setup $1 --insecure --username=bootstrapuser --password=deleteme
    echo
    echo "**** Installing enterprise CLI"
    echo
    dcos package install dcos-enterprise-cli --yes
    echo
    echo "**** Setting core.ssl_verify to false"
    echo
    dcos config set core.ssl_verify false
  fi
done
