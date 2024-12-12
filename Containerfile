FROM registry.redhat.io/ubi9/openjdk-17-runtime:1.20-2.1729773460

# Copy the application jar
COPY target/*.jar /app/app.jar

# Copy the keystore and truststore
#COPY kafka-keystore.p12 /app/kafka-keystore.p12
#COPY kafka-truststore.jks /app/kafka-truststore.jks

#USER root
#RUN chmod 640 /app/kafka-keystore.p12
#RUN chmod 640 /app/kafka-truststore.jks

#RUN microdnf install -y dnf && \
#    dnf update -y && \
#    dnf install -y openssl && \
#    dnf clean all

# Run the application
CMD ["java", "-jar", "/app/app.jar"]