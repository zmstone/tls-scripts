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

if [ "${TLS_ISSUE_CLIENT_CERT_BY_ROOT_CA:-}" = 'true' ]; then
    if [ ! -f client.key ]; then
        openssl ecparam -name secp521r1 -genkey -noout -out "client.key"
    fi

    if [ ! -f client.pem ]; then
        openssl req -sha512 -new -key client.key -out client.csr -nodes -subj "/C=${CL_C}/ST=${CL_ST}/L=${CL_L}/O=${CL_O}/OU=${CL_OU}/CN=${CL_CN}" -addext "basicConstraints=critical,CA:false"
        openssl x509 -req -CA ca.pem -CAkey ca.key -in client.csr -out client.pem -days 3650  -CAcreateserial
        rm -f client.csr
    fi
    exit 0
fi

SAN_IP=""
if [ -n "${TLS_CLIENT_IP:-}" ]; then
  SAN_IP="IP = $TLS_CLIENT_IP"
fi
SAN_DNS="DNS = $CL_CN"
if [ -n "${TLS_CLIENT_DNS:-}" ]; then
  SAN_DNS="DNS = $TLS_CLIENT_DNS"
fi
ISSUER_CA="${ISSUER_CA:-inter-ca}"

# Openssl command oneliners do not support request extentions well
# hence the need of a config file

cat <<-EOF > config
[req]
default_bits = 2048
prompt = no
default_md = sha512
req_extensions = req_ext
distinguished_name = dn

[dn]
C = $CL_C
ST = $CL_ST
L = $CL_L
O = $CL_O
OU = $CL_OU
CN = $CL_CN

[req_ext]
subjectAltName = @alt_names

[alt_names]
$SAN_DNS
$SAN_IP

[ca]
default_ca      = MyInterCA

[MyInterCA]
dir            = ./ca
database       = \$dir/index.txt
new_certs_dir  = \$dir

certificate    = ${ISSUER_CA}.pem
private_key    = ${ISSUER_CA}.key
serial         = \$dir/serial

default_days   = 3650
default_crl_days= 30
default_md     = sha512

policy         = cert_policy
email_in_dn    = no

name_opt       = ca_default
cert_opt       = ca_default
copy_extensions = none

[ cert_policy ]
countryName            = supplied
stateOrProvinceName    = supplied
organizationName       = supplied
organizationalUnitName = supplied
commonName             = supplied
emailAddress           = optional
EOF

mkdir -p ca
rm -f ./ca/*
if [ ! -f ca/index.txt ]; then touch ca/index.txt; fi
if [ ! -f ca/index.txt.attr ]; then touch ca/index.txt.attr; fi
if [ ! -f ca/serial ]; then date '+%s' > ca/serial; fi

openssl ecparam -name secp521r1 -genkey -noout -out "client.key"
openssl req -newkey ec:<(openssl ecparam -name secp521r1) -keyout client.key -out client.csr -nodes -config ./config
openssl ca -notext -batch -out client.pem -config config -extensions req_ext -infiles client.csr
rm -f client.csr
