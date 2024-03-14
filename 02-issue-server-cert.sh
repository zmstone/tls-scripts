#!/bin/bash -e

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

# Openssl command oneliners do not support request extentions well
# hence the need of a config file

cat <<-EOF > config
[req]
default_bits = 2048
prompt = no
default_md = sha256
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
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
$SAN_DNS
$SAN_IP

[ca]
default_ca      = DEFAULT_CA

[DEFAULT_CA]
dir            = ./ca
database       = \$dir/index.txt
new_certs_dir  = \$dir

certificate    = ${ISSUER_CA}.pem
private_key    = ${ISSUER_CA}.key
serial         = \$dir/serial

default_days   = 3650
default_crl_days= 30
default_md     = sha256

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

case $ALG in
    rsa)
        openssl genrsa -out server.key 2048
        openssl req -newkey rsa:2048 -sha256 -key server.key -out server.csr -nodes -config ./config
        ;;
    ec)
        openssl ecparam -name prime256v1 -genkey -noout -out server.key
        openssl req -newkey ec:<(openssl ecparam -name secp384r1) -keyout server.key -out server.csr -nodes -config ./config
        ;;
esac
openssl ca -notext -batch -out server.pem -config config -extensions req_ext -infiles server.csr
rm -f server.csr
