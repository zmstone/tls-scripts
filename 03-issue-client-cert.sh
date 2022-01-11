#!/bin/bash

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <CA_NAME>"
    echo "<CA_NAME> is the name of the CA cert files"
    echo "There should be a <CA_NAME>.pem for the CA certificate"
    echo "and a <CA_NAME>.key for the private key"
    exit 1
fi

ISSUER_CA="${1}"

cd "$(dirname "$0")"

CL_C="${TLS_DN_C:-SE}"
CL_ST="${TLS_DN_ST:-Stockholm}"
CL_L="${TLS_DN_L:-Stockholm}"
CL_O="${TLS_DN_O:-MyOrgName}"
CL_OU="${TLS_DN_OU:-MyServiceClient}"
CL_CN="${TLS_CLIENT_COMMON_NAME:-localhost}"

if [ ! -f client.key ]; then
  openssl genrsa -out client.key 2048
fi

if [ ! -f client.pem ]; then
  openssl req -sha256 -new -key client.key -out client.csr -nodes -subj "/C=${CL_C}/ST=${CL_ST}/L=${CL_L}/O=${CL_O}/OU=${CL_OU}/CN=${CL_CN}" -addext "basicConstraints=critical,CA:false"
  openssl x509 -req -CA "${ISSUER_CA}.pem" -CAkey "${ISSUER_CA}.key" -in client.csr -out client.pem -days 3650  -CAcreateserial
  rm -f client.csr
fi
