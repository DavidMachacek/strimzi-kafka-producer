#!/usr/bin/env bash


KAFKA_CLUSTER_NAME=infra-kafka-cluster

## Stop reconciliation
echo "Pausing reconciliation"
oc annotate kafka $KAFKA_CLUSTER_NAME strimzi.io/pause-reconciliation="true" --overwrite

## Patch ClusterCA key
echo "Patching ClusterCA key"
oc patch secret $KAFKA_CLUSTER_NAME-cluster-ca -p '{"data": {"ca.key": "'$(base64 -w0 < ./cluster.key)'"}}'
oc annotate secret $KAFKA_CLUSTER_NAME-cluster-ca strimzi.io/ca-key-generation="1" --overwrite

## Patch ClusterCA certificate
echo "Patching ClusterCA certificate"
oc patch secret $KAFKA_CLUSTER_NAME-cluster-ca-cert -p '{"data": {"ca-'$(date +%Y-%m-%d)'.crt": "'$(oc get secret $KAFKA_CLUSTER_NAME-cluster-ca-cert -o=jsonpath='{.data.ca\.crt}')'"}}'
oc patch secret $KAFKA_CLUSTER_NAME-cluster-ca-cert -p '{"data": {"ca.crt": "'$(base64 -w0 < ./cluster-bundle.crt)'"}}'
oc annotate secret $KAFKA_CLUSTER_NAME-cluster-ca-cert strimzi.io/ca-cert-generation="1" --overwrite

## Patch ClientsCA key
echo "Patching ClientsCA key"
oc patch secret $KAFKA_CLUSTER_NAME-clients-ca -p '{"data": {"ca.key": "'$(base64 -w0 < ./clients.key)'"}}'
oc annotate secret $KAFKA_CLUSTER_NAME-clients-ca strimzi.io/ca-key-generation="1" --overwrite

## Patch ClientsCA certificate
echo "Patching ClientsCA certificate"
oc patch secret $KAFKA_CLUSTER_NAME-clients-ca-cert -p '{"data": {"ca-'$(date +%Y-%m-%d)'.crt": "'$(oc get secret $KAFKA_CLUSTER_NAME-clients-ca-cert -o=jsonpath='{.data.ca\.crt}')'"}}'
oc patch secret $KAFKA_CLUSTER_NAME-clients-ca-cert -p '{"data": {"ca.crt": "'$(base64 -w0 < ./clients-bundle.crt)'"}}'
oc annotate secret $KAFKA_CLUSTER_NAME-clients-ca-cert strimzi.io/ca-cert-generation="1" --overwrite

## Unpause reconciliation
echo "Unpausing reconciliation"
oc annotate kafka $KAFKA_CLUSTER_NAME strimzi.io/pause-reconciliation="false" --overwrite
