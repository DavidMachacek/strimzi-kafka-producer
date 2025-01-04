#!/usr/bin/env bash

KAFKA_USERNAME=cloudhub-one-writer
KAFKA_USERNAME_PASSWORD=password

openssl pkcs12 -export \
  -in cm-tls.crt \
  -inkey cm-tls.key \
  -certfile cm-ca.crt \
  -out cloudhub-one.p12 \
  -name cloudhub-one-writer

echo "Creating Secret YAML"
cat <<EOF > ${KAFKA_USERNAME}-cert-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ${KAFKA_USERNAME}-cert-secret
type: kubernetes.io/tls
data:
  tls.crt: $(base64 -i ${KAFKA_USERNAME}-signed-certificate.crt)
  tls.key: $(base64 -i ${KAFKA_USERNAME}-certificate-to-sign.key)
  user.p12: $(base64 -i $KAFKA_USERNAME-user.p12)
  user.password: $(echo -n "$KAFKA_USERNAME_PASSWORD" | base64)
EOF

echo "Secret YAML generated at ${KAFKA_USERNAME}-cert-secret.yaml"