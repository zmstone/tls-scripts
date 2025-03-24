#!/bin/bash

## This script generates ca.key and self-signed ca.pem
set -euo pipefail

echo "Generating root CA"

cd "$(dirname "$0")"

CA_C="${TLS_DN_C:-SE}"
CA_ST="${TLS_DN_ST:-Stockholm}"
CA_L="${TLS_DN_L:-Stockholm}"
CA_O="${TLS_DN_O:-MyOrgName}"
CA_OU="${TLS_DN_OU:-MyRootCA}"
CA_CN="MyRootCA"

SIGNOPTS=''
ensure_private_key() {
  file="$1"
  if [ ! -f "$file" ]; then
    case $ALG in
      rsa)
        openssl genrsa -out "$file" 2048
        ;;
      rsa-pss)
        openssl genrsa -out "$file" 2048
        ## CA do not support this algorithm for now
        # openssl genpkey -algorithm RSA-PSS -pkeyopt rsa_keygen_bits:2048 -out "$file"
        # SIGNOPTS=$RSA_PSS_SIGNOPTS
        ;;
      ec|ecc)
        openssl ecparam -name prime256v1 -genkey -noout -out "$file"
        ;;
      dsa)
        openssl gendsa -out "$file" <(openssl dsaparam 2048)
        ;;
      *)
        echo "Unknown algorithm: $ALG"
        exit 1
        ;;
    esac
  fi
}


ensure_private_key ca.key
if [ ! -f ca.pem ]; then
    openssl req -sha256 -new -key "ca.key" -out "ca.csr" -nodes \
        -subj "/C=${CA_C}/ST=${CA_ST}/L=${CA_L}/O=${CA_O}/OU=${CA_OU}/CN=${CA_CN}" -addext "basicConstraints=critical,CA:true"
    openssl x509 -req -in ca.csr -sha256 -signkey ca.key -out ca.pem -days 3650 $SIGNOPTS
    rm -f ca.csr
fi
