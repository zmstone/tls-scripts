#!/bin/bash

set -euo pipefail

# This script issues a client certificate by root CA

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
  openssl x509 -req -CA ca.pem -CAkey ca.key -in client.csr -out client.pem -days 3650  -CAcreateserial
  rm -f client.csr
fi

