# What

This repo includes a script `generate-certs.sh` to generate test certificates.

The script generates (but does not overwrite private keys):

* Root CA key and cert (self-sign)
* 2 Intermediate CAs (issued by root CA), inter-ca-1 and inter-ca-2
* Server key and cert
* Client key and cert

The issuer of the server and client certificates can be set with environment variables
`SERVER_CERT_ISSUER` and `CLIENT_CERT_ISSUER`

By default, the server certificate is issued by intermediate CA 'inter-ca-1'
and the client certificate is issued by 'inter-ca-2'

# NOTE

To make it work for most of the Linux distributions out of the box,
this collection of scripts only uses openssl commands.
It is intended for tests only.
For production use maybe https://github.com/cloudflare/cfssl or similar PKI tools

# Steps breakdown

The script `generate-certs.sh` consists of below steps.
Each step's script can be executed independently if its input files
(from preceeding comands) are present (not deleted).

## Root CA `00-generate-root-ca.sh`

```bash
CA_C="${TLS_DN_C:-SE}"          # CA country
CA_ST="${TLS_DN_ST:-Stockholm}" # CA state or province
CA_L="${TLS_DN_L:-Stockholm}"   # CA location
CA_O="${TLS_DN_O:-MyOrgName}"   # CA org name
CA_OU="${TLS_DN_OU:-MyRootCA}"  # CA org unit name
CA_CN="MyRootCA"                # CA common name
```

## Intermediate CA `01-issue-inter-ca.sh <SUFFIX>`

Where `<SUFFIX>` is to make it possible to generate more than intermediate CAs.

```bash
CA_C="${TLS_DN_C:-SE}"                                # Inter-CA country
CA_ST="${TLS_DN_ST:-Stockholm}"                       # Inter-CA state or province
CA_L="${TLS_DN_L:-Stockholm}"                         # Inter-CA location
CA_O="${TLS_DN_O:-MyOrgName}"                         # Inter-CA org name
CA_OU="${TLS_DN_OU:-MyIntermediateCA}"                # Inter-CA org unit name
CA_CN="${TLS_INTER_CA_CN:-MyIntermediateCA-<SUFFIX>}" # Inter-CA common name
```

## Server Certificate `02-issue-server-cert.sh`

```bash
DN_C="${TLS_DN_C:-SE}"                       # Server country
DN_ST="${TLS_DN_ST:-Stockholm}"              # Server state or province
DN_L="${TLS_DN_L:-Stockholm}"                # Server location
DN_O="${TLS_DN_O:-MyOrgName}"                # Server org name
DN_OU="${TLS_DN_OU:-MyService}"              # Server org unit name
DN_CN="${TLS_SERVER_COMMON_NAME:-localhost}" # Server common name
TLS_SERVER_IP                                # IP in SAN if set
TLS_SERVER_DNS                               # DNS in SAN if set
SERVER_CERT_ISSUER=inter-ca-1                # 'ca' to issue from Root CA
```

## Client Certificates  `03-issue-client-cert.sh`

```bash
CL_C="${TLS_DN_C:-SE}"                        # Client country
CL_ST="${TLS_DN_ST:-Stockholm}"               # Client state or province
CL_L="${TLS_DN_L:-Stockholm}"                 # Client location
CL_O="${TLS_DN_O:-MyOrgName}"                 # Client org name
CL_OU="${TLS_DN_OU:-MyServiceClient}"         # Client org unit name
CL_CN="${TLS_CLIENT_COMMON_NAME:-localhost}"  # Clietn common name
CLIENT_CERT_ISSUER=inter-ca-2                 # 'ca' to issue from Root CA
```
