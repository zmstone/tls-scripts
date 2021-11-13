#!/bin/bash -e

set -euo pipefail

cd "$(dirname "$0")"

DN_C="${TLS_DN_C:-SE}"
DN_ST="${TLS_DN_ST:-Stockholm}"
DN_L="${TLS_DN_L:-Stockholm}"
DN_O="${TLS_DN_O:-MyOrgName}"
DN_OU="${TLS_DN_OU:-MyService}"
DN_CN="${TLS_SERVER_COMMON_NAME:-localhost}"

SAN_IP=""
if [ -n "${TLS_SERVER_IP:-}" ]; then
  SAN_IP="IP = $TLS_SERVER_IP"
fi
SAN_DNS="DNS = $DN_CN"
if [ -n "${TLS_SERVER_DNS:-}" ]; then
  SAN_DNS="DNS = $TLS_SERVER_DNS"
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
C = $DN_C
ST = $DN_ST
L = $DN_L
O = $DN_O
OU = $DN_OU
CN = $DN_CN

[req_ext]
subjectAltName = @alt_names

[alt_names]
$SAN_DNS
$SAN_IP

[ca]
default_ca      = MyRootCA

[MyRootCA]
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

openssl ecparam -name secp521r1 -genkey -noout -out "server.key"
openssl req -newkey ec:<(openssl ecparam -name secp521r1) -keyout server.key -out server.csr -nodes -config ./config
openssl ca -notext -batch -out server.pem -config config -extensions req_ext -infiles server.csr
rm -f server.csr
