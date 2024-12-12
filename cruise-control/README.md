# When building, tag the image with the name of a container registry
# that is accessible by the Kubernetes cluster.
# For example: quay.io/kliberti/cruise-control-with-ui:latest

# Build and tag the image
podman build --arch amd64 . -t davidmachacek/kafka-strimzi-cc-ui:3.8.0 -f cc-ui-containerfile

# Push the image to that container registry
podman push davidmachacek/kafka-strimzi-cc-ui:3.8.0


# Build and tag the image
podman build --arch amd64 . -t davidmachacek/kafka-nginx-cc-ui:0.4.0 -f cc-ui-nginx-containerfile

# Push the image to that container registry
podman push davidmachacek/kafka-nginx-cc-ui:0.4.0