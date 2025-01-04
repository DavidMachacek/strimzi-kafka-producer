#!/usr/bin/env bash

KAFKA_CLUSTER_NAME=b01
PASSWORD="password"
CA_ALIAS="${KAFKA_CLUSTER_NAME}-ca"

# Generate CA with Root, Intermediate, and Strimzi / Clients CAs
echo "Generating CA"
cfssl genkey -initca ca.json | cfssljson -bare ca
echo "Generating intermediateCA"
cfssl genkey intermediate.json | cfssljson -bare intermediate
echo "Signing intermediateCA"
cfssl sign -config config.json -profile CA -ca ca.pem -ca-key ca-key.pem intermediate.csr intermediate.json | cfssljson -bare intermediate
echo "Generating key for clusterCA"
cfssl genkey cluster.json | cfssljson -bare cluster
echo "Signing clusterCA"
cfssl sign -config config.json -profile clusterCA -ca intermediate.pem -ca-key intermediate-key.pem cluster.csr cluster.json | cfssljson -bare cluster
echo "Generating key for clientsCA"
cfssl genkey clients.json | cfssljson -bare clients
echo "Signing clientsCA"
cfssl sign -config config.json -profile clientsCA -ca intermediate.pem -ca-key intermediate-key.pem clients.csr clients.json | cfssljson -bare clients

# Create CRT bundles
cat cluster.pem > cluster-bundle.crt
cat intermediate.pem >> cluster-bundle.crt
cat ca.pem >> cluster-bundle.crt
cat clients.pem > clients-bundle.crt
cat intermediate.pem >> clients-bundle.crt
cat ca.pem >> clients-bundle.crt

cat intermediate.pem >> intermediate-bundle.crt
cat ca.pem >> intermediate-bundle.crt

# Convert keys to PKCS8
openssl pkcs8 -topk8 -nocrypt -in ca-key.pem -out ca.key
openssl pkcs8 -topk8 -nocrypt -in intermediate-key.pem -out intermediate.key
openssl pkcs8 -topk8 -nocrypt -in clients-key.pem -out clients.key
openssl pkcs8 -topk8 -nocrypt -in cluster-key.pem -out cluster.key

# Export PKCS#12 for CA
echo "Exporting PKCS#12 for CA"
openssl pkcs12 -export \
  -in ca.crt \
  -inkey ca.key \
  -out ca.p12 \
  -name $KAFKA_CLUSTER_NAME-ca \
  -passout pass:$PASSWORD

# Export PKCS#12 for cluster
echo "Exporting PKCS#12 for cluster"
openssl pkcs12 -export \
  -in cluster-bundle.crt \
  -inkey cluster.key \
  -out cluster.p12 \
  -name $KAFKA_CLUSTER_NAME-cluster \
  -passout pass:$PASSWORD

# Export PKCS#12 for clients
echo "Exporting PKCS#12 for clients"
openssl pkcs12 -export \
  -in clients-bundle.crt \
  -inkey clients.key \
  -out clients.p12 \
  -name $KAFKA_CLUSTER_NAME-clients \
  -passout pass:$PASSWORD

# Generate Kubernetes Secret manifests
echo "Generating Kubernetes Secret manifests"

cat <<EOF > ${KAFKA_CLUSTER_NAME}-cluster-ca-cert.yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    strimzi.io/ca-key-generation: "0"
  name: ${KAFKA_CLUSTER_NAME}-cluster-ca-cert
  labels:
    strimzi.io/cluster: ${KAFKA_CLUSTER_NAME}
    strimzi.io/kind: Kafka
type: Opaque
data:
  ca.crt: $(base64 -i cluster-bundle.crt)
  ca.p12: $(base64 -i cluster.p12)
  ca.password: $(echo -n "$PASSWORD" | base64)
EOF

cat <<EOF > ${KAFKA_CLUSTER_NAME}-cluster-ca.yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    strimzi.io/ca-key-generation: "0"
  name: ${KAFKA_CLUSTER_NAME}-cluster-ca
  labels:
    strimzi.io/cluster: ${KAFKA_CLUSTER_NAME}
    strimzi.io/kind: Kafka
type: Opaque
data:
  ca.key: $(base64 -i cluster.key)
EOF

cat <<EOF > ${KAFKA_CLUSTER_NAME}-cluster-tls.yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    purpose: "source TLS for cluster issuer"
  name: ${KAFKA_CLUSTER_NAME}-cluster-tls
  labels:
    strimzi.io/cluster: ${KAFKA_CLUSTER_NAME}
    strimzi.io/kind: Kafka
type: kubernetes.io/tls
data:
  tls.crt: $(base64 -i cluster-bundle.crt)
  tls.key: $(base64 -i cluster.key)
EOF

cat <<EOF > ${KAFKA_CLUSTER_NAME}-clients-ca-cert.yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    strimzi.io/ca-key-generation: "0"
  name: ${KAFKA_CLUSTER_NAME}-clients-ca-cert
  labels:
    strimzi.io/cluster: ${KAFKA_CLUSTER_NAME}
    strimzi.io/kind: Kafka
type: Opaque
data:
  ca.crt: $(base64 -i clients-bundle.crt)
  ca.p12: $(base64 -i clients.p12)
  ca.password: $(echo -n "$PASSWORD" | base64)
EOF

cat <<EOF > ${KAFKA_CLUSTER_NAME}-clients-ca.yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    strimzi.io/ca-key-generation: "0"
  name: ${KAFKA_CLUSTER_NAME}-clients-ca
  labels:
    strimzi.io/cluster: ${KAFKA_CLUSTER_NAME}
    strimzi.io/kind: Kafka
type: Opaque
data:
  ca.key: $(base64 -i clients.key)
EOF

cat <<EOF > ${KAFKA_CLUSTER_NAME}-clients-tls.yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    purpose: "source TLS for cluster issuer"
  name: ${KAFKA_CLUSTER_NAME}-clients-tls
  labels:
    strimzi.io/cluster: ${KAFKA_CLUSTER_NAME}
    strimzi.io/kind: Kafka
type: kubernetes.io/tls
data:
  tls.crt: $(base64 -i clients-bundle.crt)
  tls.key: $(base64 -i clients.key)
EOF

cat <<EOF > ${KAFKA_CLUSTER_NAME}-intermediate-tls.yaml
apiVersion: v1
kind: Secret
metadata:
  annotations:
    purpose: "source TLS for intermediate issuer"
  name: ${KAFKA_CLUSTER_NAME}-intermediate-tls
  labels:
    strimzi.io/cluster: ${KAFKA_CLUSTER_NAME}
    strimzi.io/kind: Kafka
type: kubernetes.io/tls
data:
  tls.crt: $(base64 -i intermediate-bundle.crt)
  tls.key: $(base64 -i intermediate.key)
EOF

echo "Secrets generated:"
echo "- ${KAFKA_CLUSTER_NAME}-cluster-ca-cert.yaml"
echo "- ${KAFKA_CLUSTER_NAME}-cluster-ca.yaml"
echo "- ${KAFKA_CLUSTER_NAME}-cluster-tls.yaml"
echo "- ${KAFKA_CLUSTER_NAME}-clients-ca-cert.yaml"
echo "- ${KAFKA_CLUSTER_NAME}-clients-ca.yaml"
echo "- ${KAFKA_CLUSTER_NAME}-clients-tls.yaml"

cat <<EOF > "${KAFKA_CLUSTER_NAME}-kafka-cluster-issuer.yaml"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${KAFKA_CLUSTER_NAME}-cluster-issuer
spec:
  ca:
    secretName: ${KAFKA_CLUSTER_NAME}-cluster-tls
EOF

cat <<EOF > "${KAFKA_CLUSTER_NAME}-kafka-clients-issuer.yaml"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${KAFKA_CLUSTER_NAME}-clients-issuer
spec:
  ca:
    secretName: ${KAFKA_CLUSTER_NAME}-clients-tls
EOF

cat <<EOF > "${KAFKA_CLUSTER_NAME}-kafka-intermediate-issuer.yaml"
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ${KAFKA_CLUSTER_NAME}-intermediate-issuer
spec:
  ca:
    secretName: ${KAFKA_CLUSTER_NAME}-intermediate-tls
EOF

echo "ClusterIssuer generated:"
echo "- ${KAFKA_CLUSTER_NAME}-kafka-cluster-issuer.yaml"
echo "- ${KAFKA_CLUSTER_NAME}-kafka-clients-issuer.yaml"
echo "- ${KAFKA_CLUSTER_NAME}-kafka-intermediate-issuer.yaml"

echo "File moved to directory output/"
mv ca.key ca.pem intermediate.key intermediate.pem intermediate-bundle.crt clients.key clients.pem clients.p12 cluster.key cluster.pem cluster.p12 output/
mv ca.csr ca-key.pem clients.csr clients-bundle.crt clients-key.pem cluster.csr cluster-bundle.crt cluster-key.pem intermediate.csr intermediate-key.pem output/
mv b01-intermediate-tls.yaml b01-kafka-intermediate-issuer.yaml b01-kafka-clients-issuer.yaml b01-kafka-cluster-issuer.yaml b01-cluster-ca-cert.yaml b01-cluster-ca.yaml b01-cluster-tls.yaml b01-clients-ca-cert.yaml b01-clients-ca.yaml b01-clients-tls.yaml output/