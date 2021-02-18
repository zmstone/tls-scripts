#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

./00-generate-root-ca.sh
./01-issue-inter-ca.sh
./02-issue-server-cert.sh "${SERVER_CERT_ISSUER:-inter-ca}"
./03-issue-client-cert.sh

