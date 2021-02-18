#!/bin/bash

## This script generates ca.key and self-signed ca.pem
set -euo pipefail

cd "$(dirname "$0")"

CA_C="${TLS_DN_C:-SE}"
CA_ST="${TLS_DN_ST:-Stockholm}"
CA_L="${TLS_DN_L:-Stockholm}"
CA_O="${TLS_DN_O:-MyOrgName}"
CA_OU="${TLS_DN_OU:-MyRootCA}"
CA_CN="MyRootCA"

ensure_private_key() {
  file="$1"
  if [ ! -f "$file" ]; then
    openssl genrsa -out "$file" 2048
  fi
}

ensure_private_key ca.key
if [ ! -f ca.pem ]; then
  openssl req -sha256 -new -key "ca.key" -out "ca.csr" -nodes -subj "/C=${CA_C}/ST=${CA_ST}/L=${CA_L}/O=${CA_O}/OU=${CA_OU}/CN=${CA_CN}" -addext "basicConstraints=critical,CA:true"
  openssl x509 -req -in ca.csr -sha256 -signkey ca.key -out ca.pem -days 3650
  rm -f ca.csr
fi
