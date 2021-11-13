#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

clean() {
    rm -f *.pem *.key *.csr *.srl config
    rm -rf ./ca/
}

clean

./00-generate-root-ca.sh
./01-issue-inter-ca.sh
./02-issue-server-cert.sh "${SERVER_CERT_ISSUER:-inter-ca}"
./03-issue-client-cert.sh

dir="$(date --iso-8601=second | tr ':' '-' | tr '+' '-')"
mkdir "$dir"
mv ca.pem "$dir/"
mv server.key "$dir/"
mv client.key "$dir/"
cat client.pem inter-ca.pem > "$dir/client.pem"
cat server.pem inter-ca.pem > "$dir/server.pem"

clean
