# TLS Scripts

This repository contains a set of scripts for generating test TLS certificates. The main entry point is **`generate-certs.sh`**, which orchestrates creation of:

- A Root CA (self-signed)  
- Two Intermediate CAs (issued by the Root CA), named `inter-ca-1` and `inter-ca-2`  
- A Server certificate/key  
- A Client certificate/key  

You can specify who issues the server or client certificate via environment variables:

- `SERVER_CERT_ISSUER`  
- `CLIENT_CERT_ISSUER`

By default:  
- The **server** certificate is issued by `inter-ca-1`  
- The **client** certificate is issued by `inter-ca-2`

> **Note:** These scripts are intended *only* for testing. For production-grade Public Key Infrastructure (PKI) you should consider tools such as [Cloudflare cfssl](https://github.com/cloudflare/cfssl) or other more fully-featured PKI solutions.

---

## Components & Script Breakdown

Each script can be run independently, provided their required input files (from preceding steps) are present and haven’t been removed.

### 1. Root CA — `00-generate-root-ca.sh`

Sets up the Root CA with configurable distinguished name (DN) parameters via environment variables, falling back to defaults when not provided:

```bash
CA_C="${TLS_DN_C:-SE}"         # Country
CA_ST="${TLS_DN_ST:-Stockholm}"# State or Province
CA_L="${TLS_DN_L:-Stockholm}"  # Locality (City)
CA_O="${TLS_DN_O:-MyOrgName}"  # Organization
CA_OU="${TLS_DN_OU:-MyRootCA}" # Organizational Unit
CA_CN="MyRootCA"               # Common Name
```

### 2. Intermediate CA — `01-issue-inter-ca.sh`

Creates one or more intermediate CAs under the Root CA. The DN fields are similarly configurable:

```bash
CA_C="${TLS_DN_C:-SE}"
CA_ST="${TLS_DN_ST:-Stockholm}"
CA_L="${TLS_DN_L:-Stockholm}"
CA_O="${TLS_DN_O:-MyOrgName}"
CA_OU="${TLS_DN_OU:-MyIntermediateCA}"
CA_CN="${TLS_INTER_CA_CN:-MyIntermediateCA-}"  # You can specify the suffix or override
```

### 3. Server Certificate — `02-issue-server-cert.sh`

Generates a server certificate. Key DN fields and Subject Alternative Names (SANs) are configurable via environment variables. The certificate issuer can be chosen (default: `inter-ca-1`).

```bash
DN_C="${TLS_DN_C:-SE}"
DN_ST="${TLS_DN_ST:-Stockholm}"
DN_L="${TLS_DN_L:-Stockholm}"
DN_O="${TLS_DN_O:-MyOrgName}"
DN_OU="${TLS_DN_OU:-MyService}"
DN_CN="${TLS_SERVER_COMMON_NAME:-localhost}"

# Optional SANs
TLS_SERVER_IP     # IP address to include in SAN if set
TLS_SERVER_DNS    # DNS name in SAN if set

SERVER_CERT_ISSUER=inter-ca-1  # or “ca” … depends on your setup
```

### 4. Client Certificate — `03-issue-client-cert.sh`

Similar approach as for the server, but for client-side certificate:

```bash
CL_C="${TLS_DN_C:-SE}"
CL_ST="${TLS_DN_ST:-Stockholm}"
CL_L="${TLS_DN_L:-Stockholm}"
CL_O="${TLS_DN_O:-MyOrgName}"
CL_OU="${TLS_DN_OU:-MyServiceClient}"
CL_CN="${TLS_CLIENT_COMMON_NAME:-localhost}"

CLIENT_CERT_ISSUER=inter-ca-2
```

---

## Cryptographic Algorithms Supported

You can choose the type of cryptographic key via the `ALG` environment variable. Options:

- `rsa`: Generates a **2048-bit RSA** key (key size is fixed in the current scripts)  
- `rsa-pss`: Generates an **RSA-PSS** key (uses Probabilistic Signature Scheme, also known as PSS padding).  
  This option is more secure for signatures. Currently, it applies only to client certificates —  
  server certificates will continue to use standard RSA.
- `ec`: Generates an **ECDSA** key using curve `prime256v1`  
- `dsa`: Generates a **DSA** key  
