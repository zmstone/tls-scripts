#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

clean() {
    rm -f *.pem *.key *.csr *.srl config
    rm -rf ./ca/
}

clean

./00-generate-root-ca.sh
./01-issue-inter-ca.sh 1
./01-issue-inter-ca.sh 2
./02-issue-server-cert.sh "${SERVER_CERT_ISSUER:-inter-ca-1}"
./03-issue-client-cert.sh "${CLIENT_CERT_ISSUER:-inter-ca-2}"

dir="$(date --iso-8601=second | tr ':' '-')"
mkdir "$dir"
mv client.key "$dir/"
mv ca.pem "$dir/"
mv server.key "$dir/"
cat server.pem inter-ca-1.pem > "$dir/server.pem"
cat client.pem inter-ca-2.pem > "$dir/client.pem"

clean
