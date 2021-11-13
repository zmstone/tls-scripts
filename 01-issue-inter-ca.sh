#!/bin/bash

set -euo pipefail

## This script issues an intermediate CA by root CA
## generates files: inter-ca.key inter-ca.pem

cd "$(dirname "$0")"

CA_C="${TLS_DN_C:-SE}"
CA_ST="${TLS_DN_ST:-Stockholm}"
CA_L="${TLS_DN_L:-Stockholm}"
CA_O="${TLS_DN_O:-MyOrgName}"
CA_OU="${TLS_DN_OU:-MyIntermediateCA}"
CA_CN="MyIntermediateCA"

mkdir -p ca
rm -f ./ca/*
if [ ! -f ca/index.txt ]; then touch ca/index.txt; fi
if [ ! -f ca/index.txt.attr ]; then touch ca/index.txt.attr; fi
if [ ! -f ca/serial ]; then date '+%s' > ca/serial; fi

# openssl genrsa -out inter-ca.key 2048
openssl ecparam -name secp521r1 -genkey -noout -out "inter-ca.key"
openssl req -sha256 -new -key inter-ca.key -out inter-ca.csr -nodes -subj "/C=${CA_C}/ST=${CA_ST}/L=${CA_L}/O=${CA_O}/OU=${CA_OU}/CN=${CA_CN}" -addext "basicConstraints=critical,CA:true"

# openssl onelines do not support ca extentions well
# hence the need of a config file

cat <<EOF > config
[ ca ]
default_ca      = MyIntermediateCA

[ MyIntermediateCA ]
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

[ my_policy ]
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

openssl ca -batch -config config -in inter-ca.csr -out inter-ca.pem -notext -extensions ca_ext
rm inter-ca.csr
