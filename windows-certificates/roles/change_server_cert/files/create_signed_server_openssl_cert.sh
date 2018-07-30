#!/bin/bash

# where to create the keys
CERTS_FOLDER="$1"
# set the hostname of the target server
HOST_NAME="$2"

if [[ -z "${HOST_NAME}" || -z ${CERTS_FOLDER} ]]
then
	echo "$0 <local_certs_dir> <hostname>" >&2
	exit 1
fi

export OPENSSL_CONF=${CERTS_FOLDER}/openssl_${HOST_NAME}.conf
export OPENSSL_EXT_CONF=${CERTS_FOLDER}/openssl_${HOST_NAME}_extension.conf

cat > ${OPENSSL_CONF} << EOL
distinguished_name = req_distinguished_name
x509_extensions = usr_cert
req_extensions = v3_req
[req_distinguished_name]
[v3_req]
extendedKeyUsage = serverAuth
[usr_cert]
extendedKeyUsage = serverAuth
EOL

cat > ${OPENSSL_EXT_CONF} << EOL
extendedKeyUsage=serverAuth
subjectAltName=@alt_names
[alt_names]
IP.1 = ${HOST_NAME}
DNS.1 = ${HOST_NAME}
EOL

SSL_FOLDER=${CERTS_FOLDER}/server_certificates/ssl/${HOST_NAME}
CA_FOLDER=${CERTS_FOLDER}/ca
mkdir -p ${SSL_FOLDER} ${CA_FOLDER}

openssl req -subj "/C=XX/L=Default City/O=Default Company Ltd/CN=${HOST_NAME}" -nodes -newkey rsa:2048 \
	-keyout ${SSL_FOLDER}/server.key -out ${SSL_FOLDER}/server.csr

openssl x509 -req -in ${SSL_FOLDER}/server.csr \
	-CA ${CA_FOLDER}/rootCA.pem -CAkey ${CA_FOLDER}/rootCA.key \
	-CAcreateserial -CAserial ${CA_FOLDER}/rootCA.srl -out ${SSL_FOLDER}/server.crt \
	-days 365 -sha256 -extfile ${OPENSSL_EXT_CONF}

cat ${SSL_FOLDER}/server.crt ${SSL_FOLDER}/server.key > ${SSL_FOLDER}/server.pem

openssl pkcs12 -inkey ${SSL_FOLDER}/server.pem -in ${SSL_FOLDER}/server.pem -export \
	-out ${SSL_FOLDER}/server.pfx -passin pass: -passout pass:

rm ${OPENSSL_CONF} ${OPENSSL_EXT_CONF}
