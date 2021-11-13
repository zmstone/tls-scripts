.PHONY: all clean

all:
	./generate-certs.sh

## issue certs for local.host.net
local:
	env TLS_CLIENT_COMMON_NAME=local.host.net TLS_SERVER_COMMON_NAME=local.host.net ./generate-certs.sh
