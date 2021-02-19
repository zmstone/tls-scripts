# What

This repo includes a script `generate-certs.sh` to generate test certificates.

The script generates (but does not overwrite) root CA and client key pairs.
The root CA issues an intermediate CA which is then used to issue server
certificate.

Server certificate can be issued by root CA if environment variable `SERVER_CERT_ISSUER`
is set to `ca` (default is `inter-ca` which instructs the usage of intermediate CA).

# NOTE

This collection of scripts only uses openssl commands, and it is intended for
tests only. For production use, https://github.com/cloudflare/cfssl is recommended

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

## Intermediate CA `01-issue-inter-ca.sh`

```bash
CA_C="${TLS_DN_C:-SE}"                  # Inter-CA country
CA_ST="${TLS_DN_ST:-Stockholm}"         # Inter-CA state or province
CA_L="${TLS_DN_L:-Stockholm}"           # Inter-CA location
CA_O="${TLS_DN_O:-MyOrgName}"           # Inter-CA org name
CA_OU="${TLS_DN_OU:-MyIntermediateCA}"  # Inter-CA org unit name
CA_CN="MyIntermediateCA"                # Inter-CA common name
```

## Server Certificate `02-issue-server-cert.sh`

```bash
DN_C="${TLS_DN_C:-SE}"                       # Server country
DN_ST="${TLS_DN_ST:-Stockholm}"              # Server state or province
DN_L="${TLS_DN_L:-Stockholm}"                # Server location
DN_O="${TLS_DN_O:-MyOrgName}"                # Server org name
DN_OU="${TLS_DN_OU:-MyService}"              # Server org unit name
DN_CN="${TLS_SERVER_COMMON_NAME:-localhost}" # Server common name
ISSUER_CA="${ISSUER_CA:-inter-ca}"           # Which ca ('inter-ca' or 'ca') to issue the server cert
TLS_SERVER_IP                                # IP in SAN if set
TLS_SERVER_DNS                               # DNS in SAN if set
```

## Client Certificates  `03-issue-client-cert.sh`

```bash
CL_C="${TLS_DN_C:-SE}"                        # Client country
CL_ST="${TLS_DN_ST:-Stockholm}"               # Client state or province
CL_L="${TLS_DN_L:-Stockholm}"                 # Client location
CL_O="${TLS_DN_O:-MyOrgName}"                 # Client org name
CL_OU="${TLS_DN_OU:-MyServiceClient}"         # Client org unit name
CL_CN="${TLS_CLIENT_COMMON_NAME:-localhost}"  # Clietn common name
```
