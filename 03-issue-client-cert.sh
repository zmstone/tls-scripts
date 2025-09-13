#!/bin/bash

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <CA_NAME>"
    echo "<CA_NAME> is the name of the CA cert files"
    echo "There should be a <CA_NAME>.pem for the CA certificate"
    echo "and a <CA_NAME>.key for the private key"
    exit 1
fi

echo "Issuing client certificate"

ISSUER_CA="${1}"

cd "$(dirname "$0")"

CL_C="${TLS_DN_C:-SE}"
CL_ST="${TLS_DN_ST:-Stockholm}"
CL_L="${TLS_DN_L:-Stockholm}"
CL_O="${TLS_DN_O:-MyOrgName}"
CL_OU="${TLS_DN_OU:-MyServiceClient}"
CL_CN="${TLS_CLIENT_COMMON_NAME:-localhost}"

FNAME="${TLS_CLIENT_FNAME:-client}"

SIGNOPTS=''
if [ ! -f "${FNAME}.key" ]; then
  case $ALG in
    rsa)
      openssl genrsa -out "${FNAME}.key" 2048
      ;;
    rsa-pss)
      #openssl genrsa -out "${FNAME}.key" 2048
      openssl genpkey -algorithm RSA-PSS -pkeyopt rsa_keygen_bits:2048 -out "${FNAME}.key"
      SIGNOPTS=$RSA_PSS_SIGNOPTS
      ;;
    ec|ecc)
      openssl ecparam -name prime256v1 -genkey -noout -out "${FNAME}.key"
      ;;
    dsa)
      openssl gendsa -out "${FNAME}.key" <(openssl dsaparam 2048)
      ;;
    *)
      echo "Unknown algorithm: $ALG"
      exit 1
      ;;
  esac
fi

if [ ! -f "${FNAME}" ]; then
  openssl req -sha256 -new -key "${FNAME}.key" -out client.csr -nodes -subj "/C=${CL_C}/ST=${CL_ST}/L=${CL_L}/O=${CL_O}/OU=${CL_OU}/CN=${CL_CN}" -addext "basicConstraints=critical,CA:false"
  openssl x509 -req -CA "${ISSUER_CA}.pem" -CAkey "${ISSUER_CA}.key" $SIGNOPTS -in client.csr -out "${FNAME}.pem" -days 3650 -CAcreateserial
  rm -f client.csr
fi
