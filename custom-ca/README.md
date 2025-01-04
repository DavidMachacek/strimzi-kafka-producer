## Odkaz
https://github.com/scholzj/strimzi-custom-ca-test


keytool -import -trustcacerts \
-alias b01-ppf-kafka-ca \
-file custom-ca/cluster-bundle.crt \
-keystore kafka-truststore.jks \
-storepass password

keytool -delete -alias b01-ppf-kafka-ca -keystore b01-kafka-truststore.jks -storepass truststore-password