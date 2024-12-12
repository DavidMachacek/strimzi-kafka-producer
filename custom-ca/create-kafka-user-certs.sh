#!/usr/bin/env bash

KAFKA_USERNAME=cloudhub-one-writer
KAFKA_USERNAME_PASSWORD=password

echo "Generating CA"
openssl req -new -newkey rsa:2048 -keyout $KAFKA_USERNAME-certificate-to-sign.key \
  -out $KAFKA_USERNAME-certificate-to-sign.csr \
  -passout pass:"$KAFKA_USERNAME_PASSWORD" \
  -subj "/CN=$KAFKA_USERNAME"

echo "Sign the CSR with the CA Certificate"
openssl x509 -req  \
  -in $KAFKA_USERNAME-certificate-to-sign.csr \
  -CA ca.pem -CAkey ca.key -CAcreateserial  \
  -out $KAFKA_USERNAME-signed-certificate.crt  \
  -days 365

echo "Exporting to p12 format with password"
openssl pkcs12 -export \
  -in $KAFKA_USERNAME-signed-certificate.crt \
  -inkey $KAFKA_USERNAME-certificate-to-sign.key \
  -certfile ca.pem \
  -passout pass:"$KAFKA_USERNAME_PASSWORD" -passin pass:$KAFKA_USERNAME_PASSWORD \
  -out $KAFKA_USERNAME-user.p12 \
  -name $KAFKA_USERNAME-user

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

# Optional: To apply this secret to your OpenShift cluster, uncomment:
# oc apply -f ${KAFKA_USERNAME}-cert-secret.yaml