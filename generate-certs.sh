#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

clean() {
    rm -f *.pem *.key *.csr *.srl config
    rm -rf ./ca/
}

clean

export ALG="${ALG:-rsa}"
./00-generate-root-ca.sh
./01-issue-inter-ca.sh 1
./01-issue-inter-ca.sh 2
./02-issue-server-cert.sh "${SERVER_CERT_ISSUER:-inter-ca-1}"
TLS_CLIENT_COMMON_NAME='v1-idA001' TLS_CLIENT_FNAME="c1" ./03-issue-client-cert.sh "${CLIENT_CERT_ISSUER:-inter-ca-2}"
TLS_CLIENT_COMMON_NAME='v2-idB002' TLS_CLIENT_FNAME="c2" ./03-issue-client-cert.sh "${CLIENT_CERT_ISSUER:-inter-ca-2}"

dir="$(date --iso-8601=second | tr ':' '-')"
mkdir "$dir"
mv c1.key "$dir/"
mv c2.key "$dir/"
mv ca.pem "$dir/"
mv server.key "$dir/"
cat server.pem inter-ca-1.pem > "$dir/server.pem"
cat c1.pem inter-ca-2.pem > "$dir/c1.pem"
cat c2.pem inter-ca-2.pem > "$dir/c2.pem"

clean
