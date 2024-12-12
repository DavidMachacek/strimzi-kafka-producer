#!/usr/bin/env bash
set -euo pipefail

# Variables
KAFKA_CLUSTER_NAME="infra-kafka-cluster"
STORE_PASS="password"
TRUSTSTORE_FILE="${KAFKA_CLUSTER_NAME}-truststore.jks"
CA_ALIAS="${KAFKA_CLUSTER_NAME}-ca"
CA_PEM="cluster.pem"

# Clean up any old truststore
if [ -f "${TRUSTSTORE_FILE}" ]; then
    rm "${TRUSTSTORE_FILE}"
fi

# Import the CA into a new JKS truststore
keytool -import -trustcacerts \
  -alias "${CA_ALIAS}" \
  -file "${CA_PEM}" \
  -keystore "${TRUSTSTORE_FILE}" \
  -storepass "${STORE_PASS}" \
  -noprompt

# Base64 encode the truststore
TRUSTSTORE_B64=$(cat "${TRUSTSTORE_FILE}" | base64)
PASSWORD_B64=$(echo -n "${STORE_PASS}" | base64)

# Print out the Kubernetes Secret manifest
cat <<EOF > ${KAFKA_CLUSTER_NAME}-truststore-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ${KAFKA_CLUSTER_NAME}-truststore
type: Opaque
data:
  truststore.jks: ${TRUSTSTORE_B64}
  password: ${PASSWORD_B64}
EOF
