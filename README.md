# Docker Kafka Producer
VERSION=20241206.7 && mvn clean install && podman build --arch amd64 -t davidmachacek/kafka-producer:$VERSION -f Containerfile && podman push davidmachacek/kafka-producer:$VERSION

# Change permissions
sudo chmod g=u kafka-keystore.p12 kafka-truststore.jks

## Kafka trustore and keystore
```bash
openssl pkcs12 -export \
  -in src/main/resources/user-cloudhub-writer-user.crt \
  -inkey src/main/resources/user-cloudhub-writer-user.key \
  -certfile src/main/resources/user-cloudhub-writer-ca.crt \
  -out kafka-keystore.p12 \
  -name cloudhub-one-writer

keytool -import -trustcacerts \
-alias kafka-ca \
-file src/main/resources/infra-kafka-cluster-cluster-ca-cert.crt \
-keystore kafka-truststore.jks \
-storepass password

keytool -delete -alias b01-ppf-kafka-ca -keystore b01-kafka-truststore.jks -storepass truststore-password

keytool -import -trustcacerts \
-alias b01-ppf-kafka-ca \
-file src/main/resources/b01-cluster-ca-cert.crt \
-keystore b01-kafka-truststore.jks \
-storepass password
```

## AKHQ
```
keytool -importkeystore \
    -srckeystore src/main/resources/akhq-user.p12 \
    -srcstoretype PKCS12 \
    -destkeystore src/main/resources/akhq-user-keystore.jks \
    -deststoretype JKS \
    -srcstorepass pRfZNcS6xbCHu3jYIk78dirleUnxFc8R \
    -deststorepass password \
    -destkeypass password
keytool -importkeystore -srckeystore src/main/resources/akhq-user-keystore.jks -destkeystore src/main/resources/akhq-user-keystore.jks -deststoretype pkcs12
base64 -i src/main/resources/akhq-user-keystore.jks 

openssl pkcs12 -export -out akhq-user.pfx -inkey src/main/resources/akhq-user.key -in src/main/resources/akhq-user.crt
keytool -importkeystore -srckeystore akhq-user.pfx -srcstoretype pkcs12 -srcalias 1 -srcstorepass password -destkeystore akhq-user.jks -deststoretype jks -deststorepass password -destalias akhq-user
base64 -i akhq-user.jks 

keytool -import -trustcacerts \
-alias b01-ppf-kafka-ca \
-file src/main/resources/b01-cluster-ca-cert.crt \
-keystore b01-kafka-truststore.jks \
-storepass password    

base64 -i b01-kafka-truststore.jks
```

keytool -importcert -trustcacerts \
-alias ppf-ca \
-file src/main/resources/ppf-ca.crt \
-keystore ppf-cacerts \
-storepass password