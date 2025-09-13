#!/bin/bash

set -euo pipefail

## This script issues an intermediate CA by root CA
## generates files: inter-ca-<suffix>.key inter-ca-<suffix>.pem
## where suffix is to make it possible to issue more than one intermediate CAs

echo "Issuing intermediate CA"

SUFFIX="${1:-}"

cd "$(dirname "$0")"

CA_C="${TLS_DN_C:-SE}"
CA_ST="${TLS_DN_ST:-Stockholm}"
CA_L="${TLS_DN_L:-Stockholm}"
CA_O="${TLS_DN_O:-MyOrgName}"
CA_OU="${TLS_DN_OU:-MyIntermediateCA}"
CA_CN="${TLS_INTER_CA_CN:-MyIntermediateCA-${SUFFIX}}"

if [ -z "${SUFFIX}" ]; then
    FILE_NAME="inter-ca"
else
    FILE_NAME="inter-ca-${SUFFIX}"
fi

mkdir -p ca
rm -f ./ca/*
if [ ! -f ca/index.txt ]; then touch ca/index.txt; fi
if [ ! -f ca/index.txt.attr ]; then touch ca/index.txt.attr; fi
if [ ! -f ca/serial ]; then date '+%s' > ca/serial; fi

SIGNOPTS=''
if ! [ -f "${FILE_NAME}.key" ]; then
    case $ALG in
        rsa)
            openssl genrsa -out "${FILE_NAME}.key" 2048
            ;;
        rsa-pss)
            if [ "${SUFFIX}" = 'server' ]; then
                openssl genrsa -out "${FILE_NAME}.key" 2048
            else
                openssl genpkey -algorithm RSA-PSS -pkeyopt rsa_keygen_bits:2048 -out "${FILE_NAME}.key"
                #SIGNOPTS=$RSA_PSS_SIGNOPTS
            fi
            ;;
        ec|ecc)
            openssl ecparam -name prime256v1 -genkey -noout -out "${FILE_NAME}.key"
            ;;
        dsa)
            openssl gendsa -out "${FILE_NAME}.key" <(openssl dsaparam 2048)
            ;;
        *)
            echo "Unknown algorithm: $ALG"
            exit 1
            ;;
    esac
fi
openssl req -sha256 -new -key "${FILE_NAME}.key" -out "${FILE_NAME}.csr" -nodes -subj "/C=${CA_C}/ST=${CA_ST}/L=${CA_L}/O=${CA_O}/OU=${CA_OU}/CN=${CA_CN}" -addext "basicConstraints=critical,CA:true"

# openssl onelines do not support ca extentions well
# hence the need of a config file

cat <<EOF > config
[ca]
default_ca      = DEFAULT_CA

[DEFAULT_CA]
dir            = ./ca
database       = \$dir/index.txt
new_certs_dir  = \$dir

certificate    = ca.pem
private_key    = ca.key
serial         = \$dir/serial

default_days   = 3650
default_crl_days= 30
default_md     = sha256

policy         = my_policy
email_in_dn    = no

name_opt       = ca_default
cert_opt       = ca_default
copy_extensions = none

[my_policy]
countryName            = supplied
stateOrProvinceName    = supplied
organizationName       = supplied
organizationalUnitName = supplied
commonName             = supplied
emailAddress           = optional

[ca_ext]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid,issuer
EOF

openssl ca -batch -config config $SIGNOPTS -in "${FILE_NAME}.csr" -out "${FILE_NAME}.pem" -notext -extensions ca_ext
rm -f "${FILE_NAME}.csr"
