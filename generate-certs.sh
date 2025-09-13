#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

clean() {
    rm -f *.pem *.key *.csr *.srl config
    rm -rf ./ca/
}

clean

DEFAULT_RSA_PSS_SIGNOPTS='-sigopt rsa_padding_mode:pss -sigopt rsa_pss_saltlen:20'
export RSA_PSS_SIGNOPTS="${RSA_PSS_SIGNOPTS-${DEFAULT_RSA_PSS_SIGNOPTS}}"

export ALG="${ALG:-rsa}"
./00-generate-root-ca.sh
./01-issue-inter-ca.sh server
./01-issue-inter-ca.sh client
./02-issue-server-cert.sh "${SERVER_CERT_ISSUER:-inter-ca-server}"
./03-issue-client-cert.sh "${CLIENT_CERT_ISSUER:-inter-ca-client}"

dir="$(date --iso-8601=second | tr ':' '-')"
mkdir "$dir"
mv client.key "$dir/"
mv ca.pem "$dir/"
mv server.key "$dir/"
cat server.pem inter-ca-server.pem > "$dir/server.pem"
cat client.pem inter-ca-client.pem > "$dir/client.pem"

clean
