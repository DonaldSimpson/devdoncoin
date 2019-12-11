#!/bin/bash

### evironment variables
### - the token is passed in as a secret
### - other values are set in the pipeline
### - all of them should be tested & verified...
export PIPELINE_API="https://api-endpoint:8443"
export PIPELINE_CONTEXT="k8s-context"
export PIPELINE_TOKEN=$*
export PIPELINE_USER="sa-${PIPELINE_NAMESPACE}"

### set up a .kube/config with the settings required
### setting the variables/params we have
mkdir -p ~/.kube
echo "
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: ${PIPELINE_API}
  name: ${PIPELINE_CONTEXT}

contexts:
- context:
    cluster: ${PIPELINE_CONTEXT}
    namespace: ${PIPELINE_NAMESPACE}
    user: ${PIPELINE_USER}
  name: ${PIPELINE_CONTEXT}
current-context: ${PIPELINE_CONTEXT}
kind: Config
preferences: {}
users:
- name: ${PIPELINE_USER}
  user:
   token: ${PIPELINE_TOKEN}
" >> ~/.kube/config

### the pipeline calls this script with one of these args
### to apply, delete or test as required
### the test is simplistic but could be extended
case "${ACTION}" in
test)  echo "ACTION to perform: test"
    kubectl -n ${PIPELINE_NAMESPACE} get pods
    echo "Waiting on pod Status to == Running..."
    sleep 10
    until kubectl -n ${PIPELINE_NAMESPACE} get pods | grep -m 1 "Running"; do sleep 1; done
    echo "Ok, pod is up and Running in ${PIPELINE_NAMESPACE}"
    ;;
apply)  echo  "ACTION to perform: apply"
    kubectl ${ACTION} -f doncoin.yaml -n ${PIPELINE_NAMESPACE}
    ;;
delete)  echo  "ACTION to perform: delete"
    kubectl ${ACTION} -f doncoin.yaml -n ${PIPELINE_NAMESPACE}
    ;;
*) echo "ACTION should be set to one of: test, apply or delete."
    exit 1
   ;;
esac
