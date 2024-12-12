#!/usr/bin/env bash

# Generate CA with Root, Intermediate and Strimzi / Clients CAs
echo "generating CA"
cfssl genkey -initca ca.json | cfssljson -bare ca
echo "generating intermediateCA"
cfssl genkey intermediate.json | cfssljson -bare intermediate
echo "singing intermediateCA"
cfssl sign -config config.json -profile CA -ca ca.pem -ca-key ca-key.pem intermediate.csr intermediate.json | cfssljson -bare intermediate
echo "generating key for clusterCA"
cfssl genkey cluster.json | cfssljson -bare cluster
echo "singing clusterCA"
cfssl sign -config config.json -profile clusterCA -ca intermediate.pem -ca-key intermediate-key.pem cluster.csr cluster.json | cfssljson -bare cluster
echo "generating key for clientsCA"
cfssl genkey clients.json | cfssljson -bare clients
echo "singing clientsCA"
cfssl sign -config config.json -profile clientsCA -ca intermediate.pem -ca-key intermediate-key.pem clients.csr clients.json | cfssljson -bare clients

# Create CRT bundles
cat cluster.pem > cluster-bundle.crt
cat intermediate.pem >> cluster-bundle.crt
cat ca.pem >> cluster-bundle.crt
cat clients.pem > clients-bundle.crt
cat intermediate.pem >> clients-bundle.crt
cat ca.pem >> clients-bundle.crt

# Convert keys to PKCS8
openssl pkcs8 -topk8 -nocrypt -in ca-key.pem -out ca.key
openssl pkcs8 -topk8 -nocrypt -in intermediate-key.pem -out intermediate.key
openssl pkcs8 -topk8 -nocrypt -in clients-key.pem -out clients.key
openssl pkcs8 -topk8 -nocrypt -in cluster-key.pem -out cluster.key