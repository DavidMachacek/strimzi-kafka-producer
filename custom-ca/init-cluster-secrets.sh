#!/usr/bin/env bash

KAFKA_CLUSTER_NAME=infra-kafka-cluster

# Create secrets, label and annotate secrets

oc create secret generic $KAFKA_CLUSTER_NAME-cluster-ca-cert \
  --from-file=ca.crt=cluster-bundle.crt
oc label secret $KAFKA_CLUSTER_NAME-cluster-ca-cert \
  strimzi.io/kind=Kafka \
  strimzi.io/cluster=$KAFKA_CLUSTER_NAME
oc annotate secret $KAFKA_CLUSTER_NAME-cluster-ca-cert \
  strimzi.io/ca-cert-generation=0
oc get secret $KAFKA_CLUSTER_NAME-cluster-ca-cert -o yaml > $KAFKA_CLUSTER_NAME-cluster-ca-cert.yaml

#oc delete secret $KAFKA_CLUSTER_NAME-cluster-ca --ignore-not-found
oc create secret generic $KAFKA_CLUSTER_NAME-cluster-ca \
  --from-file=ca.key=cluster.key
oc label secret $KAFKA_CLUSTER_NAME-cluster-ca \
  strimzi.io/kind=Kafka \
  strimzi.io/cluster=$KAFKA_CLUSTER_NAME
oc annotate secret $KAFKA_CLUSTER_NAME-cluster-ca \
  strimzi.io/ca-key-generation=0
oc get secret $KAFKA_CLUSTER_NAME-cluster-ca -o yaml > $KAFKA_CLUSTER_NAME-cluster-ca.yaml

#oc delete secret $KAFKA_CLUSTER_NAME-clients-ca-cert --ignore-not-found
oc create secret generic $KAFKA_CLUSTER_NAME-clients-ca-cert \
  --from-file=ca.crt=clients-bundle.crt
oc label secret $KAFKA_CLUSTER_NAME-clients-ca-cert \
  strimzi.io/kind=Kafka \
  strimzi.io/cluster=$KAFKA_CLUSTER_NAME
oc annotate secret $KAFKA_CLUSTER_NAME-clients-ca-cert \
  strimzi.io/ca-cert-generation=0
oc get secret $KAFKA_CLUSTER_NAME-clients-ca-cert -o yaml > $KAFKA_CLUSTER_NAME-clients-ca-cert.yaml

#oc delete secret $KAFKA_CLUSTER_NAME-clients-ca --ignore-not-found
oc create secret generic $KAFKA_CLUSTER_NAME-clients-ca \
  --from-file=ca.key=clients.key
oc label secret $KAFKA_CLUSTER_NAME-clients-ca \
  strimzi.io/kind=Kafka \
  strimzi.io/cluster=$KAFKA_CLUSTER_NAME
oc annotate secret $KAFKA_CLUSTER_NAME-clients-ca \
  strimzi.io/ca-key-generation=0
oc get secret $KAFKA_CLUSTER_NAME-clients-ca -o yaml > $KAFKA_CLUSTER_NAME-clients-ca.yaml
